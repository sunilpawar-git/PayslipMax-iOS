import Foundation
import PDFKit

/// A data structure representing processed and display-ready payslip information.
///
/// This struct conforms to `PayslipProtocol` and serves as a convenient container for payslip details,
/// often used for UI display or data transfer after initial parsing and processing.
/// It separates the display/transfer concerns from the persistent `@Model` `PayslipItem`.
struct PayslipData: PayslipProtocol, ContactInfoProvider {
        // MARK: - PayslipBaseProtocol Properties
        /// Unique identifier for the payslip data instance.
        var id: UUID = UUID()
        /// Timestamp when the data was created or processed.
        var timestamp: Date = Date()

        // MARK: - PayslipDataProtocol Properties
        var month: String = ""
        var year: Int = 0
        var credits: Double = 0
        var debits: Double = 0
        var dsop: Double = 0
        var tax: Double = 0
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]

        // MARK: - PayslipEncryptionProtocol Properties
        var name: String = ""
        var accountNumber: String = ""
        var panNumber: String = ""
        var isNameEncrypted: Bool = false
        var isAccountNumberEncrypted: Bool = false
        var isPanNumberEncrypted: Bool = false

        // MARK: - PayslipMetadataProtocol Properties
        var pdfData: Data? = nil
        var pdfURL: URL? = nil
        var isSample: Bool = false
        var source: String = "Manual"
        var status: String = "Active"
        /// Notes associated with the payslip.
        var notes: String? = nil

        // MARK: - Additional PayslipData-specific Properties
        /// Military rank of the payslip owner.
        var rank: String = ""
        /// Service number of the payslip owner.
        var serviceNumber: String = ""
        /// Unit or location the payslip owner is posted to.
        var postedTo: String = ""

        // MARK: - Contact Information
        /// Storage for contact information (emails, phones, websites)
        private var _contactInfo: ContactInfo? = nil

        /// Contact information extracted from the payslip (implements ContactInfoProvider)
        var contactInfo: ContactInfo {
            get {
                return _contactInfo ?? ContactInfo()
            }
            set {
                _contactInfo = newValue
            }
        }

        // MARK: - Financial Summary
        /// The final net amount paid/remitted.
        var netRemittance: Double = 0
        /// The calculated income tax amount.
        var incomeTax: Double = 0

        // MARK: - Internal Financial Tracking
        /// Internal storage for total credits, potentially before final adjustments.
        private var _totalCredits: Double = 0
        /// Internal storage for total debits, potentially before final adjustments.
        private var _totalDebits: Double = 0
        /// Internal storage for all earnings items.
        private var _allEarnings: [String: Double] = [:]
        /// Internal storage for all deductions items.
        private var _allDeductions: [String: Double] = [:]

        /// The total calculated credits (earnings).
        var totalCredits: Double {
            /// Internal storage for total credits.
            get { return _totalCredits }
            /// Internal storage for total credits.
            set { _totalCredits = newValue }
        }

        /// The total calculated debits (deductions).
        var totalDebits: Double {
            /// Internal storage for total debits.
            get { return _totalDebits }
            /// Internal storage for total debits.
            set { _totalDebits = newValue }
        }

        /// Dictionary containing all earnings items.
        var allEarnings: [String: Double] {
            /// Internal storage for all earnings.
            get { return _allEarnings }
            /// Internal storage for all earnings.
            set { _allEarnings = newValue }
        }

        /// Dictionary containing all deductions items.
        var allDeductions: [String: Double] {
            /// Internal storage for all deductions.
            get { return _allDeductions }
            /// Internal storage for all deductions.
            set { _allDeductions = newValue }
        }

        // MARK: - Standard Components
        // Standard earnings
        /// Basic Pay amount.
        var basicPay: Double = 0
        /// Dearness Pay amount.
        var dearnessPay: Double = 0
        /// Military Service Pay amount.
        var militaryServicePay: Double = 0
        /// Miscellaneous credits not categorized elsewhere.
        var miscCredits: Double = 0

        // Standard deductions
        /// Armed Forces Group Insurance Fund deduction.
        var agif: Double = 0
        /// Miscellaneous debits not categorized elsewhere.
        var miscDebits: Double = 0

        // MARK: - Additional Details
        /// Method of payment (e.g., "Bank Transfer").
        var paymentMethod: String = ""
        /// Bank account details associated with the payment.
        var bankAccount: String = ""

        // MARK: - DSOP Details
        /// Opening balance for the DSOP fund for the period.
        var dsopOpeningBalance: Double? = nil
        /// Closing balance for the DSOP fund for the period.
        var dsopClosingBalance: Double? = nil

        // MARK: - Contact Details
        /// Dictionary storing contact information extracted from the payslip.
        var contactDetails: [String: String] = [:]

        // MARK: - Initialization
        /// Default initializer
        init() {}

        /// Convenience initializer for creating empty payslip data
        init(id: UUID = UUID(), timestamp: Date = Date()) {
            self.id = id
            self.timestamp = timestamp
        }
    }
