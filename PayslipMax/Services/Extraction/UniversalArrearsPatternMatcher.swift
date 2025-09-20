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
    func classifyArrearsSection(component: String, value: Double, text: String) -> PayslipSection
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

    /// Arrears classification service for context-aware classification
    private let arrearsClassificationService: ArrearsClassificationServiceProtocol

    /// Extraction helper for universal arrears pattern processing
    private let extractionHelper: UniversalArrearsExtractionHelper

    // MARK: - Initialization

    /// Initializes with dependency injection
    init(
        arrearsClassificationService: ArrearsClassificationServiceProtocol? = nil
    ) {
        // Initialize pattern generator
        self.patternGenerator = ArrearsPatternGenerator()

        // Load pay structure for validation
        let payStructure = Self.loadPayStructure()
        self.componentValidator = MilitaryComponentValidator(payStructure: payStructure)

        // Initialize arrears classification service (use provided or create new)
        self.arrearsClassificationService = arrearsClassificationService ?? ArrearsClassificationService()

        // Initialize extraction helper
        self.extractionHelper = UniversalArrearsExtractionHelper()

        print("[UniversalArrearsPatternMatcher] Initialized with enhanced classification service")
    }

    // MARK: - Public Methods

    /// Extracts all arrears components using universal pattern matching with context-based dual storage
    /// Supports unlimited combinations: ARR-{ANY_CODE}, Arr-{ANY_CODE}, ARREARS {ANY_CODE}
    /// - Parameter text: The payslip text to analyze
    /// - Returns: Dictionary of arrears components with section-specific keys
    func extractArrearsComponents(from text: String) async -> [String: Double] {
        var extractedArrears: [String: Double] = [:]

        print("[UniversalArrearsPatternMatcher] Starting enhanced arrears extraction from \(text.count) characters")

        // Generate dynamic arrears patterns for all known pay codes
        let dynamicPatterns = patternGenerator.generateDynamicArrearsPatterns()

        // Extract using dynamic patterns with context-based classification
        for (component, patterns) in dynamicPatterns {
            for pattern in patterns {
                if let amount = extractionHelper.extractAmountWithPattern(pattern, from: text) {
                    // Validate against known military pay codes
                    if validateArrearsPattern(component) {
                        // Apply enhanced context-based dual storage
                        applyEnhancedArrearsStorage(
                            component: component,
                            amount: amount,
                            text: text,
                            extractedArrears: &extractedArrears
                        )
                        print("[UniversalArrearsPatternMatcher] Dynamic extracted \(component): ₹\(String(format: "%.1f", amount))")
                        break // Move to next component once found
                    }
                }
            }
        }

        // Fallback: Universal pattern matching for unknown codes
        let universalMatches = await extractionHelper.extractUniversalArrearsPatterns(from: text)
        for (component, amount) in universalMatches {
            // Check if we already have this component (avoid duplicates)
            let hasExistingComponent = extractedArrears.keys.contains { key in
                key.hasPrefix(component) || key.contains(component)
            }

            if !hasExistingComponent {
                // Apply enhanced context-based dual storage
                applyEnhancedArrearsStorage(
                    component: component,
                    amount: amount,
                    text: text,
                    extractedArrears: &extractedArrears
                )
                print("[UniversalArrearsPatternMatcher] Universal extracted \(component): ₹\(String(format: "%.1f", amount))")
            }
        }

        print("[UniversalArrearsPatternMatcher] Total arrears components extracted: \(extractedArrears.count)")
        return extractedArrears
    }

    /// Classifies arrears section using enhanced context-based classification
    /// Supports universal dual-section processing for all arrears types
    /// - Parameters:
    ///   - component: The arrears component (e.g., "ARR-BPAY")
    ///   - value: The monetary value for classification context
    ///   - text: The full payslip text for spatial analysis
    /// - Returns: Section type (earnings vs deductions)
    func classifyArrearsSection(component: String, value: Double, text: String) -> PayslipSection {
        // Extract base component from arrears pattern
        let baseComponent = extractBaseComponent(from: component)

        // Use arrears classification service for enhanced processing
        return arrearsClassificationService.classifyArrearsSection(
            component: component,
            baseComponent: baseComponent,
            value: value,
            text: text
        )
    }

    /// Enhanced arrears classification using old signature for compatibility
    /// - Parameters:
    ///   - component: The arrears component (e.g., "ARR-BPAY")
    ///   - text: The full payslip text for context analysis
    /// - Returns: Section type (earnings vs deductions)
    func classifyArrearsSection(component: String, text: String) -> PayslipSection {
        return classifyArrearsSection(component: component, value: 0.0, text: text)
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

    /// Applies enhanced context-based dual storage for arrears components
    /// - Parameters:
    ///   - component: The arrears component code
    ///   - amount: The monetary amount
    ///   - text: The full payslip text for context
    ///   - extractedArrears: The dictionary to store results
    private func applyEnhancedArrearsStorage(
        component: String,
        amount: Double,
        text: String,
        extractedArrears: inout [String: Double]
    ) {
        // Classify the arrears section using enhanced classification
        let section = classifyArrearsSection(component: component, value: amount, text: text)

        // Extract base component for dual-section key generation
        let baseComponent = extractBaseComponent(from: component)

        // Check if this is a universal dual-section component
        let classificationEngine = PayCodeClassificationEngine()
        let baseClassification = classificationEngine.classifyComponent(baseComponent)

        if baseClassification == .universalDualSection {
            // Universal dual-section: use section-specific keys
            let sectionSpecificKey = section == .earnings
                ? "\(component)_EARNINGS"
                : "\(component)_DEDUCTIONS"

            extractedArrears[sectionSpecificKey] = amount
            print("[UniversalArrearsPatternMatcher] Enhanced storage: \(sectionSpecificKey) = ₹\(amount) (\(section))")
        } else {
            // Guaranteed single-section: use standard key (backward compatible)
            extractedArrears[component] = amount
            print("[UniversalArrearsPatternMatcher] Standard storage: \(component) = ₹\(amount) (\(section))")
        }
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
