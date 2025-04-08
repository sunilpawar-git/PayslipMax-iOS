import Foundation

/// Protocol for handling date parsing operations
protocol DateParsingServiceProtocol {
    /// Parses a date string to a Date object
    /// - Parameter string: Date string to parse
    /// - Returns: Date object if parsing successful, nil otherwise
    func parseDate(_ string: String) -> Date?
    
    /// Creates a date formatter with the specified format
    /// - Parameter format: The date format string
    /// - Returns: Configured DateFormatter
    func createDateFormatter(format: String) -> DateFormatter
    
    /// Gets a month name from a month number
    /// - Parameter month: Month number (1-12)
    /// - Returns: Month name
    func getMonthName(from month: Int) -> String
    
    /// Extracts month and year information directly from a string
    /// - Parameters:
    ///   - string: The string to extract from
    ///   - data: Data structure to update with extracted month/year
    func extractMonthYearFromString(_ string: String, into data: inout PayslipExtractionData)
}

/// Service for handling date parsing operations
class DateParsingService: DateParsingServiceProtocol {
    
    // MARK: - Public Methods
    
    /// Parses a date string to a Date object
    /// - Parameter string: Date string to parse
    /// - Returns: Date object if parsing successful, nil otherwise
    func parseDate(_ string: String) -> Date? {
        let dateFormatters = [
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MMMM d, yyyy"),
            createDateFormatter(format: "d MMMM yyyy"),
            createDateFormatter(format: "dd-MM-yyyy"),
            createDateFormatter(format: "MM-dd-yyyy"),
            createDateFormatter(format: "dd.MM.yyyy"),
            createDateFormatter(format: "MMM yyyy"), // For formats like "Mar 2025"
            createDateFormatter(format: "MMMM yyyy"), // For formats like "March 2025"
            createDateFormatter(format: "MM/yyyy") // For formats like "03/2025"
        ]
        
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: cleanedString) {
                return date
            }
        }
        
        // Try to extract just month and year
        if let monthYearMatch = string.range(of: "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \\d{4}", options: .regularExpression) {
            let monthYearString = String(string[monthYearMatch])
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            if let date = formatter.date(from: monthYearString) {
                return date
            }
            
            formatter.dateFormat = "MMMM yyyy"
            if let date = formatter.date(from: monthYearString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Creates a date formatter with the specified format
    /// - Parameter format: The date format string
    /// - Returns: Configured DateFormatter
    func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
    /// Gets a month name from a month number
    /// - Parameter month: Month number (1-12)
    /// - Returns: Month name
    func getMonthName(from month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = month
        
        if let date = calendar.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return String(month)
    }
    
    /// Extracts month and year information directly from a string
    /// - Parameters:
    ///   - string: The string to extract from
    ///   - data: Data structure to update with extracted month/year
    func extractMonthYearFromString(_ string: String, into data: inout PayslipExtractionData) {
        // Try to find month names
        let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Check for full month names
        for (_, monthName) in monthNames.enumerated() {
            if string.contains(monthName) {
                data.month = monthName
                // Try to find a year (4 digits) near the month name
                if let yearMatch = string.range(of: "\\b(20\\d{2})\\b", options: .regularExpression) {
                    if let year = Int(string[yearMatch]) {
                        data.year = year
                    }
                }
                print("DateParsingService: Extracted month from string: \(data.month)")
                return
            }
        }
        
        // Check for abbreviated month names
        for (index, shortName) in shortMonthNames.enumerated() {
            if string.contains(shortName) {
                data.month = monthNames[index]
                // Try to find a year (4 digits) near the month name
                if let yearMatch = string.range(of: "\\b(20\\d{2})\\b", options: .regularExpression) {
                    if let year = Int(string[yearMatch]) {
                        data.year = year
                    }
                }
                print("DateParsingService: Extracted month from abbreviated name: \(data.month)")
                return
            }
        }
        
        // Check for MM/YYYY format
        if let dateMatch = string.range(of: "(\\d{1,2})\\s*[/\\-]\\s*(20\\d{2})", options: .regularExpression) {
            let dateString = string[dateMatch]
            let components = dateString.components(separatedBy: CharacterSet(charactersIn: "/- "))
            let filteredComponents = components.filter { !$0.isEmpty }
            
            if filteredComponents.count >= 2, 
               let monthNumber = Int(filteredComponents[0]),
               monthNumber >= 1 && monthNumber <= 12,
               let year = Int(filteredComponents[1]) {
                data.month = monthNames[monthNumber - 1]
                data.year = year
                print("DateParsingService: Extracted month/year from MM/YYYY format: \(data.month) \(data.year)")
            }
        }
    }
} 