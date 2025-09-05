import Foundation
import PDFKit

/// Namespace to contain data models, potentially avoiding naming conflicts with other modules or types.
enum Models {}

extension Models {
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
        
        // MARK: - Calculated Properties
        /// The calculated net income (Total Credits - Total Debits).
        var netIncome: Double {
            return totalCredits - totalDebits
        }
        
        // MARK: - PayslipEncryptionProtocol Methods
        /// No-op encryption method for the `PayslipData` value type.
        /// Encryption is typically handled by the persistent `PayslipItem` model.
        func encryptSensitiveData() async throws {
            // No-op for now since this is a value type
        }
        
        /// No-op decryption method for the `PayslipData` value type.
        /// Decryption is typically handled by the persistent `PayslipItem` model.
        func decryptSensitiveData() async throws {
            // No-op for now since this is a value type
        }
        
        // MARK: - PayslipMetadataProtocol Computed Properties
        var pdfDocument: PDFDocument? {
            guard let data = pdfData else { return nil }
            return PDFDocument(data: data)
        }
        
        // MARK: - PayslipProtocol Methods
        /// Generates a detailed, formatted string description of the payslip data.
        /// Includes personal details, financial summary, and breakdowns of earnings and deductions.
        /// - Returns: A multi-line string describing the payslip.
        func getFullDescription() -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            formatter.usesGroupingSeparator = true
            
            let creditsStr = formatter.string(from: NSNumber(value: credits)) ?? "\(credits)"
            let debitsStr = formatter.string(from: NSNumber(value: debits)) ?? "\(debits)"
            let dsopStr = formatter.string(from: NSNumber(value: dsop)) ?? "\(dsop)"
            let taxStr = formatter.string(from: NSNumber(value: tax)) ?? "\(tax)"
            let netStr = formatter.string(from: NSNumber(value: calculateNetAmount())) ?? "\(calculateNetAmount())"
            
            var description = """
            PAYSLIP DETAILS
            ---------------
            
            PERSONAL DETAILS:
            Name: \(name)
            Month: \(month)
            Year: \(year)
            
            FINANCIAL DETAILS:
            Credits: \(creditsStr)
            Debits: \(debitsStr)
            DSOP: \(dsopStr)
            Tax: \(taxStr)
            Net Amount: \(netStr)
            """
            
            // Add earnings breakdown if available
            if !earnings.isEmpty {
                description += "\n\nEARNINGS BREAKDOWN:"
                for (key, value) in earnings.sorted(by: { $0.key < $1.key }) {
                    if value > 0 {
                        let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                        description += "\n\(key): \(valueStr)"
                    }
                }
            }
            
            // Add deductions breakdown if available
            if !deductions.isEmpty {
                description += "\n\nDEDUCTIONS BREAKDOWN:"
                for (key, value) in deductions.sorted(by: { $0.key < $1.key }) {
                    if value > 0 {
                        let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                        description += "\n\(key): \(valueStr)"
                    }
                }
            }
            
            description += "\n\nGenerated by PayslipMax"
            
