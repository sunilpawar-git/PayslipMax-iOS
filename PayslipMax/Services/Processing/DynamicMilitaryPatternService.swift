//
//  DynamicMilitaryPatternService.swift
//  PayslipMax
//
//  Created for configurable military payslip pattern matching
//  Supports all ranks from Level 10-16+ with dynamic validation
//

import Foundation

/// Service for dynamic military pattern generation and validation
/// Configurable for all Indian Armed Forces ranks and pay structures
class DynamicMilitaryPatternService {

    // MARK: - Properties

    private var payStructure: MilitaryPayStructure?
    private var componentValidator: MilitaryComponentValidator?

    // MARK: - Initialization

    init() {
        loadPayStructure()
        componentValidator = MilitaryComponentValidator(payStructure: payStructure)
    }

    // MARK: - Public Methods

    /// Generates dynamic patterns for BPAY based on military structure
    func generateBPayPatterns() -> [String] {
        guard let payStructure = payStructure else {
            return [getBasicBPayPattern()]
        }

        var patterns: [String] = []

        // Generate patterns for all pay levels
        for (levelKey, _) in payStructure.payLevels {
            // Pattern for BPAY with level in parentheses
            patterns.append("(?:BASIC\\s+PAY|BPAY)\\s*\\(\\s*\(levelKey)\\s*\\)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)")

            // Pattern for level-specific variations
            patterns.append("(?:BASIC\\s+PAY|BPAY)\\s*\\(?\\s*(?:LEVEL\\s+)?\(levelKey)\\s*\\)?\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)")
        }

        // Add general BPAY pattern as fallback
        patterns.append(getBasicBPayPattern())

        return patterns
    }

    /// Validates extracted BPAY against known military pay ranges
    func validateBasicPay(_ amount: Double, forLevel level: String? = nil) -> ValidationStatus {
        return componentValidator?.validateBasicPay(amount, forLevel: level) ?? .unknown("Validator not available")
    }

    /// Detects military level from payslip text
    func detectMilitaryLevel(from text: String) -> String? {
        guard let payStructure = payStructure else { return nil }

        let uppercaseText = text.uppercased()

        // Look for explicit level mentions
        for (levelKey, levelData) in payStructure.payLevels {
            let levelPatterns = [
                "LEVEL\\s+\(levelKey)",
                "BPAY\\s*\\(\\s*\(levelKey)\\s*\\)",
                "\(levelKey)\\s*LEVEL",
                levelData.rank.uppercased()
            ]

            for pattern in levelPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   regex.firstMatch(in: uppercaseText, options: [], range: NSRange(location: 0, length: uppercaseText.count)) != nil {
                    return levelKey
                }
            }
        }

        return nil
    }

    /// Pre-validates extracted amount before adding to results (SOLID: Single Responsibility)
    func preValidateExtraction(_ component: String, amount: Double, basicPay: Double?, level: String?) -> Bool {
        return componentValidator?.preValidateExtraction(component, amount: amount, basicPay: basicPay, level: level) ?? true
    }

    /// Generates comprehensive allowance patterns for all military ranks
    func generateAllowancePatterns() -> [String: [String]] {
        var patterns: [String: [String]] = [:]

        // MSP patterns (fixed for all ranks)
        patterns["MSP"] = [
            "(?:MSP|MILITARY\\s+SERVICE\\s+PAY)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:MILITARY\\s+SERVICE\\s+PAY|MSP)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"
        ]

        // DA patterns (percentage-based)
        patterns["DA"] = [
            "(?:DA|DEARNESS\\s+ALLOWANCE|D\\.A\\.)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:DEARNESS\\s+ALLOWANCE|DA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"
        ]

        // HRA patterns (city-dependent) - WITH PRE-VALIDATION
        // Note: HRA extraction is disabled by default to prevent false positives
        // Will only extract if explicitly validated against basic pay
        patterns["HRA"] = []

        // RH11 patterns (risk and hardship level 11)
        patterns["RH11"] = [
            "(?:RH11)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*11)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH12 patterns (risk and hardship level 12)
        patterns["RH12"] = [
            "(?:RH12|RISK\\s+(?:AND\\s+)?HARDSHIP|R&H|RISK\\s+HARDSHIP)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:RISK\\s+(?:AND\\s+)?HARDSHIP\\s+ALLOWANCE|RH12)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:RH\\s*12)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH13 patterns (risk and hardship level 13)
        patterns["RH13"] = [
            "(?:RH13)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*13)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH21 patterns (risk and hardship level 21)
        patterns["RH21"] = [
            "(?:RH21)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*21)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH22 patterns (risk and hardship level 22)
        patterns["RH22"] = [
            "(?:RH22)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*22)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH23 patterns (risk and hardship level 23)
        patterns["RH23"] = [
            "(?:RH23)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*23)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH31 patterns (risk and hardship level 31)
        patterns["RH31"] = [
            "(?:RH31)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*31)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH32 patterns (risk and hardship level 32)
        patterns["RH32"] = [
            "(?:RH32)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*32)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // RH33 patterns (risk and hardship level 33)
        patterns["RH33"] = [
            "(?:RH33)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s*33)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]

        // Transport allowances
        patterns["TPTA"] = [
            "(?:TPTA|TRANSPORT\\s+ALLOWANCE|TA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:TRANSPORT\\s+ALLOWANCE|TPTA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"
        ]

        patterns["TPTADA"] = [
            "(?:TPTADA|TRANSPORT\\s+ALLOWANCE\\s+DA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)",
            "(?:TRANSPORT\\s+ALLOWANCE\\s+DA|TPTADA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"
        ]

        return patterns
    }

    /// Validates allowance amounts against military standards
    func validateAllowance(_ component: String, amount: Double, basicPay: Double?, level: String?) -> ValidationStatus {
        return componentValidator?.validateAllowance(component, amount: amount, basicPay: basicPay, level: level) ?? .unknown("Validator not available")
    }

    // MARK: - Private Methods

    private func loadPayStructure() {
        guard let url = Bundle.main.url(forResource: "military_pay_structure", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let structure = try? JSONDecoder().decode(MilitaryPayStructure.self, from: data) else {
            print("[DynamicMilitaryPatternService] Failed to load military pay structure")
            return
        }

        self.payStructure = structure
        print("[DynamicMilitaryPatternService] Loaded pay structure with \(structure.payLevels.count) levels")
    }

    private func getBasicBPayPattern() -> String {
        return "(?:BASIC\\s+PAY|BPAY(?:\\s*\\([^)]*\\))?)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"
    }

    private func validateAmountInRange(_ amount: Double, range: PayRange, component: String) -> ValidationStatus {
        if amount >= range.min && amount <= range.max {
            return .valid("\(component) within valid range")
        } else if amount < range.min {
            return .warning("\(component) ₹\(amount) below minimum ₹\(range.min)")
        } else {
            return .warning("\(component) ₹\(amount) above maximum ₹\(range.max)")
        }
    }
}

// MARK: - Supporting Models

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
