import Foundation
@testable import Payslip_Max

// Define the protocol based on PayslipPatternManager functionality
protocol PayslipPatternManagerProtocol {
    func getPattern(for format: PayslipFormat) -> [String: String]
    func getCommonKeywords(for format: PayslipFormat) -> [String]
}

class MockPayslipPatternManager: PayslipPatternManagerProtocol {
    nonisolated(unsafe) var shouldFail = false
    nonisolated(unsafe) var getPatternForFormatCallCount = 0
    nonisolated(unsafe) var getCommonKeywordsCallCount = 0
    nonisolated(unsafe) var patternResult: [String: String] = [:]
    nonisolated(unsafe) var keywordsResult: [String] = []
    
    init() {}
    
    nonisolated func getPattern(for format: PayslipFormat) -> [String: String] {
        getPatternForFormatCallCount += 1
        return shouldFail ? [:] : patternResult
    }
    
    nonisolated func getCommonKeywords(for format: PayslipFormat) -> [String] {
        getCommonKeywordsCallCount += 1
        return shouldFail ? [] : keywordsResult
    }
    
    nonisolated func reset() {
        shouldFail = false
        getPatternForFormatCallCount = 0
        getCommonKeywordsCallCount = 0
        patternResult = [:]
        keywordsResult = []
    }
} 