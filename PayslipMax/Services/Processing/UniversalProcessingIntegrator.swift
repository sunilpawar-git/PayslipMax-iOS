//
//  UniversalProcessingIntegrator.swift
//  PayslipMax
//
//  Created for universal dual-section processing integration
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service for integrating universal dual-section processing with legacy payslip processors
/// Handles component classification and routing to appropriate processors
final class UniversalProcessingIntegrator {
    
    // MARK: - Dependencies
    
    /// Pay code classification engine for component classification
    private let classificationEngine: PayCodeClassificationEngine
    
    /// Section classifier for dual-section component detection
    private let sectionClassifier: PayslipSectionClassifier
    
    // MARK: - Initialization
    
    /// Initialize with required dependencies
    /// - Parameters:
    ///   - classificationEngine: Engine for component type classification
    ///   - sectionClassifier: Service for section-based classification
    init(
        classificationEngine: PayCodeClassificationEngine? = nil,
        sectionClassifier: PayslipSectionClassifier? = nil
    ) {
        self.classificationEngine = classificationEngine ?? PayCodeClassificationEngine()
        self.sectionClassifier = sectionClassifier ?? PayslipSectionClassifier()
    }
    
    // MARK: - Public Interface
    
    /// Processes a component using the enhanced classification system
    /// - Parameters:
    ///   - key: The component key
    ///   - value: The monetary value
    ///   - text: Full payslip text for context
    ///   - earnings: Mutable earnings dictionary
    ///   - deductions: Mutable deductions dictionary
    func processComponentWithClassification(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        // Get component classification to determine processing strategy
        let classification = classificationEngine.classifyComponent(key)
        
        switch classification {
        case .guaranteedEarnings:
            processGuaranteedEarningsComponent(key: key, value: value, earnings: &earnings)
            
        case .guaranteedDeductions:
            processGuaranteedDeductionsComponent(key: key, value: value, deductions: &deductions)
            
        case .universalDualSection:
            // Use enhanced dual-section classification for components that can appear anywhere
            processUniversalDualSectionComponent(
                key: key,
                value: value,
                text: text,
                earnings: &earnings,
                deductions: &deductions
            )
        }
    }
    
    // MARK: - Private Processing Methods
    
    /// Processes guaranteed earnings components
    private func processGuaranteedEarningsComponent(key: String, value: Double, earnings: inout [String: Double]) {
        if key.contains("BPAY") || key.contains("BasicPay") {
            earnings["Basic Pay"] = value
        } else if key.contains("MSP") {
            earnings["Military Service Pay"] = value
        } else {
            // Use the component key as-is for display
            earnings[key] = value
        }
        print("[UniversalProcessingIntegrator] Processed guaranteed earnings: \(key) = ₹\(value)")
    }
    
    /// Processes guaranteed deductions components
    private func processGuaranteedDeductionsComponent(key: String, value: Double, deductions: inout [String: Double]) {
        if key.contains("DSOP") {
            deductions["DSOP"] = value
        } else if key.contains("AGIF") {
            deductions["AGIF"] = value
        } else if key.contains("EHCESS") {
            deductions["EHCESS"] = value
        } else if key.contains("ITAX") || key.contains("IncomeTax") || key.contains("Income Tax") ||
                  key.contains("ITAX_STATIC") || key.contains("ITAX_DEBUG") || key.contains("ITAX_EXACT") ||
                  key.contains("ITAX_UNIVERSAL") || key.contains("ITAX_WIDE") || key.contains("ITAX_SIMPLE") || key.contains("ITAX_COMPLETE") {
            deductions["Income Tax"] = value
        } else if key.contains("Group Insurance") {
            deductions["Group Insurance"] = value
        } else if key.contains("Naval Benevolent Fund") {
            deductions["Naval Benevolent Fund"] = value
        } else if key.contains("Mess Charges") {
            deductions["Mess Charges"] = value
        } else if key.contains("Other Deductions") {
            deductions["Other Deductions"] = value
        } else {
            // Use the component key as-is for display
            deductions[key] = value
        }
        print("[UniversalProcessingIntegrator] Processed guaranteed deductions: \(key) = ₹\(value)")
    }
    
