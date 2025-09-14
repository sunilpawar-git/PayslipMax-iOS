//
//  DateSelectionService.swift
//  PayslipMax
//
//  Created for military payslip date selection and deduplication logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for date selection services
protocol DateSelectionServiceProtocol {
    /// Select the best date from all found dates using intelligent prioritization
    func selectBestDate(from dates: [(month: String, year: Int, position: Int, confidence: Int)], text: String, scope: String) -> (month: String, year: Int)?

    /// Remove duplicates (same month/year combination) and keep highest confidence
    func deduplicateDates(_ dates: [(month: String, year: Int, position: Int, confidence: Int)]) -> [(month: String, year: Int, position: Int, confidence: Int)]

    /// Sort dates by confidence and position for optimal selection
    func sortDatesByPriority(_ dates: [(month: String, year: Int, position: Int, confidence: Int)]) -> [(month: String, year: Int, position: Int, confidence: Int)]
}

/// Service responsible for selecting the best date from extracted date candidates
/// Implements intelligent prioritization based on confidence scores and document context
final class DateSelectionService: DateSelectionServiceProtocol {

    /// Select the best date from all found dates using intelligent prioritization
    func selectBestDate(from dates: [(month: String, year: Int, position: Int, confidence: Int)], text: String, scope: String) -> (month: String, year: Int)? {
        guard !dates.isEmpty else {
            print("[DateSelectionService] No dates found in \(scope)")
            return nil
        }

        print("[DateSelectionService] Total \(scope) dates found: \(dates.count)")
        for date in dates.sorted(by: { $0.confidence > $1.confidence }) {
            print("[DateSelectionService] - \(date.month) \(date.year) at position \(date.position) (confidence: \(date.confidence))")
        }

        // Remove duplicates and keep highest confidence
        let uniqueDates = deduplicateDates(dates)

        // Sort by confidence, then by position (earlier positions preferred for statement dates)
        let sortedDates = sortDatesByPriority(uniqueDates)

        let selectedDate = sortedDates.first!
        print("[DateSelectionService] ✅ Selected \(scope) date: \(selectedDate.month) \(selectedDate.year) (confidence: \(selectedDate.confidence))")
        return (selectedDate.month, selectedDate.year)
    }

    /// Remove duplicates (same month/year combination) and keep highest confidence
    func deduplicateDates(_ dates: [(month: String, year: Int, position: Int, confidence: Int)]) -> [(month: String, year: Int, position: Int, confidence: Int)] {
        var uniqueDates: [(month: String, year: Int, position: Int, confidence: Int)] = []
        var seenMonthYears: Set<String> = []

        for date in dates.sorted(by: { $0.confidence > $1.confidence }) {
            let monthYearKey = "\(date.month)-\(date.year)"
            if !seenMonthYears.contains(monthYearKey) {
                uniqueDates.append(date)
                seenMonthYears.insert(monthYearKey)
            }
        }

        return uniqueDates
    }

    /// Sort dates by confidence and position for optimal selection
    func sortDatesByPriority(_ dates: [(month: String, year: Int, position: Int, confidence: Int)]) -> [(month: String, year: Int, position: Int, confidence: Int)] {
        return dates.sorted { (a, b) in
            if a.confidence != b.confidence {
                return a.confidence > b.confidence
            }
            return a.position < b.position  // Prefer EARLIER positions (document headers)
        }
    }
}
