//
//  UniversalPayCodeSearchEngine.swift
//  PayslipMax
//
//  Created for Phase 4: Universal Pay Code Search
//  Searches ALL codes in ALL columns (earnings + deductions) with intelligent classification
//

import Foundation

/// Protocol for universal pay code search operations
protocol UniversalPayCodeSearchEngineProtocol {
    /// Searches for all known pay codes in the entire text regardless of section
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their found values and sections
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult]

    /// Validates if a pay code is a known military component
    /// - Parameter code: The pay code to validate
    /// - Returns: True if it's a valid military pay code
    func isKnownMilitaryPayCode(_ code: String) -> Bool
}

/// Result structure for pay code search operations
struct PayCodeSearchResult {
    let value: Double
    let section: PayslipSection
    let confidence: Double
    let context: String
    let isDualSection: Bool
}

/// Result structure for intelligent component classification
struct PayCodeClassificationResult {
    let section: PayslipSection
    let confidence: Double
    let reasoning: String
    let isDualSection: Bool
}

/// Universal pay code search engine that searches ALL codes everywhere
/// Implements Phase 4 requirement: find codes in both earnings and deductions
final class UniversalPayCodeSearchEngine: UniversalPayCodeSearchEngineProtocol {

    // MARK: - Properties

    /// Pattern generator for pay code patterns
    private let patternGenerator: PayCodePatternGenerator

    /// Classification engine for intelligent component classification
    private let classificationEngine: PayCodeClassificationEngine
    
    /// Parallel processor for optimized multi-code processing
    private let parallelProcessor: ParallelPayCodeProcessorProtocol

    // MARK: - Initialization

    init(parallelProcessor: ParallelPayCodeProcessorProtocol? = nil) {
        // Initialize dependencies
        self.patternGenerator = PayCodePatternGenerator()
        self.classificationEngine = PayCodeClassificationEngine()
        self.parallelProcessor = parallelProcessor ?? ParallelPayCodeProcessor.shared

        print("[UniversalPayCodeSearchEngine] Initialized with pattern generator, classification engine, and parallel processor")
    }

    // MARK: - Public Methods

