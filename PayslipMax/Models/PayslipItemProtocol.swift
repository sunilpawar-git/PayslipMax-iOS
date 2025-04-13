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
/// MIGRATION GUIDE:
/// - For new code, use the appropriate focused protocol based on your needs:
///   - If you only need ID and timestamp: use PayslipBaseProtocol
///   - If you need financial data: use PayslipDataProtocol
///   - If you need encryption capabilities: use PayslipEncryptionProtocol
///   - If you need metadata/PDF properties: use PayslipMetadataProtocol
///   - If you need full functionality: use PayslipProtocol
///
/// - To update existing code:
///   1. Replace `any PayslipItemProtocol` with `AnyPayslip`
///   2. Replace methods with their newer equivalents (see deprecation messages)
///   3. Target completion for migration: 2025-06-01
///
/// New code should use the appropriate focused protocols when possible.
@available(*, deprecated, message: "Use the focused protocol hierarchy instead")
protocol PayslipItemProtocol: PayslipProtocol, Identifiable, Codable {
    // This protocol inherits all requirements from PayslipProtocol
    // which already includes all the requirements from the focused protocols
}

// MARK: - Core Identity Extensions

/// Extension providing basic identity-related functionality
/// 
/// MIGRATION PATH:
/// - These methods have direct equivalents in PayslipBaseProtocol and its extensions
/// - For displayId: implement your own extension on PayslipBaseProtocol
/// - For formattedTimestamp: implement your own extension on PayslipBaseProtocol
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

/// Financial data properties for the payslip item.
/// @deprecated Please use PayslipDataProtocol instead.
/// 
/// ## Migration Path
/// These methods have direct equivalents in `PayslipDataProtocol`:
///
/// 1. Replace `PayslipItemProtocol` with `PayslipDataProtocol` in your type declaration
/// 2. Implement required properties from `PayslipBaseProtocol` (id, timestamp)
/// 3. Financial data properties map directly:
///   - month → month
///   - year → year
///   - totalCredits → totalCredits
///   - totalDebits → totalDebits
///   - dsopContribution → dsopContribution
///   - taxDeduction → taxDeduction
///   - breakdownItems → Optional earningsBreakdown and deductionsBreakdown
///
/// Additionally, `PayslipDataProtocol` provides the `netAmount` calculation through a default implementation.
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

// MARK: - Metadata Extension (Deprecated)
/// Extension providing metadata-related functionality.
/// @deprecated Please use PayslipMetadataProtocol instead.
/// 
/// ## Migration Path
/// These methods should be implemented through the `PayslipMetadataProtocol`:
///
/// 1. Replace `PayslipItemProtocol` with `PayslipMetadataProtocol` in your type declaration
/// 2. Implement required properties from `PayslipBaseProtocol` (id, timestamp)
/// 3. Metadata properties map directly:
///   - employerName → employerName
///   - employeeId → employeeId
///   - department → department
///   - source → sourceDocumentInfo
///
/// Additional benefits of `PayslipMetadataProtocol` include stronger typing for document sources
/// and support for standardized metadata extraction.
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

// MARK: - PDF Extension (Deprecated)
/// Extension providing PDF-related functionality.
/// @deprecated Please use DocumentManagementProtocol instead.
/// 
/// ## Migration Path
/// These methods should be implemented through the `DocumentManagementProtocol`:
///
/// 1. Replace `PayslipItemProtocol` with `DocumentManagementProtocol` in your type declaration
/// 2. Implement required property from `PayslipBaseProtocol` (id)
/// 3. PDF properties map as follows:
///   - pdfData → documentData
///   - pdfThumbnail → generateThumbnail() method
///
/// Additional benefits of `DocumentManagementProtocol` include support for multiple document
/// formats, built-in validation, and integration with document storage services.
@available(*, deprecated, message: "Use DocumentManagementProtocol instead")
extension PayslipItemProtocol {
    // ... existing code ...
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
@available(*, deprecated, message: "Use AnyPayslip instead")
typealias AnyPayslipItem = any PayslipItemProtocol

/// Helper typealias that makes it clear which protocol should be used for new code
typealias AnyPayslip = any PayslipProtocol
