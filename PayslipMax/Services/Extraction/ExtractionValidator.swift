import Foundation

/// Protocol defining simple extraction validation capabilities.
///
/// This service handles validation of extracted data and PayslipItem objects
/// to ensure data quality and completeness before processing.
protocol SimpleExtractionValidatorProtocol {
    /// Validates that essential data fields are present and valid.
    /// - Parameter data: Dictionary of extracted data to validate
    /// - Throws: ModularExtractionError if essential data is missing or invalid
    func validateEssentialData(_ data: [String: String]) throws
    
    /// Validates a PayslipItem for completeness and data integrity.
    /// - Parameter payslip: The PayslipItem to validate
    /// - Returns: True if the PayslipItem is valid, false otherwise
    func validatePayslipItem(_ payslip: PayslipItem) -> Bool
}

/// Service responsible for validating extraction completeness and quality.
///
/// This service provides validation logic to ensure that extracted data meets
/// minimum quality standards and contains all essential fields required for
/// a valid PayslipItem.
class ExtractionValidator: SimpleExtractionValidatorProtocol {
    
    /// Validates that essential data fields are present and valid.
    /// - Parameter data: Dictionary of extracted data to validate
    /// - Throws: ModularExtractionError if essential data is missing or invalid
    func validateEssentialData(_ data: [String: String]) throws {
        // Check for required fields
        guard hasRequiredFields(data) else {
            print("ExtractionValidator: Missing required fields")
            throw ModularExtractionError.insufficientData
        }
        
        // Check for valid numeric values
        guard hasValidNumericValues(data) else {
            print("ExtractionValidator: Invalid numeric values")
            throw ModularExtractionError.insufficientData
        }
        
        print("ExtractionValidator: Essential data validation passed")
    }
    
    /// Validates a PayslipItem for completeness and data integrity.
    /// - Parameter payslip: The PayslipItem to validate
    /// - Returns: True if the PayslipItem is valid, false otherwise
    func validatePayslipItem(_ payslip: PayslipItem) -> Bool {
        // Check basic required fields
        guard !payslip.month.isEmpty else {
            print("ExtractionValidator: PayslipItem missing month")
            return false
        }
        
        guard payslip.year > 1900 && payslip.year <= Calendar.current.component(.year, from: Date()) + 1 else {
            print("ExtractionValidator: PayslipItem has invalid year: \(payslip.year)")
            return false
        }
        
        // Check that at least some financial data is present
        guard payslip.credits > 0 else {
            print("ExtractionValidator: PayslipItem has no credits")
            return false
        }
        
        // Validate that debits don't exceed credits by an unreasonable margin
        if payslip.debits > payslip.credits * 2 {
            print("ExtractionValidator: PayslipItem has suspiciously high deductions")
            return false
        }
        
        print("ExtractionValidator: PayslipItem validation passed")
        return true
    }
    
    /// Checks if all required fields are present in the data.
    /// - Parameter data: Dictionary of extracted data
    /// - Returns: True if required fields are present, false otherwise
    private func hasRequiredFields(_ data: [String: String]) -> Bool {
        let requiredFields = ["month", "year"]
        
        for field in requiredFields {
            guard let value = data[field], !value.isEmpty else {
                print("ExtractionValidator: Missing required field: \(field)")
                return false
            }
        }
        
        return true
    }
    
    /// Checks if numeric values in the data are valid.
    /// - Parameter data: Dictionary of extracted data
    /// - Returns: True if numeric values are valid, false otherwise
    private func hasValidNumericValues(_ data: [String: String]) -> Bool {
        let numericFields = ["credits", "debits", "tax", "dsop"]
        
        for field in numericFields {
            if let value = data[field] {
                let cleaned = value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                if !cleaned.isEmpty && Double(cleaned) == nil {
                    print("ExtractionValidator: Invalid numeric value for \(field): \(value)")
                    return false
                }
            }
        }
        
        // Check that at least credits has a meaningful value
        if let creditsString = data["credits"] {
            let cleaned = creditsString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            let credits = Double(cleaned) ?? 0.0
            if credits <= 0 {
                print("ExtractionValidator: Credits must be greater than 0, got: \(credits)")
                return false
            }
        } else {
            print("ExtractionValidator: Credits field is required")
            return false
        }
        
        return true
    }
}