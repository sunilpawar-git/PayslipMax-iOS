//
//  MilitaryPatternExtractor.swift
//  PayslipMax
//
//  Created for military-specific pattern extraction logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation
import CoreGraphics

/// Enhanced military payslip pattern extraction with spatial validation
/// Implements SOLID principles with single responsibility for pattern matching
final class MilitaryPatternExtractor {
    
    // MARK: - Properties
    
    private let dynamicPatternService: DynamicMilitaryPatternService
    
    /// Spatial analyzer for enhanced pattern validation
    private let spatialAnalyzer: SpatialAnalyzerProtocol?
    
    /// Section classifier for military payslip structure
    private let sectionClassifier: SpatialSectionClassifier?
    
    /// Validation service for military-specific rules
    private let validationService: MilitaryValidationService
    
    // MARK: - Initialization
    
    /// Initializes the military pattern extractor
    /// - Parameters:
    ///   - dynamicPatternService: Dynamic pattern service for military-specific patterns
    ///   - spatialAnalyzer: Optional spatial analyzer for enhanced validation
    ///   - sectionClassifier: Optional section classifier for structure awareness
    ///   - validationService: Military validation service
    init(
        dynamicPatternService: DynamicMilitaryPatternService = DynamicMilitaryPatternService(),
        spatialAnalyzer: SpatialAnalyzerProtocol? = nil,
        sectionClassifier: SpatialSectionClassifier? = nil,
        validationService: MilitaryValidationService = MilitaryValidationService()
    ) {
        self.dynamicPatternService = dynamicPatternService
        self.spatialAnalyzer = spatialAnalyzer
        self.sectionClassifier = sectionClassifier
        self.validationService = validationService
    }
    
    // MARK: - Public Interface
    
    /// Enhanced military financial data extraction with spatial validation
    /// Combines traditional pattern matching with spatial intelligence for better accuracy
    /// - Parameter structuredDocument: Document with positional elements
    /// - Returns: Dictionary mapping military pay component keys to values
    /// - Throws: MilitaryExtractionError for processing failures
    func extractFinancialDataWithSpatialValidation(
        from structuredDocument: StructuredDocument
    ) async throws -> [String: Double] {
        
        guard let firstPage = structuredDocument.pages.first else {
            throw MilitaryExtractionError.noElementsFound
        }
        
        let elements = firstPage.elements
        var extractedData: [String: Double] = [:]
        
        // Step 1: Use spatial analysis if available
        if let spatialAnalyzer = spatialAnalyzer, elements.count >= 4 {
            do {
                let spatialData = try await extractUsingSpatialAnalysis(
                    elements: elements,
                    analyzer: spatialAnalyzer
                )
                extractedData.merge(spatialData) { current, _ in current }
                print("[MilitaryPatternExtractor] Spatial extraction found \(spatialData.count) military components")
            } catch {
                print("[MilitaryPatternExtractor] Spatial extraction failed: \(error), falling back to patterns")
            }
        }
        
        // Step 2: Enhance with legacy pattern extraction
        let fallbackText = structuredDocument.originalText.values.joined(separator: " ")
        let legacyData = extractFinancialDataLegacy(from: fallbackText)
        
        // Merge legacy data, but don't overwrite spatial results
        for (key, value) in legacyData {
            if extractedData[key] == nil {
                extractedData[key] = value
            }
        }
        
        // Step 3: Apply military-specific validation
        extractedData = validationService.applyMilitaryValidation(to: extractedData)
        
        return extractedData
    }
    
