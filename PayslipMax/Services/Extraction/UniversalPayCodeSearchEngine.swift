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

// MARK: - Private Methods

extension UniversalPayCodeSearchEngine {

    /// Searches for a specific pay code everywhere in the text
    private func searchPayCodeEverywhere(code: String, in text: String) async -> [PayCodeSearchResult]? {
        var results: [PayCodeSearchResult] = []

        // 🔍 DEBUG: Log critical codes (DA, RH12)
        let isCriticalCode = ["DA", "RH12", "RH11", "RH13"].contains(code.uppercased())
        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG] searchPayCodeEverywhere: code=\(code)")
            print("[DEBUG]   Text sample: \(String(text.prefix(300))...)")
        }

        // Generate multiple pattern variations for the pay code
        let patterns = patternGenerator.generatePayCodePatterns(for: code)

        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG]   Generated \(patterns.count) patterns for \(code)")
        }

        for (patternIndex, pattern) in patterns.enumerated() {
            let matches = extractPatternMatches(pattern: pattern, from: text)

            if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
                print("[DEBUG]   Pattern[\(patternIndex)]: found \(matches.count) matches")
            }

            for match in matches {
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: code,
                    value: match.value,
                    context: match.context
                )

                if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
                    let debugMsg = "[DEBUG] value=₹\(match.value) section=\(classification.section) confidence=\(classification.confidence)"
                    print(debugMsg)
                }

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

        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG]   Total results for \(code): \(results.count)")
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
                    let suffix = classification.section == .earnings ? "_EARNINGS" : "_DEDUCTIONS"
                    finalKey = "\(arrearsCode)\(suffix)"
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

            for result in results where result.numberOfRanges > 1 {
                let amountRange = result.range(at: 1)
                if amountRange.location != NSNotFound {
                    let amountString = nsText.substring(with: amountRange)
                    if let value = parseAmount(amountString) {
                        let contextRange = NSRange(
                            location: max(0, result.range.location - 200),
                            length: min(400, nsText.length - max(0, result.range.location - 200))
                        )
                        let context = nsText.substring(with: contextRange)
                        matches.append((value: value, context: context))
                    }
                }
            }
        } catch {}

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

            for result in results where result.numberOfRanges >= 3 {
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
        } catch {}

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
