import Foundation

/// Validation result for PCDA financial extraction
public enum PCDAValidationResult {
    case passed
    case failed(String)
    case warning(String)
    
    var isValid: Bool {
        switch self {
        case .passed, .warning:
            return true
        case .failed:
            return false
        }
    }
    
    var message: String? {
        switch self {
        case .passed:
            return nil
        case .failed(let message), .warning(let message):
            return message
        }
    }
}

/// Protocol for PCDA financial validation
public protocol PCDAFinancialValidatorProtocol {
    func validatePCDAExtraction(
        credits: [String: Double],
        debits: [String: Double],
        remittance: Double?
    ) -> PCDAValidationResult
}

/// Service responsible for validating PCDA financial data extraction accuracy
///
/// This validator enforces PCDA-specific rules and validates that extracted financial data
/// conforms to military payslip standards, particularly the Principal Controller of Defence
/// Accounts (PCDA) format requirements.
public class PCDAFinancialValidator: PCDAFinancialValidatorProtocol {
    
    // MARK: - Configuration
    
    /// Tolerance for floating point comparisons
    private let amountTolerance: Double = 1.0
    
    /// Maximum reasonable values for military pay components (in INR)
    private let maxReasonableValues: [String: Double] = [
        "BASIC_PAY": 500_000,
        "DA": 300_000,
        "HRA": 200_000,
        "TOTAL_CREDITS": 1_000_000,
        "TOTAL_DEBITS": 800_000,
        "NET_REMITTANCE": 800_000
    ]
    
    /// Minimum reasonable values for military pay components (in INR)
    private let minReasonableValues: [String: Double] = [
        "BASIC_PAY": 10_000,
        "DA": 5_000,
        "TOTAL_CREDITS": 15_000,
        "TOTAL_DEBITS": 1_000,
        "NET_REMITTANCE": 5_000
    ]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Validates PCDA financial data extraction
    ///
    /// Performs comprehensive validation of extracted PCDA financial data including:
    /// - PCDA format rule: Total Credits = Total Debits
    /// - Remittance calculation validation
    /// - Range checks for military pay scales
    /// - Component reasonableness checks
    ///
    /// - Parameters:
    ///   - credits: Dictionary of credit/earning components and amounts
    ///   - debits: Dictionary of debit/deduction components and amounts
    ///   - remittance: Optional net remittance amount
    /// - Returns: Validation result indicating success, failure, or warnings
    public func validatePCDAExtraction(
        credits: [String: Double],
        debits: [String: Double],
        remittance: Double?
    ) -> PCDAValidationResult {
        
        print("PCDAFinancialValidator: Starting validation - credits: \(credits.count), debits: \(debits.count)")
        
        // Basic data presence check
        if credits.isEmpty && debits.isEmpty {
            return .failed("No financial data extracted")
        }
        
        let totalCredits = credits.values.reduce(0, +)
        let totalDebits = debits.values.reduce(0, +)
        
        print("PCDAFinancialValidator: Total credits: \(totalCredits), Total debits: \(totalDebits)")
        
        // PCDA Rule 1: Total Credits = Total Debits (fundamental PCDA requirement)
        if totalCredits > 0 && totalDebits > 0 {
            let creditDebitDifference = abs(totalCredits - totalDebits)
            if creditDebitDifference > amountTolerance {
                let message = "PCDA format violation: Total Credits (\(totalCredits)) ≠ Total Debits (\(totalDebits)). Difference: \(creditDebitDifference)"
                print("PCDAFinancialValidator: \(message)")
                return .failed(message)
            }
        }
        
        // Range validation for total amounts
        if let rangeValidation = validateAmountRanges(totalCredits: totalCredits, totalDebits: totalDebits, remittance: remittance) {
            return rangeValidation
        }
        
        // Remittance calculation validation
        if let remittance = remittance {
            if let remittanceValidation = validateRemittanceCalculation(
                totalCredits: totalCredits,
                totalDebits: totalDebits,
                remittance: remittance
            ) {
                return remittanceValidation
            }
        }
        
        // Component-level validation
        if let componentValidation = validateIndividualComponents(credits: credits, debits: debits) {
            return componentValidation
        }
        
        // Military pay scale validation
        if let scaleValidation = validateMilitaryPayScale(credits: credits) {
            return scaleValidation
        }
        
        print("PCDAFinancialValidator: All validations passed")
        return .passed
    }
    
    // MARK: - Private Validation Methods
    
