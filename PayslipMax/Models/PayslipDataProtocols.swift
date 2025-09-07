import Foundation
import PDFKit

/// Namespace to contain data models, potentially avoiding naming conflicts with other modules or types.
enum Models {}

// ContactInfo and ContactInfoProvider are defined in ContactInfo.swift

// MARK: - Type Aliases

// AnyPayslip is already defined in PayslipItemProtocol.swift

// MARK: - Utility Extensions

extension PayslipDataProtocol {
    /// Convenience method to get formatted financial amounts
    func getFormattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// isFullyEncrypted is already defined in PayslipEncryptionProtocol extension
