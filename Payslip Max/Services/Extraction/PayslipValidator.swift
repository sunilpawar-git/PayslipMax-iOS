import Foundation

/// Responsible for validating payslip data
class PayslipValidator {
    private let patternProvider: PatternProvider
    
    init(patternProvider: PatternProvider) {
        self.patternProvider = patternProvider
    }
    
    /// Validates financial data to ensure values are reasonable
    ///
    /// - Parameter data: The financial data to validate
    /// - Returns: Validated financial data
    func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        var validatedData: [String: Double] = [:]
        
        for (key, value) in data {
            // Skip values that are too small (likely errors)
            if value < 2 {
                continue
            }
            
            // Skip values that are unreasonably large (likely errors)
            if value > 10_000_000 {
                continue
            }
            
            // Add the validated value
            validatedData[key] = value
        }
        
        return validatedData
    }
    
    /// Categorizes an abbreviation as an earning or deduction using available heuristics
    ///
    /// - Parameters:
    ///   - abbreviation: The abbreviation to categorize
    ///   - value: The value associated with the abbreviation
    /// - Returns: Category type (earning, deduction, or unknown)
    func categorizeAbbreviation(_ abbreviation: String, value: Double) -> AbbreviationType {
        // Check if abbreviation is in standard components
        if patternProvider.standardEarningsComponents.contains(abbreviation) {
            return .earning
        }
        
        if patternProvider.standardDeductionsComponents.contains(abbreviation) {
            return .deduction
        }
        
        // Use heuristics to guess the type
        // Common earnings prefixes/keywords
        let earningsKeywords = ["PAY", "ALLOW", "BONUS", "ARREAR", "ARR", "SALARY", "WAGE", "STIPEND", "GRANT"]
        
        // Common deductions prefixes/keywords
        let deductionsKeywords = ["TAX", "FUND", "RECOVERY", "FEE", "CHARGE", "DEDUCT", "LOAN", "ADVANCE", "SUBSCRIPTION"]
        
        // Check if the abbreviation contains any earnings keywords
        for keyword in earningsKeywords {
            if abbreviation.contains(keyword) {
                return .earning
            }
        }
        
        // Check if the abbreviation contains any deductions keywords
        for keyword in deductionsKeywords {
            if abbreviation.contains(keyword) {
                return .deduction
            }
        }
        
        // Default to unknown
        return .unknown
    }
    
    /// Validates a month name
    /// - Parameter month: The month to validate
    /// - Returns: true if the month is valid, false otherwise
    func validateMonth(_ month: String) -> Bool {
        let monthNames = ["January", "February", "March", "April", "May", "June", 
                           "July", "August", "September", "October", "November", "December"]
        let shortMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        let normalizedMonth = month.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return monthNames.contains { $0.lowercased() == normalizedMonth } ||
                shortMonthNames.contains { $0.lowercased() == normalizedMonth }
    }
    
    /// Validates a year string
    /// - Parameter year: The year to validate
    /// - Returns: true if the year is valid, false otherwise
    func validateYear(_ year: String) -> Bool {
        guard let yearInt = Int(year) else { return false }
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Check if year is reasonable (not too far in past or future)
        return yearInt >= currentYear - 10 && yearInt <= currentYear + 2
    }
    
    /// Validates a DSOP value
    /// - Parameter value: The DSOP value to validate
    /// - Returns: true if the value is valid, false otherwise
    func isValidDSOPValue(_ value: Double) -> Bool {
        return value >= patternProvider.minimumDSOPAmount
    }
    
    /// Validates a tax value
    /// - Parameter value: The tax value to validate
    /// - Returns: true if the value is valid, false otherwise
    func isValidTaxValue(_ value: Double) -> Bool {
        return value >= patternProvider.minimumTaxAmount
    }
}

/// Enum for categorizing abbreviations
enum AbbreviationType {
    case earning
    case deduction
    case unknown
} 