//
//  QuizUtilities.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Implementation of utility functions for quiz generation
final class QuizUtility: QuizUtilityProtocol {
    // MARK: - QuizUtilityProtocol Implementation

    /// Formats currency amount for quiz options
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string
    func formatCurrencyForOptions(_ amount: Double) -> String {
        if amount >= 100000 {
            return "₹\((amount/100000).formatted(.number.precision(.fractionLength(1))))L"
        } else if amount >= 1000 {
            return "₹\((amount/1000).formatted(.number.precision(.fractionLength(1))))K"
        } else {
            return "₹\(amount.formatted(.number.precision(.fractionLength(0))))"
        }
    }

    /// Generates plausible wrong options for currency amounts
    /// - Parameter correct: The correct amount
    /// - Returns: Array of formatted wrong options
    func generateWrongCurrencyOptions(correct: Double) -> [String] {
        let variations = [
            correct * 0.8,  // 20% less
            correct * 1.2,  // 20% more
            correct * 0.9   // 10% less
        ]

        return variations.map { formatCurrencyForOptions($0) }
    }

    /// Determines if a question difficulty should be included
    /// - Parameters:
    ///   - requested: The requested difficulty filter (nil means all difficulties)
    ///   - questionDifficulty: The difficulty of the question
    /// - Returns: True if the question should be included
    func shouldIncludeDifficulty(_ requested: QuizDifficulty?, _ questionDifficulty: QuizDifficulty) -> Bool {
        guard let requested = requested else { return true }
        return requested == questionDifficulty
    }

    /// Determines chronologically correct comparison order for date-based questions
    /// - Parameters:
    ///   - latest: Tuple of (month, net) for latest payslip
    ///   - previous: Tuple of (month, net) for previous payslip
    /// - Returns: Tuple of (fromMonth, toMonth, fromNet, toNet, difference)
    func chronologicalComparison(
        latest: (month: String, net: Double),
        previous: (month: String, net: Double)
    ) -> (String, String, Double, Double, Double) {
        // Extract month and year from strings like "October 2024"
        func parseMonthYear(_ monthYear: String) -> (month: Int, year: Int)? {
            let components = monthYear.components(separatedBy: " ")
            guard components.count == 2,
                  let year = Int(components[1]) else { return nil }

            let monthNames = ["January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"]

            guard let monthIndex = monthNames.firstIndex(of: components[0]) else { return nil }
            return (month: monthIndex + 1, year: year)
        }

        guard let latestDate = parseMonthYear(latest.month),
              let previousDate = parseMonthYear(previous.month) else {
            // Fallback: assume previous is actually earlier
            return (previous.month, latest.month, previous.net, latest.net, latest.net - previous.net)
        }

        // Compare dates
        if latestDate.year > previousDate.year ||
           (latestDate.year == previousDate.year && latestDate.month > previousDate.month) {
            // Latest is actually later chronologically
            return (previous.month, latest.month, previous.net, latest.net, latest.net - previous.net)
        } else {
            // Previous is actually later chronologically
            return (latest.month, previous.month, latest.net, previous.net, previous.net - latest.net)
        }
    }
}

/// Additional utility functions for quiz generation
extension QuizUtility {
    /// Formats currency amount using NumberFormatter
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    /// Generates income options for quiz questions
    /// - Parameter correctAnswer: The correct income amount
    /// - Returns: Array of formatted income options
    func generateIncomeOptions(correctAnswer: Double) -> [String] {
        let correct = "Rs. \(formatCurrency(correctAnswer))"
        let variations = [
            "Rs. \(formatCurrency(correctAnswer * 0.8))",
            "Rs. \(formatCurrency(correctAnswer * 1.2))",
            "Rs. \(formatCurrency(correctAnswer * 0.95))"
        ]
        return ([correct] + variations).shuffled()
    }

    /// Generates deduction options for quiz questions
    /// - Parameter correctAnswer: The correct deduction amount
    /// - Returns: Array of formatted deduction options
    func generateDeductionOptions(correctAnswer: Double) -> [String] {
        let correct = "Rs. \(formatCurrency(correctAnswer))"
        let variations = [
            "Rs. \(formatCurrency(correctAnswer * 0.7))",
            "Rs. \(formatCurrency(correctAnswer * 1.3))",
            "Rs. \(formatCurrency(correctAnswer * 0.9))"
        ]
        return ([correct] + variations).shuffled()
    }

    /// Generates account digit options for quiz questions
    /// - Parameter correctAnswer: The correct last four digits
    /// - Returns: Array of account digit options
    func generateAccountDigitOptions(correctAnswer: String) -> [String] {
        let incorrectOptions = ["1234", "5678", "9876", "4321"].filter { $0 != correctAnswer }
        return ([correctAnswer] + Array(incorrectOptions.prefix(3))).shuffled()
    }
}
