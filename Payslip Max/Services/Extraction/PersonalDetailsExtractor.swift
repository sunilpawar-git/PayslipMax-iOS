import Foundation
import PDFKit

/// Service for extracting personal details from payslip text
class PersonalDetailsExtractor {
    // MARK: - Public Methods
    
    /// Extracts personal details from the page texts
    /// - Parameters:
    ///   - pageTexts: Array of page texts
    ///   - pageTypes: Array of page types
    /// - Returns: Personal details structure
    func extractPersonalDetails(from pageTexts: [String], pageTypes: [PageType]) -> PersonalDetails {
        var details = PersonalDetails()
        
        // Find the main summary page
        if let mainSummaryIndex = pageTypes.firstIndex(of: .mainSummary), mainSummaryIndex < pageTexts.count {
            let pageText = pageTexts[mainSummaryIndex]
            
            // Extract Name
            details.name = extractName(from: pageText)
            
            // Extract Account Number
            details.accountNumber = extractAccountNumber(from: pageText)
            
            // Extract PAN
            details.panNumber = extractPanNumber(from: pageText)
            
            // Extract Month/Year
            let (month, year) = extractMonthAndYear(from: pageText)
            details.month = month
            details.year = year
        }
        
        return details
    }
    
    // MARK: - Private Methods
    
    /// Extracts the name from the text
    /// - Parameter text: The text to extract from
    /// - Returns: The extracted name
    private func extractName(from text: String) -> String {
        if let nameRange = text.range(of: "Name:\\s*([^\\n]+)", options: .regularExpression) {
            let nameMatch = text[nameRange]
            let nameComponents = nameMatch.components(separatedBy: ":")
            if nameComponents.count > 1 {
                return nameComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    /// Extracts the account number from the text
    /// - Parameter text: The text to extract from
    /// - Returns: The extracted account number
    private func extractAccountNumber(from text: String) -> String {
        if let accountRange = text.range(of: "A/C No\\s*-\\s*([^\\s]+)", options: .regularExpression) {
            let accountMatch = text[accountRange]
            let accountComponents = accountMatch.components(separatedBy: "-")
            if accountComponents.count > 1 {
                return accountComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    /// Extracts the PAN number from the text
    /// - Parameter text: The text to extract from
    /// - Returns: The extracted PAN number
    private func extractPanNumber(from text: String) -> String {
        if let panRange = text.range(of: "PAN No:\\s*([^\\s\\n]+)", options: .regularExpression) {
            let panMatch = text[panRange]
            let panComponents = panMatch.components(separatedBy: ":")
            if panComponents.count > 1 {
                return panComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }
    
    /// Extracts the month and year from the text
    /// - Parameter text: The text to extract from
    /// - Returns: A tuple containing the month and year
    private func extractMonthAndYear(from text: String) -> (String, String) {
        var month = ""
        var year = ""
        
        if let statementRange = text.range(of: "STATEMENT OF ACCOUNT FOR (\\d+/\\d+)", options: .regularExpression) {
            let statementMatch = text[statementRange]
            if let periodRange = statementMatch.range(of: "\\d+/\\d+", options: .regularExpression) {
                let period = statementMatch[periodRange]
                let components = period.components(separatedBy: "/")
                if components.count == 2 {
                    month = mapMonthNumber(components[0])
                    if let yearComponent = Int(components[1]) {
                        if yearComponent < 100 {
                            year = String(2000 + yearComponent)
                        } else {
                            year = String(yearComponent)
                        }
                    } else {
                        year = String(Calendar.current.component(.year, from: Date()))
                    }
                }
            }
        }
        
        return (month, year)
    }
    
    /// Maps a month number to a month name
    /// - Parameter number: The month number as a string
    /// - Returns: The month name
    private func mapMonthNumber(_ number: String) -> String {
        guard let monthNum = Int(number) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        guard let date = Calendar.current.date(from: DateComponents(year: 2000, month: monthNum, day: 1)) else {
            return ""
        }
        
        return formatter.string(from: date)
    }
} 