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

    /// Cache manager for performance optimization
    private let cacheManager: ClassificationCacheManagerProtocol


    // MARK: - Initialization

    init(cacheManager: ClassificationCacheManagerProtocol? = nil) {
        self.abbreviationsService = MilitaryAbbreviationsService.shared
        self.sectionClassifier = PayslipSectionClassifier()
        self.cacheManager = cacheManager ?? ClassificationCacheManager.shared
    }

    // MARK: - Public Methods

    /// Classifies a component using the enhanced universal classification system with caching
    /// - Parameter code: The pay component code to classify
    /// - Returns: ComponentClassification indicating processing strategy
    func classifyComponent(_ code: String) -> ComponentClassification {
        let normalizedCode = normalizeComponent(code)

        // Check cache first for performance optimization
        if let cached = cacheManager.getCachedClassification(for: normalizedCode) {
            return cached
        }

        // Perform classification logic
        let classification: ComponentClassification

        // Check guaranteed earnings first
        if PayCodeClassificationConstants.isGuaranteedEarnings(normalizedCode) {
            classification = .guaranteedEarnings
        }
        // Check guaranteed deductions
        else if PayCodeClassificationConstants.isGuaranteedDeductions(normalizedCode) {
            classification = .guaranteedDeductions
        }
        // Default to universal dual-section for all allowances and other codes
        else {
            classification = .universalDualSection
        }

        // Cache result with memory management
        cacheManager.cacheClassification(classification, for: normalizedCode)
        return classification
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
        // swiftlint:disable:next no_hardcoded_strings
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
    // swiftlint:disable:next no_hardcoded_strings
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

    /// Clears all caches for memory management
    func clearCaches() {
        cacheManager.clearAllCaches()
        print("[PayCodeClassificationEngine] All caches cleared for memory optimization")
    }

    /// Gets cache statistics for performance monitoring
    func getCacheStatistics() -> (classificationCacheSize: Int, contextCacheSize: Int) {
        return cacheManager.getCacheStatistics()
    }
}
