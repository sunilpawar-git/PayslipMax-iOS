//
//  DatePatternService.swift
//  PayslipMax
//
//  Extracted from MilitaryDateExtractor for architectural compliance
//  Handles date patterns, validation, and conversion logic
//

import Foundation

/// Protocol for date pattern services following SOLID principles
protocol DatePatternServiceProtocol {
    func getDatePatterns() -> [String]
    func convertToMonthName(_ input: String) -> String
    func isValidMonth(_ monthStr: String) -> Bool
    func isReasonableDate(month: String, year: Int) -> Bool
}

/// Service responsible for date pattern matching and validation
/// Implements single responsibility principle for date pattern operations
class DatePatternService: DatePatternServiceProtocol {

    /// Returns comprehensive military payslip date patterns
    /// Future-proof for all years and formats
    func getDatePatterns() -> [String] {
        return [
            // 1. Standard text month patterns with various prefixes
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})",
            "(?:STATEMENT\\s+(?:OF\\s+ACCOUNT\\s+)?FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})",
            "(?:PAY\\s+(?:ACCOUNT\\s+)?FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})",
            "(?:PAYSLIP\\s+FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})",

            // 2. Numeric month patterns (MM/YYYY, MM-YYYY, MM.YYYY) - ONLY valid months 01-12
            "(?:STATEMENT\\s+(?:OF\\s+ACCOUNT\\s+)?FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
            "(?:PAY\\s+(?:ACCOUNT\\s+)?FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
            "(?:PAYSLIP\\s+FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",

            // 3. Abbreviated month patterns
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",
            "(?:STATEMENT\\s+FOR\\s+)?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",
            "(?:PAY\\s+ACCOUNT\\s+FOR\\s+)?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",

            // 4. Generic patterns to catch any month-year combination
            "(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",
            "(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",
            "([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",

            // 5. Hindi month patterns (supporting multilingual payslips)
            "(जनवरी|फरवरी|मार्च|अप्रैल|मई|जून|जुलाई|अगस्त|सितंबर|अक्टूबर|नवंबर|दिसंबर)\\s*(20[0-9]{2})",

            // 6. Legacy and special patterns
            "(?:वेतन\\s+के\\s+लिए\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})",
            "(?:SALARY\\s+FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+(20[0-9]{2})"
        ]
    }

    /// Converts numeric month (01-12) to month name, or returns the input if already a month name
    func convertToMonthName(_ input: String) -> String {
        let upperInput = input.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Direct numeric month mapping
        let numericMonthMapping = [
            "01": "JANUARY", "02": "FEBRUARY", "03": "MARCH", "04": "APRIL",
            "05": "MAY", "06": "JUNE", "07": "JULY", "08": "AUGUST",
            "09": "SEPTEMBER", "10": "OCTOBER", "11": "NOVEMBER", "12": "DECEMBER",
            "1": "JANUARY", "2": "FEBRUARY", "3": "MARCH", "4": "APRIL",
            "5": "MAY", "6": "JUNE", "7": "JULY", "8": "AUGUST",
            "9": "SEPTEMBER"
        ]

        if let monthName = numericMonthMapping[upperInput] {
            return monthName
        }

        // Abbreviated month mapping
        let abbreviatedMonthMapping = [
            "JAN": "JANUARY", "FEB": "FEBRUARY", "MAR": "MARCH", "APR": "APRIL",
            "MAY": "MAY", "JUN": "JUNE", "JUL": "JULY", "AUG": "AUGUST",
            "SEP": "SEPTEMBER", "SEPT": "SEPTEMBER", "OCT": "OCTOBER",
            "NOV": "NOVEMBER", "DEC": "DECEMBER"
        ]

        if let monthName = abbreviatedMonthMapping[upperInput] {
            return monthName
        }

        // Full month names (already converted to uppercase)
        let fullMonthNames = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                             "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

        if fullMonthNames.contains(upperInput) {
            return upperInput
        }

        // Partial month name matching (for cases like "JANU" -> "JANUARY")
        for monthName in fullMonthNames {
            if monthName.hasPrefix(upperInput) && upperInput.count >= 3 {
                return monthName
            }
        }

        return upperInput // Return as-is if no conversion found
    }

    /// Validates that a month string is a valid month (1-12 or valid month name)
    func isValidMonth(_ monthStr: String) -> Bool {
        print("[DatePatternService] 🔍 Validating month: '\(monthStr)'")

        let validMonthNames = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                              "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

        // Check if it's a valid month name
        if validMonthNames.contains(monthStr.uppercased()) {
            print("[DatePatternService] ✅ Valid month name: \(monthStr)")
            return true
        }

        // Check if it's a valid numeric month (1-12)
        if let monthNum = Int(monthStr), monthNum >= 1 && monthNum <= 12 {
            print("[DatePatternService] ✅ Valid numeric month: \(monthStr) (\(monthNum))")
            return true
        }

        // Check if it's a valid abbreviated month
        let validAbbreviations = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                 "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]

        if validAbbreviations.contains(monthStr.uppercased()) {
            print("[DatePatternService] ✅ Valid abbreviated month: \(monthStr)")
            return true
        }

        if let monthNum = Int(monthStr) {
            print("[DatePatternService] ❌ Invalid numeric month: \(monthStr) (\(monthNum)) - out of range 1-12")
        }

        print("[DatePatternService] ❌ Invalid month: '\(monthStr)' - not recognized")
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
            print("[DatePatternService] ❌ Unreasonable year: \(year) (valid range: \(minYear)-\(maxYear))")
            return false
        }

        print("[DatePatternService] ✅ Reasonable date: \(month) \(year)")
        return true
    }
}
