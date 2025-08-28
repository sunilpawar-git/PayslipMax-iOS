import Foundation

/// Protocol for AI-powered military code recognition
public protocol MilitaryCodeRecognizerProtocol {
    func recognizeCodes(in textElements: [LiteRTTextElement]) async throws -> MilitaryCodeRecognitionResult
    func expandAbbreviation(_ code: String) async throws -> MilitaryCodeExpansion?
    func validateCode(_ code: String, context: MilitaryCodeContext) async throws -> MilitaryCodeValidation
    func standardizeCodes(_ codes: [String]) async throws -> [MilitaryCodeStandardization]
}

/// Comprehensive result of military code recognition
public struct MilitaryCodeRecognitionResult {
    let recognizedCodes: [MilitaryCode]
    let confidence: Double
    let unrecognizedElements: [LiteRTTextElement]
    let suggestions: [MilitaryCodeSuggestion]
}

/// Individual military code recognition
public struct MilitaryCode {
    let originalText: String
    let standardizedCode: String
    let category: MilitaryCodeCategory
    let confidence: Double
    let bounds: CGRect
    let expansion: MilitaryCodeExpansion
}

/// Military allowance code categories
public enum MilitaryCodeCategory {
    case allowance
    case deduction
    case specialPay
    case insurance
    case unknown
}

/// Expansion of military code abbreviation
public struct MilitaryCodeExpansion {
    let fullName: String
    let description: String
    let category: MilitaryCodeCategory
    let typicalAmount: ClosedRange<Double>?
    let isMandatory: Bool
}

/// Context for military code validation
public struct MilitaryCodeContext {
    let rank: String?
    let serviceType: String?
    let location: String?
    let payScale: String?
}

/// Validation result for military code
public struct MilitaryCodeValidation {
    let isValid: Bool
    let confidence: Double
    let issues: [String]
    let suggestions: [String]
}

/// Standardization result for military codes
public struct MilitaryCodeStandardization {
    let originalCode: String
    let standardizedCode: String
    let confidence: Double
    let changes: [String]
}

/// Suggestion for military code improvement
public struct MilitaryCodeSuggestion {
    let originalElement: LiteRTTextElement
    let suggestedCode: String
    let confidence: Double
    let reason: String
}

/// Military code patterns and expansions
public struct MilitaryCodePatterns {
    static let patterns: [String: MilitaryCodeExpansion] = [
        "DSOP": MilitaryCodeExpansion(
            fullName: "Defence Savings Option Plan Fund",
            description: "Voluntary savings scheme for defence personnel",
            category: .deduction,
            typicalAmount: 1000...50000,
            isMandatory: false
        ),
        "DSOPF": MilitaryCodeExpansion(
            fullName: "Defence Savings Option Plan Fund",
            description: "Voluntary savings scheme for defence personnel",
            category: .deduction,
            typicalAmount: 1000...50000,
            isMandatory: false
        ),
        "AGIF": MilitaryCodeExpansion(
            fullName: "Armed Forces Group Insurance Fund",
            description: "Group insurance scheme for armed forces",
            category: .insurance,
            typicalAmount: 500...5000,
            isMandatory: true
        ),
        "MSP": MilitaryCodeExpansion(
            fullName: "Military Service Pay",
            description: "Special pay for military service",
            category: .specialPay,
            typicalAmount: 1000...15000,
            isMandatory: true
        ),
        "HRA": MilitaryCodeExpansion(
            fullName: "House Rent Allowance",
            description: "Allowance for housing accommodation",
            category: .allowance,
            typicalAmount: 2000...50000,
            isMandatory: false
        ),
        "DA": MilitaryCodeExpansion(
            fullName: "Dearness Allowance",
            description: "Allowance to offset inflation impact",
            category: .allowance,
            typicalAmount: 5000...100000,
            isMandatory: true
        ),
        "CCA": MilitaryCodeExpansion(
            fullName: "City Compensatory Allowance",
            description: "Allowance for urban cost of living",
            category: .allowance,
            typicalAmount: 500...5000,
            isMandatory: false
        ),
        "TA": MilitaryCodeExpansion(
            fullName: "Transport Allowance",
            description: "Allowance for transportation costs",
            category: .allowance,
            typicalAmount: 1000...10000,
            isMandatory: true
        ),
        "LTC": MilitaryCodeExpansion(
            fullName: "Leave Travel Concession",
            description: "Concession for travel during leave",
            category: .allowance,
            typicalAmount: 10000...50000,
            isMandatory: false
        ),
        "RH": MilitaryCodeExpansion(
            fullName: "Rank Pay",
            description: "Pay based on military rank",
            category: .specialPay,
            typicalAmount: 5000...30000,
            isMandatory: true
        ),
        "RH12": MilitaryCodeExpansion(
            fullName: "Rank Pay",
            description: "Pay based on military rank",
            category: .specialPay,
            typicalAmount: 5000...30000,
            isMandatory: true
        )
    ]

    static let variations: [String: String] = [
        "DSOP": "DSOPF",
        "DEFENCESAVINGS": "DSOPF",
        "ARMEDFORCESINSURANCE": "AGIF",
        "MILITARYSERVICEPAY": "MSP",
        "HOUSERENTALLOWANCE": "HRA",
        "DEARNESSALLOWANCE": "DA",
        "CITYCOMPENSATORYALLOWANCE": "CCA",
        "TRANSPORTALLOWANCE": "TA",
        "LEAVETRAVELCONCESSION": "LTC",
        "RANKPAY": "RH"
    ]
}
