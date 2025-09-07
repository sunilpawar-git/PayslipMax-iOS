import Foundation
import PDFKit

/// Namespace to contain data models, potentially avoiding naming conflicts with other modules or types.
enum Models {}

/// Model representing contact information extracted from payslips
struct ContactInfo: Codable, Hashable {
    /// Email addresses found in the payslip
    var emails: [String] = []

    /// Phone numbers found in the payslip
    var phoneNumbers: [String] = []

    /// Websites/URLs found in the payslip
    var websites: [String] = []

    /// Whether the contact info model contains any data
    var isEmpty: Bool {
        emails.isEmpty && phoneNumbers.isEmpty && websites.isEmpty
    }
}

// MARK: - Protocol Definitions

/// Protocol for models that support contact information
protocol ContactInfoProvider {
    /// Contact information extracted from the model
    var contactInfo: ContactInfo { get set }
}

/// Core identification properties for payslip models
protocol PayslipBaseProtocol {
    /// Unique identifier for the payslip
    var id: UUID { get set }
    /// Timestamp when the data was created or processed
    var timestamp: Date { get set }
}

/// Financial data properties for payslip models
protocol PayslipDataProtocol: PayslipBaseProtocol {
    var month: String { get set }
    var year: Int { get set }
    var credits: Double { get set }
    var debits: Double { get set }
    var dsop: Double { get set }
    var tax: Double { get set }
    var earnings: [String: Double] { get set }
    var deductions: [String: Double] { get set }
}

/// Sensitive data and encryption properties for payslip models
protocol PayslipEncryptionProtocol: PayslipBaseProtocol {
    var name: String { get set }
    var accountNumber: String { get set }
    var panNumber: String { get set }
    var isNameEncrypted: Bool { get set }
    var isAccountNumberEncrypted: Bool { get set }
    var isPanNumberEncrypted: Bool { get set }

    /// Encrypt sensitive data
    func encryptSensitiveData() async throws
    /// Decrypt sensitive data
    func decryptSensitiveData() async throws
}

/// Metadata and presentation properties for payslip models
protocol PayslipMetadataProtocol: PayslipBaseProtocol {
    var pdfData: Data? { get set }
    var pdfURL: URL? { get set }
    var isSample: Bool { get set }
    var source: String { get set }
    var status: String { get set }
    var notes: String? { get set }
}

/// Combined protocol for full payslip functionality
protocol PayslipProtocol: PayslipBaseProtocol, PayslipDataProtocol, PayslipEncryptionProtocol, PayslipMetadataProtocol {
    /// Get a comprehensive description of the payslip
    func getFullDescription() -> String

    /// Calculate the net amount
    func getNetAmount() -> Double

    /// Get the total tax amount
    func getTotalTax() -> Double
}

// MARK: - Default Protocol Implementations

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

extension PayslipDataProtocol {
    /// Default implementation for net amount calculation
    var netAmount: Double {
        return credits - debits
    }

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

extension PayslipEncryptionProtocol {
    /// Indicates whether all sensitive fields are marked as encrypted
    var isFullyEncrypted: Bool {
        return isNameEncrypted && isAccountNumberEncrypted && isPanNumberEncrypted
    }
}

extension PayslipMetadataProtocol {
    /// Computed property for PDF document
    var pdfDocument: PDFDocument? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)
    }
}

// MARK: - Type Aliases

/// Typealias to support gradual migration from PayslipItemProtocol to PayslipProtocol
typealias AnyPayslip = any PayslipProtocol
