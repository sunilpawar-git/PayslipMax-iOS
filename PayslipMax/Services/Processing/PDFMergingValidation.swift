import Foundation

/// Handles validation logic for PDF result merging operations
final class PDFMergingValidation {
    
    // MARK: - Properties
    
    private let configuration: ResultMergingConfiguration
    
    // MARK: - Initialization
    
    init(configuration: ResultMergingConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Validates merged results for consistency and quality
    /// - Parameter results: Merged results to validate
    /// - Returns: Validated results dictionary
    func validateMergedResults(_ results: [String: Double]) async -> [String: Double] {
        var validatedResults = results
        
        // Remove obviously invalid values
        validatedResults = validatedResults.filter { key, value in
            guard value >= 0 else {
                print("[PDFMergingValidation] Removing negative value for \(key): \(value)")
                return false
            }
            
            guard value <= configuration.maximumReasonableValue else {
                print("[PDFMergingValidation] Removing unreasonably large value for \(key): \(value)")
                return false
            }
            
            return true
        }
        
        // Validate totals consistency if present
        validateTotalsConsistency(&validatedResults)
        
        return validatedResults
    }
    
    // MARK: - Private Implementation
    
    /// Validates that earnings and deductions totals are consistent with individual items
    /// - Parameter results: Results dictionary to validate (modified in place)
    private func validateTotalsConsistency(_ results: inout [String: Double]) {
        let earningsTotal = results["credits"] ?? results["gross_pay"]
        let deductionsTotal = results["debits"] ?? results["total_deductions"]
        
        if let expectedEarnings = earningsTotal {
            let actualEarnings = calculateEarningsSum(from: results)
            let difference = abs(expectedEarnings - actualEarnings)
            
            if difference > configuration.totalsToleranceAmount {
                print("[PDFMergingValidation] Earnings total inconsistency: expected \(expectedEarnings), calculated \(actualEarnings)")
            }
        }
        
        if let expectedDeductions = deductionsTotal {
            let actualDeductions = calculateDeductionsSum(from: results)
            let difference = abs(expectedDeductions - actualDeductions)
            
            if difference > configuration.totalsToleranceAmount {
                print("[PDFMergingValidation] Deductions total inconsistency: expected \(expectedDeductions), calculated \(actualDeductions)")
            }
        }
    }
    
    /// Calculates sum of earnings from individual items
    /// - Parameter results: Financial data dictionary
    /// - Returns: Sum of earnings items
    private func calculateEarningsSum(from results: [String: Double]) -> Double {
        let earningsCodes = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA"]
        return earningsCodes.compactMap { results[$0] }.reduce(0, +)
    }
    
    /// Calculates sum of deductions from individual items
    /// - Parameter results: Financial data dictionary
    /// - Returns: Sum of deduction items
    private func calculateDeductionsSum(from results: [String: Double]) -> Double {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "EHCESS"]
        return deductionCodes.compactMap { results[$0] }.reduce(0, +)
    }
}
