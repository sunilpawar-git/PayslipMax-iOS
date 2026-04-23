import Foundation
import FoundationModels
import os

/// On-device payslip parser using Apple Foundation Models (iOS 26+).
/// Runs entirely on-device -- zero network calls, zero PII exposure.
@available(iOS 26, *)
final class FoundationModelPayslipService: OnDeviceLLMServiceProtocol {

    private let logger = os.Logger(
        subsystem: "com.payslipmax.ondevice",
        category: "FoundationModel"
    )

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func parsePayslip(text: String) async -> OnDeviceLLMResult? {
        guard isAvailable else {
            logger.info("On-device model not available")
            return nil
        }

        let truncatedText = truncateForTokenBudget(text)
        let session = LanguageModelSession(instructions: Self.instructions)

        do {
            let response = try await session.respond(
                to: "Extract financial data from this Indian military payslip:\n\n\(truncatedText)",
                generating: PayslipExtractionSchema.self
            )
            let schema = response.content
            logger.info("On-device extraction succeeded: gross=\(schema.grossPay)")
            return schema.toResult()
        } catch {
            logger.error("On-device extraction failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Truncates input to stay within the ~4K token budget (roughly 3 chars per token)
    private func truncateForTokenBudget(_ text: String, maxChars: Int = 10000) -> String {
        if text.count <= maxChars { return text }
        return String(text.prefix(maxChars))
    }

    private static let instructions = """
    You are a military payslip data extractor. Extract ONLY financial data.
    NEVER extract names, account numbers, PAN, or personal information.
    Map pay codes to their standard abbreviations (BPAY, DA, MSP, DSOP, ITAX, AGIF, etc.).
    Ensure grossPay equals the sum of earnings, totalDeductions equals the sum of deductions,
    and netRemittance equals grossPay minus totalDeductions.
    """
}
