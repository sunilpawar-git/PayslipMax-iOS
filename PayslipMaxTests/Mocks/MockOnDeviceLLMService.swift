import Foundation
@testable import PayslipMax

/// Mock implementation of OnDeviceLLMServiceProtocol for unit testing
final class MockOnDeviceLLMService: OnDeviceLLMServiceProtocol {

    var mockIsAvailable: Bool = true
    var mockResult: OnDeviceLLMResult?
    var parseCallCount = 0
    var lastParsedText: String?

    var isAvailable: Bool { mockIsAvailable }

    func parsePayslip(text: String) async -> OnDeviceLLMResult? {
        parseCallCount += 1
        lastParsedText = text
        return mockResult
    }

    /// Creates a realistic mock result for testing
    static func makeDefaultResult() -> OnDeviceLLMResult {
        OnDeviceLLMResult(
            earnings: ["BPAY": 56900, "DA": 34140, "MSP": 15500],
            deductions: ["DSOP": 15000, "AGIF": 7500, "ITAX": 12000],
            grossPay: 106540,
            totalDeductions: 34500,
            netRemittance: 72040,
            month: "JANUARY",
            year: 2025
        )
    }
}