    /// Searches for all known pay codes with parallel processing optimization
    /// Enhanced for universal dual-section processing with performance improvements
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their search results
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult] {
        print("[UniversalPayCodeSearchEngine] Starting parallel universal search with enhanced classification")
        
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
        
        // End performance monitoring
        if let metrics = DualSectionPerformanceMonitor.shared.endMonitoring(sessionId: sessionId) {
            let isAcceptable = DualSectionPerformanceMonitor.shared.isPerformanceAcceptable(metrics)
            let processingTime = Date().timeIntervalSince(startTime)
            
            print("[UniversalPayCodeSearchEngine] Parallel search completed: \(searchResults.count) components found")
            print("  - Processing time: \(String(format: "%.3f", processingTime * 1000))ms")
            print("  - Cache hit rate: \(String(format: "%.1f", metrics.cacheHitRate * 100))%")
            print("  - Performance acceptable: \(isAcceptable)")
        }
        
        return searchResults
    }

    /// Validates if a pay code is a known military component
    /// - Parameter code: The pay code to validate
    /// - Returns: True if it's a valid military pay code
    func isKnownMilitaryPayCode(_ code: String) -> Bool {
        return patternGenerator.isKnownMilitaryPayCode(code)
    }

    // MARK: - Private Methods

    /// Searches for a specific pay code everywhere in the text
    private func searchPayCodeEverywhere(code: String, in text: String) async -> [PayCodeSearchResult]? {
        var results: [PayCodeSearchResult] = []

        // Generate multiple pattern variations for the pay code
        let patterns = patternGenerator.generatePayCodePatterns(for: code)

        for pattern in patterns {
            let matches = extractPatternMatches(pattern: pattern, from: text)
            for match in matches {
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: code,
                    value: match.value,
                    context: match.context
                )

                let result = PayCodeSearchResult(
                    value: match.value,
                    section: classification.section,
                    confidence: classification.confidence,
                    context: match.context,
                    isDualSection: classification.isDualSection
                )

                results.append(result)
            }
        }

        return results.isEmpty ? nil : results
    }

    /// Searches for universal arrears patterns with enhanced classification
    private func searchUniversalArrearsPatterns(in text: String) async -> [String: PayCodeSearchResult] {
        var arrearsResults: [String: PayCodeSearchResult] = [:]

        // Get universal arrears patterns from pattern generator
        let universalArrearsPatterns = patternGenerator.generateUniversalArrearsPatterns()

        for pattern in universalArrearsPatterns {
            let matches = extractUniversalArrearsMatches(pattern: pattern, from: text)
            for match in matches {
                let arrearsCode = "ARR-\(match.component)"

                // Classify arrears using enhanced system
                let baseComponentClassification = classificationEngine.classifyComponent(match.component)
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: arrearsCode,
                    value: match.value,
                    context: match.context
                )

                // For universal dual-section arrears, use section-specific keys
                let finalKey: String
                if baseComponentClassification == .universalDualSection {
                    finalKey = classification.section == .earnings ? "\(arrearsCode)_EARNINGS" : "\(arrearsCode)_DEDUCTIONS"
                } else {
                    finalKey = arrearsCode
                }

                arrearsResults[finalKey] = PayCodeSearchResult(
                    value: match.value,
                    section: classification.section,
                    confidence: classification.confidence,
                    context: match.context,
                    isDualSection: baseComponentClassification == .universalDualSection
                )

                print("[UniversalPayCodeSearchEngine] Enhanced arrears: \(finalKey) = ₹\(match.value) (\(classification.section))")
            }
        }

        return arrearsResults
    }

    /// Extracts pattern matches with context
    private func extractPatternMatches(pattern: String, from text: String) -> [(value: Double, context: String)] {
        var matches: [(value: Double, context: String)] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results {
                if result.numberOfRanges > 1 {
                    let amountRange = result.range(at: 1)
                    if amountRange.location != NSNotFound {
                        let amountString = nsText.substring(with: amountRange)
                        if let value = parseAmount(amountString) {
                            // Extract context around the match
                            let contextRange = NSRange(
                                location: max(0, result.range.location - 200),
                                length: min(400, nsText.length - max(0, result.range.location - 200))
                            )
                            let context = nsText.substring(with: contextRange)
                            matches.append((value: value, context: context))
                        }
                    }
                }
            }
        } catch {
            print("[UniversalPayCodeSearchEngine] Pattern matching error: \(error)")
        }

        return matches
    }

    /// Extracts universal arrears matches with component identification
    private func extractUniversalArrearsMatches(
        pattern: String,
        from text: String
    ) -> [(component: String, value: Double, context: String)] {
        var matches: [(component: String, value: Double, context: String)] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results {
                if result.numberOfRanges >= 3 {
                    let componentRange = result.range(at: 1)
                    let amountRange = result.range(at: 2)

                    if componentRange.location != NSNotFound && amountRange.location != NSNotFound {
                        let component = nsText.substring(with: componentRange).uppercased()
                        let amountString = nsText.substring(with: amountRange)

                        if let value = parseAmount(amountString), isKnownMilitaryPayCode(component) {
                            let contextRange = NSRange(
                                location: max(0, result.range.location - 200),
                                length: min(400, nsText.length - max(0, result.range.location - 200))
                            )
                            let context = nsText.substring(with: contextRange)
                            matches.append((component: component, value: value, context: context))
                        }
                    }
                }
            }
        } catch {
            print("[UniversalPayCodeSearchEngine] Universal arrears pattern error: \(error)")
        }

        return matches
    }

    /// Parses amount string to double value
    private func parseAmount(_ amountString: String) -> Double? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanAmount)
    }
}
