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
        // Only use contextual classification for known dual-section components
        let isKnownDualSection = isDualSectionComponent(component)
        let contextualSection = isKnownDualSection ?
            sectionClassifier.classifyDualSectionComponent(
                componentKey: component,
                value: value,
                text: context
            ) : nil

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
    /// Uses military abbreviations service to identify known dual-section components
    /// - Parameter component: The component code to check
    /// - Returns: True if component can appear in multiple sections
    func isDualSectionComponent(_ component: String) -> Bool {
        let normalizedComponent = component.uppercased().trimmingCharacters(in: .whitespaces)

        // Handle arrears patterns (ARR-CODE)
        let cleanComponent = normalizedComponent.hasPrefix("ARR-")
            ? String(normalizedComponent.dropFirst(4))
            : normalizedComponent

        // Known dual-section components from analysis:
        // RH codes (Risk & Hardship) - can appear as both allowance and recovery
        // MSP (Military Service Pay) - can have adjustments in deductions
        // TPTA (Technical Pay & Technical Allowance) - can have recoveries
        let knownDualSectionPatterns = [
            "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33", // Risk & Hardship family
            "MSP",    // Military Service Pay
            "TPTA",   // Technical Pay & Technical Allowance
            "DA",     // Dearness Allowance (can have adjustments)
            "HRA"     // House Rent Allowance (can have recoveries)
        ]

        // Check if component matches any known dual-section pattern
        for pattern in knownDualSectionPatterns {
            if cleanComponent.contains(pattern) || pattern.contains(cleanComponent) {
                return true
            }
        }

        // Additional check: Look up in military abbreviations for patterns
        // Only specific components in certain categories are dual-section
        if let abbreviation = abbreviationsService.abbreviation(forCode: cleanComponent) {
            let categoryString = abbreviation.category.rawValue.lowercased()
            // Only specific allowances that can have recoveries are dual-section
            if (categoryString.contains("allowance") && (cleanComponent == "DA" || cleanComponent == "HRA")) ||
               categoryString.contains("risk") || categoryString.contains("hardship") ||
               categoryString.contains("technical") {
                return true
            }
        }

        return false
    }

    // MARK: - Private Methods

    /// Combines multiple classification results with confidence scoring
    private func combineClassifications(
        militaryClassification: PayslipSection?,
        contextualSection: PayslipSection?,
        component: String,
        value: Double
    ) -> (section: PayslipSection, confidence: Double, reasoning: String) {

        // If we have both classifications, compare them
        if let militarySection = militaryClassification, let contextSection = contextualSection {
            if militarySection == contextSection {
                return (militarySection, 0.95, "Military service and context agree")
            } else {
                // Conflict - use military service but lower confidence
                return (militarySection, 0.75, "Military service override (context conflict)")
            }
        }

        // If we only have military classification, use it with high confidence
        if let militarySection = militaryClassification {
            return (militarySection, 0.95, "Military service classification")
        }

        // If we only have contextual classification, use it
        if let contextSection = contextualSection {
            return (contextSection, 0.85, "Contextual classification")
        }

        // Fallback for unknown components - low confidence
        return (.earnings, 0.6, "Unknown component, defaulting to earnings")
    }
}

// MARK: - Extensions

/// Extension to MilitaryAbbreviationsService for component classification
extension MilitaryAbbreviationsService {
    /// Classifies a component using the comprehensive military abbreviations database
    /// - Parameter component: The pay component code to classify
    /// - Returns: PayslipSection (.earnings or .deductions) or nil if unknown
    func classifyComponent(_ component: String) -> PayslipSection? {
        let normalizedComponent = component.uppercased().trimmingCharacters(in: .whitespaces)

        // Handle arrears patterns (ARR-CODE)
        let cleanComponent = normalizedComponent.hasPrefix("ARR-")
            ? String(normalizedComponent.dropFirst(4))
            : normalizedComponent

        // First try exact match lookup
        if let abbreviation = abbreviation(forCode: cleanComponent) {
            return (abbreviation.isCredit ?? true) ? .earnings : .deductions
        }

        // Try partial matching for complex codes (e.g., "RH12" should match codes containing "RH")
        let creditCodes = creditAbbreviations.map { $0.code.uppercased() }
        let debitCodes = debitAbbreviations.map { $0.code.uppercased() }

        // Check if component contains any known credit code
        for creditCode in creditCodes {
            if cleanComponent.contains(creditCode) || creditCode.contains(cleanComponent) {
                return .earnings
            }
        }

        // Check if component contains any known debit code
        for debitCode in debitCodes {
            if cleanComponent.contains(debitCode) || debitCode.contains(cleanComponent) {
                return .deductions
            }
        }

        // Fallback: Check for common military allowance patterns that are typically earnings
        // Only match complete words or clear abbreviations to avoid false positives
        let allowancePatterns = ["RH", "MSP", "DA", "TPTA", "CEA", "CLA", "HRA", "BPAY", "BP"]
        for pattern in allowancePatterns {
            // Use word boundaries to avoid partial matches like "UNKNOWN" containing "WN"
            if cleanComponent.range(of: "\\b\(pattern)\\b", options: .regularExpression) != nil {
                return .earnings
            }
        }

        // Fallback: Check for common deduction patterns
        let deductionPatterns = ["DSOP", "AGIF", "AFPF", "ITAX", "IT", "EHCESS", "GPF", "PF"]
        for pattern in deductionPatterns {
            // Use word boundaries to avoid partial matches
            if cleanComponent.range(of: "\\b\(pattern)\\b", options: .regularExpression) != nil {
                return .deductions
            }
        }

        return nil // Unknown classification
    }
}
