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

// MARK: - Default Implementation

@available(*, deprecated, message: "Use the focused protocol extensions instead")
extension PayslipItemProtocol {
    var document: PDFDocument? {
        return pdfDocument
    }
    
    var areAllFieldsEncrypted: Bool {
        return isFullyEncrypted
    }
    
    func formattedDescription() -> String {
        return getFullDescription()
    }
    
    func calculateNetAmount() -> Double {
        return getNetAmount()
    }
}

// MARK: - Factory Protocol

/// A protocol for factories that create payslip items.
protocol PayslipItemFactoryProtocol {
    /// Creates an empty payslip item.
    ///
    /// - Returns: An empty payslip item.
    static func createEmpty() -> any PayslipItemProtocol
    
    /// Creates a sample payslip item for testing or preview.
    ///
    /// - Returns: A sample payslip item.
    static func createSample() -> any PayslipItemProtocol
}

// MARK: - Typealias for Transition

/// Typealias to support gradual migration from PayslipItemProtocol to PayslipProtocol.
/// This allows existing code to continue using PayslipItemProtocol type parameters while
/// we transition to the new focused protocol hierarchy.
typealias AnyPayslipItem = any PayslipItemProtocol

/// Helper typealias that makes it clear which protocol should be used for new code
typealias AnyPayslip = any PayslipProtocol
