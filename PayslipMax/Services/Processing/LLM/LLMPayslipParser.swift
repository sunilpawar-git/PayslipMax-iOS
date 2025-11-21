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
    private let anonymizer: PayslipAnonymizerProtocol
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Parser")

    // MARK: - Initialization

    init(service: LLMServiceProtocol, anonymizer: PayslipAnonymizerProtocol) {
        self.service = service
        self.anonymizer = anonymizer
    }

    // MARK: - Constants

    private let systemPrompt = """
    You are a military payslip parser. Extract earnings and deductions from this payslip.

    IMPORTANT: Return ONLY valid JSON, no markdown formatting or explanations.

    Return JSON in this exact format:
    {
      "earnings": {
        "BPAY": <amount>,
        "DA": <amount>,
        "MSP": <amount>,
        ...
      },
      "deductions": {
        "DSOP": <amount>,
        "AGIF": <amount>,
        "ITAX": <amount>,
        ...
      },
      "grossPay": <amount>,
      "totalDeductions": <amount>,
      "netRemittance": <amount>,
      "month": "JUNE", // Full month name in uppercase
      "year": 2025
    }
    """

    // MARK: - Public Methods

    /// Parses payslip text into a PayslipItem
    /// - Parameter text: Raw payslip text
    /// - Returns: Parsed PayslipItem
    /// - Throws: LLMError or AnonymizationError
    func parse(_ text: String) async throws -> PayslipItem {
        // 1. Anonymize
        logger.info("Anonymizing text before LLM processing...")
        let anonymizedText = try anonymizer.anonymize(text)

        // 2. Create prompt
        let prompt = createPrompt(from: anonymizedText)

        // 3. Call LLM
        logger.info("Sending request to LLM provider: \(self.service.provider.rawValue)")
        let request = LLMRequest(
            prompt: prompt,
            systemPrompt: systemPrompt,
            jsonMode: true
        )

        let response = try await service.send(request)

        // 4. Parse JSON response
        guard let data = response.content.data(using: .utf8) else {
            throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
        }

        do {
            let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
            logger.info("Successfully parsed LLM response")
            return mapToPayslipItem(llmResponse)
        } catch {
            logger.error("Failed to decode LLM response: \(error.localizedDescription)")
            throw LLMError.decodingError(error)
        }
    }

    // MARK: - Private Methods

    private func createPrompt(from text: String) -> String {
        return """
        Payslip Text (anonymized):
        \(text)
        """
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
