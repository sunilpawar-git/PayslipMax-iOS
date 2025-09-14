//
//  MilitaryDateExtractor.swift
//  PayslipMax
//
//  Refactored for architectural compliance - maintains < 300 lines
//  Core orchestration service using dependency injection
//

import Foundation

/// Protocol for military date extraction following SOLID principles
protocol MilitaryDateExtractorProtocol {
    func extractStatementDate(from text: String) -> (month: String, year: Int)?
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?)
}

/// Service responsible for orchestrating date extraction from military payslips
/// Implements SOLID principles with dependency injection and single responsibility
class MilitaryDateExtractor: MilitaryDateExtractorProtocol {
    
    // MARK: - Dependencies
    private let datePatternService: DatePatternServiceProtocol
    private let confidenceCalculator: DateConfidenceCalculatorProtocol
    private let personalInfoExtractor: PersonalInfoExtractorProtocol
    
    // MARK: - Initialization
    init(
        datePatternService: DatePatternServiceProtocol,
        confidenceCalculator: DateConfidenceCalculatorProtocol,
        personalInfoExtractor: PersonalInfoExtractorProtocol
    ) {
        self.datePatternService = datePatternService
        self.confidenceCalculator = confidenceCalculator
        self.personalInfoExtractor = personalInfoExtractor
    }
    
    // MARK: - Public Methods
    
    /// Extracts the payslip statement month and year from military payslip text
    /// Uses page-based extraction prioritizing Page 1 header information
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // First attempt: Extract ONLY from first page (first ~2000 characters)
        // This avoids confusion from financial logs in later pages
        let firstPageText = getFirstPageText(from: text)
        
        if let firstPageDate = extractDateFromText(firstPageText, scope: "FirstPage") {
            print("[MilitaryDateExtractor] 🎯 Using first page date: \(firstPageDate.month) \(firstPageDate.year)")
            return firstPageDate
        }
        
        // Fallback: If no date found in first page, search entire document
        print("[MilitaryDateExtractor] ⚠️ No date found in first page, searching entire document")
        return extractDateFromText(text, scope: "FullDocument")
    }
    
    /// Extracts personal information using the dedicated extractor service
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?) {
        return personalInfoExtractor.extractPersonalInfo(from: text)
    }
    
    // MARK: - Private Methods
    
    /// Extracts first page content (header and main payslip details)
    private func getFirstPageText(from text: String) -> String {
        // Most payslip headers and primary date info appear in first 2000 characters
        // This covers: document header, payslip period, employee info, main summary
        let firstPageLength = min(2000, text.count)
        let firstPageEndIndex = text.index(text.startIndex, offsetBy: firstPageLength)
        let firstPageText = String(text[text.startIndex..<firstPageEndIndex])
        
        print("[MilitaryDateExtractor] 📄 Extracted first page text (\(firstPageText.count) chars): \(firstPageText.prefix(100))...")
        return firstPageText
    }
    
    /// Extracts date from given text with specified scope
    private func extractDateFromText(_ text: String, scope: String) -> (month: String, year: Int)? {
        print("[MilitaryDateExtractor] 🔍 Searching for dates in scope: \(scope)")
        
        // Get patterns from the pattern service
        let militaryDatePatterns = datePatternService.getDatePatterns()
        
        // Collect ALL possible dates from ALL patterns
        var allFoundDates: [(month: String, year: Int, position: Int, confidence: Int)] = []
        
        for (patternIndex, pattern) in militaryDatePatterns.enumerated() {
            let datesFromPattern = extractAllDatesWithPattern(pattern, from: text, patternIndex: patternIndex, scope: scope)
            allFoundDates.append(contentsOf: datesFromPattern)
        }
        
        // Select the best date using the confidence calculator
        return confidenceCalculator.selectBestDate(from: allFoundDates, text: text, scope: scope)
    }
    
    /// Extract all dates from text using a specific pattern with confidence scoring
    private func extractAllDatesWithPattern(_ pattern: String, from text: String, patternIndex: Int, scope: String) -> [(month: String, year: Int, position: Int, confidence: Int)] {
        var foundDates: [(month: String, year: Int, position: Int, confidence: Int)] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges > 2 {
                    let monthRange = match.range(at: 1)
                    let yearRange = match.range(at: 2)
                    
                    if let monthSwiftRange = Range(monthRange, in: text),
                       let yearSwiftRange = Range(yearRange, in: text) {
                        
                        let monthStr = String(text[monthSwiftRange])
                        let yearStr = String(text[yearSwiftRange])
                        
                        // Convert month to standardized format
                        let month = datePatternService.convertToMonthName(monthStr)
                        
                        if let year = Int(yearStr), year >= 2000 && year <= 2050 {
                            // Validate that month is valid and date is reasonable
                            if datePatternService.isValidMonth(month) && datePatternService.isReasonableDate(month: month, year: year) {
                                // Calculate confidence using the confidence calculator
                                let confidence = confidenceCalculator.calculateConfidence(
                                    patternIndex: patternIndex, 
                                    position: match.range.location, 
                                    text: text,
                                    scope: scope
                                )
                                
                                foundDates.append((month: month, year: year, position: match.range.location, confidence: confidence))
                                print("[MilitaryDateExtractor] Found \(scope) date with pattern #\(patternIndex): \(month) \(year) at position \(match.range.location) (confidence: \(confidence))")
                            } else {
                                print("[MilitaryDateExtractor] ❌ Invalid/unreasonable date rejected: \(month) \(year) at position \(match.range.location)")
                            }
                        }
                    }
                }
            }
        } catch {
            print("[MilitaryDateExtractor] Error in regex pattern: \(error)")
        }
        
        return foundDates
    }
}

// MARK: - Factory Method for Dependency Injection

extension MilitaryDateExtractor {
    /// Factory method to create MilitaryDateExtractor with default dependencies
    /// Supports dependency injection for testing and modularity
    static func create() -> MilitaryDateExtractorProtocol {
        let datePatternService = DatePatternService()
        let confidenceCalculator = DateConfidenceCalculator()
        let personalInfoExtractor = PersonalInfoExtractor()
        
        return MilitaryDateExtractor(
            datePatternService: datePatternService,
            confidenceCalculator: confidenceCalculator,
            personalInfoExtractor: personalInfoExtractor
        )
    }
}