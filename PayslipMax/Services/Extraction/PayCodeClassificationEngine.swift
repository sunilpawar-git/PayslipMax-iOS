//
//  PayCodeClassificationEngine.swift
//  PayslipMax
//
//  Enhanced for Universal Dual-Section Implementation - Phase 1
//  Handles intelligent classification with universal dual-section support
//

import Foundation

/// Component classification categories for universal dual-section processing
enum ComponentClassification {
    case guaranteedEarnings     // Basic Pay, MSP - NEVER recovered
    case guaranteedDeductions   // AGIF, DSOP, ITAX - NEVER earnings
    case universalDualSection   // ALL allowances - can appear anywhere
}

/// Engine for intelligent pay code classification with universal dual-section support
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

    /// Classifies a component using the enhanced universal classification system
    /// - Parameter code: The pay component code to classify
    /// - Returns: ComponentClassification indicating processing strategy
    func classifyComponent(_ code: String) -> ComponentClassification {
        let normalizedCode = normalizeComponent(code)
        
        // Check guaranteed earnings first
        if PayCodeClassificationConstants.isGuaranteedEarnings(normalizedCode) {
            return .guaranteedEarnings
        }
        
        // Check guaranteed deductions
        if PayCodeClassificationConstants.isGuaranteedDeductions(normalizedCode) {
            return .guaranteedDeductions
        }
        
        // Default to universal dual-section for all allowances and other codes
        // This enables any allowance to appear as payment OR recovery
        return .universalDualSection
    }

    /// Enhanced classification with context validation
    /// - Parameters:
    ///   - code: The pay component code to classify
    ///   - context: The surrounding text context for validation
    ///   - value: The monetary value for additional context
    /// - Returns: ComponentClassification with context-based validation
    func classifyComponentWithContext(_ code: String, context: String, value: Double) -> ComponentClassification {
        // First get the base classification
        let baseClassification = classifyComponent(code)
        
        // Apply edge case validation for borderline components
        if let edgeCaseClassification = validateEdgeCases(component: code, value: value, context: context) {
            return edgeCaseClassification
        }
        
        return baseClassification
    }

    /// Classifies a component intelligently using spatial context and military abbreviations
    /// Enhanced for universal dual-section processing
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
        
        // Get component classification to determine processing strategy
        let componentClassification = classifyComponent(component)
        
        // Check if this should be treated as dual-section
        let isDualSection = (componentClassification == .universalDualSection)

        // Use military abbreviations service for primary classification
        let militaryClassification = abbreviationsService.classifyComponent(component)

        // Use section classifier for context-based classification
        // Only use contextual classification for universal dual-section components
        let contextualSection = isDualSection ?
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
            value: value,
            componentClassification: componentClassification
        )

        return PayCodeClassificationResult(
            section: finalClassification.section,
            confidence: finalClassification.confidence,
            reasoning: finalClassification.reasoning,
            isDualSection: isDualSection
        )
    }

    /// Validates if a component can appear in both sections
    /// Enhanced to use the new universal classification system
    /// - Parameter component: The component code to check
    /// - Returns: True if component can appear in multiple sections
    func isDualSectionComponent(_ component: String) -> Bool {
        let classification = classifyComponent(component)
        return classification == .universalDualSection
    }

    // MARK: - Private Methods

    /// Normalizes component code for consistent classification
    /// - Parameter component: The raw component code
    /// - Returns: Normalized component code for classification
    private func normalizeComponent(_ component: String) -> String {
        let normalized = component.uppercased().trimmingCharacters(in: .whitespaces)
        
        // Handle arrears patterns (ARR-CODE) - extract base component
        if normalized.hasPrefix("ARR-") {
            return String(normalized.dropFirst(4))
        }
        
        return normalized
    }

    /// Validates edge cases for component classification
    /// Provides additional context-based validation for borderline cases
    /// - Parameters:
    ///   - component: The component code
    ///   - value: The monetary value
    ///   - context: The surrounding text context
    /// - Returns: Additional validation rules or nil
    private func validateEdgeCases(component: String, value: Double, context: String) -> ComponentClassification? {
        let normalizedComponent = normalizeComponent(component)
        
        // Special validation for components that might appear in unexpected sections
        
        // Loan advance disbursements vs recoveries
        if normalizedComponent.contains("ADV") && !normalizedComponent.contains("RECOVERY") {
            // Context analysis: Check if it's disbursement or recovery
            let contextLower = context.lowercased()
            if contextLower.contains("recovery") || contextLower.contains("deduction") {
                return .guaranteedDeductions  // Recovery
            } else if contextLower.contains("disbursement") || contextLower.contains("advance paid") {
                return .universalDualSection   // Could be both
            }
        }
        
        // Insurance premium vs claim
        if normalizedComponent.contains("INSURANCE") || normalizedComponent.contains("CGEIS") || normalizedComponent.contains("CGHS") {
            let contextLower = context.lowercased()
            if contextLower.contains("claim") || contextLower.contains("reimbursement") {
                return .universalDualSection   // Could be reimbursement
            }
            return .guaranteedDeductions       // Default: premium
        }
        
        // Transport allowance vs transport deduction
        if normalizedComponent == "TA" || normalizedComponent.contains("TRANSPORT") {
            let contextLower = context.lowercased()
            if contextLower.contains("recovery") || contextLower.contains("excess") {
                return .universalDualSection   // Could be recovery
            }
        }
        
        return nil // No special validation needed
    }

    /// Combines multiple classification results with confidence scoring
    /// Enhanced for universal dual-section processing
    private func combineClassifications(
        militaryClassification: PayslipSection?,
        contextualSection: PayslipSection?,
        component: String,
        value: Double,
        componentClassification: ComponentClassification
    ) -> (section: PayslipSection, confidence: Double, reasoning: String) {

        // For guaranteed single-section components, override any conflicting classifications
        switch componentClassification {
        case .guaranteedEarnings:
            return (.earnings, 0.98, "Guaranteed earnings component")
        case .guaranteedDeductions:
            return (.deductions, 0.98, "Guaranteed deductions component")
        case .universalDualSection:
            // Continue with dual-section logic below
            break
        }

        // Dual-section component logic: prioritize context over military service
        if let militarySection = militaryClassification, let contextSection = contextualSection {
            if militarySection == contextSection {
                return (militarySection, 0.95, "Military service and context agree (dual-section)")
            } else {
                // For dual-section components, prefer contextual classification
                return (contextSection, 0.85, "Context override for dual-section component")
            }
        }

        // If we only have contextual classification for dual-section, use it with high confidence
        if let contextSection = contextualSection {
            return (contextSection, 0.90, "Contextual classification (dual-section)")
        }

        // If we only have military classification, use it
        if let militarySection = militaryClassification {
            return (militarySection, 0.80, "Military service classification (dual-section)")
        }

        // Fallback for unknown dual-section components - default to earnings
        return (.earnings, 0.60, "Unknown dual-section component, defaulting to earnings")
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
