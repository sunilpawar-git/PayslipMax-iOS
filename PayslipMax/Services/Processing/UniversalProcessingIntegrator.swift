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

    /// Universal dual-section processor for enhanced processing
    private let universalProcessor: UniversalDualSectionProcessor

    // MARK: - Initialization

    /// Initialize with required dependencies
    /// - Parameters:
    ///   - classificationEngine: Engine for component type classification
    ///   - universalProcessor: Processor for universal dual-section components
    init(
        classificationEngine: PayCodeClassificationEngine? = nil,
        universalProcessor: UniversalDualSectionProcessor? = nil
    ) {
        self.classificationEngine = classificationEngine ?? PayCodeClassificationEngine()
        self.universalProcessor = universalProcessor ?? UniversalDualSectionProcessor()
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
            // Use the UniversalDualSectionProcessor for enhanced processing
            processUniversalDualSectionComponentAsync(
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

    /// Processes universal dual-section components using enhanced classification with dual-section keys
    /// Implements the dual-section pattern similar to RH12_EARNINGS/RH12_DEDUCTIONS
    private func processUniversalDualSectionComponentAsync(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        // Skip technical/metadata keys that shouldn't be processed as components
        if shouldSkipTechnicalKey(key) {
            print("[UniversalProcessingIntegrator] Skipping technical key: \(key)")
            return
        }

        // Check if component should get dual-section processing
        guard universalProcessor.shouldProcessAsDualSection(key) else {
            print("[UniversalProcessingIntegrator] Component \(key) not eligible for dual-section processing, using legacy")
            processLegacyComponent(key: key, value: value, earnings: &earnings, deductions: &deductions)
            return
        }

        // Get the section classifier from the universal processor dependency
        let sectionClassifier = PayslipSectionClassifier()

        // Use enhanced dual-section classification
        let sectionType = sectionClassifier.classifyDualSectionComponent(
            componentKey: key,
            value: value,
            text: text
        )

        // Store using proper display names (like "Dearness Allowance", "HRA")
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
            print("[UniversalProcessingIntegrator] Unknown section for \(key), using legacy processing")
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
           normalizedKey.contains("DA_COMPLETE") {
            return section == .earnings ? "Dearness Allowance" : "DA Recovery"
        }

        // Special handling for RH12 to maintain dual-section key format
        if normalizedKey.contains("RH12") {
            return section == .earnings ? "RH12_EARNINGS" : "RH12_DEDUCTIONS"
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

        // For components without specific mapping, use clean key names
        // Only add section suffix for components that truly need dual-section identification
        if isKnownDualSectionComponent(normalizedKey) {
            return section == .earnings ? "\(key)_EARNINGS" : "\(key)_DEDUCTIONS"
        }

        // For other components, use clean display name
        return key
    }

    // MARK: - Utility Methods

    /// Checks if a key should be skipped as it's technical/metadata and not a pay component
    private func shouldSkipTechnicalKey(_ key: String) -> Bool {
        let technicalKeys = [
            "credits", "debits", // Total values - should not be processed as components
            "totalCredits", "totalDebits", "totalEarnings", "totalDeductions",
            "netPay", "netRemittance", "total", "amount", "sum"
        ]

        // Skip debug/testing variants that should not be processed as separate components
        let debugVariants = [
            "_DEBUG", "_STATIC", "_UNIVERSAL", "_WIDE", "_SIMPLE", "_EXACT"
        ]

        let uppercaseKey = key.uppercased()

        // Check for technical keys
        if technicalKeys.contains(where: { technicalKey in
            uppercaseKey.contains(technicalKey.uppercased())
        }) {
            return true
        }

        // Check for debug variants
        if debugVariants.contains(where: { variant in
            uppercaseKey.contains(variant)
        }) {
            return true
        }

        return false
    }

    /// Checks if a component is known to have dual-section behavior and needs _EARNINGS/_DEDUCTIONS suffixes
    private func isKnownDualSectionComponent(_ normalizedKey: String) -> Bool {
        let knownDualSectionComponents = [
            "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
            // Only include components that truly have dual-section behavior
            // Other components should use clean display names
        ]

        return knownDualSectionComponents.contains { component in
            normalizedKey.contains(component)
        }
    }

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
