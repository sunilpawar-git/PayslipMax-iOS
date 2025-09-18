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
    /// Enhanced for universal dual-section processing in Phase 1
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary mapping component codes to their search results
    func searchAllPayCodes(in text: String) async -> [String: PayCodeSearchResult] {
        var searchResults: [String: PayCodeSearchResult] = [:]

        print("[UniversalPayCodeSearchEngine] Starting universal search with enhanced classification")

        // Search for each known military pay code everywhere in the text
        let knownPayCodes = patternGenerator.getAllKnownPayCodes()
        for payCode in knownPayCodes {
            // Get component classification to determine search strategy
            let componentClassification = classificationEngine.classifyComponent(payCode)
            
            if let results = await searchPayCodeEverywhere(code: payCode, in: text) {
                switch componentClassification {
                case .guaranteedEarnings, .guaranteedDeductions:
                    // Single-section guaranteed components
                    if let singleResult = results.first {
                        searchResults[payCode] = singleResult
                        print("[UniversalPayCodeSearchEngine] Guaranteed single-section: \(payCode) = ₹\(singleResult.value) (\(singleResult.section))")
                    }
                    
                case .universalDualSection:
                    // Universal dual-section components - can appear in both sections
                    if results.count > 1 {
                        // Multiple instances found - store with section-specific keys
                        var earningsCount = 0
                        var deductionsCount = 0
                        
                        for result in results {
                            let sectionKey: String
                            if result.section == .earnings {
                                earningsCount += 1
                                sectionKey = earningsCount == 1 ? "\(payCode)_EARNINGS" : "\(payCode)_EARNINGS_\(earningsCount)"
                            } else {
                                deductionsCount += 1
                                sectionKey = deductionsCount == 1 ? "\(payCode)_DEDUCTIONS" : "\(payCode)_DEDUCTIONS_\(deductionsCount)"
                            }
                            
                            searchResults[sectionKey] = result
                            print("[UniversalPayCodeSearchEngine] Universal dual-section: \(sectionKey) = ₹\(result.value)")
                        }
                    } else if let singleResult = results.first {
                        // Single instance - still use section-specific key for consistency
                        let sectionKey = singleResult.section == .earnings ? "\(payCode)_EARNINGS" : "\(payCode)_DEDUCTIONS"
                        searchResults[sectionKey] = singleResult
                        print("[UniversalPayCodeSearchEngine] Universal single instance: \(sectionKey) = ₹\(singleResult.value)")
                    }
                }
            }
        }

        // Search for arrears patterns with enhanced classification
        let arrearsResults = await searchUniversalArrearsPatterns(in: text)
        for (arrearsCode, result) in arrearsResults {
            searchResults[arrearsCode] = result
        }

        print("[UniversalPayCodeSearchEngine] Enhanced universal search completed: \(searchResults.count) components found")
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
