//
//  UniversalDualSectionProcessor.swift
//  PayslipMax
//
//  Created for universal dual-section processing of military payslips
//  Handles ALL allowances that can appear as both payments and recoveries
//

import Foundation

/// Protocol for universal dual-section processing capabilities
protocol UniversalDualSectionProcessorProtocol {
    /// Processes any allowance component that can appear in both earnings and deductions
    /// - Parameters:
    ///   - key: The component key (e.g., "HRA", "CEA", "SICHA")
    ///   - value: The monetary value extracted
    ///   - text: Full payslip text for context analysis
    ///   - earnings: Mutable earnings dictionary
    ///   - deductions: Mutable deductions dictionary
    func processUniversalComponent(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) async
    
    /// Validates if a component should be processed as dual-section
    /// - Parameter key: The component key to validate
    /// - Returns: True if component should get dual-section processing
    func shouldProcessAsDualSection(_ key: String) -> Bool
}

/// Universal processor for components that can appear in both earnings and deductions
/// Extends the proven RH12 dual-section pattern to all allowances
final class UniversalDualSectionProcessor: UniversalDualSectionProcessorProtocol {
    
    // MARK: - Dependencies
    
    /// Section classifier for context-based classification
    private let sectionClassifier: PayslipSectionClassifier
    
    /// Classification engine for component type determination
    private let classificationEngine: PayCodeClassificationEngine
    
    // MARK: - Performance Optimization
    
    /// Cache for classification results to avoid repeated analysis
    private var classificationCache: [String: ComponentClassification] = [:]
    
    /// Cache for section classification results
    private var sectionCache: [String: PayslipSection] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with required dependencies
    /// - Parameters:
    ///   - sectionClassifier: Service for section-based classification
    ///   - classificationEngine: Engine for component type classification
    init(
        sectionClassifier: PayslipSectionClassifier? = nil,
        classificationEngine: PayCodeClassificationEngine? = nil
    ) {
        self.sectionClassifier = sectionClassifier ?? PayslipSectionClassifier()
        self.classificationEngine = classificationEngine ?? PayCodeClassificationEngine()
    }
    
    // MARK: - Public Interface
    
    /// Processes any universal component using intelligent dual-section logic
    /// Enhanced from RH12 processor to handle all allowances
    func processUniversalComponent(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) async {
        print("[UniversalDualSectionProcessor] Processing component: \(key) = ₹\(value)")
        
        // Validate component should get dual-section processing
        guard shouldProcessAsDualSection(key) else {
            print("[UniversalDualSectionProcessor] Component \(key) not eligible for dual-section processing")
            return
        }
        
        // Classify the section using context analysis
        let sectionType = await classifyComponentSection(
            componentKey: key,
            value: value,
            text: text
        )
        
        // Store in appropriate section using dual-section keys
        await storeInAppropriateSection(
            key: key,
            value: value,
            sectionType: sectionType,
            earnings: &earnings,
            deductions: &deductions
        )
    }
    
    /// Validates if component should get dual-section processing
    func shouldProcessAsDualSection(_ key: String) -> Bool {
        let classification = getCachedClassification(for: key)
        return classification == .universalDualSection
    }
    
    // MARK: - Private Methods
    
    /// Gets cached classification or computes new one
    private func getCachedClassification(for key: String) -> ComponentClassification {
        if let cached = classificationCache[key] {
            return cached
        }
        
        let classification = classificationEngine.classifyComponent(key)
        classificationCache[key] = classification
        return classification
    }
    
    /// Classifies component section using enhanced dual-section logic
    private func classifyComponentSection(
        componentKey: String,
        value: Double,
        text: String
    ) async -> PayslipSection {
        // Check cache first for performance
        let cacheKey = "\(componentKey)_\(value)_\(text.hashValue)"
        if let cached = sectionCache[cacheKey] {
            return cached
        }
        
        // Use enhanced section classifier with dual-section capabilities
        let sectionType = sectionClassifier.classifyDualSectionComponent(
            componentKey: componentKey,
            value: value,
            text: text
        )
        
        // Cache result for performance
        sectionCache[cacheKey] = sectionType
        
        print("[UniversalDualSectionProcessor] \(componentKey) ₹\(value) classified as \(sectionType)")
        return sectionType
    }
    
    /// Stores component in appropriate section using dual-section key pattern
    private func storeInAppropriateSection(
        key: String,
        value: Double,
        sectionType: PayslipSection,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) async {
        switch sectionType {
        case .earnings:
            let earningsKey = "\(key)_EARNINGS"
            let currentValue = earnings[earningsKey] ?? 0.0
            earnings[earningsKey] = currentValue + value
            print("[UniversalDualSectionProcessor] Stored \(earningsKey) = ₹\(currentValue + value)")
            
        case .deductions:
            let deductionsKey = "\(key)_DEDUCTIONS"
            let currentValue = deductions[deductionsKey] ?? 0.0
            deductions[deductionsKey] = currentValue + value
            print("[UniversalDualSectionProcessor] Stored \(deductionsKey) = ₹\(currentValue + value)")
            
        case .unknown:
            // For unknown sections, default to earnings as safer choice
            let earningsKey = "\(key)_EARNINGS"
            let currentValue = earnings[earningsKey] ?? 0.0
            earnings[earningsKey] = currentValue + value
            print("[UniversalDualSectionProcessor] Unknown section for \(key), defaulted to earnings: ₹\(currentValue + value)")
        }
    }
    
    /// Clears caches for memory management
    func clearCaches() {
        classificationCache.removeAll()
        sectionCache.removeAll()
        print("[UniversalDualSectionProcessor] Caches cleared for memory optimization")
    }
    
    /// Gets current cache statistics for monitoring
    func getCacheStatistics() -> (classificationCacheSize: Int, sectionCacheSize: Int) {
        return (classificationCache.count, sectionCache.count)
    }
}

// MARK: - Extensions

/// Extension for component-specific processing rules
extension UniversalDualSectionProcessor {
    
    /// Checks if component has specific dual-section processing rules
    /// - Parameter key: Component key to check
    /// - Returns: True if component has specific rules
    private func hasSpecificProcessingRules(_ key: String) -> Bool {
        let specialComponents = ["RH12", "RH11", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
        return specialComponents.contains { key.uppercased().contains($0) }
    }
    
    /// Gets component-specific processing confidence
    /// - Parameter key: Component key
    /// - Returns: Confidence score (0.0 to 1.0)
    private func getProcessingConfidence(for key: String) -> Double {
        if hasSpecificProcessingRules(key) {
            return 0.95 // High confidence for RH codes
        } else if ["HRA", "CEA", "SICHA", "DA", "TPTA"].contains(key.uppercased()) {
            return 0.85 // Good confidence for common allowances
        } else {
            return 0.70 // Moderate confidence for other components
        }
    }
}
