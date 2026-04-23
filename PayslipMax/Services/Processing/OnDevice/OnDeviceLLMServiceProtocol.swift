import Foundation

/// Result from on-device LLM payslip extraction
struct OnDeviceLLMResult {
    let earnings: [String: Double]
    let deductions: [String: Double]
    let grossPay: Double
    let totalDeductions: Double
    let netRemittance: Double
    let month: String?
    let year: Int?
}

/// Protocol for on-device LLM payslip parsing.
/// Implementations must run entirely on-device with zero network calls.
protocol OnDeviceLLMServiceProtocol: Sendable {
    /// Whether the on-device model is currently available
    var isAvailable: Bool { get }

    /// Attempts to parse payslip text using the on-device LLM.
    /// Returns nil if the model is unavailable or cannot parse the input.
    func parsePayslip(text: String) async -> OnDeviceLLMResult?
}
