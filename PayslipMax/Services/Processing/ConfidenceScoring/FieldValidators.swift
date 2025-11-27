//
//  FieldValidators.swift
//  PayslipMax
//
//  Shared validation logic for confidence calculations
//  Eliminates duplication across LLM, Universal, and Simplified calculators
//

import Foundation

/// Shared validation utilities for confidence calculations
/// Provides consistent validation logic across all calculator types
final class FieldValidators {

    // MARK: - Month Validation

    /// Calculate confidence for a month field
    /// - Parameter month: The month string to validate
    /// - Returns: Confidence score (0.0-1.0)
    static func monthConfidence(_ month: String) -> Double {
        guard !month.isEmpty else {
            return 0.0
        }

        // "Unknown" is a recognized placeholder
        if month == "Unknown" {
            return 0.1
        }

        let normalizedMonth = month.trimmingCharacters(in: .whitespaces).uppercased()

        // Perfect match: full month name
        if validMonths.contains(normalizedMonth) {
            return 1.0
        }

        // Good match: abbreviated month name
        if validMonthAbbreviations.contains(normalizedMonth) {
            return 0.95
        }

        // Partial match: at least 3 characters
        if normalizedMonth.count >= 3 {
            return 0.7
        }

        // Weak confidence: has value but unrecognized
        return 0.3
    }

    // MARK: - Year Validation

    /// Calculate confidence for a year field
    /// - Parameter year: The year to validate
    /// - Returns: Confidence score (0.0-1.0)
    static func yearConfidence(_ year: Int) -> Double {
        let currentYear = Calendar.current.component(.year, from: Date())
        let maxYear = currentYear + ConfidenceThresholds.maximumYearOffset

        // Valid range: 2015 to 3 years in future
        if year >= ConfidenceThresholds.minimumYear && year <= maxYear {
            return 1.0
        }

        // Suspicious but possible: 2000 to 10 years in future
        if year >= 2000 && year <= (currentYear + 10) {
            return 0.7
        }

        // Likely incorrect
        return 0.2
    }

    // MARK: - Amount Validation

    /// Calculate confidence for an amount field
    /// - Parameters:
    ///   - amount: The amount to validate
    ///   - fieldName: The name of the field (affects interpretation of zero values)
    ///   - isCritical: Whether this is a critical field (net, gross, basic pay)
    /// - Returns: Confidence score (0.0-1.0)
    static func amountConfidence(_ amount: Double, fieldName: String = "", isCritical: Bool = false) -> Double {
        // Zero handling
        if amount == 0.0 {
            return isCritical ? 0.2 : 0.6
        }

        // Negative amounts are suspicious
        if amount < 0 {
            return 0.3
        }

        // Reasonable range for Indian payslips (up to 1 crore)
        if amount > 0 && amount < ConfidenceThresholds.maximumReasonableAmount {
            return 1.0
        }

        // Very high but possible
        if amount >= ConfidenceThresholds.maximumReasonableAmount {
            return 0.8
        }

        return 0.5
    }

    // MARK: - Dictionary Validation

    /// Calculate confidence for dictionary fields (earnings/deductions)
    /// - Parameters:
    ///   - dict: The dictionary to validate
    ///   - allowEmpty: Whether empty dictionaries are acceptable
    /// - Returns: Confidence score (0.0-1.0)
    static func dictionaryConfidence(_ dict: [String: Double], allowEmpty: Bool = false) -> Double {
        // Empty dictionary
        if dict.isEmpty {
            return allowEmpty ? 0.8 : 0.2
        }

        let values = dict.values
        let nonZeroCount = values.filter { $0 > 0 }.count
        let totalCount = values.count

        // All zeros is suspicious
        if nonZeroCount == 0 {
            return 0.3
        }

        // Calculate ratio of non-zero values
        let nonZeroRatio = Double(nonZeroCount) / Double(totalCount)

        // High ratio = high confidence
        if nonZeroRatio >= 0.8 {
            return 1.0
        } else if nonZeroRatio >= 0.5 {
            return 0.8
        } else if nonZeroRatio >= 0.3 {
            return 0.6
        }

        return 0.4
    }

    // MARK: - Totals Validation

    /// Calculate confidence based on totals consistency
    /// Verifies the equation: Gross - Deductions = Net
    /// - Parameters:
    ///   - gross: Gross pay amount
    ///   - deductions: Total deductions amount
    ///   - net: Net remittance amount
    /// - Returns: Confidence score (0.0-1.0)
    static func totalsConsistencyConfidence(gross: Double, deductions: Double, net: Double) -> Double {
        guard gross > 0 && deductions >= 0 && net > 0 else {
            return 0.0
        }

        let calculatedNet = gross - deductions
        let difference = abs(net - calculatedNet)
        let percentDifference = difference / max(net, calculatedNet)

        if percentDifference <= ConfidenceThresholds.perfectMatchTolerance {
            return 1.0 // Perfect match (±1%)
        } else if percentDifference <= ConfidenceThresholds.goodMatchTolerance {
            return 0.8 // Good match (±5%)
        } else if percentDifference <= ConfidenceThresholds.acceptableMatchTolerance {
            return 0.4 // Acceptable match (±10%)
        }

        return 0.0 // Poor match (>10%)
    }

    // MARK: - Constants

    private static let validMonths: Set<String> = [
        "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ]

    private static let validMonthAbbreviations: Set<String> = [
        "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
        "JUL", "AUG", "SEP", "SEPT", "OCT", "NOV", "DEC"
    ]
}
