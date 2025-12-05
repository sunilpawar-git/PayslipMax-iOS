//
//  ComponentClassificationRules.swift
//  PayslipMax
//
//  Created for component-specific classification rules
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service for component-specific dual-section classification rules
/// Handles specialized logic for different allowance types
final class ComponentClassificationRules {

    // MARK: - Public Interface

    /// Applies component-specific classification rules for known patterns
    /// - Parameters:
    ///   - componentKey: The component key to classify
    ///   - value: The monetary value
    ///   - text: Full payslip text for context
    ///   - spatialAnalyzer: Function to perform spatial context analysis
    /// - Returns: Section classification if specific rules apply, nil otherwise
    func getComponentSpecificClassification(
        _ componentKey: String,
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection? {
        let uppercaseKey = componentKey.uppercased()

        // HRA specific rules - based on military payslip patterns
        if uppercaseKey.contains("HRA") {
            return classifyHRAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // CEA (Children Education Allowance) specific rules
        if uppercaseKey.contains("CEA") {
            return classifyCEAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // SICHA (Siachen Allowance) specific rules
        if uppercaseKey.contains("SICHA") {
            return classifySICHAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // DA (Dearness Allowance) specific rules
        if uppercaseKey.contains("DA") && !uppercaseKey.contains("TPTADA") {
            return classifyDAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // LTC (Leave Travel Concession) specific rules
        if uppercaseKey.contains("LTC") {
            return classifyLTCComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // MEDICAL allowance specific rules
        if uppercaseKey.contains("MEDICAL") {
            return classifyMedicalComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // CONVEYANCE allowance specific rules
        if uppercaseKey.contains("CONVEYANCE") {
            return classifyConveyanceComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // TPTADA (Transport Allowance DA) specific rules - check first as it contains TPTA
        if uppercaseKey.contains("TPTADA") {
            return classifyTPTADAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // TPTA (Transport Allowance) specific rules
        if uppercaseKey.contains("TPTA") {
            return classifyTPTAComponent(value: value, text: text, spatialAnalyzer: spatialAnalyzer)
        }

        // No specific rules found
        return nil
    }

    // MARK: - Component-Specific Classification Methods

    /// HRA classification logic - typically earnings unless explicitly in deductions section
    private func classifyHRAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // HRA recoveries are usually smaller amounts in deductions section
        if value <= 5000 {
            let spatialSection = spatialAnalyzer("HRA", value, text)
            if spatialSection == .deductions {
                return .deductions // Likely HRA recovery
            }
        }
        return .earnings // Default: HRA is usually an allowance
    }

    /// CEA classification logic - similar to HRA
    private func classifyCEAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // CEA recoveries are typically smaller amounts
        if value <= 2000 {
            let spatialSection = spatialAnalyzer("CEA", value, text)
            if spatialSection == .deductions {
                return .deductions // Likely CEA recovery
            }
        }
        return .earnings // Default: CEA is usually an allowance
    }

    /// SICHA classification logic - high-value allowance
    private func classifySICHAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // SICHA is typically a significant allowance, recoveries are rare
        if value >= 10000 {
            return .earnings // High-value SICHA is almost always an allowance
        }

        // For smaller amounts, check context
        return spatialAnalyzer("SICHA", value, text)
    }

    /// DA classification logic - common allowance with potential recoveries
    private func classifyDAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // DA is very common, use spatial analysis primarily
        let spatialSection = spatialAnalyzer("DA", value, text)

        if spatialSection != .unknown {
            return spatialSection
        }

        // DA is typically an allowance
        return .earnings
    }

    /// LTC classification logic - travel allowance with recoveries
    private func classifyLTCComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // LTC has frequent recoveries due to advance/reimbursement patterns
        let spatialSection = spatialAnalyzer("LTC", value, text)

        if spatialSection != .unknown {
            return spatialSection
        }

        // For medium amounts, could be either
        if value >= 5000 && value <= 20000 {
            // Check for recovery keywords in surrounding text
            let uppercaseText = text.uppercased()
            if uppercaseText.contains("LTC") && uppercaseText.contains("RECOVERY") {
                return .deductions
            }
        }

        return .earnings // Default: LTC is usually an allowance
    }

    /// Medical allowance classification logic
    private func classifyMedicalComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // Medical has both allowances and recoveries
        let spatialSection = spatialAnalyzer("MEDICAL", value, text)

        if spatialSection != .unknown {
            return spatialSection
        }

        // Small amounts might be recoveries
        if value <= 3000 {
            return .deductions
        }

        return .earnings // Default: Medical is usually an allowance
    }

    /// Conveyance allowance classification logic
    private func classifyConveyanceComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // Conveyance is typically a smaller allowance
        let spatialSection = spatialAnalyzer("CONVEYANCE", value, text)

        if spatialSection != .unknown {
            return spatialSection
        }

        return .earnings // Default: Conveyance is usually an allowance
    }

    /// TPTA classification logic - transport allowance with May 2025 pattern analysis
    private func classifyTPTAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // May 2025 Pattern Analysis:
        // TPTA ₹3,600 appeared in earnings section despite spatial analysis suggesting deductions
        // Enhanced value-based classification for transport allowances

        if value >= 1500 {
            // Transport allowances ≥ ₹1,500 are typically earnings (regular allowances)
            // Only classify as deductions if there's strong textual evidence of recovery
            let recoveryIndicators = ["RECOVERY", "REC", "REFUND", "EXCESS", "OVERPAYMENT"]
            let uppercaseText = text.uppercased()

            for indicator in recoveryIndicators {
                if uppercaseText.contains("TPTA") && uppercaseText.contains(indicator) {
                    print("[ComponentClassificationRules] TPTA classified as deductions due to recovery indicator: \(indicator)")
                    return .deductions
                }
            }

            print("[ComponentClassificationRules] TPTA ₹\(value) classified as earnings (value-based: ≥₹1,500)")
            return .earnings // Default for regular transport allowances
        }

        // For smaller amounts, use spatial analysis
        let spatialSection = spatialAnalyzer("TPTA", value, text)
        if spatialSection != .unknown {
            print("[ComponentClassificationRules] TPTA ₹\(value) classified via spatial analysis: \(spatialSection)")
            return spatialSection
        }

        print("[ComponentClassificationRules] TPTA ₹\(value) classified as earnings (fallback default)")
        return .earnings // Conservative default
    }

    /// TPTADA (Transport Allowance DA) classification logic - based on May 2025 analysis
    private func classifyTPTADAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        // May 2025 Pattern: TPTADA ₹1,980 appeared in earnings section
        // TPTADA is a variant of transport allowance, should follow similar logic to TPTA

        if value >= 1000 {
            // TPTADA ≥ ₹1,000 are typically earnings (regular allowances)
            // Check for recovery indicators
            let recoveryIndicators = ["RECOVERY", "REC", "REFUND", "EXCESS", "OVERPAYMENT", "DA RECOVERY"]
            let uppercaseText = text.uppercased()

            for indicator in recoveryIndicators {
                if uppercaseText.contains("TPTADA") && uppercaseText.contains(indicator) {
                    print("[ComponentClassificationRules] TPTADA classified as deductions due to recovery indicator: \(indicator)")
                    return .deductions
                }
            }

            print("[ComponentClassificationRules] TPTADA ₹\(value) classified as earnings (value-based: ≥₹1,000)")
            return .earnings // Regular TPTADA allowance
        }

        // For smaller amounts, check context
        let spatialSection = spatialAnalyzer("TPTADA", value, text)
        if spatialSection != .unknown {
            print("[ComponentClassificationRules] TPTADA ₹\(value) classified via spatial analysis: \(spatialSection)")
            return spatialSection
        }

        print("[ComponentClassificationRules] TPTADA ₹\(value) classified as earnings (fallback default)")
        return .earnings
    }

    // MARK: - Helper Methods

    /// Checks if component commonly appears as recovery
    func isCommonRecoveryPattern(_ componentKey: String) -> Bool {
        let commonRecoveryComponents = ["HRA", "CEA", "LTC", "MEDICAL", "CONVEYANCE", "DA"]
        return commonRecoveryComponents.contains { componentKey.uppercased().contains($0) }
    }

    /// Gets confidence score for component-specific classification
    func getClassificationConfidence(for componentKey: String, value: Double) -> Double {
        let uppercaseKey = componentKey.uppercased()
        let hasSpecificRules = ["HRA", "CEA", "SICHA", "DA", "LTC", "MEDICAL"].contains { uppercaseKey.contains($0) }
        guard hasSpecificRules else { return 0.70 }
        return value >= 10000 ? 0.90 : (value <= 1000 ? 0.85 : 0.80)
    }
}
