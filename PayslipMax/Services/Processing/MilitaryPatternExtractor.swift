//
//  MilitaryPatternExtractor.swift
//  PayslipMax
//
//  Created for military-specific pattern extraction logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service responsible for military payslip pattern extraction
/// Implements SOLID principles with single responsibility for pattern matching
class MilitaryPatternExtractor {
    
    private let dynamicPatternService: DynamicMilitaryPatternService
    
    init(dynamicPatternService: DynamicMilitaryPatternService = DynamicMilitaryPatternService()) {
        self.dynamicPatternService = dynamicPatternService
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
