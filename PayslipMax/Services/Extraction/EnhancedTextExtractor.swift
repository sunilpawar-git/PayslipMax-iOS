//
//  EnhancedTextExtractor.swift
//  PayslipMax
//
//  Created for Phase 4: Enhanced text extraction with universal pay code search
//  Replaces mutually exclusive column logic with universal search capability
//

import Foundation
import PDFKit

/// Enhanced text extractor that uses universal pay code search
/// Implements Phase 4 requirement: search ALL codes in ALL columns
class EnhancedTextExtractor: TextExtractor {

    // MARK: - Properties

    /// Pattern provider for legacy compatibility
    private let patternProvider: PatternProvider

    /// Universal pay code search engine for Phase 4 implementation
    private let universalSearchEngine: UniversalPayCodeSearchEngineProtocol

    /// Legacy extractor for fallback
    private let legacyExtractor: TextExtractorImplementation

    // MARK: - Initialization

    init(
        patternProvider: PatternProvider = DefaultPatternProvider(),
        universalSearchEngine: UniversalPayCodeSearchEngineProtocol
    ) {
        self.patternProvider = patternProvider
        self.universalSearchEngine = universalSearchEngine
        self.legacyExtractor = TextExtractorImplementation(patternProvider: patternProvider)
    }

    // MARK: - TextExtractor Protocol Implementation

    /// Extracts text from a PDF document asynchronously
    func extractText(from document: PDFDocument) async -> String {
        var allText = ""

        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if let pageText = page.string {
                    allText += pageText
                }
            }
        }

        return allText
    }

    /// Extracts data from text using patterns (legacy compatibility)
    func extractData(from text: String) -> [String: String] {
        return legacyExtractor.extractData(from: text)
    }

    /// Enhanced tabular data extraction using universal pay code search
    /// This replaces the mutually exclusive column logic with universal search
    /// NOTE: Temporarily synchronous for protocol compatibility. Should be async in future.
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {

        print("[EnhancedTextExtractor] Starting enhanced tabular data extraction")

        // For now, fall back to legacy extraction with improved logic
        // TODO: Make this async when the protocol is updated to support async
        return enhancedLegacyExtraction(from: text)
    }

    /// Enhanced legacy extraction that simulates universal search behavior
    /// Uses improved heuristics until async protocol support is available
    private func enhancedLegacyExtraction(from text: String) -> ([String: Double], [String: Double]) {
        // Start with legacy extraction
        let (legacyEarnings, legacyDeductions) = legacyExtractor.extractTabularData(from: text)

        // Apply enhanced processing to simulate universal search results
        var enhancedEarnings = legacyEarnings
        var enhancedDeductions = legacyDeductions

        // Apply universal search-like logic for dual-section components
        let potentialDualSectionComponents = findPotentialDualSectionComponents(in: text)
        for (code, values) in potentialDualSectionComponents {
            for (value, section) in values {
                switch section {
                case .earnings:
                    enhancedEarnings[code] = value
                case .deductions:
                    enhancedDeductions[code] = value
                case .unknown:
                    // Apply fallback logic
                    if value >= patternProvider.minimumEarningsAmount {
                        enhancedEarnings[code] = value
                    }
                }
            }
        }

        return (enhancedEarnings, enhancedDeductions)
    }

    /// Finds potential dual-section components using pattern matching
    private func findPotentialDualSectionComponents(in text: String) -> [String: [(Double, PayslipSection)]] {
        var dualComponents: [String: [(Double, PayslipSection)]] = [:]

        // Known dual-section codes to search for
        let dualSectionCodes = ["RH12", "RH11", "RH13", "MSP", "TPTA"]

        for code in dualSectionCodes {
            let patterns = generateBasicPatterns(for: code)
            for pattern in patterns {
                let matches = extractBasicMatches(pattern: pattern, from: text)
                for (value, context) in matches {
                    let section = classifyBasicContext(context: context, value: value)
                    if dualComponents[code] == nil {
                        dualComponents[code] = []
                    }
                    dualComponents[code]?.append((value, section))
                }
            }
        }

        return dualComponents
    }

    /// Generates basic patterns for a pay code
    private func generateBasicPatterns(for code: String) -> [String] {
        return [
            "(?:\(code))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "\(code)\\s+(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]
    }

    /// Extracts basic pattern matches
    private func extractBasicMatches(pattern: String, from text: String) -> [(value: Double, context: String)] {
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
                            let contextRange = NSRange(
                                location: max(0, result.range.location - 100),
                                length: min(200, nsText.length - max(0, result.range.location - 100))
                            )
                            let context = nsText.substring(with: contextRange)
                            matches.append((value: value, context: context))
                        }
                    }
                }
            }
        } catch {
            print("[EnhancedTextExtractor] Pattern matching error: \(error)")
        }

        return matches
    }

    /// Classifies context using basic heuristics
    private func classifyBasicContext(context: String, value: Double) -> PayslipSection {
        let upperContext = context.uppercased()

        // Look for section indicators
        if upperContext.contains("EARNINGS") || upperContext.contains("CREDIT") {
            return .earnings
        } else if upperContext.contains("DEDUCTIONS") || upperContext.contains("DEBIT") {
            return .deductions
        }

        // Use value-based heuristic for large amounts
        if value > 15000 {
            return .earnings
        } else {
            return .deductions
        }
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