            return description
        }
        
        // MARK: - Helper Methods
        /// Calculates the net amount (credits - debits).
        /// This uses the primary `credits` and `debits` properties conforming to `PayslipDataProtocol`.
        /// - Returns: The calculated net amount.
        func calculateNetAmount() -> Double {
            return credits - debits
        }
        
        /// Indicates whether all sensitive fields (`name`, `accountNumber`, `panNumber`) are marked as encrypted.
        var isFullyEncrypted: Bool {
            return isNameEncrypted && isAccountNumberEncrypted && isPanNumberEncrypted
        }
        
        /// Calculates derived financial fields based on detailed earnings and deductions.
        /// Populates `totalCredits`, `totalDebits`, and `netRemittance` if they are zero.
        /// Updates the `credits`, `debits`, `earnings`, and `deductions` properties required by `PayslipProtocol`.
        mutating func calculateDerivedFields() {
            // If any values are missing, try to calculate them
            if totalCredits == 0 && !allEarnings.isEmpty {
                totalCredits = allEarnings.values.reduce(0, +)
            }
            
            if totalDebits == 0 && !allDeductions.isEmpty {
                totalDebits = allDeductions.values.reduce(0, +)
            }
            
            if netRemittance == 0 {
                netRemittance = totalCredits - totalDebits
            }
            
            // Update credits and debits to match protocol requirements
            credits = totalCredits
            debits = totalDebits
            
            // Update earnings and deductions dictionaries
            earnings = allEarnings
            deductions = allDeductions
        }
        
        /// Creates a `PayslipData` instance from a type conforming to `PayslipItemProtocol`.
        /// Extracts and maps relevant fields.
        /// - Parameter payslipItem: The source payslip item.
        /// - Returns: A new `PayslipData` instance populated with data from `payslipItem`.
        @available(*, deprecated, message: "Use initializer with PayslipProtocol instead")
        static func from(payslipItem: any PayslipItemProtocol) -> PayslipData {
            var data = PayslipData(from: PayslipItemFactory.createEmpty())
            
            // Personal details
            data.id = payslipItem.id
            data.timestamp = payslipItem.timestamp
            data.name = payslipItem.name
            data.accountNumber = payslipItem.accountNumber
            data.panNumber = payslipItem.panNumber
            data.month = payslipItem.month
            data.year = payslipItem.year
            
            // Financial summary
            data.totalCredits = payslipItem.credits
            data.totalDebits = payslipItem.debits
            data.dsop = payslipItem.dsop
            data.tax = payslipItem.tax
            data.incomeTax = payslipItem.tax
            data.netRemittance = payslipItem.credits - payslipItem.debits
            
            // Store all earnings and deductions
            data.allEarnings = payslipItem.earnings
            data.allDeductions = payslipItem.deductions
            
            // Standard earnings components - Updated to use new unified extraction keys
            data.basicPay = payslipItem.earnings["Basic Pay"] ?? payslipItem.earnings["BPAY"] ?? 0
            data.dearnessPay = payslipItem.earnings["Dearness Allowance"] ?? payslipItem.earnings["DA"] ?? 0
            data.militaryServicePay = payslipItem.earnings["Military Service Pay"] ?? payslipItem.earnings["MSP"] ?? 0
            
            // Handle the RH12 using correct unified extraction key
            let rh12Value = payslipItem.earnings["Risk and Hardship Allowance"] ?? payslipItem.earnings["RH12"] ?? payslipItem.deductions["RH12"] ?? 0
            print("PayslipData: Found RH12 value: \(rh12Value) from Risk and Hardship Allowance key")
            
            // Calculate miscCredits as the difference between total credits and known components
            let knownEarnings = data.basicPay + data.dearnessPay + data.militaryServicePay
            data.miscCredits = data.totalCredits - knownEarnings
            
            print("PayslipData: Basic Pay: \(data.basicPay), DA: \(data.dearnessPay), MSP: \(data.militaryServicePay)")
            print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(data.miscCredits)")
            
            return data
        }
        
        /// Creates a `PayslipData` instance from any type conforming to `PayslipProtocol`.
        /// Extracts and maps relevant fields, including standard components and metadata.
        /// Calculates miscellaneous credits based on known earnings components.
        /// - Parameter payslip: The source payslip object conforming to `PayslipProtocol`.
        init(from payslip: AnyPayslip) {
            // Personal details
            self.id = payslip.id
            self.timestamp = payslip.timestamp
            self.name = payslip.name
            self.accountNumber = payslip.accountNumber
            self.panNumber = payslip.panNumber
            self.month = payslip.month
            self.year = payslip.year
            
            // Financial summary
            self.totalCredits = payslip.credits
            self.totalDebits = payslip.debits
            self.dsop = payslip.dsop
            self.tax = payslip.tax
            self.incomeTax = payslip.tax
            self.netRemittance = payslip.credits - payslip.debits
            
            // Store all earnings and deductions
            self.allEarnings = payslip.earnings
            self.allDeductions = payslip.deductions
            
            // Standard earnings components - Updated to use new unified extraction keys
            self.basicPay = payslip.earnings["Basic Pay"] ?? payslip.earnings["BPAY"] ?? 0
            self.dearnessPay = payslip.earnings["Dearness Allowance"] ?? payslip.earnings["DA"] ?? 0
            self.militaryServicePay = payslip.earnings["Military Service Pay"] ?? payslip.earnings["MSP"] ?? 0
            
            // Handle the RH12 using correct unified extraction key
            let rh12Value = payslip.earnings["Risk and Hardship Allowance"] ?? payslip.earnings["RH12"] ?? payslip.deductions["RH12"] ?? 0
            print("PayslipData: Found RH12 value: \(rh12Value) from Risk and Hardship Allowance key")
            
            // Calculate miscCredits as the difference between total credits and known components
            let knownEarnings = self.basicPay + self.dearnessPay + self.militaryServicePay
            self.miscCredits = self.totalCredits - knownEarnings
            
            // Metadata
            self.pdfData = payslip.pdfData
            self.isSample = payslip.isSample
            self.source = payslip.source
            self.status = payslip.status
            
            print("PayslipData: Basic Pay: \(self.basicPay), DA: \(self.dearnessPay), MSP: \(self.militaryServicePay)")
            print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(self.miscCredits)")
        }
    }
} 