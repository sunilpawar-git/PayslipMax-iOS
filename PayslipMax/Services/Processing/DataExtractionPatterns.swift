import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [NEW_FILE]/300 lines
/// Contains extraction patterns and pattern-related algorithms

/// Contains pattern definitions and pattern-matching algorithms for data extraction.
/// Separated from main algorithms to maintain single responsibility and keep files under 300 lines.
struct DataExtractionPatterns {
    
    // MARK: - Financial Patterns
    
    static func getFinancialPatterns() -> [(key: String, regex: String)] {
        return [
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
    }
    
    static func getCreditsPattern() -> String {
        return "(?:Total|Gross|Sum|कुल)\\s+(?:Pay|Earnings|Income|Credits|आय)\\s*[:-]?\\s*([0-9,.]+)"
    }
    
    static func getDebitsPattern() -> String {
        return "(?:Total|Gross|Sum|कुल)\\s+(?:Deductions|Debits|कटौती)\\s*[:-]?\\s*([0-9,.]+)"
    }
    
    static func getTableLinePattern() -> String {
        return "\\b([A-Za-z0-9\\s]+)\\s+([0-9,.]+)\\b"
    }
    
    // MARK: - Date Patterns
    
    static func getStatementDatePattern() -> String {
        return "STATEMENT\\s+OF\\s+ACCOUNT\\s+FOR\\s+([0-9]{1,2})/([0-9]{4})"
    }
    
    static func getMonthYearPattern() -> String {
        return "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+([0-9]{4})"
    }
    
    static func getFilenamePatterns() -> [String] {
        return [
            // Pattern 1: "12 Dec 2024.pdf"
            "\\b(\\d{1,2})\\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})\\b",
            
            // Pattern 2: "Dec 2024.pdf"
            "\\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})\\b",
            
            // Pattern 3: "12-2024.pdf"
            "\\b(\\d{1,2})[-/](\\d{4})\\b"
        ]
    }
    
    // MARK: - Pattern Matching Utilities
    
    static func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                return convertToDouble(value)
            }
        } catch {
            print("[DataExtractionPatterns] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    static func convertToDouble(_ value: String) -> Double? {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
        return Double(cleanValue)
    }
    
    // MARK: - Description Mapping
    
    static func mapDescriptionToStandardKey(_ description: String) -> String {
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
    
    // MARK: - Month Name Utilities
    
    static func getFullMonthName(_ monthText: String) -> String {
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
    
    static func getMonthNameFromNumber(_ monthNumber: Int) -> String {
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
    
    // MARK: - Pattern Processing Utilities
    
    static func processRegexPattern(_ pattern: String, in text: String) -> (String, Int)? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                return processRegexMatch(match, in: nsString)
            }
        } catch {
            print("[DataExtractionPatterns] Error parsing pattern: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    static func processRegexMatch(_ match: NSTextCheckingResult, in nsString: NSString) -> (String, Int)? {
        // Different patterns have different group arrangements
        if match.numberOfRanges == 4 { // Pattern 1: day, month, year
            let monthRange = match.range(at: 2)
            let yearRange = match.range(at: 3)
            let monthString = nsString.substring(with: monthRange)
            let yearString = nsString.substring(with: yearRange)
            
            if let year = Int(yearString) {
                let fullMonthName = getFullMonthName(monthString)
                return (fullMonthName, year)
            }
        } else if match.numberOfRanges == 3 { // Pattern 2: month, year OR Pattern 3: month number, year
            let firstRange = match.range(at: 1)
            let yearRange = match.range(at: 2)
            let firstString = nsString.substring(with: firstRange)
            let yearString = nsString.substring(with: yearRange)
            
            if let year = Int(yearString) {
                // Check if first string is a month name or number
                if let monthNumber = Int(firstString), monthNumber >= 1 && monthNumber <= 12 {
                    let fullMonthName = getMonthNameFromNumber(monthNumber)
                    return (fullMonthName, year)
                } else {
                    let fullMonthName = getFullMonthName(firstString)
                    return (fullMonthName, year)
                }
            }
        }
        
        return nil
    }
}
