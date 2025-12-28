//
//  MilitaryDateExtractor.swift
//  PayslipMax
//
//  Created for military payslip date extraction logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Protocol for military date extraction services
protocol MilitaryDateExtractorProtocol {
    /// Extracts the payslip statement month and year from military payslip text
    func extractStatementDate(from text: String) -> (month: String, year: Int)?

    /// Extracts personal information from military payslip text
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?)
}

/// Service responsible for extracting dates from military payslips
/// Implements SOLID principles with single responsibility for date parsing
final class MilitaryDateExtractor: MilitaryDateExtractorProtocol {

    // MARK: - Dependencies

    private let datePatterns: DatePatternDefinitionsProtocol
    private let dateValidation: DateValidationServiceProtocol
    private let dateProcessing: DateProcessingUtilitiesProtocol
    private let dateSelection: DateSelectionServiceProtocol
    private let confidenceCalculator: DateConfidenceCalculatorProtocol

    // MARK: - Initialization

    init(
        datePatterns: DatePatternDefinitionsProtocol,
        dateValidation: DateValidationServiceProtocol,
        dateProcessing: DateProcessingUtilitiesProtocol,
        dateSelection: DateSelectionServiceProtocol,
        confidenceCalculator: DateConfidenceCalculatorProtocol
    ) {
        self.datePatterns = datePatterns
        self.dateValidation = dateValidation
        self.dateProcessing = dateProcessing
        self.dateSelection = dateSelection
        self.confidenceCalculator = confidenceCalculator
    }

    /// Extracts the payslip statement month and year from military payslip text
    /// Supports comprehensive date formats across all payslip types and years
    /// Uses page-based extraction prioritizing Page 1 header information
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // First attempt: Extract ONLY from first page (first ~2000 characters)
        // This avoids confusion from financial logs in later pages
        let firstPageText = dateProcessing.getFirstPageText(from: text)

        if let firstPageDate = extractDateFromText(firstPageText, scope: "FirstPage") {
            print("[MilitaryDateExtractor] 🎯 Using first page date: \(firstPageDate.month) \(firstPageDate.year)")
            return firstPageDate
        }

        // Fallback: If no date found in first page, search entire document
        print("[MilitaryDateExtractor] ⚠️ No date found in first page, searching entire document")
        return extractDateFromText(text, scope: "FullDocument")
    }


    /// Extracts date from given text with specified scope
    private func extractDateFromText(_ text: String, scope: String) -> (month: String, year: Int)? {
        print("[MilitaryDateExtractor] 🔍 Searching for dates in scope: \(scope)")

        // Collect ALL possible dates from ALL patterns using extracted services
        var allFoundDates: [(month: String, year: Int, position: Int, confidence: Int)] = []

        for (patternIndex, pattern) in datePatterns.militaryDatePatterns.enumerated() {
            let datesFromPattern = extractAllDatesWithPattern(pattern, from: text, patternIndex: patternIndex, scope: scope)
            allFoundDates.append(contentsOf: datesFromPattern)
        }

        // Select the best date using intelligent prioritization
        return dateSelection.selectBestDate(from: allFoundDates, text: text, scope: scope)
    }


    /// Extract all dates from text using a specific pattern with confidence scoring
    private func extractAllDatesWithPattern(
        _ pattern: String,
        from text: String,
        patternIndex: Int,
        scope: String
    ) -> [(month: String, year: Int, position: Int, confidence: Int)] {
        var foundDates: [(month: String, year: Int, position: Int, confidence: Int)] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                if match.numberOfRanges >= 3 {
                    let monthRange = match.range(at: 1)
                    let yearRange = match.range(at: 2)
                    let monthStr = nsString.substring(with: monthRange)
                    let yearStr = nsString.substring(with: yearRange)

                    // Convert month to standard format using extracted service
                    let month = dateProcessing.convertToMonthName(monthStr)

                    if let year = Int(yearStr), year >= 2000 && year <= 2050 {
                        // Validate that month is valid and date is reasonable using extracted services
                        if dateValidation.isValidMonth(month) && dateValidation.isReasonableDate(month: month, year: year) {
                            // Calculate confidence based on pattern type and context using extracted service
                            let confidence = confidenceCalculator.calculateConfidence(
                                patternIndex: patternIndex,
                                position: match.range.location,
                                text: text,
                                scope: scope
                            )

                            foundDates.append((month: month, year: year, position: match.range.location, confidence: confidence))
                            print("[MilitaryDateExtractor] Found \(scope) date with pattern #\(patternIndex): \(month) \(year) at position \(match.range.location) (confidence: \(confidence))")
                        } else {
                            print("[MilitaryDateExtractor] ❌ Invalid/unreasonable \(scope) date rejected: \(month) \(year) at position \(match.range.location)")
                        }
                    }
                }
            }
        } catch {
            print("[MilitaryDateExtractor] Error with pattern #\(patternIndex): \(error.localizedDescription)")
        }

        return foundDates
    }




    /// Extracts personal information from military payslip text
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?) {
        let name = extractName(from: text)
        let accountNumber = extractAccountNumber(from: text)
        let panNumber = extractPANNumber(from: text)

        return (name, accountNumber, panNumber)
    }

    /// Extracts employee name from military payslip
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "(?:Name|Employee Name|Emp Name)[:\\s]+([A-Za-z\\s.]+?)(?:\\n|\\s{2,}|[A-Z/]{2,})",
            "Name:\\s*([A-Za-z\\s.]+?)(?:\\s+A/C|\\s+Service)",
            "([A-Z][a-z]+\\s+[A-Z][a-z]+\\s+[A-Z][a-z]+)\\s*(?:A/C|Account)"
        ]

        for pattern in namePatterns {
            if let name = extractValueWithPattern(pattern, from: text) {
                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanName.count > 3 && cleanName.count < 50 {
                    return cleanName
                }
            }
        }
        return nil
    }

    /// Extracts account number from military payslip
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "(?:A/C No|Account No|Account Number)[:\\s-]+([A-Za-z0-9/\\-]+)",
            "A/C\\s+No[:\\s-]+([0-9/\\-A-Za-z]+)"
        ]

        for pattern in accountPatterns {
            if let account = extractValueWithPattern(pattern, from: text) {
                let cleanAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanAccount.count > 5 {
                    return cleanAccount
                }
            }
        }
        return nil
    }

    /// Extracts PAN number from military payslip
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "(?:PAN No|PAN Number)[:\\s]+([A-Z]{5}[0-9]{4}[A-Z]{1})",
            "PAN\\s+No[:\\s]+([A-Z0-9*]+)",
            "([A-Z]{5}[0-9]{4}[A-Z]{1})",  // Direct PAN pattern
            "([A-Z]{2}\\*{4}[0-9A-Z]{2,3})" // Masked PAN pattern
        ]

        for pattern in panPatterns {
            if let pan = extractValueWithPattern(pattern, from: text) {
                let cleanPAN = pan.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanPAN.count >= 6 {
                    return cleanPAN
                }
            }
        }
        return nil
    }

    /// Helper to extract value with regex pattern
    private func extractValueWithPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                return nsString.substring(with: valueRange)
            }
        } catch {
            print("[MilitaryDateExtractor] Error with pattern \\(pattern): \\(error.localizedDescription)")
        }
        return nil
    }
}
