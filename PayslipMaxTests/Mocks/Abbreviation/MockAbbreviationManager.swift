import Foundation
@testable import Payslip_Max

class MockAbbreviationManager: AbbreviationManagerProtocol {
    var loadCallCount = 0
    var saveCallCount = 0
    var expandCallCount = 0
    var addCallCount = 0
    var removeCallCount = 0
    
    var shouldFailLoad = false
    var shouldFailSave = false
    
    var abbreviations: [Abbreviation] = []
    var customAbbreviations: [Abbreviation] = []
    
    func load() async throws {
        loadCallCount += 1
        if shouldFailLoad {
            throw MockError.loadFailed
        }
        
        // Default mock abbreviations
        if abbreviations.isEmpty {
            abbreviations = [
                Abbreviation(short: "HRA", expanded: "House Rent Allowance", isCustom: false),
                Abbreviation(short: "DA", expanded: "Dearness Allowance", isCustom: false),
                Abbreviation(short: "TA", expanded: "Travel Allowance", isCustom: false)
            ]
        }
    }
    
    func save() async throws {
        saveCallCount += 1
        if shouldFailSave {
            throw MockError.saveFailed
        }
    }
    
    func expand(abbreviation: String) -> String? {
        expandCallCount += 1
        
        // First check custom abbreviations
        if let custom = customAbbreviations.first(where: { $0.short == abbreviation }) {
            return custom.expanded
        }
        
        // Then check standard abbreviations
        if let standard = abbreviations.first(where: { $0.short == abbreviation }) {
            return standard.expanded
        }
        
        return nil
    }
    
    func add(abbreviation: Abbreviation) {
        addCallCount += 1
        if abbreviation.isCustom {
            customAbbreviations.append(abbreviation)
        } else {
            abbreviations.append(abbreviation)
        }
    }
    
    func remove(abbreviation: Abbreviation) {
        removeCallCount += 1
        if abbreviation.isCustom {
            customAbbreviations.removeAll { $0.short == abbreviation.short }
        } else {
            abbreviations.removeAll { $0.short == abbreviation.short }
        }
    }
    
    func reset() {
        loadCallCount = 0
        saveCallCount = 0
        expandCallCount = 0
        addCallCount = 0
        removeCallCount = 0
        shouldFailLoad = false
        shouldFailSave = false
        abbreviations = []
        customAbbreviations = []
    }
} 