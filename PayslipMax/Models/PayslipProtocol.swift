import Foundation
import PDFKit

/// A protocol that combines all the focused protocols for Payslip.
/// This serves as a bridge for backward compatibility.
/// New code should use the more focused protocols when appropriate.
protocol PayslipProtocol: PayslipBaseProtocol, PayslipDataProtocol, PayslipEncryptionProtocol, PayslipMetadataProtocol {
    /// Get a comprehensive description of the payslip
    func getFullDescription() -> String
    
    /// Calculate the net amount
    func getNetAmount() -> Double
    
    /// Get the total tax amount
    func getTotalTax() -> Double
}

// MARK: - Default Implementations
extension PayslipProtocol {
    func getFullDescription() -> String {
        return "Payslip for \(month) \(year)"
    }
    
    func getNetAmount() -> Double {
        return credits - debits
    }
    
    func getTotalTax() -> Double {
        return tax
    }
} 