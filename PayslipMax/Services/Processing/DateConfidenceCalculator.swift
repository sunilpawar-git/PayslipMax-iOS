//
//  DateConfidenceCalculator.swift
//  PayslipMax
//
//  Extracted from MilitaryDateExtractor for architectural compliance
//  Handles date confidence scoring and selection logic
//

import Foundation

/// Protocol for date confidence calculation following SOLID principles
protocol DateConfidenceCalculatorProtocol {
    func calculateConfidence(patternIndex: Int, position: Int, text: String, scope: String) -> Int
    func selectBestDate(from dates: [(month: String, year: Int, position: Int, confidence: Int)], text: String, scope: String) -> (month: String, year: Int)?
}

/// Service responsible for calculating date extraction confidence scores
/// Implements single responsibility principle for confidence calculation
class DateConfidenceCalculator: DateConfidenceCalculatorProtocol {

    /// Calculates confidence score for a date based on context and pattern
    func calculateConfidence(patternIndex: Int, position: Int, text: String, scope: String) -> Int {
        _ = 100 // baseConfidence reserved for future use

        // Pattern-based confidence (earlier patterns are more specific)
        let patternConfidence = max(50, 100 - (patternIndex * 5))

        // Position-based confidence (earlier positions usually contain headers)
        let positionConfidence: Int
        if position < 500 {
            positionConfidence = 100 // Very early in document
        } else if position < 1500 {
            positionConfidence = 80  // Early in document
        } else if position < 3000 {
            positionConfidence = 60  // Middle of document
        } else {
            positionConfidence = 40  // Later in document
        }

        // Context-based confidence (look for date-related keywords nearby)
        let contextConfidence = calculateContextConfidence(position: position, text: text)

        // First page bonus
        let firstPageBonus = scope == "FirstPage" ? 50 : 0

        // Calculate weighted average with first page bonus
        let weightedConfidence = (patternConfidence + positionConfidence + contextConfidence) / 3 + firstPageBonus

        if scope == "FirstPage" && firstPageBonus > 0 {
            print("[DateConfidenceCalculator] 🏆 First page date bonus: +\(firstPageBonus) confidence")
        }

        return min(200, max(20, weightedConfidence)) // Cap between 20-200
    }

    /// Calculates context-based confidence by looking for relevant keywords
    private func calculateContextConfidence(position: Int, text: String) -> Int {
        let contextRange = 200 // Look 200 characters before and after
        let startIndex = max(0, position - contextRange)
        let endIndex = min(text.count, position + contextRange)

        let contextStartIndex = text.index(text.startIndex, offsetBy: startIndex)
        let contextEndIndex = text.index(text.startIndex, offsetBy: endIndex)
        let contextText = String(text[contextStartIndex..<contextEndIndex]).uppercased()

        var confidence = 60 // Base context confidence

        // Positive indicators
        let positiveKeywords = [
            "STATEMENT", "PAYSLIP", "FOR THE MONTH", "PAY ACCOUNT",
            "SALARY", "PERIOD", "वेतन", "खाता", "ACCOUNT"
        ]

        for keyword in positiveKeywords {
            if contextText.contains(keyword) {
                confidence += 15
            }
        }

        // Negative indicators (suggests this might be transaction data, not statement period)
        let negativeKeywords = [
            "TRANSACTION", "CREDIT", "DEBIT", "BALANCE", "AMOUNT",
            "TRANSFER", "PAYMENT", "RECEIPT", "INVOICE"
        ]

        for keyword in negativeKeywords {
            if contextText.contains(keyword) {
                confidence -= 10
            }
        }

        return max(20, min(100, confidence))
    }

    /// Select the best date from all found dates using intelligent prioritization
    func selectBestDate(from dates: [(month: String, year: Int, position: Int, confidence: Int)], text: String, scope: String) -> (month: String, year: Int)? {
        guard !dates.isEmpty else {
            print("[DateConfidenceCalculator] No dates found in \(scope)")
            return nil
        }

        print("[DateConfidenceCalculator] Total \(scope) dates found: \(dates.count)")
        for date in dates.sorted(by: { $0.confidence > $1.confidence }) {
            print("[DateConfidenceCalculator] - \(date.month) \(date.year) at position \(date.position) (confidence: \(date.confidence))")
        }

        // Remove duplicates (same month/year combination) and keep highest confidence
        var uniqueDates: [(month: String, year: Int, position: Int, confidence: Int)] = []
        var seenMonthYears: Set<String> = []

        for date in dates.sorted(by: { $0.confidence > $1.confidence }) {
            let monthYearKey = "\(date.month)-\(date.year)"
            if !seenMonthYears.contains(monthYearKey) {
                uniqueDates.append(date)
                seenMonthYears.insert(monthYearKey)
            }
        }

        // Sort by confidence, then by position (earlier positions preferred for statement dates)
        let sortedDates = uniqueDates.sorted { (a, b) in
            if a.confidence != b.confidence {
                return a.confidence > b.confidence
            }
            return a.position < b.position  // Prefer EARLIER positions (document headers)
        }

        let selectedDate = sortedDates.first!
        print("[DateConfidenceCalculator] ✅ Selected \(scope) date: \(selectedDate.month) \(selectedDate.year) (confidence: \(selectedDate.confidence))")
        return (selectedDate.month, selectedDate.year)
    }
}
