import Foundation

/// Enhanced validation result for PCDA financial extraction with AI intelligence
public enum PCDAValidationResult {
    case passed
    case failed(String)
    case warning(String)
    case enhanced(EnhancedValidationResult)

    var isValid: Bool {
        switch self {
        case .passed, .warning:
            return true
        case .enhanced(let result):
            return result.isValid
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
        case .enhanced(let result):
            return result.primaryIssue
        }
    }
}

/// Enhanced validation result with detailed AI analysis
public struct EnhancedValidationResult {
    let isValid: Bool
    let confidence: Double
    let primaryIssue: String?
    let secondaryIssues: [String]
    let suggestions: [String]
    let outlierAnalysis: OutlierDetectionResult?
}

/// Protocol for PCDA financial validation
public protocol PCDAFinancialValidatorProtocol {
    func validatePCDAExtraction(
        credits: [String: Double],
        debits: [String: Double],
        remittance: Double?
    ) -> PCDAValidationResult

    @MainActor
    func validateWithAI(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> PCDAValidationResult
}

/// Service responsible for validating PCDA financial data extraction accuracy
///
/// This validator enforces PCDA-specific rules and validates that extracted financial data
/// conforms to military payslip standards, particularly the Principal Controller of Defence
/// Accounts (PCDA) format requirements. Enhanced with AI-powered analysis and dynamic thresholds.
public class PCDAFinancialValidator: PCDAFinancialValidatorProtocol {
    
    // MARK: - Configuration

        /// Tolerance for floating point comparisons
    private let amountTolerance: Double = 1.0

    /// Enhanced validator for AI-powered validation
    private let enhancedValidator: PCDAEnhancedValidatorProtocol

    /// Basic validator for traditional validation
    private let basicValidator: PCDABasicValidatorProtocol

    // MARK: - Initialization

    public init() {
        self.enhancedValidator = PCDAEnhancedValidator()
        self.basicValidator = PCDABasicValidator()
    }

    public init(
        enhancedValidator: PCDAEnhancedValidatorProtocol,
        basicValidator: PCDABasicValidatorProtocol
    ) {
        self.enhancedValidator = enhancedValidator
        self.basicValidator = basicValidator
    }
    
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
        
        // PCDA Rule 1: Total Credits ≈ Total Debits (fundamental PCDA requirement)
        // Allow for reasonable discrepancies that can be handled by reconciliation
        if totalCredits > 0 && totalDebits > 0 {
            let creditDebitDifference = abs(totalCredits - totalDebits)
            let maxAllowedDifference = max(amountTolerance, totalCredits * 0.05) // 5% tolerance or minimum tolerance

            if creditDebitDifference > maxAllowedDifference {
                let message = "PCDA format violation: Total Credits (\(totalCredits)) ≠ Total Debits (\(totalDebits)). Difference: \(creditDebitDifference)"
                print("PCDAFinancialValidator: \(message)")
                return .failed(message)
            } else if creditDebitDifference > amountTolerance {
                // Small discrepancy - issue warning but allow validation to continue
                let message = "PCDA format discrepancy: Total Credits (\(totalCredits)) ≠ Total Debits (\(totalDebits)). Difference: \(creditDebitDifference). Reconciliation recommended."
                print("PCDAFinancialValidator: \(message)")
                return .warning(message)
            }
        }
        
        // Range validation for total amounts
        if let rangeValidation = basicValidator.validateAmountRanges(totalCredits: totalCredits, totalDebits: totalDebits, remittance: remittance) {
            return rangeValidation
        }

        // Remittance calculation validation
        if let remittance = remittance {
            if let remittanceValidation = basicValidator.validateRemittanceCalculation(
                totalCredits: totalCredits,
                totalDebits: totalDebits,
                remittance: remittance
            ) {
                return remittanceValidation
            }
        }

        // Component-level validation
        if let componentValidation = basicValidator.validateIndividualComponents(credits: credits, debits: debits) {
            return componentValidation
        }

        // Military pay scale validation
        if let scaleValidation = basicValidator.validateMilitaryPayScale(credits: credits) {
            return scaleValidation
        }
        
        print("PCDAFinancialValidator: All validations passed")
        return .passed
    }

    /// Validates PCDA extraction using AI-powered analysis with dynamic thresholds
    ///
    /// This enhanced validation method uses machine learning to:
    /// - Apply dynamic thresholds based on document context
    /// - Detect outliers using statistical analysis
    /// - Cross-reference with printed totals when available
    /// - Generate reconciliation suggestions
    ///
    /// - Parameters:
    ///   - extractedData: Dictionary of all extracted financial components
    ///   - printedTotals: Optional printed totals for cross-reference validation
    ///   - documentFormat: Document format type for context-aware validation
    /// - Returns: Enhanced validation result with AI analysis
    public func validateWithAI(
        extractedData: [String: Double],
        printedTotals: [String: Double]?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> PCDAValidationResult {

        return try await enhancedValidator.validateWithAI(
            extractedData: extractedData,
            printedTotals: printedTotals,
            documentFormat: documentFormat
        )
    }
    



}