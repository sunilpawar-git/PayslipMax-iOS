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
        
        // Enhanced RH12 detection patterns - more comprehensive than single legacy pattern
        let rhPatterns = [
            "RH12[\\s]*:?[\\s]*₹?([0-9,]+)",
            "RH12[\\s]*₹?([0-9,]+)",
            "RH12[\\s]+([0-9,]+)",
            "Risk.*Hardship.*₹?([0-9,]+)",
            "R\\s*H\\s*1\\s*2.*?₹?([0-9,]+)"
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
                            let amountString = nsText.substring(with: amountRange)
                            if let value = parseAmount(amountString) {
                                // Extract context around the match (400 chars window)
                                let contextStart = max(0, result.range.location - 200)
                                let contextLength = min(400, nsText.length - contextStart)
                                let contextRange = NSRange(location: contextStart, length: contextLength)
                                let context = nsText.substring(with: contextRange)
                                
                                // Avoid duplicates by checking if this value is already detected
                                if !instances.contains(where: { abs($0.value - value) < 0.01 }) {
                                    instances.append((value: value, context: context))
                                    print("[EnhancedRH12Detector] Enhanced RH12 pattern found: ₹\(value)")
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
}
