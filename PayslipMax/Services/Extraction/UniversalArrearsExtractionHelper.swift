//
//  UniversalArrearsExtractionHelper.swift
//  PayslipMax
//
//  Created for Phase 3: Universal Arrears Enhancement
//  Helper service for universal arrears pattern extraction
//

import Foundation

/// Helper service for universal arrears pattern extraction
/// Extracted to maintain file size compliance
final class UniversalArrearsExtractionHelper {

    // MARK: - Properties

    /// Pattern generator for dynamic arrears patterns
    private let patternGenerator: ArrearsPatternGenerator

    // MARK: - Initialization

    init() {
        self.patternGenerator = ArrearsPatternGenerator()
    }

    // MARK: - Public Methods

    /// Extracts universal arrears patterns using flexible regex
    func extractUniversalArrearsPatterns(from text: String) async -> [String: Double] {
        var universalMatches: [String: Double] = [:]

        // Get universal patterns from pattern generator
        let universalPatterns = patternGenerator.getUniversalArrearsPatterns()

        for pattern in universalPatterns {
            let matches = extractUniversalMatches(pattern: pattern, from: text)
            for (component, amount) in matches {
                let arrearsKey = "ARR-\(component)"
                universalMatches[arrearsKey] = amount
            }
        }

        return universalMatches
    }

    /// Extracts amount using regex pattern
    func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results {
                if result.numberOfRanges > 1 {
                    let amountRange = result.range(at: 1)
                    if amountRange.location != NSNotFound {
                        let amountString = nsText.substring(with: amountRange)
                        return parseAmount(amountString)
                    }
                }
            }
        } catch {
            print("[UniversalArrearsExtractionHelper] Error in pattern extraction: \(error)")
        }

        return nil
    }

    // MARK: - Private Methods

    /// Extracts matches using universal regex with component capture
    private func extractUniversalMatches(pattern: String, from text: String) -> [String: Double] {
        var matches: [String: Double] = [:]

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results {
                if result.numberOfRanges >= 3 {
                    let componentRange = result.range(at: 1)
                    let amountRange = result.range(at: 2)

                    if componentRange.location != NSNotFound && amountRange.location != NSNotFound {
                        let component = nsText.substring(with: componentRange)
                        let amountString = nsText.substring(with: amountRange)

                        if let amount = parseAmount(amountString) {
                            matches[component.uppercased()] = amount
                        }
                    }
                }
            }
        } catch {
            print("[UniversalArrearsExtractionHelper] Error in universal pattern matching: \(error)")
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
