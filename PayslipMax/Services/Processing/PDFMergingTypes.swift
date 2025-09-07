import Foundation

/// Configuration for result merging operations
struct ResultMergingConfiguration {
    /// Threshold for considering values as conflicting (relative difference)
    let conflictThreshold: Double
    /// Maximum reasonable value for financial data
    let maximumReasonableValue: Double
    /// Tolerance amount for totals validation
    let totalsToleranceAmount: Double
    
    /// Default configuration for payslip merging
    static let `default` = ResultMergingConfiguration(
        conflictThreshold: 0.05, // 5% difference threshold
        maximumReasonableValue: 1_000_000.0, // 10 lakh maximum
        totalsToleranceAmount: 1.0 // 1 rupee tolerance
    )
}
