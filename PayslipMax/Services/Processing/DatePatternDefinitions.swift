//
//  DatePatternDefinitions.swift
//  PayslipMax
//
//  Created for military payslip date pattern definitions
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for date pattern definitions
protocol DatePatternDefinitionsProtocol {
    /// Comprehensive military payslip date patterns - future-proof for all years and formats
    var militaryDatePatterns: [String] { get }

    /// Get pattern category description for a given pattern index
    func getPatternCategory(for index: Int) -> String

    /// Get confidence base score for a pattern type
    func getConfidenceBaseScore(for index: Int) -> Int
}

/// Service responsible for managing comprehensive date pattern definitions
/// Implements SOLID principles with single responsibility for pattern management
final class DatePatternDefinitions: DatePatternDefinitionsProtocol {

    /// Comprehensive military payslip date patterns - future-proof for all years and formats
    let militaryDatePatterns: [String] = [
        // 1. Standard text month patterns with various prefixes
        "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",
        "(?:STATEMENT\\s+(?:OF\\s+ACCOUNT\\s+)?FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",
        "(?:PAY\\s+(?:ACCOUNT\\s+)?FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",
        "(?:PAYSLIP\\s+FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",

        // 2. Numeric month patterns (MM/YYYY, MM-YYYY, MM.YYYY) - ONLY valid months 01-12
        "(?:STATEMENT\\s+(?:OF\\s+ACCOUNT\\s+)?FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
        "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
        "(?:PAY\\s+(?:ACCOUNT\\s+)?FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",
        "(?:PAYSLIP\\s+FOR\\s+)?([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",

        // 3. Abbreviated month patterns (JAN, FEB, MAR, etc.)
        "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",
        "(?:STATEMENT\\s+(?:OF\\s+ACCOUNT\\s+)?FOR\\s+)?(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",

        // 4. Generic patterns to catch any month-year combination
        "(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s*[,-]?\\s*(20[0-9]{2})",
        "(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\\s*[,-]?\\s*(20[0-9]{2})",
        "([0-1]?[0-9])[/\\-\\.]\\s*(20[0-9]{2})",

        // 5. Hindi/English mixed patterns (common in Indian payslips)
        "([0-9]{1,2})[/\\-\\.]([0-9]{4})\\s*(?:की\\s+लेखा\\s+विवरणी|STATEMENT)",
        "(?:लेखा\\s+विवरणी|STATEMENT).*?([0-9]{1,2})[/\\-\\.]([0-9]{4})"
    ]

    /// Get pattern category description for a given pattern index
    func getPatternCategory(for index: Int) -> String {
        switch index {
        case 0...3: return "Text month with context prefixes"
        case 4...7: return "Numeric month with context prefixes"
        case 8...9: return "Abbreviated month with context"
        case 10...12: return "Generic patterns"
        case 13...14: return "Hindi/English mixed"
        default: return "Unknown pattern type"
        }
    }

    /// Get confidence base score for a pattern type
    func getConfidenceBaseScore(for index: Int) -> Int {
        switch index {
        case 0...3: return 30  // Text month with context prefixes - highest confidence
        case 4...7: return 20  // Numeric month with context prefixes
        case 8...9: return 25  // Abbreviated month with context
        case 10...12: return 10 // Generic patterns
        case 13...14: return 40 // Hindi/English mixed - very specific to Indian payslips
        default: return 5
        }
    }
}
