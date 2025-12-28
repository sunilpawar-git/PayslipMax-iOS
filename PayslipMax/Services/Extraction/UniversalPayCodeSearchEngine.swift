//
//  UniversalPayCodeSearchEngine.swift
//  PayslipMax
//
//  Created for Phase 4: Universal Pay Code Search
//  Core implementation of the universal pay code search engine
//
import Foundation

/// Universal pay code search engine that searches ALL codes everywhere
/// Implements Phase 4 requirement: find codes in both earnings and deductions
final class UniversalPayCodeSearchEngine: UniversalPayCodeSearchEngineProtocol {
    // MARK: - Properties
    /// Pattern generator for pay code patterns
    let patternGenerator: PayCodePatternGenerator

    /// Classification engine for intelligent component classification
    let classificationEngine: PayCodeClassificationEngine

    /// Parallel processor for optimized multi-code processing
    let parallelProcessor: ParallelPayCodeProcessorProtocol

    // MARK: - Initialization
    init(parallelProcessor: ParallelPayCodeProcessorProtocol? = nil) {
        // Initialize dependencies - use singleton to avoid repeated JSON loading
        self.patternGenerator = PayCodePatternGenerator.shared
        self.classificationEngine = PayCodeClassificationEngine()
        self.parallelProcessor = parallelProcessor ?? ParallelPayCodeProcessor.shared
    }

    // MARK: - Public Methods
    /// Searches for all known pay codes with parallel processing optimization
    /// Enhanced for universal dual-section processing with performance improvements
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their search results
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult] {

        // Start performance monitoring
        let sessionId = UUID().uuidString
        DualSectionPerformanceMonitor.shared.startMonitoring(sessionId: sessionId)
        let startTime = Date()

        // Get all known pay codes and partition them by classification
        let knownPayCodes = Array(patternGenerator.getAllKnownPayCodes())
        let (guaranteedCodes, universalCodes) = parallelProcessor.partitionPayCodesByClassification(knownPayCodes) { code in
            self.classificationEngine.classifyComponent(code)
        }

        // Process guaranteed single-section codes in parallel (faster processing)
        async let guaranteedResults = parallelProcessor.processGuaranteedCodesInParallel(
            guaranteedCodes,
            text: text,
            searchFunction: self.searchPayCodeEverywhere
        )

        // Process universal dual-section codes in parallel (more complex processing)
        async let universalResults = parallelProcessor.processUniversalCodesInParallel(
            universalCodes,
            text: text,
            searchFunction: self.searchPayCodeEverywhere
        )

        // Process arrears patterns in parallel
        async let arrearsResults = searchUniversalArrearsPatterns(in: text)

        // Await all parallel operations
        let (guaranteedDict, universalDict, arrearsDict) = await (guaranteedResults, universalResults, arrearsResults)

        // Combine all results
        var searchResults: [String: PayCodeSearchResult] = [:]
        searchResults.merge(guaranteedDict) { _, new in new }
        searchResults.merge(universalDict) { _, new in new }
        searchResults.merge(arrearsDict) { _, new in new }

        // Pass 2: relaxed line-based sweep for noisy OCR on key components
        let relaxed = extractRelaxedLineMatches(from: text)
        searchResults.merge(relaxed) { _, new in new }

        // Pass 3: cross-line sweep for labels followed by numbers across breaks
        let crossLine = extractCrossLineMatches(from: text)
        searchResults.merge(crossLine) { _, new in new }

        // End performance monitoring
        if let metrics = DualSectionPerformanceMonitor.shared.endMonitoring(sessionId: sessionId) {
            let isAcceptable = DualSectionPerformanceMonitor.shared.isPerformanceAcceptable(metrics)
            let processingTime = Date().timeIntervalSince(startTime)

            // swiftlint:disable no_hardcoded_strings
            print("  - Processing time: \(String(format: "%.3f", processingTime * 1000))ms")
            print("  - Cache hit rate: \(String(format: "%.1f", metrics.cacheHitRate * 100))%")
            print("  - Performance acceptable: \(isAcceptable)")
            // swiftlint:enable no_hardcoded_strings
        }

        return searchResults
    }

    /// Validates if a pay code is a known military component
    /// - Parameter code: The pay code to validate
    /// - Returns: True if it's a valid military pay code
    func isKnownMilitaryPayCode(_ code: String) -> Bool {
        return patternGenerator.isKnownMilitaryPayCode(code)
    }
}
