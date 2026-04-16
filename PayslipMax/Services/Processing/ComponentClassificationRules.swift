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
