//
//  DateProcessingUtilities.swift
//  PayslipMax
//
//  Created for military payslip date processing utilities
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for date processing utilities
protocol DateProcessingUtilitiesProtocol {
    /// Converts numeric month (01-12) or abbreviated month to full month name
    func convertToMonthName(_ input: String) -> String

    /// Extracts first page content (header and main payslip details)
    func getFirstPageText(from text: String) -> String
}

/// Service responsible for date processing utilities in military payslips
/// Implements SOLID principles with single responsibility for date processing operations
final class DateProcessingUtilities: DateProcessingUtilitiesProtocol {

    /// Converts numeric month (01-12) or abbreviated month to full month name
    func convertToMonthName(_ input: String) -> String {
        let numericMonthMapping = [
            "01": "JANUARY", "02": "FEBRUARY", "03": "MARCH", "04": "APRIL",
            "05": "MAY", "06": "JUNE", "07": "JULY", "08": "AUGUST",
            "09": "SEPTEMBER", "10": "OCTOBER", "11": "NOVEMBER", "12": "DECEMBER",
            "1": "JANUARY", "2": "FEBRUARY", "3": "MARCH", "4": "APRIL",
            "5": "MAY", "6": "JUNE", "7": "JULY", "8": "AUGUST",
            "9": "SEPTEMBER"
        ]

        let abbreviatedMonthMapping = [
            "JAN": "JANUARY", "FEB": "FEBRUARY", "MAR": "MARCH", "APR": "APRIL",
            "MAY": "MAY", "JUN": "JUNE", "JUL": "JULY", "AUG": "AUGUST",
            "SEP": "SEPTEMBER", "OCT": "OCTOBER", "NOV": "NOVEMBER", "DEC": "DECEMBER"
        ]

        let upperInput = input.uppercased()

        // Check numeric mapping first
        if let monthName = numericMonthMapping[input] {
            return monthName
        }

        // Check abbreviated mapping
        if let monthName = abbreviatedMonthMapping[upperInput] {
            return monthName
        }

        // Check if it's already a full month name
        let fullMonths = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                         "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
        if fullMonths.contains(upperInput) {
            return upperInput
        }

        // Try to match partial month names (e.g., "JANU" -> "JANUARY")
        for fullMonth in fullMonths {
            if fullMonth.hasPrefix(upperInput) && upperInput.count >= 3 {
                return fullMonth
            }
        }

        return upperInput // Return as-is if no conversion found
    }

    /// Extracts first page content (header and main payslip details)
    func getFirstPageText(from text: String) -> String {
        // Most payslip headers and primary date info appear in first 2000 characters
        // This covers: document header, payslip period, employee info, main summary
        let firstPageLength = min(2000, text.count)
        let firstPageEndIndex = text.index(text.startIndex, offsetBy: firstPageLength)
        let firstPageText = String(text[text.startIndex..<firstPageEndIndex])

        print("[DateProcessingUtilities] 📄 Extracted first page text (\(firstPageText.count) chars): \(firstPageText.prefix(100))...")
        return firstPageText
    }
}
