import Foundation

// MARK: - RH12 Section Classification

extension PayslipSectionClassifier {

    /// Classifies RH12 component into earnings or deductions based on section context
    /// RH12 can appear in both sections in military payslips
    func classifyRH12SectionImpl(key: String, value: Double, text: String) -> PayslipSection {
        let uppercaseText = text.uppercased()

        let valueString = String(format: "%.0f", value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let commaFormattedValue = formatter.string(from: NSNumber(value: value)) ?? valueString

        let searchPatterns = [
            "RH12[\\s]*.*[\\s]*\(valueString)",
            "RH12[\\s]*.*[\\s]*\(commaFormattedValue)",
            "\(valueString)[\\s]*.*RH12",
            "\(commaFormattedValue)[\\s]*.*RH12",
            "RH12[\\s]+\(valueString)",
            "RH12[\\s]+\(commaFormattedValue)"
        ]

        var matchPosition = -1
        for pattern in searchPatterns {
            if let range = uppercaseText.range(of: pattern, options: .regularExpression) {
                matchPosition = uppercaseText.distance(from: uppercaseText.startIndex, to: range.lowerBound)
                break
            }
        }

        guard matchPosition >= 0 else {
            return .earnings
        }

        let beforeMatch = String(uppercaseText.prefix(matchPosition + 200))
        let beforeMatchLast1000 = String(beforeMatch.suffix(1000))

        let earningsIndicators = [
            "EARNINGS", "आय", "CREDIT", "जमा", "GROSS PAY", "TOTAL EARNINGS", "कुल आय",
            "ALLOWANCES"
        ]

        let deductionsIndicators = [
            "DEDUCTIONS", "कटौती", "DEBIT", "नामे", "TOTAL DEDUCTIONS", "कुल कटौती"
        ]

        var lastEarningsPos = -1
        var lastDeductionsPos = -1

        for indicator in earningsIndicators {
            if let range = beforeMatchLast1000.range(of: indicator, options: .backwards) {
                let pos = beforeMatchLast1000.distance(from: beforeMatchLast1000.startIndex, to: range.lowerBound)
                lastEarningsPos = max(lastEarningsPos, pos)
            }
        }

        for indicator in deductionsIndicators {
            if let range = beforeMatchLast1000.range(of: indicator, options: .backwards) {
                let pos = beforeMatchLast1000.distance(from: beforeMatchLast1000.startIndex, to: range.lowerBound)
                lastDeductionsPos = max(lastDeductionsPos, pos)
            }
        }

        let hasStrongEarningsContext = lastEarningsPos > lastDeductionsPos && lastEarningsPos >= 0
        let hasStrongDeductionsContext = lastDeductionsPos > lastEarningsPos && lastDeductionsPos >= 0

        if value >= 15000 {
            return .earnings
        }

        if hasStrongEarningsContext {
            return .earnings
        } else if hasStrongDeductionsContext {
            return .deductions
        } else {
            if value >= 15000 {
                return .earnings
            } else if value < 10000 {
                return .deductions
            } else {
                return .earnings
            }
        }
    }
}
