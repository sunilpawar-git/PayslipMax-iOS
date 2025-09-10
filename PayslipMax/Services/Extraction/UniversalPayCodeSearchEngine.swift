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

    // MARK: - Initialization

    init() {
        // Initialize dependencies
        self.patternGenerator = PayCodePatternGenerator()
        self.classificationEngine = PayCodeClassificationEngine()

        print("[UniversalPayCodeSearchEngine] Initialized with pattern generator and classification engine")
    }

    // MARK: - Public Methods

    /// Searches for all known pay codes in the entire text regardless of section
    /// This implements the core Phase 4 requirement: search ALL codes in ALL columns
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their search results
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult] {
        var searchResults: [String: PayCodeSearchResult] = [:]

        print("[UniversalPayCodeSearchEngine] Starting universal search in \(text.count) characters")

        // Search for each known military pay code everywhere in the text
        let knownPayCodes = patternGenerator.getAllKnownPayCodes()
        for payCode in knownPayCodes {
            if let results = await searchPayCodeEverywhere(code: payCode, in: text) {
                // Handle dual-section codes (like RH12)
                if results.count > 1 {
                    // Multiple instances found - process each with context
                    for (index, result) in results.enumerated() {
                        let dualKey = "\(payCode)_\(index + 1)"
                        searchResults[dualKey] = result
                        print("[UniversalPayCodeSearchEngine] Dual-section found: \(dualKey) = ₹\(result.value) (\(result.section))")
                    }
                } else if let singleResult = results.first {
                    // Single instance found
                    searchResults[payCode] = singleResult
                    print("[UniversalPayCodeSearchEngine] Found: \(payCode) = ₹\(singleResult.value) (\(singleResult.section))")
                }
            }
        }

        // Also search for arrears patterns universally
        let arrearsResults = await searchUniversalArrearsPatterns(in: text)
        for (arrearsCode, result) in arrearsResults {
            searchResults[arrearsCode] = result
        }

        print("[UniversalPayCodeSearchEngine] Universal search completed: \(searchResults.count) components found")
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

    /// Searches for universal arrears patterns
    private func searchUniversalArrearsPatterns(in text: String) async -> [String: PayCodeSearchResult] {
        var arrearsResults: [String: PayCodeSearchResult] = [:]

        // Get universal arrears patterns from pattern generator
        let universalArrearsPatterns = patternGenerator.generateUniversalArrearsPatterns()

        for pattern in universalArrearsPatterns {
            let matches = extractUniversalArrearsMatches(pattern: pattern, from: text)
            for match in matches {
                let arrearsCode = "ARR-\(match.component)"
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: arrearsCode,
                    value: match.value,
                    context: match.context
                )

                arrearsResults[arrearsCode] = PayCodeSearchResult(
                    value: match.value,
                    section: classification.section,
                    confidence: classification.confidence,
                    context: match.context,
                    isDualSection: false
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
