import Foundation

/// Protocol for parsing financial data from document sections
protocol FinancialDataSectionParserProtocol {
    /// Parse earnings section from a document section
    /// - Parameter section: The document section containing earnings data
    /// - Returns: Dictionary of earnings items and their values
    func parseEarningsSection(_ section: DocumentSection) -> [String: Double]
    
    /// Parse deductions section from a document section
    /// - Parameter section: The document section containing deductions data
    /// - Returns: Dictionary of deduction items and their values
    func parseDeductionsSection(_ section: DocumentSection) -> [String: Double]
    
    /// Parse tax section from a document section
    /// - Parameter section: The document section containing tax data
    /// - Returns: Dictionary of tax fields and their values
    func parseTaxSection(_ section: DocumentSection) -> [String: Double]
    
    /// Parse DSOP section from a document section
    /// - Parameter section: The document section containing DSOP data
    /// - Returns: Dictionary of DSOP fields and their values
    func parseDSOPSection(_ section: DocumentSection) -> [String: Double]
}

/// Service responsible for parsing financial data from payslip document sections
class FinancialDataSectionParser: FinancialDataSectionParserProtocol {
    
    // MARK: - Properties
    
    private let militaryTerminologyService: MilitaryAbbreviationsService
    
    // MARK: - Initialization
    
    init(militaryTerminologyService: MilitaryAbbreviationsService = MilitaryAbbreviationsService.shared) {
        self.militaryTerminologyService = militaryTerminologyService
    }
    
    // MARK: - Public Methods
    
    /// Parse earnings section from a document section
    /// - Parameter section: The document section containing earnings data
    /// - Returns: Dictionary of earnings items and their values
    func parseEarningsSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Look for patterns like "Item Name...........1234.56" or "Item Name: 1234.56"
        let pattern = "([A-Za-z\\s&\\-]+)[.:\\s]+(\\d+(?:[.,]\\d+)?)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = section.text as NSString
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let itemNameRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let itemName = nsString.substring(with: itemNameRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let valueString = nsString.substring(with: valueRange)
                    .replacingOccurrences(of: ",", with: "")
                
                if let value = Double(valueString), value > 0 {
                    // Normalize the item name using military terminology service
                    let normalizedName = militaryTerminologyService.normalizePayComponent(itemName)
                    result[normalizedName] = value
                }
            }
        }
        
        return result
    }
    
    /// Parse deductions section from a document section
    /// - Parameter section: The document section containing deductions data
    /// - Returns: Dictionary of deduction items and their values
    func parseDeductionsSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Look for patterns like "Item Name...........1234.56" or "Item Name: 1234.56"
        let pattern = "([A-Za-z\\s&\\-]+)[.:\\s]+(\\d+(?:[.,]\\d+)?)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = section.text as NSString
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let itemNameRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let itemName = nsString.substring(with: itemNameRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let valueString = nsString.substring(with: valueRange)
                    .replacingOccurrences(of: ",", with: "")
                
                if let value = Double(valueString), value > 0 {
                    // Normalize the item name using military terminology service
                    let normalizedName = militaryTerminologyService.normalizePayComponent(itemName)
                    result[normalizedName] = value
                }
            }
        }
        
        return result
    }
    
    /// Parse tax section from a document section
    /// - Parameter section: The document section containing tax data
    /// - Returns: Dictionary of tax fields and their values
    func parseTaxSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Common tax info fields
        let patterns = [
            "incomeTax": "(?:Income Tax Deducted|Tax Deducted)[^:]*:[^\\n]*([0-9,.]+)",
            "edCess": "(?:Ed. Cess|Education Cess)[^:]*:[^\\n]*([0-9,.]+)",
            "totalTaxPayable": "(?:Total Tax|Tax Payable)[^:]*:[^\\n]*([0-9,.]+)",
            "grossSalary": "(?:Gross Salary|Gross Income)[^:]*:[^\\n]*([0-9,.]+)",
            "standardDeduction": "(?:Standard Deduction)[^:]*:[^\\n]*([0-9,.]+)",
            "netTaxableIncome": "(?:Net Taxable Income|Taxable Income)[^:]*:[^\\n]*([0-9,.]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([0-9,.\\-]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([0-9,.\\-]+)", options: .regularExpression) {
                    let valueString = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")
                    
                    if let value = Double(valueString) {
                        result[field] = value
                    }
                }
            }
        }
        
        return result
    }
    
    /// Parse DSOP section from a document section
    /// - Parameter section: The document section containing DSOP data
    /// - Returns: Dictionary of DSOP fields and their values
    func parseDSOPSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Common DSOP info fields
        let patterns = [
            "openingBalance": "(?:Opening Balance)[^:]*:[^\\n]*([0-9,.]+)",
            "subscription": "(?:Subscription|Monthly Contribution)[^:]*:[^\\n]*([0-9,.]+)",
            "miscAdjustment": "(?:Misc Adj|Adjustment)[^:]*:[^\\n]*([0-9,.]+)",
            "withdrawal": "(?:Withdrawal)[^:]*:[^\\n]*([0-9,.]+)",
            "refund": "(?:Refund)[^:]*:[^\\n]*([0-9,.]+)",
            "closingBalance": "(?:Closing Balance)[^:]*:[^\\n]*([0-9,.]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([0-9,.]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let valueString = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")
                    
                    if let value = Double(valueString) {
                        result[field] = value
                    }
                }
            }
        }
        
        return result
    }
}