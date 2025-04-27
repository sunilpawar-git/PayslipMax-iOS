import Foundation

/// Provides utility functions for extracting structured data (financial figures, dates, personal info)
/// from raw text content, typically derived from PDF documents or filenames.
/// Uses regex patterns and attempts to handle common variations and tabular data.
@MainActor
class DataExtractionService {
    /// Extracts financial data from text using predefined and common patterns.
    /// Attempts to identify specific earnings/deductions and calculates totals if needed.
    /// - Parameter text: The text to analyze
    /// - Returns: Dictionary mapping data keys to values
    func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Define patterns to look for in the PDF text
        let patterns: [(key: String, regex: String)] = [
            ("BPAY", "BPAY\\s*[:-]?\\s*([0-9,.]+)"),
            ("DA", "DA\\s*[:-]?\\s*([0-9,.]+)"),
            ("MSP", "MSP\\s*[:-]?\\s*([0-9,.]+)"),
            ("RH12", "RH12\\s*[:-]?\\s*([0-9,.]+)"),
            ("TPTA", "TPTA\\s*[:-]?\\s*([0-9,.]+)"),
            ("TPTADA", "TPTADA\\s*[:-]?\\s*([0-9,.]+)"),
            ("DSOP", "DSOP\\s*[:-]?\\s*([0-9,.]+)"),
            ("AGIF", "AGIF\\s*[:-]?\\s*([0-9,.]+)"),
            ("ITAX", "ITAX\\s*[:-]?\\s*([0-9,.]+)"),
            ("EHCESS", "EHCESS\\s*[:-]?\\s*([0-9,.]+)"),
            ("credits", "(?:Gross Pay|कुल आय)\\s*[:-]?\\s*([0-9,.]+)"),
            ("debits", "(?:Total Deductions|कुल कटौती)\\s*[:-]?\\s*([0-9,.]+)"),
        ]
        
