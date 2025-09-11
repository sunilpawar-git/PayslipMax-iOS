//
//  PayCodeClassificationEngine.swift
//  PayslipMax
//
//  Created for Phase 4: Universal Pay Code Search - Classification Logic
//  Handles intelligent classification of pay components using spatial context
//

import Foundation

/// Engine for intelligent pay code classification
final class PayCodeClassificationEngine {

    // MARK: - Properties

    /// Military abbreviations service for component identification
    private let abbreviationsService: MilitaryAbbreviationsService

    /// Section classifier for intelligent classification
    private let sectionClassifier: PayslipSectionClassifier

    // MARK: - Initialization

    init() {
        self.abbreviationsService = MilitaryAbbreviationsService.shared
        self.sectionClassifier = PayslipSectionClassifier()
    }

    // MARK: - Public Methods

    /// Classifies a component intelligently using spatial context and military abbreviations
    /// Implements enhanced classification logic beyond simple section headers
    /// - Parameters:
    ///   - component: The pay component code
    ///   - value: The extracted monetary value
    ///   - context: The surrounding text context
    /// - Returns: Classification result with reasoning
    func classifyComponentIntelligently(
        component: String,
        value: Double,
        context: String
    ) -> PayCodeClassificationResult {

        // Check if this is a known dual-section component
        let isDualSection = isDualSectionComponent(component)

        // Use military abbreviations service for primary classification
        let militaryClassification = abbreviationsService.classifyComponent(component)

        // Use section classifier for context-based classification
        let contextualSection = sectionClassifier.classifyDualSectionComponent(
            componentKey: component,
            value: value,
            text: context
        )

        // Combine classifications with confidence scoring
        let finalClassification = combineClassifications(
            militaryClassification: militaryClassification,
            contextualSection: contextualSection,
            component: component,
            value: value
        )

        return PayCodeClassificationResult(
            section: finalClassification.section,
            confidence: finalClassification.confidence,
            reasoning: finalClassification.reasoning,
            isDualSection: isDualSection
        )
    }

    /// Validates if a component can appear in both sections
    /// - Parameter component: The component code to check
    /// - Returns: True if component can appear in multiple sections
    func isDualSectionComponent(_ component: String) -> Bool {
        let dualSectionCodes = ["RH12", "RH11", "RH13", "MSP", "TPTA"]
        return dualSectionCodes.contains { component.uppercased().contains($0) }
    }

    // MARK: - Private Methods

    /// Combines multiple classification results with confidence scoring
    private func combineClassifications(
        militaryClassification: PayslipSection?,
        contextualSection: PayslipSection,
        component: String,
        value: Double
    ) -> (section: PayslipSection, confidence: Double, reasoning: String) {

        // If military service has a strong opinion, use it
        if let militarySection = militaryClassification {
            if militarySection == contextualSection {
                return (militarySection, 0.95, "Military service and context agree")
            } else {
                // Conflict - use military service but lower confidence
                return (militarySection, 0.75, "Military service override (context conflict)")
            }
        }

        // Fall back to contextual classification
        return (contextualSection, 0.85, "Contextual classification")
    }
}

// MARK: - Extensions

/// Extension to MilitaryAbbreviationsService for component classification
extension MilitaryAbbreviationsService {
    func classifyComponent(_ component: String) -> PayslipSection? {
        // This would use the military abbreviations database to classify components
        // For now, return basic classification based on known patterns
        let earningsCodes = ["BPAY", "BP", "MSP", "DA", "TPTA", "CEA", "CLA", "HRA", "RH"]
        let deductionsCodes = ["DSOP", "AGIF", "AFPF", "ITAX", "IT", "EHCESS", "GPF", "PF"]

        let upperComponent = component.uppercased()

        if earningsCodes.contains(where: { upperComponent.contains($0) }) {
            return .earnings
        } else if deductionsCodes.contains(where: { upperComponent.contains($0) }) {
            return .deductions
        }

        return nil // Unknown classification
    }
}
