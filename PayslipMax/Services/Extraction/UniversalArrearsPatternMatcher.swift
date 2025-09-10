//
//  UniversalArrearsPatternMatcher.swift
//  PayslipMax
//
//  Created for Phase 3: Universal Arrears System
//  Handles unlimited arrears combinations with dynamic pattern matching
//

import Foundation

/// Protocol for universal arrears pattern matching
protocol UniversalArrearsPatternMatcherProtocol {
    func extractArrearsComponents(from text: String) async -> [String: Double]
    func classifyArrearsSection(component: String, text: String) -> PayslipSection
    func validateArrearsPattern(_ pattern: String) -> Bool
}

/// Universal arrears pattern matcher for unlimited arrears combinations
/// Handles ARR-{ANY_CODE}, Arr-{ANY_CODE}, ARREARS {ANY_CODE} patterns
class UniversalArrearsPatternMatcher: UniversalArrearsPatternMatcherProtocol {

    // MARK: - Properties

    /// Pattern generator for dynamic arrears patterns
    private let patternGenerator: ArrearsPatternGenerator

    /// Validation service for extracted amounts
    private let componentValidator: MilitaryComponentValidator?

    // MARK: - Initialization

    init() {
        // Initialize pattern generator
        self.patternGenerator = ArrearsPatternGenerator()

        // Load pay structure for validation
        let payStructure = Self.loadPayStructure()
        self.componentValidator = MilitaryComponentValidator(payStructure: payStructure)

        print("[UniversalArrearsPatternMatcher] Initialized with pattern generator")
    }

    // MARK: - Public Methods

    /// Extracts all arrears components using universal pattern matching
    /// Supports unlimited combinations: ARR-{ANY_CODE}, Arr-{ANY_CODE}, ARREARS {ANY_CODE}
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary of arrears components with extracted amounts
    func extractArrearsComponents(from text: String) async -> [String: Double] {
        var extractedArrears: [String: Double] = [:]

        print("[UniversalArrearsPatternMatcher] Starting universal arrears extraction from \(text.count) characters")

        // Generate dynamic arrears patterns for all known pay codes
        let dynamicPatterns = patternGenerator.generateDynamicArrearsPatterns()

        // Extract using dynamic patterns
        for (component, patterns) in dynamicPatterns {
            for pattern in patterns {
                if let amount = extractAmountWithPattern(pattern, from: text) {
                    // Validate against known military pay codes
                    if validateArrearsPattern(component) {
                        extractedArrears[component] = amount
                        print("[UniversalArrearsPatternMatcher] Dynamic extracted \(component): ₹\(String(format: "%.1f", amount))")
                        break // Move to next component once found
                    }
                }
            }
        }

        // Fallback: Universal pattern matching for unknown codes
        let universalMatches = await extractUniversalArrearsPatterns(from: text)
        for (component, amount) in universalMatches {
            if extractedArrears[component] == nil {
                extractedArrears[component] = amount
                print("[UniversalArrearsPatternMatcher] Universal extracted \(component): ₹\(String(format: "%.1f", amount))")
            }
        }

        print("[UniversalArrearsPatternMatcher] Total arrears components extracted: \(extractedArrears.count)")
        return extractedArrears
    }

    /// Classifies arrears section using base component inheritance logic
    /// - Parameters:
    ///   - component: The arrears component (e.g., "ARR-BPAY")
    ///   - text: The full payslip text for context analysis
    /// - Returns: Section type (earnings vs deductions)
    func classifyArrearsSection(component: String, text: String) -> PayslipSection {
        // Extract base component from arrears pattern
        let baseComponent = extractBaseComponent(from: component)

        // Use existing section classifier logic for base component
        let sectionClassifier = PayslipSectionClassifier()
        let sectionType = sectionClassifier.classifyDualSectionComponent(
            componentKey: baseComponent,
            value: 0.0, // Amount not needed for classification
            text: text
        )

        // Special handling for deduction-based arrears
        if isDeductionBasedArrears(component) {
            return .deductions
        }

        // Default to earnings for most arrears (back-payments)
        return sectionType == .deductions ? .deductions : .earnings
    }

    /// Validates arrears pattern against known military pay codes
    /// - Parameter pattern: The arrears pattern to validate
    /// - Returns: True if pattern is valid military arrears
    func validateArrearsPattern(_ pattern: String) -> Bool {
        let baseComponent = extractBaseComponent(from: pattern)

        // Check against known pay codes
        return patternGenerator.isKnownPayCode(baseComponent)
    }

    // MARK: - Private Methods

    /// Extracts universal arrears patterns using flexible regex
    private func extractUniversalArrearsPatterns(from text: String) async -> [String: Double] {
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
            print("[UniversalArrearsPatternMatcher] Error in universal pattern matching: \(error)")
        }

        return matches
    }

    /// Extracts base component from arrears pattern
    private func extractBaseComponent(from arrearsComponent: String) -> String {
        let component = arrearsComponent.uppercased()

        // Remove ARR- prefix
        if component.hasPrefix("ARR-") {
            return String(component.dropFirst(4))
        }

        // Remove ARREARS prefix
        if component.hasPrefix("ARREARS") {
            return component.replacingOccurrences(of: "ARREARS", with: "").trimmingCharacters(in: .whitespaces)
        }

        return component
    }

    /// Checks if arrears component is deduction-based
    private func isDeductionBasedArrears(_ component: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "IT", "EHCESS", "PF", "GPF"]
        let baseComponent = extractBaseComponent(from: component)

        return deductionCodes.contains { deductionCode in
            baseComponent.uppercased().contains(deductionCode)
        }
    }

    /// Extracts amount using regex pattern
    private func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
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
            print("[UniversalArrearsPatternMatcher] Error in pattern extraction: \(error)")
        }

        return nil
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

    // MARK: - Static Helper Methods

    /// Loads military pay structure from resources
    private static func loadPayStructure() -> MilitaryPayStructure? {
        guard let url = Bundle.main.url(forResource: "military_pay_structure", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let structure = try? JSONDecoder().decode(MilitaryPayStructure.self, from: data) else {
            print("[UniversalArrearsPatternMatcher] Failed to load military pay structure")
            return nil
        }

        return structure
    }
}
