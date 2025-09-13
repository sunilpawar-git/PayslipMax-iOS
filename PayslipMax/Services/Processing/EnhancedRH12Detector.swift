//
//  EnhancedRH12Detector.swift
//  PayslipMax
//
//  Created for Phase 4: Enhanced dual-section RH12 detection
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Enhanced RH12 detection service for dual-section component identification
/// Addresses Phase 4 requirement to find both earnings and deductions RH12 instances
final class EnhancedRH12Detector {

    // MARK: - Public Interface

    /// Detects all RH12 instances in the payslip text using enhanced pattern matching
    /// This addresses Phase 4 requirement to find both earnings and deductions RH12 instances
    /// - Parameter text: The payslip text to search
    /// - Returns: Array of tuples containing (value, context) for each RH12 instance found
    func detectAllRH12Instances(in text: String) -> [(value: Double, context: String)] {
        var instances: [(value: Double, context: String)] = []
        var foundValues: Set<Double> = []

        // Enhanced RH12 detection patterns - more comprehensive than single legacy pattern
        let rhPatterns = [
            "RH12[\\s]*:?[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "RH12[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "RH12[\\s]+([0-9,]+(?:\\.[0-9]+)?)",
            "Risk[\\s]+Hardship[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",  // More specific Risk Hardship pattern
            "Risk.*Hardship.*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "R\\s*H\\s*1\\s*2.*?₹?([0-9,]+(?:\\.[0-9]+)?)"
        ]

        for pattern in rhPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let nsText = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

                for result in results {
                    if result.numberOfRanges > 1 {
                        let amountRange = result.range(at: 1)
                        if amountRange.location != NSNotFound {
                            // Check for invalid characters immediately before the number
                            let precedingCharIndex = amountRange.location - 1
                            var hasInvalidPrecedingChar = false
                            if precedingCharIndex >= 0 && precedingCharIndex < nsText.length {
                                let precedingChar = nsText.character(at: precedingCharIndex)
                                if precedingChar == 45 { // ASCII for '-'
                                    hasInvalidPrecedingChar = true
                                }
                            }
                            
                            if !hasInvalidPrecedingChar {
                                let amountString = nsText.substring(with: amountRange)
                                if let value = parseAmount(amountString), isValidAmount(value) {
                                    // Use exact match for duplicate detection (no tolerance for different values)
                                    if !foundValues.contains(value) {
                                        foundValues.insert(value)
                                        
                                        // Extract context around the match (800 chars window to ensure section headers)
                                        let contextStart = max(0, result.range.location - 400)
                                        let contextLength = min(800, nsText.length - contextStart)
                                        let contextRange = NSRange(location: contextStart, length: contextLength)
                                        let context = nsText.substring(with: contextRange)

                                        instances.append((value: value, context: context))
                                        print("[EnhancedRH12Detector] Enhanced RH12 pattern found: ₹\(value)")
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("[EnhancedRH12Detector] RH12 pattern error: \(error)")
            }
        }

        print("[EnhancedRH12Detector] Enhanced RH12 detection found \(instances.count) instances")
        return instances
    }

    // MARK: - Private Helper Methods

    /// Parses amount string to double value (helper for RH12 detection)
    private func parseAmount(_ amountString: String) -> Double? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanAmount)
    }
    
    /// Validates if the detected amount is reasonable for RH12 component
    /// Filters out invalid amounts like 0, negative values, or unrealistic amounts
    private func isValidAmount(_ value: Double) -> Bool {
        // RH12 amounts should be positive and within reasonable military allowance range
        // Based on analysis: RH12 typically ranges from ₹500 to ₹50,000
        return value > 0 && value >= 500 && value <= 50000
    }
}
