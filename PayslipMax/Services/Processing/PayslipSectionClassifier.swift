//
//  PayslipSectionClassifier.swift
//  PayslipMax
//
//  Created for military payslip section classification logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Section types for payslip component classification
enum PayslipSection {
    case earnings
    case deductions
    case unknown
}

/// Service for classifying payslip components into appropriate sections
/// Implements intelligent context analysis for dual-section components like RH12
final class PayslipSectionClassifier {
    
    // MARK: - Public Interface
    
    /// Classifies RH12 component into earnings or deductions based on section context
    /// RH12 can appear in both sections in military payslips (e.g., May 2025: ₹21,125 earnings + ₹7,518 deductions)
    /// - Parameters:
    ///   - key: The extracted key containing RH12
    ///   - value: The extracted monetary value
    ///   - text: The full payslip text for context analysis
    /// - Returns: The section type (earnings, deductions, or unknown)
    func classifyRH12Section(key: String, value: Double, text: String) -> PayslipSection {
        // Strategy: Analyze surrounding text context to determine section
        let uppercaseText = text.uppercased()
        
        // Look for section indicators around the RH12 value
        let valueString = String(format: "%.0f", value)
        let commaFormattedValue = NumberFormatter().string(from: NSNumber(value: value)) ?? valueString
        
        // Find the position of this RH12 entry in the text
        let searchPatterns = [
            "RH12.*\(valueString)",
            "RH12.*\(commaFormattedValue)",
            "\(valueString).*RH12",
            "\(commaFormattedValue).*RH12"
        ]
        
        var matchPosition = -1
        for pattern in searchPatterns {
            if let range = uppercaseText.range(of: pattern, options: .regularExpression) {
                matchPosition = uppercaseText.distance(from: uppercaseText.startIndex, to: range.lowerBound)
                break
            }
        }
        
        guard matchPosition >= 0 else {
            print("[PayslipSectionClassifier] RH12 section classification: Could not locate RH12 \(valueString) in text, defaulting to earnings")
            return .earnings // Default fallback
        }
        
        // Analyze text segments before the match to determine section context
        let beforeMatch = String(uppercaseText.prefix(matchPosition + 500)) // Include some context after match
        let beforeMatchLast1000 = String(beforeMatch.suffix(1000)) // Look at last 1000 chars before match
        
        // Look for earnings section indicators
        let earningsIndicators = [
            "EARNINGS", "आय", "CREDIT", "जमा", "GROSS PAY", "TOTAL EARNINGS", "कुल आय"
        ]
        
        // Look for deductions section indicators  
        let deductionsIndicators = [
            "DEDUCTIONS", "कटौती", "DEBIT", "नामे", "TOTAL DEDUCTIONS", "कुल कटौती"
        ]
        
        // Find the most recent section header
        var lastEarningsPos = -1
        var lastDeductionsPos = -1
        
        for indicator in earningsIndicators {
            if let range = beforeMatchLast1000.range(of: indicator, options: .backwards) {
                let pos = beforeMatchLast1000.distance(from: beforeMatchLast1000.startIndex, to: range.lowerBound)
                lastEarningsPos = max(lastEarningsPos, pos)
            }
        }
        
        for indicator in deductionsIndicators {
            if let range = beforeMatchLast1000.range(of: indicator, options: .backwards) {
                let pos = beforeMatchLast1000.distance(from: beforeMatchLast1000.startIndex, to: range.lowerBound)
                lastDeductionsPos = max(lastDeductionsPos, pos)
            }
        }
        
        // Determine section based on most recent header
        if lastEarningsPos > lastDeductionsPos && lastEarningsPos >= 0 {
            print("[PayslipSectionClassifier] RH12 \(valueString) classified as EARNINGS (context: earnings header found)")
            return .earnings
        } else if lastDeductionsPos > lastEarningsPos && lastDeductionsPos >= 0 {
            print("[PayslipSectionClassifier] RH12 \(valueString) classified as DEDUCTIONS (context: deductions header found)")
            return .deductions
        } else {
            // Fallback: Use value-based heuristic (larger amounts typically earnings)
            // Based on May 2025 reference: ₹21,125 earnings vs ₹7,518 deductions
            if value > 15000 {
                print("[PayslipSectionClassifier] RH12 \(valueString) classified as EARNINGS (heuristic: large amount)")
                return .earnings
            } else {
                print("[PayslipSectionClassifier] RH12 \(valueString) classified as DEDUCTIONS (heuristic: smaller amount)")
                return .deductions
            }
        }
    }
    
    /// Classifies any dual-section component using similar logic
    /// Can be extended for other components that may appear in both earnings and deductions
    /// - Parameters:
    ///   - componentKey: The component key (e.g., "RH12", "MSP")
    ///   - value: The monetary value
    ///   - text: Full payslip text for context
    /// - Returns: The classified section type
    func classifyDualSectionComponent(componentKey: String, value: Double, text: String) -> PayslipSection {
        // Currently only RH12 is known to be dual-section, but this can be extended
        if componentKey.contains("RH12") {
            return classifyRH12Section(key: componentKey, value: value, text: text)
        }
        
        // Future: Add logic for other dual-section components as they're identified
        // For now, default to earnings for unknown components
        print("[PayslipSectionClassifier] Unknown dual-section component '\(componentKey)', defaulting to earnings")
        return .earnings
    }
}