    /// Enhanced military financial data extraction using dynamic patterns for all ranks
    /// Supports Level 10-16+ with configurable validation
    func extractFinancialDataLegacy(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Detect military level first for context-aware extraction
        let detectedLevel = dynamicPatternService.detectMilitaryLevel(from: text)
        print("[MilitaryPatternExtractor] Detected military level: \(detectedLevel ?? "unknown")")
        
        // Generate dynamic BPAY patterns for all military levels
        let bpayPatterns = dynamicPatternService.generateBPayPatterns()
        for pattern in bpayPatterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData["BasicPay"] = value
                print("[MilitaryPatternExtractor] Dynamic extracted BasicPay: ₹\(value)")
                
                // Validate the extracted basic pay
                let validation = dynamicPatternService.validateBasicPay(value, forLevel: detectedLevel)
                print("[MilitaryPatternExtractor] BasicPay validation: \(validation.message)")
                break // Stop after first successful extraction
            }
        }
        
        // Generate dynamic allowance patterns with pre-validation
        let allowancePatterns = dynamicPatternService.generateAllowancePatterns()
        for (componentKey, patterns) in allowancePatterns {
            for pattern in patterns {
                if let value = extractAmountWithPattern(pattern, from: text) {
                    // Pre-validate to prevent false positives (SINGLE SOURCE OF TRUTH)
                    let basicPay = extractedData["BasicPay"]
                    if dynamicPatternService.preValidateExtraction(componentKey, amount: value, basicPay: basicPay, level: detectedLevel) {
                        extractedData[componentKey] = value
                        print("[MilitaryPatternExtractor] Dynamic extracted \(componentKey): ₹\(value)")
                        
                        // Post-validate for detailed feedback
                        if let basicPay = basicPay {
                            let validation = dynamicPatternService.validateAllowance(componentKey, amount: value, basicPay: basicPay, level: detectedLevel)
                            print("[MilitaryPatternExtractor] \(componentKey) validation: \(validation.message)")
                        }
                    } else {
                        print("[MilitaryPatternExtractor] Pre-validation rejected \(componentKey): ₹\(value) (likely false positive)")
                    }
                    break
                }
            }
        }
        
        // Fallback to static patterns for components not covered by dynamic patterns
        let staticPatterns: [(key: String, regex: String)] = [
            // Arrears patterns
            ("ARR-CEA", "(?:ARR-CEA|ARREARS.*CEA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ARR-DA", "(?:ARR-DA|ARREARS.*DA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ARR-TPTADA", "(?:ARR-TPTADA|ARREARS.*TPTADA)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Military-specific deductions
            ("DSOP", "(?:DSOP|DSOP\\s+FUND)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("AGIF", "(?:AGIF|ARMY\\s+GROUP\\s+INSURANCE)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("AFPF", "(?:AFPF|AIR\\s+FORCE\\s+PROVIDENT\\s+FUND)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("EHCESS", "(?:EHCESS|EDUCATION\\s+HEALTH\\s+CESS)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("ITAX", "(?:ITAX|INCOME\\s+TAX|IT)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            
            // Totals with multilingual support
            ("credits", "(?:GROSS\\s+PAY|कुल\\s+आय|TOTAL\\s+EARNINGS)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)"),
            ("debits", "(?:TOTAL\\s+DEDUCTIONS|कुल\\s+कटौती|GROSS\\s+DEDUCTIONS)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR)?\\s*([0-9,.]+)")
        ]
        
        // Extract each value using the static patterns
        for (key, pattern) in staticPatterns {
            if extractedData[key] == nil { // Only extract if not already found by dynamic patterns
                if let value = extractAmountWithPattern(pattern, from: text) {
                    extractedData[key] = value
                    print("[MilitaryPatternExtractor] Static extracted \\(key): ₹\\(value)")
                }
            }
        }
        
        return extractedData
    }
    
    // MARK: - Private Implementation
    
    /// Extracts military financial data using spatial analysis
    private func extractUsingSpatialAnalysis(
        elements: [PositionalElement],
        analyzer: SpatialAnalyzerProtocol
    ) async throws -> [String: Double] {
        
        // Step 1: Find element pairs using spatial relationships
        let elementPairs = try await analyzer.findRelatedElements(elements, tolerance: nil)
        
        // Step 2: Filter for military-specific patterns
        var militaryData: [String: Double] = [:]
        
        for pair in elementPairs where pair.isHighConfidence {
            let labelText = pair.label.text.uppercased()
            let valueText = pair.value.text
            
            // Check if this is a military pay component
            if let militaryCode = validationService.identifyMilitaryComponent(from: labelText),
               let amount = validationService.extractFinancialAmount(from: valueText) {
                
                // Validate spatial relationship for military payslips
                if validationService.isValidMilitaryPair(label: pair.label, value: pair.value, code: militaryCode) {
                    militaryData[militaryCode] = amount
                    print("[MilitaryPatternExtractor] Spatial military pair: \(militaryCode) = \(amount)")
                }
            }
        }
        
        return militaryData
    }
    
    /// Helper function to extract numerical amount using regex pattern
    private func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                return Double(cleanValue)
            }
        } catch {
            print("[MilitaryPatternExtractor] Error with regex pattern \\(pattern): \\(error.localizedDescription)")
        }
        return nil
    }
}

// MARK: - Supporting Types

/// Error types for military extraction
enum MilitaryExtractionError: Error, LocalizedError {
    case noElementsFound
    case insufficientElements(count: Int)
    case spatialAnalysisFailure(String)
    case validationFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .noElementsFound:
            return "No positional elements found for military extraction"
        case .insufficientElements(let count):
            return "Insufficient elements for military spatial extraction: \(count)"
        case .spatialAnalysisFailure(let message):
            return "Military spatial analysis failed: \(message)"
        case .validationFailure(let message):
            return "Military validation failed: \(message)"
        }
    }
}
