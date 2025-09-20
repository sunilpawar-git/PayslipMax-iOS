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

    /// Cache for section classification results with context hashing
    private var sectionCache: [String: PayslipSection] = [:]

    /// Performance monitor for tracking optimization effectiveness
    private let performanceMonitor: DualSectionPerformanceMonitorProtocol

    /// Current processing session identifier
    private var currentSessionId: String?

    /// Maximum cache size to prevent memory bloat
    private let maxCacheSize: Int = 1000

    // MARK: - Initialization

    /// Initialize with required dependencies
    /// - Parameters:
    ///   - sectionClassifier: Service for section-based classification
    ///   - classificationEngine: Engine for component type classification
    ///   - performanceMonitor: Performance monitoring service
    init(
        sectionClassifier: PayslipSectionClassifier? = nil,
        classificationEngine: PayCodeClassificationEngine? = nil,
        performanceMonitor: DualSectionPerformanceMonitorProtocol? = nil
    ) {
        self.sectionClassifier = sectionClassifier ?? PayslipSectionClassifier()
        self.classificationEngine = classificationEngine ?? PayCodeClassificationEngine()
        self.performanceMonitor = performanceMonitor ?? DualSectionPerformanceMonitor.shared
    }

    // MARK: - Public Interface

    /// Processes any universal component using intelligent dual-section logic
    /// Enhanced from RH12 processor to handle all allowances with performance optimization
    func processUniversalComponent(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) async {
        let startTime = Date()

        // Start performance session if not already active
        if currentSessionId == nil {
            currentSessionId = UUID().uuidString
            performanceMonitor.startMonitoring(sessionId: currentSessionId!)
        }

        print("[UniversalDualSectionProcessor] Processing component: \(key) = ₹\(value)")

        // Early termination: Check if component should get dual-section processing
        let classification = getCachedClassification(for: key)
        guard classification == .universalDualSection else {
            print("[UniversalDualSectionProcessor] Early termination: \(key) not eligible for dual-section processing")
            recordPerformance(key: key, wasFromCache: true, startTime: startTime)
            return
        }

        // Classify the section using optimized context analysis
        let sectionType = await classifyComponentSectionOptimized(
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

        recordPerformance(key: key, wasFromCache: false, startTime: startTime)
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

    /// Optimized section classification with intelligent caching and memory management
    private func classifyComponentSectionOptimized(
        componentKey: String,
        value: Double,
        text: String
    ) async -> PayslipSection {
        // Generate optimized cache key with truncated text hash for memory efficiency
        let truncatedTextHash = String(text.prefix(500).hashValue)
        let cacheKey = "\(componentKey)_\(value)_\(truncatedTextHash)"

        // Check cache first for performance
        if let cached = sectionCache[cacheKey] {
            return cached
        }

        // Memory management: Clear cache if it gets too large
        if sectionCache.count >= maxCacheSize {
            clearOldestCacheEntries()
        }

        // Use enhanced section classifier with dual-section capabilities
        let sectionType = sectionClassifier.classifyDualSectionComponent(
            componentKey: componentKey,
            value: value,
            text: text
        )

        // Cache result for performance with memory-conscious approach
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

    /// Clears oldest cache entries to maintain memory efficiency
    private func clearOldestCacheEntries() {
        let entriesToRemove = max(1, sectionCache.count / 4) // Remove 25% of cache
        let keysToRemove = Array(sectionCache.keys.prefix(entriesToRemove))

        for key in keysToRemove {
            sectionCache.removeValue(forKey: key)
        }

        print("[UniversalDualSectionProcessor] Cleared \(keysToRemove.count) oldest cache entries")
    }

    /// Records performance metrics for monitoring
    private func recordPerformance(key: String, wasFromCache: Bool, startTime: Date) {
        guard let sessionId = currentSessionId else { return }

        let processingTime = Date().timeIntervalSince(startTime)
        performanceMonitor.recordComponentProcessing(
            sessionId: sessionId,
            componentKey: key,
            wasFromCache: wasFromCache,
            processingTime: processingTime
        )
    }

    /// Ends current performance monitoring session and returns metrics
    func endPerformanceSession() -> DualSectionPerformanceMetrics? {
        guard let sessionId = currentSessionId else { return nil }

        let metrics = performanceMonitor.endMonitoring(sessionId: sessionId)
        currentSessionId = nil
        return metrics
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
