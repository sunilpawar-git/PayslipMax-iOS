import Foundation

/// Protocol for military basic data extraction services
protocol MilitaryBasicDataExtractorProtocol {
    func extractName(from text: String) -> String
    func extractMonth(from text: String) -> String
    func extractYear(from text: String) -> Int
    func extractAccountNumber(from text: String) -> String
}

/// Service responsible for extracting basic identifying information from military payslips
///
/// This service handles the extraction of fundamental payslip data including personnel information,
/// pay period details, and banking information using military-specific patterns and formats.
class MilitaryBasicDataExtractor: MilitaryBasicDataExtractorProtocol {
    
    // MARK: - Dependencies
    
    /// Service used for applying pattern definitions to extract data
    private let patternMatchingService: PatternMatchingServiceProtocol
    
    // MARK: - Initialization
    
    init(patternMatchingService: PatternMatchingServiceProtocol) {
        self.patternMatchingService = patternMatchingService
    }
    
    // MARK: - Public Methods
    
    /// Extracts the employee's name from the military payslip text.
    ///
    /// Military payslips typically include rank along with name (e.g., "Capt. John Smith" or 
    /// "SGT Maria Rodriguez"). This method is designed to handle these military-specific 
    /// name formats and extract the complete name with rank where applicable.
    ///
    /// ## Extraction Strategy
    ///
    /// 1. **Pattern-Based Approach**:
    ///    First attempts to use a predefined pattern (`military_name`) through the pattern matching service,
    ///    which may be customized for specific military branches or payslip formats.
    ///
    /// 2. **Direct Pattern Matching**:
    ///    If the pattern service fails, falls back to direct regex matching using common
    ///    military payslip formats for name fields:
    ///    - Standard: `Name: Capt. John Smith`
    ///    - Officer-specific: `Officer Name: Lt. Jane Doe`
    ///    - Rank-inclusive: `Rank & Name: WO Thomas Johnson`
    ///
    /// The method is designed to preserve rank prefixes and military-specific name elements
    /// that might be relevant for proper identification and addressing of personnel.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted name (trimmed), or an empty string if no name is found.
    func extractName(from text: String) -> String {
        // Use pattern matching service if possible
        if let name = patternMatchingService.extractValue(for: "military_name", from: text) {
            return name
        }
        
        // Fallback to direct pattern matching
        let namePatterns = [
            "Name\\s*:\\s*([A-Za-z\\s.]+)",
            "Officer Name\\s*:\\s*([A-Za-z\\s.]+)",
            "Rank & Name\\s*:\\s*([A-Za-z0-9\\s.]+)"
        ]
        
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let name = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return name
                }
            }
        }
        
        return ""
    }
    
    /// Extracts the pay period month from the military payslip text.
    ///
    /// Military payslips may present month information in various formats:
    /// - Full month names (e.g., "January", "February")
    /// - Abbreviated forms (e.g., "Jan", "Feb")
    /// - Numeric formats (e.g., "01", "02")
    /// - In different contexts (e.g., "For Month: January", "Pay Period: Jan 2024")
    ///
    /// The method attempts multiple extraction strategies to handle these variations
    /// and converts the result to a standardized full month name format.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted month name (e.g., "January"), or current month as fallback.
    func extractMonth(from text: String) -> String {
        // Use pattern matching service if available
        if let month = patternMatchingService.extractValue(for: "military_month", from: text) {
            return month
        }
        
        // Define month patterns to search for
        let monthPatterns = [
            "For Month\\s*:\\s*([A-Za-z]+)",
            "Month\\s*:\\s*([A-Za-z]+)",
            "Pay Period\\s*:\\s*([A-Za-z]+)",
            "([A-Za-z]+)\\s+\\d{4}",  // Month Year format
            "\\b(January|February|March|April|May|June|July|August|September|October|November|December)\\b",
            "\\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\b"
        ]
        
        for pattern in monthPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let monthStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return normalizeMonthName(monthStr)
                }
            }
        }
        
        return getCurrentMonth()
    }
    
    /// Extracts the pay period year from the military payslip text.
    ///
    /// Military payslips typically include the year in contexts such as:
    /// - "For Year: 2024"
    /// - "Pay Period: January 2024"
    /// - "Year: 2024"
    /// - Simple four-digit year appearances
    ///
    /// The method searches for these patterns and returns the first valid year found.
    /// It validates that the extracted year is reasonable (between 2000 and current year + 5).
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted year as an integer, or current year as fallback.
    func extractYear(from text: String) -> Int {
        // Use pattern matching service if available
        if let yearStr = patternMatchingService.extractValue(for: "military_year", from: text),
           let year = Int(yearStr) {
            return year
        }
        
        // Define year patterns to search for
        let yearPatterns = [
            "For Year\\s*:\\s*(\\d{4})",
            "Year\\s*:\\s*(\\d{4})",
            "Pay Period\\s*:.*?(\\d{4})",
            "\\b(20\\d{2})\\b"  // Years from 2000-2099
        ]
        
        for pattern in yearPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let yearStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if let year = Int(yearStr), year >= 2000 && year <= getCurrentYear() + 5 {
                        return year
                    }
                }
            }
        }
        
        return getCurrentYear()
    }
    
    /// Extracts the bank account number from the payslip text using predefined regex patterns.
    ///
    /// In military payslips, bank account numbers are typically formatted differently than
    /// civilian payslips. They often include service-specific identifiers or branch codes
    /// and may appear in various sections of the document.
    ///
    /// ## Common Military Account Number Formats
    ///
    /// 1. **Standard Format**: `Account No: 1234567890`
    /// 2. **A/C Format**: `Bank A/c: SBI-1234567890` 
    /// 3. **Credit Format**: `Crdt A/c: 1234567890`
    ///
    /// The method tries multiple pattern variations to accommodate these different formats
    /// and extracts the first successful match. It handles potential OCR irregularities by
    /// allowing flexible whitespace patterns around the separators.
    ///
    /// - Parameter text: The payslip text content to search within.
    /// - Returns: The extracted account number (trimmed), or an empty string if no pattern matches.
    func extractAccountNumber(from text: String) -> String {
        // Common patterns for account numbers in military payslips
        let accountPatterns = [
            "Account No[.:]?\\s*([A-Z0-9\\s]+)",
            "Account[\\s:]+([A-Z0-9\\s]+)",
            "Bank A/c[\\s:]+([A-Z0-9\\s]+)",
            "Crdt A/c:[\\s]*([A-Z0-9\\s]+)"
        ]
        
        for pattern in accountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if range.location != NSNotFound, let range = Range(range, in: text) {
                    let account = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return account
                }
            }
        }
        
        return ""
    }
    
    // MARK: - Private Helper Methods
    
    /// Normalizes month names to full month format
    private func normalizeMonthName(_ monthStr: String) -> String {
        let lowercased = monthStr.lowercased()
        
        let monthMapping: [String: String] = [
            "jan": "January", "feb": "February", "mar": "March", "apr": "April",
            "may": "May", "jun": "June", "jul": "July", "aug": "August",
            "sep": "September", "oct": "October", "nov": "November", "dec": "December"
        ]
        
        if let fullMonth = monthMapping[lowercased] {
            return fullMonth
        }
        
        // If it's already a full month name, capitalize it properly
        return monthStr.prefix(1).uppercased() + monthStr.dropFirst().lowercased()
    }
    
    /// Returns the full name of the current month (e.g., "January", "February").
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    /// Returns the current year as an integer.
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
} 