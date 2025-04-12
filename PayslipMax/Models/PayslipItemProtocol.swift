import Foundation
import PDFKit
import SwiftData

/// Protocol defining the interface for a payslip item.
///
/// This protocol is being deprecated in favor of the more focused protocol hierarchy:
/// - PayslipBaseProtocol: Core identification properties
/// - PayslipDataProtocol: Financial data properties
/// - PayslipEncryptionProtocol: Sensitive data and encryption properties
/// - PayslipMetadataProtocol: Metadata and presentation properties
/// - PayslipProtocol: Combined protocol for backward compatibility
///
/// New code should use the appropriate focused protocols when possible.
@available(*, deprecated, message: "Use the focused protocol hierarchy instead")
protocol PayslipItemProtocol: PayslipProtocol, Identifiable, Codable {
    // This protocol inherits all requirements from PayslipProtocol
    // which already includes all the requirements from the focused protocols
}

// MARK: - Core Identity Extensions

/// Extension providing basic identity-related functionality
@available(*, deprecated, message: "Use PayslipBaseProtocol instead")
extension PayslipItemProtocol {
    /// Returns a unique identifier string that can be used in UI elements
    var displayId: String {
        return id.uuidString.prefix(8).lowercased()
    }
    
    /// Returns the creation timestamp formatted as a string
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Financial Data Extensions

/// Extension providing financial data-related functionality
@available(*, deprecated, message: "Use PayslipDataProtocol instead")
extension PayslipItemProtocol {
    /// Returns the net amount (credits - debits)
    func calculateNetAmount() -> Double {
        return getNetAmount()
    }
    
    /// Returns true if the payslip has a positive balance
    var hasPositiveBalance: Bool {
        return calculateNetAmount() > 0
    }
    
    /// Formatted string representation of the net amount
    var formattedNetAmount: String {
        let amount = calculateNetAmount()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - Encryption Extensions

/// Extension providing encryption-related functionality
@available(*, deprecated, message: "Use PayslipEncryptionProtocol instead")
extension PayslipItemProtocol {
    /// Returns whether all sensitive fields are encrypted
    var areAllFieldsEncrypted: Bool {
        return isFullyEncrypted
    }
    
    /// Returns a masked version of the account number for display
    var maskedAccountNumber: String {
        if isAccountNumberEncrypted {
            return "••••••"
        }
        
        guard accountNumber.count > 4 else {
            return accountNumber
        }
        
        let visiblePart = accountNumber.suffix(4)
        return String(repeating: "•", count: accountNumber.count - 4) + visiblePart
    }
    
    /// Returns a masked version of the PAN number for display
    var maskedPanNumber: String {
        if isPanNumberEncrypted {
            return "••••••••••"
        }
        
        guard panNumber.count > 4 else {
            return panNumber
        }
        
        let visiblePart = panNumber.suffix(4)
        return String(repeating: "•", count: panNumber.count - 4) + visiblePart
    }
}

// MARK: - PDF and Metadata Extensions

/// Extension providing PDF and metadata-related functionality
@available(*, deprecated, message: "Use PayslipMetadataProtocol instead")
extension PayslipItemProtocol {
    /// Returns the PDF document if available
    var document: PDFDocument? {
        return pdfDocument
    }
    
    /// Returns true if the payslip has associated PDF data
    var hasPDF: Bool {
        return pdfData != nil
    }
    
    /// Returns a formatted description of the payslip
    func formattedDescription() -> String {
        return getFullDescription()
    }
    
    /// Returns a string representation of the payslip source
    var formattedSource: String {
        if isSample {
            return "\(source) (Sample)"
        }
        return source
    }
}

// MARK: - Factory Protocol

/// A protocol for factories that create payslip items.
protocol PayslipItemFactoryProtocol {
    /// Creates an empty payslip item.
    ///
    /// - Returns: An empty payslip item.
    static func createEmpty() -> AnyPayslip
    
    /// Creates a sample payslip item for testing or preview.
    ///
    /// - Returns: A sample payslip item.
    static func createSample() -> AnyPayslip
}

// MARK: - Typealias for Transition

/// Typealias to support gradual migration from PayslipItemProtocol to PayslipProtocol.
/// This allows existing code to continue using PayslipItemProtocol type parameters while
/// we transition to the new focused protocol hierarchy.
typealias AnyPayslipItem = any PayslipItemProtocol

/// Helper typealias that makes it clear which protocol should be used for new code
typealias AnyPayslip = any PayslipProtocol
