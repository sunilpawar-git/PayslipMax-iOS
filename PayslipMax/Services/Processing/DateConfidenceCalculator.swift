//
//  DateConfidenceCalculator.swift
//  PayslipMax
//
//  Created for military payslip date confidence calculation logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for date confidence calculation services
protocol DateConfidenceCalculatorProtocol {
    /// Calculate confidence score for a date match based on context and pattern type
    func calculateConfidence(patternIndex: Int, position: Int, text: String, scope: String) -> Int
}

/// Service responsible for calculating confidence scores for extracted dates
/// Implements intelligent scoring based on pattern type, position, and context keywords
final class DateConfidenceCalculator: DateConfidenceCalculatorProtocol {

    /// Calculate confidence score for a date match based on context and pattern type
    func calculateConfidence(patternIndex: Int, position: Int, text: String, scope: String) -> Int {
        var confidence = 50 // Base confidence

        // Higher confidence for more specific patterns
        confidence += getPatternConfidenceBonus(patternIndex)

        // Boost confidence for dates appearing in document headers (early positions)
        confidence += getPositionConfidenceBonus(position)

        // Check for context keywords near the date
        confidence += getContextConfidenceBonus(position: position, text: text)

        // 🎯 BOOST confidence significantly for first page dates
        if scope == "FirstPage" {
            confidence += 50 // Major boost for first page dates
            print("[DateConfidenceCalculator] 🏆 First page date bonus: +50 confidence")
        }

        return min(confidence, 100) // Cap at 100
    }

    /// Get confidence bonus based on pattern type
    private func getPatternConfidenceBonus(_ patternIndex: Int) -> Int {
        switch patternIndex {
        case 0...3: return 30  // Text month with context prefixes
        case 4...7: return 20  // Numeric month with context prefixes
        case 8...9: return 25  // Abbreviated month with context
        case 10...12: return 10 // Generic patterns
        case 13...14: return 40 // Hindi/English mixed (very specific to Indian payslips)
        default: return 5
        }
    }

    /// Get confidence bonus based on position in document
    private func getPositionConfidenceBonus(_ position: Int) -> Int {
        // Boost confidence for dates appearing in document headers (early positions)
        if position < 1000 {
            return 20
        }
        return 0
    }

    /// Get confidence bonus based on context keywords near the date
    private func getContextConfidenceBonus(position: Int, text: String) -> Int {
        let contextRange = max(0, position - 100)..<min(text.count, position + 100)
        let contextText = String(text[text.index(text.startIndex, offsetBy: contextRange.lowerBound)..<text.index(text.startIndex, offsetBy: contextRange.upperBound)]).uppercased()

        var bonus = 0

        if contextText.contains("STATEMENT") || contextText.contains("ACCOUNT") {
            bonus += 25
        }
        if contextText.contains("PAYSLIP") || contextText.contains("PAY SLIP") {
            bonus += 20
        }
        if contextText.contains("MONTH") || contextText.contains("FOR") {
            bonus += 15
        }

        return bonus
    }
}