    /// Processes universal dual-section components using enhanced classification
    private func processUniversalDualSectionComponent(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        // Use section classifier to determine appropriate section
        let sectionType = sectionClassifier.classifyDualSectionComponent(
            componentKey: key,
            value: value,
            text: text
        )
        
        switch sectionType {
        case .earnings:
            let displayName = getDisplayName(for: key, section: .earnings)
            let currentValue = earnings[displayName] ?? 0.0
            earnings[displayName] = currentValue + value
            print("[UniversalProcessingIntegrator] Universal dual-section - stored \(displayName) = ₹\(currentValue + value)")
            
        case .deductions:
            let displayName = getDisplayName(for: key, section: .deductions)
            let currentValue = deductions[displayName] ?? 0.0
            deductions[displayName] = currentValue + value
            print("[UniversalProcessingIntegrator] Universal dual-section - stored \(displayName) = ₹\(currentValue + value)")
            
        case .unknown:
            // For unknown sections, fallback to legacy processing
            processLegacyComponent(key: key, value: value, earnings: &earnings, deductions: &deductions)
        }
    }
    
    /// Legacy processing for components when universal classification fails
    private func processLegacyComponent(key: String, value: Double, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Legacy hardcoded classification logic
        if (key.contains("DA") && !key.contains("ARR") && !key.contains("TPTA")) ||
           key.contains("DA_STATIC") || key.contains("DA_DEBUG") || key.contains("DA_EXACT") ||
           key.contains("DA_UNIVERSAL") || key.contains("DA_WIDE") || key.contains("DA_SIMPLE") || key.contains("DA_COMPLETE") {
            earnings["Dearness Allowance"] = value
        } else if key.contains("TPTA") && !key.contains("TPTADA") && !key.contains("ARR") {
            earnings["Transport Allowance"] = value
        } else if key.contains("TPTADA") && !key.contains("ARR") {
            earnings["Transport Allowance DA"] = value
        } else if key.contains("HRA") {
            earnings["HRA"] = value // Default HRA to earnings in legacy mode
        } else {
            // Default unknown components to earnings
            earnings[key] = value
        }
        print("[UniversalProcessingIntegrator] Processed legacy component: \(key) = ₹\(value)")
    }
    
    /// Gets the appropriate display name for a component based on its key and target section
    private func getDisplayName(for key: String, section: PayslipSection) -> String {
        let normalizedKey = key.uppercased()
        
        // Map common components to their standard display names
        if (normalizedKey.contains("DA") && !normalizedKey.contains("ARR") && !normalizedKey.contains("TPTA")) ||
           normalizedKey.contains("DA_STATIC") || normalizedKey.contains("DA_DEBUG") || normalizedKey.contains("DA_EXACT") ||
           normalizedKey.contains("DA_UNIVERSAL") || normalizedKey.contains("DA_WIDE") || normalizedKey.contains("DA_SIMPLE") || normalizedKey.contains("DA_COMPLETE") {
            return section == .earnings ? "Dearness Allowance" : "DA Recovery"
        }
        
        if normalizedKey.contains("HRA") {
            return section == .earnings ? "HRA" : "HRA Recovery"
        }
        
        if normalizedKey.contains("TPTA") && !normalizedKey.contains("TPTADA") && !normalizedKey.contains("ARR") {
            return section == .earnings ? "Transport Allowance" : "Transport Allowance Recovery"
        }
        
        if normalizedKey.contains("TPTADA") && !normalizedKey.contains("ARR") {
            return section == .earnings ? "Transport Allowance DA" : "Transport Allowance DA Recovery"
        }
        
        if normalizedKey.contains("CEA") {
            return section == .earnings ? "CEA" : "CEA Recovery"
        }
        
        if normalizedKey.contains("SICHA") {
            return section == .earnings ? "SICHA" : "SICHA Recovery"
        }
        
        // For components without specific mapping, use the key with section suffix
        return section == .earnings ? "\(key)_EARNINGS" : "\(key)_DEDUCTIONS"
    }
    
    // MARK: - Utility Methods
    
    /// Gets classification statistics for monitoring
    /// - Parameter components: List of component keys to analyze
    /// - Returns: Dictionary with classification counts
    func getClassificationStatistics(for components: [String]) -> [String: Int] {
        var stats: [String: Int] = [
            "guaranteedEarnings": 0,
            "guaranteedDeductions": 0,
            "universalDualSection": 0
        ]
        
        for component in components {
            let classification = classificationEngine.classifyComponent(component)
            switch classification {
            case .guaranteedEarnings:
                stats["guaranteedEarnings"]! += 1
            case .guaranteedDeductions:
                stats["guaranteedDeductions"]! += 1
            case .universalDualSection:
                stats["universalDualSection"]! += 1
            }
        }
        
        return stats
    }
}
