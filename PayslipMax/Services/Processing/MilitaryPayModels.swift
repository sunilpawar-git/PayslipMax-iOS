import Foundation

public struct MilitaryPayStructure: Codable {
    let version: Int
    let lastUpdated: String
    let description: String
    let payLevels: [String: PayLevel]
    let allowanceRatios: [String: AllowanceRatio]
    let commonDeductions: [String: DeductionInfo]
}

public struct PayLevel: Codable {
    let rank: String
    let basicPayRange: PayRange
    let msaRange: PayRange
    let level: String
}

public struct PayRange: Codable {
    let min: Double
    let max: Double
}

struct AllowanceRatio: Codable {
    let percentage: Double?
    let fixedAmount: Double?
    let xClassCities: Double?
    let yClassCities: Double?
    let zClassCities: Double?
    let rate: Double?
    let description: String
}

struct DeductionInfo: Codable {
    let description: String
    let typicalRange: [Double]?
    let calculation: String?
}

public enum ValidationStatus {
    case valid(String)
    case warning(String)
    case invalid(String)
    case unknown(String)

    var isValid: Bool {
        switch self {
        case .valid: return true
        default: return false
        }
    }

    var message: String {
        switch self {
        case .valid(let msg), .warning(let msg), .invalid(let msg), .unknown(let msg):
            return msg
        }
    }
}