    /// Validates amount ranges for reasonableness
    private func validateAmountRanges(totalCredits: Double, totalDebits: Double, remittance: Double?) -> PCDAValidationResult? {
        // Validate total credits range
        if totalCredits > 0 {
            if totalCredits > maxReasonableValues["TOTAL_CREDITS"]! {
                return .warning("Total credits (\(totalCredits)) exceeds typical military pay range")
            }
            if totalCredits < minReasonableValues["TOTAL_CREDITS"]! {
                return .warning("Total credits (\(totalCredits)) below typical military pay range")
            }
        }
        
        // Validate total debits range
        if totalDebits > 0 {
            if totalDebits > maxReasonableValues["TOTAL_DEBITS"]! {
                return .warning("Total debits (\(totalDebits)) exceeds typical deduction range")
            }
        }
        
        // Validate remittance range
        if let remittance = remittance {
            if remittance > maxReasonableValues["NET_REMITTANCE"]! {
                return .warning("Net remittance (\(remittance)) exceeds typical range")
            }
            if remittance < minReasonableValues["NET_REMITTANCE"]! {
                return .warning("Net remittance (\(remittance)) below typical range")
            }
        }
        
        return nil
    }
    
    /// Validates remittance calculation consistency
    private func validateRemittanceCalculation(totalCredits: Double, totalDebits: Double, remittance: Double) -> PCDAValidationResult? {
        // For PCDA format, remittance is usually shown separately
        // But we can validate it against the credit-debit calculation if meaningful
        
        if totalCredits > 0 && totalDebits > 0 {
            // In PCDA, typically Credits = Debits, so remittance would be calculated differently
            // This is more of a consistency check
            let calculatedNet = totalCredits - totalDebits
            let remittanceDifference = abs(remittance - calculatedNet)
            
            // Only flag if there's a significant discrepancy and both values are substantial
            if remittanceDifference > (totalCredits * 0.1) && remittance > 10000 {
                return .warning("Remittance (\(remittance)) doesn't align with calculated net (\(calculatedNet))")
            }
        }
        
        return nil
    }
    
    /// Validates individual financial components
    private func validateIndividualComponents(credits: [String: Double], debits: [String: Double]) -> PCDAValidationResult? {
        // Validate credits
        for (component, amount) in credits {
            if amount <= 0 {
                return .warning("Credit component '\(component)' has non-positive amount: \(amount)")
            }
            
            // Check for obviously wrong amounts
            if amount > 1_000_000 { // 10 lakh seems excessive for individual components
                return .warning("Credit component '\(component)' has unusually high amount: \(amount)")
            }
        }
        
        // Validate debits
        for (component, amount) in debits {
            if amount <= 0 {
                return .warning("Debit component '\(component)' has non-positive amount: \(amount)")
            }
            
            if amount > 500_000 { // 5 lakh seems high for individual deductions
                return .warning("Debit component '\(component)' has unusually high amount: \(amount)")
            }
        }
        
        return nil
    }
    
    /// Validates military pay scale relationships
    private func validateMilitaryPayScale(credits: [String: Double]) -> PCDAValidationResult? {
        // Look for basic pay component
        let basicPayKeys = credits.keys.filter { key in
            let upperKey = key.uppercased()
            return upperKey.contains("BASIC") || upperKey.contains("BPAY") || upperKey == "PAY"
        }
        
        if let basicPayKey = basicPayKeys.first {
            let basicPay = credits[basicPayKey]!
            
            // Validate basic pay range
            if basicPay > maxReasonableValues["BASIC_PAY"]! {
                return .warning("Basic pay (\(basicPay)) exceeds typical military basic pay range")
            }
            if basicPay < minReasonableValues["BASIC_PAY"]! {
                return .warning("Basic pay (\(basicPay)) below typical military basic pay range")
            }
            
            // Validate DA relationship (DA is typically 50-100% of basic pay for military)
            let daKeys = credits.keys.filter { $0.uppercased().contains("DA") }
            if let daKey = daKeys.first {
                let da = credits[daKey]!
                let daRatio = da / basicPay
                
                if daRatio > 1.5 { // DA more than 150% of basic pay is unusual
                    return .warning("DA (\(da)) seems high relative to basic pay (\(basicPay))")
                }
                if daRatio < 0.3 { // DA less than 30% of basic pay is unusual
                    return .warning("DA (\(da)) seems low relative to basic pay (\(basicPay))")
                }
            }
        }
        
        return nil
    }
}