//
//  LLMPayslipParser.swift
//  PayslipMax
//
//  Parses payslips using LLM services
//

import Foundation
import OSLog

/// Parses payslip text using an LLM service
class LLMPayslipParser {

    // MARK: - Properties

    private let service: LLMServiceProtocol
    private let anonymizer: PayslipAnonymizerProtocol?
    private let selectiveRedactor: SelectiveRedactorProtocol?
    private let usageTracker: LLMUsageTrackerProtocol?
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Parser")

    // MARK: - Initialization

    /// Initializes with full anonymization (legacy)
    init(service: LLMServiceProtocol,
         anonymizer: PayslipAnonymizerProtocol,
         usageTracker: LLMUsageTrackerProtocol? = nil) {
        self.service = service
        self.anonymizer = anonymizer
        self.selectiveRedactor = nil
        self.usageTracker = usageTracker
    }

    /// Initializes with selective redaction (recommended)
    init(service: LLMServiceProtocol,
         selectiveRedactor: SelectiveRedactorProtocol,
         usageTracker: LLMUsageTrackerProtocol? = nil) {
        self.service = service
        self.anonymizer = nil
        self.selectiveRedactor = selectiveRedactor
        self.usageTracker = usageTracker
    }

    // MARK: - Constants

    private static let systemPrompt = """
    You are a military payslip parser. Extract earnings and deductions from payslips.

    PRIVACY PROTECTION: The payslip text has been selectively redacted for privacy:
    - ***NAME*** = Personal name (redacted for privacy)
    - ***ACCOUNT*** = Bank/account number (redacted)
    - ***PAN*** = PAN card number (redacted)
    - ***PHONE*** = Phone number (redacted)
    - ***EMAIL*** = Email address (redacted)

    IMPORTANT: These placeholders protect user privacy. Focus on extracting:
    - Pay codes (BPAY, DA, MSP, etc.) and their amounts
    - Deduction codes (DSOP, AGIF, ITAX, etc.) and their amounts
    - Totals (Gross Pay, Total Deductions, Net Remittance)
    - Month and year

    Ignore the redacted placeholders - they are not pay codes.

    IMPORTANT: Return ONLY valid JSON, no markdown formatting or explanations.

    Return JSON in this exact format:
    {
      \"earnings\": {
        \"BPAY\": <amount>,
        \"DA\": <amount>,
        \"MSP\": <amount>,
        ...
      },
      \"deductions\": {
        \"DSOP\": <amount>,
        \"AGIF\": <amount>,
        \"ITAX\": <amount>,
        ...
      },
      \"grossPay\": <amount>,
      \"totalDeductions\": <amount>,
      \"netRemittance\": <amount>,
      \"month\": \"JUNE\", // Full month name in uppercase
      \"year\": 2025
    }
    """

    // MARK: - Public Methods

    /// Parses payslip text into a PayslipItem
    /// - Parameter text: Raw payslip text
    /// - Returns: Parsed PayslipItem
    /// - Throws: LLMError or AnonymizationError
    func parse(_ text: String) async throws -> PayslipItem {
        let startTime = Date()
        var response: LLMResponse?

        do {
            // 1. Redact PII (selective or full based on configuration)
            logger.info("Redacting PII before LLM processing...")
            let redactedText: String
            if let selectiveRedactor = selectiveRedactor {
                logger.info("Using selective redaction (preserves structure)")
                redactedText = try selectiveRedactor.redact(text)
            } else if let anonymizer = anonymizer {
                logger.info("Using full anonymization (legacy)")
                redactedText = try anonymizer.anonymize(text)
            } else {
                logger.error("No redactor configured!")
                throw AnonymizationError.noTextProvided
            }

            // 2. Create prompt
            let prompt = createPrompt(from: redactedText)

            // 3. Call LLM
            logger.info("Sending request to LLM provider: \(self.service.provider.rawValue)")
            let request = LLMRequest(
                prompt: prompt,
                systemPrompt: Self.systemPrompt,
                jsonMode: true
            )

            response = try await service.send(request)

            // 4. Parse JSON response
            let cleanedContent = cleanJSONResponse(response?.content ?? "")
            guard let data = cleanedContent.data(using: .utf8) else {
                throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
            }

            let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
            logger.info("Successfully parsed LLM response")

            let result = mapToPayslipItem(llmResponse)

            // Track successful usage
            await trackUsage(request: request, response: response, error: nil, startTime: startTime)

            return result

        } catch {
            logger.error("Failed to parse payslip: \(error.localizedDescription)")

            // Track failed usage
            let request = LLMRequest(prompt: "", systemPrompt: Self.systemPrompt, jsonMode: true)
            await trackUsage(request: request, response: response, error: error, startTime: startTime)

            throw error
        }
    }

    // MARK: - Usage Tracking

    private func trackUsage(request: LLMRequest, response: LLMResponse?, error: Error?, startTime: Date) async {
        guard let tracker = usageTracker else { return }

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        do {
            try await tracker.trackUsage(
                request: request,
                response: response,
                provider: service.provider,
                model: getModelName(),
                latencyMs: latencyMs,
                error: error
            )
        } catch {
            logger.error("Failed to track usage: \(error.localizedDescription)")
        }
    }

    private func getModelName() -> String {
        // Try to extract model name from service
        // This is a simple approach; could be improved with a protocol method
        switch service.provider {
        case .gemini:
            return "gemini-2.5-flash-lite"
        case .mock:
            return "mock"
        }
    }

    // MARK: - Private Methods

    private func createPrompt(from text: String) -> String {
        return """
        Payslip Text (anonymized):
        \(text)
        """
    }

    private func cleanJSONResponse(_ content: String) -> String {
        // Remove markdown code blocks if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        } else if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }

        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func mapToPayslipItem(_ response: LLMPayslipResponse) -> PayslipItem {
        // Use defaults for missing values to ensure robustness
        let earnings = response.earnings ?? [:]
        let deductions = response.deductions ?? [:]

        // Calculate totals if missing
        let calculatedCredits = earnings.values.reduce(0, +)
        let calculatedDebits = deductions.values.reduce(0, +)

        return PayslipItem(
            month: response.month ?? "UNKNOWN",
            year: response.year ?? Calendar.current.component(.year, from: Date()),
            credits: response.grossPay ?? calculatedCredits,
            debits: response.totalDeductions ?? calculatedDebits,
            dsop: deductions["DSOP"] ?? 0.0,
            tax: deductions["ITAX"] ?? 0.0,
            earnings: earnings,
            deductions: deductions,
            source: "LLM (\(service.provider.rawValue))"
        )
    }
}

// MARK: - Internal Models

private struct LLMPayslipResponse: Decodable {
    let earnings: [String: Double]?
    let deductions: [String: Double]?
    let grossPay: Double?
    let totalDeductions: Double?
    let netRemittance: Double?
    let month: String?
    let year: Int?
}
