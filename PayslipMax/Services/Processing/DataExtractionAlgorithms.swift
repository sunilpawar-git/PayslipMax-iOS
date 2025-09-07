import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [REFACTORED]/300 lines
/// Contains core algorithms for data extraction - uses extracted patterns

/// Handles the complex algorithms and pattern matching logic for extracting financial data,
/// dates, and other structured information from text content and filenames.
/// Uses extracted patterns to maintain single responsibility principle and stay under 300 lines.
final class DataExtractionAlgorithms {
    
    // MARK: - Financial Data Extraction
    
    /// Extracts financial data from text using predefined and common patterns.
    /// Attempts to identify specific earnings/deductions and calculates totals if needed.
    /// - Parameter text: The text to analyze
    /// - Returns: Dictionary mapping data keys to values
    func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Extract using predefined patterns
        let patterns = DataExtractionPatterns.getFinancialPatterns()
        for (key, pattern) in patterns {
            if let value = DataExtractionPatterns.extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[DataExtractionAlgorithms] Extracted \(key): \(value)")
            }
        }

        // Try to extract from tables if no direct matches
        if extractedData.isEmpty {
            extractDataFromTables(text, into: &extractedData)
        }
        
        // Try to find credits/debits totals from common phrases
        extractCreditsAndDebits(from: text, into: &extractedData)
        
        return extractedData
    }
    
    /// Attempts to extract key-value pairs from text lines resembling simple table rows.
    func extractDataFromTables(_ text: String, into data: inout [String: Double]) {
        let tableLinePattern = DataExtractionPatterns.getTableLinePattern()
        
        do {
            let regex = try NSRegularExpression(pattern: tableLinePattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches where match.numberOfRanges > 2 {
                let descriptionRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let description = nsString.substring(with: descriptionRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let valueString = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let key = DataExtractionPatterns.mapDescriptionToStandardKey(description)
                
                if let doubleValue = DataExtractionPatterns.convertToDouble(valueString) {
                    data[key] = doubleValue
                    print("[DataExtractionAlgorithms] Extracted from table - \(key): \(doubleValue)")
                }
            }
        } catch {
            print("[DataExtractionAlgorithms] Error parsing table pattern: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Date Extraction
    
    /// Extracts the payslip statement date from text
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Try statement pattern first
        if let result = extractStatementDatePattern(from: text) {
            return result
        }
        
        // Try month-year pattern
        return extractMonthYearPattern(from: text)
    }
    
    /// Extracts month and year from filename
    func extractMonthAndYearFromFilename(_ filename: String) -> (String, Int)? {
        let cleanFilename = filename.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
        
        // Try regex patterns first
        if let result = extractDateWithRegexPatterns(from: cleanFilename) {
            return result
        }
        
        // Fallback to string splitting
        return extractDateFromFilenameParts(cleanFilename)
    }
    
    // MARK: - Private Helper Methods
    
    private func extractCreditsAndDebits(from text: String, into data: inout [String: Double]) {
        if data["credits"] == nil {
            if let credits = DataExtractionPatterns.extractAmountWithPattern(DataExtractionPatterns.getCreditsPattern(), from: text) {
                data["credits"] = credits
            }
        }
        
        if data["debits"] == nil {
            if let debits = DataExtractionPatterns.extractAmountWithPattern(DataExtractionPatterns.getDebitsPattern(), from: text) {
                data["debits"] = debits
            }
        }
    }
    
    private func extractStatementDatePattern(from text: String) -> (month: String, year: Int)? {
        return DataExtractionPatterns.processRegexPattern(DataExtractionPatterns.getStatementDatePattern(), in: text)
    }
    
    private func extractMonthYearPattern(from text: String) -> (month: String, year: Int)? {
        return DataExtractionPatterns.processRegexPattern(DataExtractionPatterns.getMonthYearPattern(), in: text)
    }
    
    private func extractDateWithRegexPatterns(from filename: String) -> (String, Int)? {
        let patterns = DataExtractionPatterns.getFilenamePatterns()
        
        for pattern in patterns {
            if let result = DataExtractionPatterns.processRegexPattern(pattern, in: filename) {
                return result
            }
        }
        
        return nil
    }
    
    private func extractDateFromFilenameParts(_ filename: String) -> (String, Int)? {
        let parts = filename.components(separatedBy: CharacterSet(charactersIn: " -_/"))
        let filteredParts = parts.filter { !$0.isEmpty }
        
        var extractedMonth: String?
        var extractedYear: Int?
        
        for part in filteredParts {
            let trimmedPart = part.trimmingCharacters(in: .punctuationCharacters)
            
            if extractedMonth == nil {
                let monthName = DataExtractionPatterns.getFullMonthName(trimmedPart)
                if monthName != trimmedPart {
                    extractedMonth = monthName
                    continue
                }
            }
            
            if extractedYear == nil, let year = Int(trimmedPart), year >= 2000 && year <= 2100 {
                extractedYear = year
            }
        }
        
        if let month = extractedMonth, let year = extractedYear {
            print("[DataExtractionAlgorithms] Extracted month and year from filename parts: \(month) \(year)")
            return (month, year)
        }
        
        return nil
    }
}
