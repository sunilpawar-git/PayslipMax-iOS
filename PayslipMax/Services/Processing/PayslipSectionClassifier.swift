//
//  PayslipSectionClassifier.swift
//  PayslipMax
//
//  Created for military payslip section classification logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Section types for payslip component classification
enum PayslipSection {
    case earnings
    case deductions
    case unknown
}

/// Represents a pay component with its section classification
struct PayComponent {
    let code: String
    let amount: Double
    let section: PayslipSection
}


/// Service for classifying payslip components into appropriate sections
/// Implements intelligent context analysis for dual-section components like RH12
final class PayslipSectionClassifier {

    // MARK: - Dependencies

    /// Component-specific classification rules service
    private let classificationRules = ComponentClassificationRules()

    // MARK: - Public Interface

    /// Classifies RH12 component into earnings or deductions based on section context
    func classifyRH12Section(key: String, value: Double, text: String) -> PayslipSection {
        classifyRH12SectionImpl(key: key, value: value, text: text)
    }

    /// Classifies any dual-section component using enhanced generic logic
    /// Extended to handle ALL allowances that can appear in both earnings and deductions
    /// - Parameters:
    ///   - componentKey: The component key (e.g., "RH12", "HRA", "CEA", "SICHA")
    ///   - value: The monetary value
    ///   - text: Full payslip text for context
    /// - Returns: The classified section type
    func classifyDualSectionComponent(componentKey: String, value: Double, text: String) -> PayslipSection {
        if isRHComponent(componentKey) {
            return classifyRH12Section(key: componentKey, value: value, text: text)
        }

        if let obviousSection = classifyByObviousName(componentKey) {
            return obviousSection
        }

        if let specificSection = classificationRules.getComponentSpecificClassification(
            componentKey, value: value, text: text, spatialAnalyzer: analyzeSpatialContext
        ) {
            return specificSection
        }

        return classifyGenericDualSectionComponent(componentKey: componentKey, value: value, text: text)
    }

    // MARK: - Enhanced Classification Methods

    /// Checks if component belongs to RH family (RH11-RH33)
    private func isRHComponent(_ componentKey: String) -> Bool {
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
        let uppercaseKey = componentKey.uppercased()
        return rhCodes.contains { rhCode in uppercaseKey.contains(rhCode) }
    }

    /// Classifies components with obvious section indicators in their names
    private func classifyByObviousName(_ componentKey: String) -> PayslipSection? {
        let uppercaseKey = componentKey.uppercased()

        // Components with "DEDUCTION" in name should be deductions
        if uppercaseKey.contains("DEDUCTION") {
            return .deductions
        }

        // Components with "RECOVERY" in name should be deductions
        if uppercaseKey.contains("RECOVERY") {
            return .deductions
        }

        // Components with "CHARGE" or "CHARGES" in name are typically deductions
        if uppercaseKey.contains("CHARGE") {
            return .deductions
        }

        // Insurance and fund components are typically deductions
        if uppercaseKey.contains("INSURANCE") || uppercaseKey.contains("FUND") {
            return .deductions
        }

        // No obvious classification
        return nil
    }

    /// Generic dual-section classification using enhanced spatial analysis
    private func classifyGenericDualSectionComponent(componentKey: String, value: Double, text: String) -> PayslipSection {
        let section = analyzeSpatialContext(for: componentKey, value: value, in: text)

        if section != .unknown {
            return section
        }

        return applyEnhancedHeuristics(componentKey: componentKey, value: value)
    }


    // MARK: - Enhanced Analysis Methods

    /// Enhanced spatial context analysis for any component
    private func analyzeSpatialContext(for componentKey: String, value: Double, in text: String) -> PayslipSection {
        let uppercaseText = text.uppercased()
        let valueString = String(format: "%.0f", value)

        // Create search patterns for the component
        let searchPatterns = createSearchPatterns(for: componentKey, value: valueString)

        var matchPosition = -1
        for pattern in searchPatterns {
            if let range = uppercaseText.range(of: pattern, options: .regularExpression) {
                matchPosition = uppercaseText.distance(from: uppercaseText.startIndex, to: range.lowerBound)
                break
            }
        }

        guard matchPosition >= 0 else {
            return .unknown
        }

        // Analyze surrounding context
        let beforeMatch = String(uppercaseText.prefix(matchPosition + 200))
        let beforeMatchLast1000 = String(beforeMatch.suffix(1000))

        return determineSectionFromContext(beforeMatchLast1000)
    }

    /// Creates search patterns for component detection
    private func createSearchPatterns(for componentKey: String, value: String) -> [String] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: Double(value) ?? 0)) ?? value
        return ["\(componentKey)[\\s]*.*[\\s]*\(value)", "\(componentKey)[\\s]*.*[\\s]*\(formatted)",
                "\(value)[\\s]*.*\(componentKey)", "\(formatted)[\\s]*.*\(componentKey)"]
    }

    /// Determines section from contextual indicators
    private func determineSectionFromContext(_ context: String) -> PayslipSection {
        let earningsIndicators = ["EARNINGS", "आय", "CREDIT", "जमा", "GROSS PAY", "ALLOWANCES"]
        let deductionsIndicators = ["DEDUCTIONS", "कटौती", "DEBIT", "नामे", "RECOVERY", "RECOVERIES"]
        let lastEarningsPos = findLastIndicatorPosition(in: context, indicators: earningsIndicators)
        let lastDeductionsPos = findLastIndicatorPosition(in: context, indicators: deductionsIndicators)
        if lastEarningsPos > lastDeductionsPos && lastEarningsPos >= 0 { return .earnings }
        if lastDeductionsPos > lastEarningsPos && lastDeductionsPos >= 0 { return .deductions }
        return .unknown
    }

    private func findLastIndicatorPosition(in context: String, indicators: [String]) -> Int {
        var lastPos = -1
        for indicator in indicators {
            if let range = context.range(of: indicator, options: .backwards) {
                lastPos = max(lastPos, context.distance(from: context.startIndex, to: range.lowerBound))
            }
        }
        return lastPos
    }

    /// Applies enhanced value-based heuristics for classification
    private func applyEnhancedHeuristics(componentKey: String, value: Double) -> PayslipSection {
        if value >= 15000 { return .earnings }
        if value <= 1000 && classificationRules.isCommonRecoveryPattern(componentKey) { return .deductions }
        return .earnings
    }
}
