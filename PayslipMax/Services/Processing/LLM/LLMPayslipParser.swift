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
    private static let systemPrompt = LLMPrompt.payslip
    private static let reconciliationHint = """
    Ensure every numeric value is a plain number (no currency symbols or commas).
    Reconcile totals strictly: netRemittance must equal grossPay - totalDeductions.
    If totals are missing, derive them from the earnings/deductions you extract.
    """

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

    // MARK: - Public Methods

    /// Calls the LLM service to parse the text
    /// - Parameter prompt: The prompt containing the redacted payslip text
    /// - Returns: The raw JSON response string
    private func callLLM(prompt: String) async throws -> String {
        if BuildConfiguration.useBackendProxy {
            // Use backend proxy (production/secure mode)
            let backendService = LLMBackendService()
            return try await backendService.parsePayslip(text: prompt)
        } else {
            // Direct API call (development only)
            // Note: This requires the API key to be present in APIKeys.swift
            let request = LLMRequest(
                prompt: prompt,
                systemPrompt: Self.systemPrompt,
                jsonMode: true
            )
            let response = try await service.send(request)
            return response.content
        }
    }

    /// Parses payslip text into a PayslipItem
    /// - Parameter text: Raw payslip text
    /// - Returns: Parsed PayslipItem
    /// - Throws: LLMError or AnonymizationError
    func parse(_ text: String) async throws -> PayslipItem {
        let startTime = Date()
        var response: LLMResponse?

        do {
            // 1. Redact PII (skip work when redactor is no-op)
            let redactedText: String
            if let selectiveRedactor = selectiveRedactor {
                if selectiveRedactor is NoOpSelectiveRedactor {
                    logger.info("Skipping redaction (no-op redactor)")
                    redactedText = text
                } else {
                    logger.info("Using selective redaction (preserves structure)")
                    redactedText = try selectiveRedactor.redact(text)
                }
            } else if let anonymizer = anonymizer {
                logger.info("Using full anonymization (legacy)")
                redactedText = try anonymizer.anonymize(text)
            } else {
                logger.error("No redactor configured!")
                throw AnonymizationError.noTextProvided
            }

            // 2. Create prompt
            let prompt = createPrompt(from: redactedText)

            // 3. Create request for tracking
            let request = LLMRequest(
                prompt: prompt,
                systemPrompt: Self.systemPrompt,
                jsonMode: true
            )

            // 4. Call LLM
            logger.info("Sending request to LLM provider: \(self.service.provider.rawValue)")

            // Use helper method to support backend proxy
            let responseContent = try await callLLM(prompt: prompt)

            // Create response object for processing
            response = LLMResponse(content: responseContent, usage: nil)

            // 5. Parse JSON response
            let cleanedContent = cleanJSONResponse(response?.content ?? "")
            guard let data = cleanedContent.data(using: .utf8) else {
                throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
            }

            let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
            let sanitizedResponse = sanitizeResponse(llmResponse)
            validate(response: sanitizedResponse)
            logger.info("Successfully parsed LLM response after reconciliation")

            let result = mapToPayslipItem(sanitizedResponse, originalText: text)

            // Track successful usage
            await trackUsage(request: request, response: response, error: nil, startTime: startTime)

            return result

        } catch {
            logger.error("Failed to parse payslip: \(error.localizedDescription)")

            // Track failed usage
            let request = LLMRequest(prompt: "", systemPrompt: LLMPrompt.payslip, jsonMode: true)
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
        \(Self.reconciliationHint)

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

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extra safety: trim to the outermost JSON braces to drop any leading/trailing prose
        if let firstBrace = cleaned.firstIndex(of: "{"), let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        return cleaned
    }

    private func validate(response: LLMPayslipResponse) {
        // Require totals to reconcile when provided
        guard let gross = response.grossPay,
              let deductionsTotal = response.totalDeductions,
              let net = response.netRemittance else {
            // If any totals are missing, skip strict validation (will be handled downstream)
            return
        }

        let netError = reconciliationError(gross: gross, deductions: deductionsTotal, net: net)
        if net > 0 && netError > 0.05 {
            logger.warning("LLM totals mismatch beyond tolerance (gross: \(gross), deductions: \(deductionsTotal), net: \(net), error: \(String(format: "%.2f%%", netError * 100))) - accepting response for fallback")
            return
        }

        let netErrorPercent = String(format: "%.2f%%", netError * 100)
        logger.info("LLM totals validated within tolerance (gross: \(gross), deductions: \(deductionsTotal), net: \(net), netError: \(netErrorPercent))")
    }

    private func sanitizeResponse(_ response: LLMPayslipResponse) -> LLMPayslipResponse {
        let earningsTotal = response.earnings?.values.reduce(0, +) ?? 0
        let deductionsTotal = response.deductions?.values.reduce(0, +) ?? 0

        let gross = response.grossPay ?? earningsTotal
        let deductions = response.totalDeductions ?? deductionsTotal
        let reconciledNet = gross - deductions
        let providedNet = response.netRemittance ?? reconciledNet

        let error = reconciliationError(gross: gross, deductions: deductions, net: providedNet)
        if error > 0.05 {
            logger.warning("LLM totals mismatch beyond tolerance; reconciling net to gross - deductions (error: \(String(format: "%.2f%%", error * 100)))")
        }

        return LLMPayslipResponse(
            earnings: response.earnings,
            deductions: response.deductions,
            grossPay: gross > 0 ? gross : earningsTotal,
            totalDeductions: deductions > 0 ? deductions : deductionsTotal,
            netRemittance: error > 0.05 ? reconciledNet : providedNet,
            month: response.month,
            year: response.year
        )
    }

    private func reconciliationError(gross: Double, deductions: Double, net: Double) -> Double {
        guard gross > 0 else { return 0 }
        return abs((gross - deductions) - net) / gross
    }

    private func mapToPayslipItem(_ response: LLMPayslipResponse, originalText: String) -> PayslipItem {
        // Use defaults for missing values to ensure robustness
        let earnings = response.earnings ?? [:]
        let deductions = response.deductions ?? [:]

        // Calculate totals if missing
        let calculatedCredits = earnings.values.reduce(0, +)
        let calculatedDebits = deductions.values.reduce(0, +)

        let credits = response.grossPay ?? calculatedCredits
        let debits = response.totalDeductions ?? calculatedDebits

        // Extract DSOP and tax from deductions (common deduction codes)
        let dsop = deductions["DSOP"] ?? 0.0
        let tax = deductions["ITAX"] ?? deductions["TAX"] ?? 0.0

        // Calculate confidence using unified confidence calculator
        let confidenceResult = LLMConfidenceCalculator.calculateConfidence(
            for: response,
            earnings: earnings,
            deductions: deductions
        )

        return PayslipItem(
            id: UUID(),
            month: response.month ?? "",
            year: response.year ?? Calendar.current.component(.year, from: Date()),
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            earnings: earnings,
            deductions: deductions,
            source: "LLM (\(service.provider.rawValue))",
            confidenceScore: confidenceResult.overall,
            fieldConfidences: confidenceResult.fieldLevel
        )
    }
}
