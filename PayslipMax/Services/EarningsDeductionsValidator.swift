import Foundation

/// Protocol for validating and adjusting earnings and deductions data
/// This component handles data consistency, duplicate removal, and misc value calculations
protocol EarningsDeductionsValidatorProtocol {
    /// Validate data and make adjustments if needed
    /// - Parameter data: Data structure to validate and adjust
    func validateAndAdjustData(_ data: inout EarningsDeductionsData)

    /// Remove duplicate entries that appear in both earnings and deductions
    /// - Parameter data: Data structure to clean up
    func removeDuplicateEntries(_ data: inout EarningsDeductionsData)

    /// Calculate miscCredits and miscDebits from unknown items
    /// - Parameter data: Data structure to update
    func calculateMiscValues(_ data: inout EarningsDeductionsData)
}

/// Implementation of the validator protocol
class EarningsDeductionsValidator: EarningsDeductionsValidatorProtocol {
    private let abbreviationManager: AbbreviationManager

    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
    }

    /// Validate data and make adjustments if needed
    /// - Parameter data: Data structure to validate and adjust
    func validateAndAdjustData(_ data: inout EarningsDeductionsData) {
        // Ensure standard components are properly categorized
        let standardEarningsKeys = ["BPAY", "DA", "MSP"]
        let standardDeductionsKeys = ["DSOP", "AGIF", "ITAX"]

        // Move any standard earnings from knownEarnings to their proper fields
        for key in standardEarningsKeys {
            if let value = data.knownEarnings[key] {
                switch key {
                case "BPAY": data.bpay = value
                case "DA": data.da = value
                case "MSP": data.msp = value
                default: break
                }
                data.knownEarnings.removeValue(forKey: key)
            }
        }

        // Move any standard deductions from knownDeductions to their proper fields
        for key in standardDeductionsKeys {
            if let value = data.knownDeductions[key] {
                switch key {
                case "DSOP": data.dsop = value
                case "AGIF": data.agif = value
                case "ITAX": data.itax = value
                default: break
                }
                data.knownDeductions.removeValue(forKey: key)
            }
        }
    }

    /// Remove duplicate entries that appear in both earnings and deductions
    /// - Parameter data: Data structure to clean up
    func removeDuplicateEntries(_ data: inout EarningsDeductionsData) {
        // For each item in both earnings and deductions, determine its correct category
        let allKeys = Set(data.rawEarnings.keys).union(Set(data.rawDeductions.keys))

        for key in allKeys {
            // Skip if it doesn't appear in both collections
            guard data.rawEarnings[key] != nil && data.rawDeductions[key] != nil else { continue }

            // Convert key to uppercase for comparison
            let upperKey = key.uppercased()
            let type = abbreviationManager.getType(for: upperKey)

            switch type {
            case .earning:
                // Keep in earnings, remove from deductions
                data.rawDeductions.removeValue(forKey: key)
            case .deduction:
                // Keep in deductions, remove from earnings
                data.rawEarnings.removeValue(forKey: key)
            case .unknown:
                // For unknown, keep in both but add to misc
                if let value = data.rawEarnings[key] {
                    data.miscCredits += value
                }
                if let value = data.rawDeductions[key] {
                    data.miscDebits += value
                }
            }
        }
    }

    /// Calculate miscCredits and miscDebits from unknown items
    /// - Parameter data: Data structure to update
    func calculateMiscValues(_ data: inout EarningsDeductionsData) {
        // Sum up all unknown earnings
        for (_, value) in data.unknownEarnings {
            data.miscCredits += value
        }

        // Sum up all unknown deductions
        for (_, value) in data.unknownDeductions {
            data.miscDebits += value
        }
    }
}
