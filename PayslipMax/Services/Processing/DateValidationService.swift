//
//  DateValidationService.swift
//  PayslipMax
//
//  Created for military payslip date validation logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for date validation services
protocol DateValidationServiceProtocol {
    /// Validates that a month string is a valid month (1-12 or valid month name)
    func isValidMonth(_ monthStr: String) -> Bool

    /// Validates that a date is reasonable for a payslip (not too far in future/past)
    func isReasonableDate(month: String, year: Int) -> Bool
}

/// Service responsible for validating extracted dates from military payslips
/// Implements SOLID principles with single responsibility for date validation
final class DateValidationService: DateValidationServiceProtocol {

    /// Validates that a month string is a valid month (1-12 or valid month name)
    func isValidMonth(_ monthStr: String) -> Bool {
        let validMonthNames = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                              "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

        print("[DateValidationService] 🔍 Validating month: '\(monthStr)'")

        // Check if it's a valid month name
        if validMonthNames.contains(monthStr.uppercased()) {
            print("[DateValidationService] ✅ Valid month name: \(monthStr)")
            return true
        }

        // Check if it's a valid numeric month (1-12)
        if let monthNum = Int(monthStr), monthNum >= 1 && monthNum <= 12 {
            print("[DateValidationService] ✅ Valid numeric month: \(monthStr) (\(monthNum))")
            return true
        } else if let monthNum = Int(monthStr) {
            print("[DateValidationService] ❌ Invalid numeric month: \(monthStr) (\(monthNum)) - out of range 1-12")
            return false
        }

        // Check if it's a valid abbreviated month
        let validAbbreviations = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                 "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
        if validAbbreviations.contains(monthStr.uppercased()) {
            print("[DateValidationService] ✅ Valid abbreviated month: \(monthStr)")
            return true
        }

        print("[DateValidationService] ❌ Invalid month: '\(monthStr)' - not recognized")
        return false
    }

    /// Validates that a date is reasonable for a payslip (not too far in future/past)
    func isReasonableDate(month: String, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)

        // Allow dates from 2 years ago to 1 year in the future
        let minYear = currentYear - 2
        let maxYear = currentYear + 1

        if year < minYear || year > maxYear {
            print("[DateValidationService] ❌ Unreasonable year: \(year) (valid range: \(minYear)-\(maxYear))")
            return false
        }

        return true
    }
}
