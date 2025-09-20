//
//  ArrearsClassificationService.swift
//  PayslipMax
//
//  Created for Phase 3: Universal Arrears Enhancement
//  Handles context-aware arrears classification with dual-section support
//

import Foundation

/// Protocol for arrears-specific classification
protocol ArrearsClassificationServiceProtocol {
    func classifyArrearsSection(
        component: String,
        baseComponent: String,
        value: Double,
        text: String
    ) -> PayslipSection
}

/// Service for intelligent arrears classification
/// Supports universal dual-section processing with context-aware heuristics
final class ArrearsClassificationService: ArrearsClassificationServiceProtocol {
    
    // MARK: - Properties
    
    /// Section classifier for context-based classification
    private let sectionClassifier: PayslipSectionClassifier
    
    /// Classification engine for component analysis
    private let classificationEngine: PayCodeClassificationEngine
    
    // MARK: - Initialization
    
    init() {
        self.sectionClassifier = PayslipSectionClassifier()
        self.classificationEngine = PayCodeClassificationEngine()
    }
    
    // MARK: - Public Methods
    
    /// Classifies universal dual-section arrears using enhanced context analysis
    /// - Parameters:
    ///   - component: The full arrears component (e.g., "ARR-HRA")
    ///   - baseComponent: The base component without ARR prefix
    ///   - value: The monetary value for context
    ///   - text: The full payslip text for spatial analysis
    /// - Returns: Section classification based on context
    func classifyArrearsSection(
        component: String,
        baseComponent: String,
        value: Double,
        text: String
    ) -> PayslipSection {
        // Get base component classification to determine strategy
        let baseClassification = classificationEngine.classifyComponent(baseComponent)
        
        switch baseClassification {
        case .guaranteedEarnings:
            // ARR-BPAY, ARR-MSP always earnings (back-payments)
            return .earnings
            
        case .guaranteedDeductions:
            // ARR-DSOP, ARR-AGIF always deductions (rare but possible excess recovery)
            return .deductions
            
        case .universalDualSection:
            // Universal dual-section: use intelligent context analysis
            return classifyUniversalArrearsSection(
                component: component,
                baseComponent: baseComponent,
                value: value,
                text: text
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Classifies universal dual-section arrears using enhanced context analysis
    /// - Parameters:
    ///   - component: The full arrears component (e.g., "ARR-HRA")
    ///   - baseComponent: The base component without ARR prefix
    ///   - value: The monetary value for context
    ///   - text: The full payslip text for spatial analysis
    /// - Returns: Section classification based on context
    private func classifyUniversalArrearsSection(
        component: String,
        baseComponent: String,
        value: Double,
        text: String
    ) -> PayslipSection {
        // Use section classifier for intelligent context-based classification
        let contextualSection = sectionClassifier.classifyDualSectionComponent(
            componentKey: component,
            value: value,
            text: text
        )
        
        // Apply arrears-specific heuristics
        let arrearsSpecificSection = applyArrearsSpecificHeuristics(
            component: component,
            baseComponent: baseComponent,
            value: value,
            text: text
        )
        
        // Combine contextual and arrears-specific classifications
        // Prioritize arrears-specific logic for known patterns
        return arrearsSpecificSection ?? contextualSection
    }
    
    /// Applies arrears-specific classification heuristics
    /// - Parameters:
    ///   - component: The full arrears component
    ///   - baseComponent: The base component
    ///   - value: The monetary value
    ///   - text: The context text
    /// - Returns: Optional section classification, nil if no specific rule applies
    private func applyArrearsSpecificHeuristics(
        component: String,
        baseComponent: String,
        value: Double,
        text: String
    ) -> PayslipSection? {
        // Check for explicit recovery patterns in context
        let recoveryPatterns = [
            "recovery", "excess", "overpayment", "adjustment",
            "deduct", "minus", "recover", "refund"
        ]
        
        let contextLowercased = text.lowercased()
        for pattern in recoveryPatterns {
            if contextLowercased.contains(pattern) && contextLowercased.contains(component.lowercased()) {
                return .deductions
            }
        }
        
        // Check for payment/credit patterns in context
        let paymentPatterns = [
            "arrears", "back pay", "due", "payment", "credit",
            "allowance", "entitlement", "benefit"
        ]
        
        for pattern in paymentPatterns {
            if contextLowercased.contains(pattern) && contextLowercased.contains(component.lowercased()) {
                return .earnings
            }
        }
        
        // No specific pattern found - let contextual classifier decide
        return nil
    }
}
