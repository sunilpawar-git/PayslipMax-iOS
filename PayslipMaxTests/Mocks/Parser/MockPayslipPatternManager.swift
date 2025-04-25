import Foundation
@testable import Payslip_Max

class MockPayslipPatternManager: PayslipPatternManagerProtocol {
    var patterns: [PatternType: [String]] = [:]
    var loadCallCount = 0
    var saveCallCount = 0
    var shouldFailLoad = false
    var shouldFailSave = false
    
    func loadPatterns() async throws {
        loadCallCount += 1
        if shouldFailLoad {
            throw MockError.loadFailed
        }
    }
    
    func savePatterns() async throws {
        saveCallCount += 1
        if shouldFailSave {
            throw MockError.saveFailed
        }
    }
    
    func getPatterns(for type: PatternType) -> [String] {
        return patterns[type] ?? []
    }
    
    func reset() {
        patterns = [:]
        loadCallCount = 0
        saveCallCount = 0
        shouldFailLoad = false
        shouldFailSave = false
    }
} 