        // Extract each value using regex patterns
        for (key, pattern) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Convert to Double
                    let cleanValue = value.replacingOccurrences(of: ",", with: "")
                    if let doubleValue = Double(cleanValue) {
                        extractedData[key] = doubleValue
                        print("[DataExtractionService] Extracted \(key): \(doubleValue)")
                    }
                }
            } catch {
                print("[DataExtractionService] Error with regex pattern \(pattern): \(error.localizedDescription)")
            }
        }

        // Try to extract from tables by looking for patterns in the text
        if extractedData.isEmpty {
            extractDataFromTables(text, into: &extractedData)
        }
        
        // Try to find credits/debits totals from common phrases
        if extractedData["credits"] == nil {
            // Look for anything that could be Gross Pay/Total Earnings
            extractAmountWithPattern("(?:Total|Gross|Sum|कुल)\\s+(?:Pay|Earnings|Income|Credits|आय)\\s*[:-]?\\s*([0-9,.]+)", 
                                   from: text, 
                                   forKey: "credits", 
                                   into: &extractedData)
        }
        
        if extractedData["debits"] == nil {
            // Look for anything that could be Total Deductions
            extractAmountWithPattern("(?:Total|Gross|Sum|कुल)\\s+(?:Deductions|Debits|कटौती)\\s*[:-]?\\s*([0-9,.]+)", 
                                   from: text, 
                                   forKey: "debits", 
                                   into: &extractedData)
        }
        
        return extractedData
    }
    
    /// Attempts to extract key-value pairs from text lines resembling simple table rows (e.g., "Description    Amount").
    /// Populates the provided data dictionary with mapped keys and extracted values.
    /// - Parameters:
    ///   - text: The text containing potential table data.
    ///   - data: The dictionary to populate with extracted key-value pairs.
    private func extractDataFromTables(_ text: String, into data: inout [String: Double]) {
        // Look for common payslip table patterns
        // Format: Description    Amount
        let tableLinePattern = "\\b([A-Za-z0-9\\s]+)\\s+([0-9,.]+)\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: tableLinePattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches where match.numberOfRanges > 2 {
                let descriptionRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let description = nsString.substring(with: descriptionRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let valueString = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Map description to standard keys
                let key = mapDescriptionToStandardKey(description)
                
                // Convert value to Double
                let cleanValue = valueString.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanValue) {
                    data[key] = doubleValue
                    print("[DataExtractionService] Extracted from table - \(key): \(doubleValue)")
                }
            }
        } catch {
            print("[DataExtractionService] Error parsing table pattern: \(error.localizedDescription)")
        }
    }
    
    /// Maps common textual descriptions found in payslips to standardized internal keys.
    /// For example, maps "basic pay" or "basic salary" to "BPAY".
    /// - Parameter description: The text description extracted from the payslip (e.g., from a table row).
    /// - Returns: A standardized key (e.g., "BPAY", "DA", "ITAX") or the original description if no mapping is found.
    private func mapDescriptionToStandardKey(_ description: String) -> String {
        let lowerDescription = description.lowercased()
        
        // Map common descriptions to standard keys
        if lowerDescription.contains("basic") && (lowerDescription.contains("pay") || lowerDescription.contains("salary")) {
            return "BPAY"
        } else if lowerDescription.contains("da") || lowerDescription.contains("dearness") {
            return "DA"
        } else if lowerDescription.contains("msp") || lowerDescription.contains("military service") {
            return "MSP"
        } else if lowerDescription.contains("rh12") {
            return "RH12"
        } else if lowerDescription.contains("tpta") && !lowerDescription.contains("tptada") {
            return "TPTA"
        } else if lowerDescription.contains("tptada") {
            return "TPTADA"
        } else if lowerDescription.contains("dsop") {
            return "DSOP"
        } else if lowerDescription.contains("agif") {
            return "AGIF"
        } else if lowerDescription.contains("tax") && !lowerDescription.contains("cess") {
            return "ITAX"
        } else if (lowerDescription.contains("cess") || lowerDescription.contains("ehcess")) {
            return "EHCESS"
        } else if lowerDescription.contains("gross") || lowerDescription.contains("total") && 
                 (lowerDescription.contains("pay") || lowerDescription.contains("earnings") || lowerDescription.contains("income")) {
            return "credits"
        } else if lowerDescription.contains("total") && lowerDescription.contains("deduction") {
            return "debits"
        }
        
        // Return the original description if no mapping is found
        return description
    }
    
    /// Helper function to extract a numerical amount using a specific regex pattern and store it in the data dictionary.
    /// Used for extracting totals or specific items when the standard patterns fail.
    /// - Parameters:
    ///   - pattern: The regex pattern string. Must contain a capture group for the numerical value.
    ///   - text: The text to search within.
    ///   - key: The key under which to store the extracted value in the `data` dictionary.
    ///   - data: The dictionary to update with the extracted value.
    private func extractAmountWithPattern(_ pattern: String, from text: String, forKey key: String, into data: inout [String: Double]) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanValue) {
                    data[key] = doubleValue
                    print("[DataExtractionService] Extracted \(key) from alternative pattern: \(doubleValue)")
                }
            }
        } catch {
            print("[DataExtractionService] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
    }
    
    /// Extracts the payslip statement date (month and year) from the text.
    /// Tries multiple common patterns like "STATEMENT OF ACCOUNT FOR MM/YYYY" and "Month YYYY".
    /// - Parameter text: The text to analyze
    /// - Returns: Tuple containing month name and year if found
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Look for "STATEMENT OF ACCOUNT FOR MM/YYYY" pattern
        let statementPattern = "STATEMENT\\s+OF\\s+ACCOUNT\\s+FOR\\s+([0-9]{1,2})/([0-9]{4})"
        
        do {
            let regex = try NSRegularExpression(pattern: statementPattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 2 {
                let monthNumberRange = match.range(at: 1)
                let yearRange = match.range(at: 2)
                
                let monthNumberString = nsString.substring(with: monthNumberRange)
                let yearString = nsString.substring(with: yearRange)
                
                if let monthNumber = Int(monthNumberString), let year = Int(yearString),
                   monthNumber >= 1 && monthNumber <= 12 {
                    // Convert month number to name
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM"
                    
                    var dateComponents = DateComponents()
                    dateComponents.month = monthNumber
                    dateComponents.year = 2000  // Any year would work for getting month name
                    
                    if let date = Calendar.current.date(from: dateComponents) {
                        let monthName = dateFormatter.string(from: date)
                        return (monthName, year)
                    }
                }
            }
            
            // Alternative pattern: "Month Year" format
            let monthYearPattern = "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+([0-9]{4})"
            
            let monthYearRegex = try NSRegularExpression(pattern: monthYearPattern, options: [.caseInsensitive])
            let monthYearMatches = monthYearRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = monthYearMatches.first, match.numberOfRanges > 2 {
                let monthRange = match.range(at: 1)
                let yearRange = match.range(at: 2)
                
                let month = nsString.substring(with: monthRange)
                let yearString = nsString.substring(with: yearRange)
                
                if let year = Int(yearString) {
                    return (month.capitalized, year)
                }
            }
            
        } catch {
            print("[DataExtractionService] Error parsing statement date: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extracts the month and year from a filename string.
    /// Attempts various common date patterns found in filenames (e.g., "Dec 2024.pdf", "12-2024.pdf").
    /// - Parameter filename: The filename to analyze
    /// - Returns: Tuple containing month name and year if found
    func extractMonthAndYearFromFilename(_ filename: String) -> (String, Int)? {
        // First, try to extract potential date components from the filename
        let patterns = [
            // Pattern 1: "12 Dec 2024.pdf"
            "\\b(\\d{1,2})\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})\\b",
            
            // Pattern 2: "Dec 2024.pdf"
            "\\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})\\b",
            
            // Pattern 3: "12-2024.pdf" (assuming month-year format)
            "\\b(\\d{1,2})[-/](\\d{4})\\b"
        ]
        
        // First, clean the filename by removing extension
        let cleanFilename = filename.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
        
        // Try each pattern
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let nsString = cleanFilename as NSString
                let matches = regex.matches(in: cleanFilename, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first {
                    // Different patterns have different group arrangements
                    if match.numberOfRanges == 4 { // Pattern 1: day, month, year
                        let monthRange = match.range(at: 2)
                        let yearRange = match.range(at: 3)
                        let monthString = nsString.substring(with: monthRange)
                        let yearString = nsString.substring(with: yearRange)
                        
                        if let year = Int(yearString) {
                            let fullMonthName = getFullMonthName(monthString)
                            print("[DataExtractionService] Extracted month and year from filename: \(fullMonthName) \(year)")
                            return (fullMonthName, year)
                        }
                    } else if match.numberOfRanges == 3 { // Pattern 2: month, year
                        let monthRange = match.range(at: 1)
                        let yearRange = match.range(at: 2)
                        let monthString = nsString.substring(with: monthRange)
                        let yearString = nsString.substring(with: yearRange)
                        
                        if let year = Int(yearString) {
                            let fullMonthName = getFullMonthName(monthString)
                            print("[DataExtractionService] Extracted month and year from filename: \(fullMonthName) \(year)")
                            return (fullMonthName, year)
                        }
                    } else if match.numberOfRanges == 3 { // Pattern 3: month number, year
                        let monthNumberRange = match.range(at: 1)
                        let yearRange = match.range(at: 2)
                        let monthNumberString = nsString.substring(with: monthNumberRange)
                        let yearString = nsString.substring(with: yearRange)
                        
                        if let monthNumber = Int(monthNumberString), let year = Int(yearString), 
                           monthNumber >= 1 && monthNumber <= 12 {
                            let fullMonthName = getMonthNameFromNumber(monthNumber)
                            print("[DataExtractionService] Extracted month and year from filename: \(fullMonthName) \(year)")
                            return (fullMonthName, year)
                        }
                    }
                }
            } catch {
                print("[DataExtractionService] Error parsing filename with pattern: \(error.localizedDescription)")
            }
        }
        
        // If regex approach fails, fall back to the original string splitting method
        let parts = cleanFilename.components(separatedBy: CharacterSet(charactersIn: " -_/"))
        let filteredParts = parts.filter { !$0.isEmpty }
        
        var extractedMonth: String?
        var extractedYear: Int?
        
        // Check each part for month names or abbreviations
        for part in filteredParts {
            let trimmedPart = part.trimmingCharacters(in: .punctuationCharacters)
            
            // Check for month name or abbreviation
            if extractedMonth == nil {
                let monthName = getFullMonthName(trimmedPart)
                if monthName != trimmedPart { // If conversion succeeded
                    extractedMonth = monthName
                    continue
                }
            }
            
            // Check for year (4-digit number between 2000-2100)
            if extractedYear == nil, let year = Int(trimmedPart), 
               year >= 2000 && year <= 2100 {
                extractedYear = year
            }
        }
        
        if let month = extractedMonth, let year = extractedYear {
            print("[DataExtractionService] Extracted month and year from filename parts: \(month) \(year)")
            return (month, year)
        }
        
        return nil
    }
    
    /// Gets the full month name from abbreviation or partial name
    /// - Parameter monthText: The month text to convert
    /// - Returns: Full month name
    private func getFullMonthName(_ monthText: String) -> String {
        let lowercaseMonth = monthText.lowercased()
        
        let monthMappings = [
            "jan": "January", "january": "January",
            "feb": "February", "february": "February",
            "mar": "March", "march": "March",
            "apr": "April", "april": "April",
            "may": "May",
            "jun": "June", "june": "June",
            "jul": "July", "july": "July",
            "aug": "August", "august": "August",
            "sep": "September", "sept": "September", "september": "September",
            "oct": "October", "october": "October",
            "nov": "November", "november": "November",
            "dec": "December", "december": "December"
        ]
        
        return monthMappings[lowercaseMonth] ?? monthText
    }
    
    /// Gets month name from month number (1-12)
    /// - Parameter monthNumber: The month number (1-12)
    /// - Returns: Full month name
    private func getMonthNameFromNumber(_ monthNumber: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var dateComponents = DateComponents()
        dateComponents.month = monthNumber
        dateComponents.year = 2000 // Any year works for getting month name
        
        if let date = Calendar.current.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        // Fallback mapping if Calendar fails
        let monthNames = ["January", "February", "March", "April", "May", "June", 
                           "July", "August", "September", "October", "November", "December"]
        if monthNumber >= 1 && monthNumber <= 12 {
            return monthNames[monthNumber - 1]
        }
        
        return "Unknown"
    }
} 