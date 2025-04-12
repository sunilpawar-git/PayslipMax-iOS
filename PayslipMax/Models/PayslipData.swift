import Foundation
import PDFKit

/// Models namespace to avoid ambiguity with the PayslipData in PageAwarePayslipParser
enum Models {}

extension Models {
    /// A clean data model for displaying payslip information
    /// This serves as the single source of truth for the UI
    struct PayslipData: PayslipProtocol {
        // MARK: - PayslipBaseProtocol Properties
        var id: UUID = UUID()
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
        var notes: String? = nil
        
        // MARK: - Additional PayslipData-specific Properties
        var rank: String = ""
        var serviceNumber: String = ""
        var postedTo: String = ""
        
        // MARK: - Financial Summary
        var netRemittance: Double = 0
        var incomeTax: Double = 0
        
        // MARK: - Internal Financial Tracking
        private var _totalCredits: Double = 0
        private var _totalDebits: Double = 0
        private var _allEarnings: [String: Double] = [:]
        private var _allDeductions: [String: Double] = [:]
        
        var totalCredits: Double {
            get { return _totalCredits }
            set { _totalCredits = newValue }
        }
        
        var totalDebits: Double {
            get { return _totalDebits }
            set { _totalDebits = newValue }
        }
        
        var allEarnings: [String: Double] {
            get { return _allEarnings }
            set { _allEarnings = newValue }
        }
        
        var allDeductions: [String: Double] {
            get { return _allDeductions }
            set { _allDeductions = newValue }
        }
        
        // MARK: - Standard Components
        // Standard earnings
        var basicPay: Double = 0
        var dearnessPay: Double = 0
        var militaryServicePay: Double = 0
        var miscCredits: Double = 0
        
        // Standard deductions
        var agif: Double = 0
        var miscDebits: Double = 0
        
        // MARK: - Additional Details
        var paymentMethod: String = ""
        var bankAccount: String = ""
        
        // MARK: - DSOP Details
        var dsopOpeningBalance: Double? = nil
        var dsopClosingBalance: Double? = nil
        
        // MARK: - Contact Details
        var contactDetails: [String: String] = [:]
        
        // MARK: - Calculated Properties
        var netIncome: Double {
            return totalCredits - totalDebits
        }
        
        // MARK: - PayslipEncryptionProtocol Methods
        func encryptSensitiveData() throws {
            // No-op for now since this is a value type
        }
        
        func decryptSensitiveData() throws {
            // No-op for now since this is a value type
        }
        
        // MARK: - PayslipMetadataProtocol Computed Properties
        var pdfDocument: PDFDocument? {
            guard let data = pdfData else { return nil }
            return PDFDocument(data: data)
        }
        
        // MARK: - PayslipProtocol Methods
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
            
            description += "\n\nGenerated by Payslip Max"
            
            return description
        }
        
        // MARK: - Helper Methods
        func calculateNetAmount() -> Double {
            return credits - debits
        }
        
        var isFullyEncrypted: Bool {
            return isNameEncrypted && isAccountNumberEncrypted && isPanNumberEncrypted
        }
        
        /// Calculate the derived fields
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
        
        /// Create from a PayslipItem
        @available(*, deprecated, message: "Use initializer with PayslipProtocol instead")
        static func from(payslipItem: any PayslipItemProtocol) -> PayslipData {
            var data = PayslipData()
            
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
            
            // Standard earnings components 
            data.basicPay = payslipItem.earnings["BPAY"] ?? payslipItem.earnings["Basic Pay"] ?? 0
            data.dearnessPay = payslipItem.earnings["DA"] ?? payslipItem.earnings["Dearness Allowance"] ?? 0
            data.militaryServicePay = payslipItem.earnings["MSP"] ?? payslipItem.earnings["Military Service Pay"] ?? 0
            
            // Handle the RH12 special case - it's an earning but sometimes extracted as deduction
            let rh12Value = payslipItem.earnings["RH12"] ?? payslipItem.deductions["RH12"] ?? 0
            print("PayslipData: Found RH12 value: \(rh12Value)")
            
            // Calculate miscCredits as the difference between total credits and known components
            let knownEarnings = data.basicPay + data.dearnessPay + data.militaryServicePay
            data.miscCredits = data.totalCredits - knownEarnings
            
            print("PayslipData: Basic Pay: \(data.basicPay), DA: \(data.dearnessPay), MSP: \(data.militaryServicePay)")
            print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(data.miscCredits)")
            print("PayslipData: totalCredits: \(data.totalCredits), using 'Other Allowances' of \(data.miscCredits)")
            
            // Standard deductions
            data.dsop = payslipItem.dsop // Use the primary dsop value
            data.agif = payslipItem.deductions["AGIF"] ?? payslipItem.deductions["Army Group Insurance Fund"] ?? 0
            data.tax = payslipItem.tax // Use the primary tax value
            
            // Calculate miscDebits as the difference between total debits and known components
            let knownDeductions = data.dsop + data.tax + data.agif
            data.miscDebits = data.totalDebits - knownDeductions
            
            // Sanity check - ensure we're not showing negative values for misc items
            if data.miscCredits < 0 {
                data.miscCredits = 0
            }
            
            if data.miscDebits < 0 {
                data.miscDebits = 0
            }
            
            // Update protocol-required properties
            data.credits = data.totalCredits
            data.debits = data.totalDebits
            data.earnings = data.allEarnings
            data.deductions = data.allDeductions
            
            return data
        }
        
        /// Create from a PayslipProtocol
        static func from(payslip: any PayslipProtocol) -> PayslipData {
            var data = PayslipData()
            
            // PayslipBaseProtocol properties
            data.id = payslip.id
            data.timestamp = payslip.timestamp
            
            // PayslipDataProtocol properties
            data.month = payslip.month
            data.year = payslip.year
            data.credits = payslip.credits
            data.debits = payslip.debits
            data.dsop = payslip.dsop
            data.tax = payslip.tax
            data.earnings = payslip.earnings
            data.deductions = payslip.deductions
            
            // PayslipEncryptionProtocol properties
            data.name = payslip.name
            data.accountNumber = payslip.accountNumber
            data.panNumber = payslip.panNumber
            data.isNameEncrypted = payslip.isNameEncrypted
            data.isAccountNumberEncrypted = payslip.isAccountNumberEncrypted
            data.isPanNumberEncrypted = payslip.isPanNumberEncrypted
            
            // PayslipMetadataProtocol properties
            data.pdfData = payslip.pdfData
            data.pdfURL = payslip.pdfURL
            data.isSample = payslip.isSample
            data.source = payslip.source
            data.status = payslip.status
            data.notes = payslip.notes
            
            // Initialize PayslipData-specific properties
            data.totalCredits = payslip.credits
            data.totalDebits = payslip.debits
            data.incomeTax = payslip.tax
            data.netRemittance = payslip.credits - payslip.debits
            
            // Store all earnings and deductions
            data.allEarnings = payslip.earnings
            data.allDeductions = payslip.deductions
            
            // Standard earnings components 
            data.basicPay = payslip.earnings["BPAY"] ?? payslip.earnings["Basic Pay"] ?? 0
            data.dearnessPay = payslip.earnings["DA"] ?? payslip.earnings["Dearness Allowance"] ?? 0
            data.militaryServicePay = payslip.earnings["MSP"] ?? payslip.earnings["Military Service Pay"] ?? 0
            
            // Calculate miscCredits as the difference between total credits and known components
            let knownEarnings = data.basicPay + data.dearnessPay + data.militaryServicePay
            data.miscCredits = data.totalCredits - knownEarnings
            
            // Standard deductions
            data.agif = payslip.deductions["AGIF"] ?? payslip.deductions["Army Group Insurance Fund"] ?? 0
            
            // Calculate miscDebits as the difference between total debits and known components
            let knownDeductions = data.dsop + data.tax + data.agif
            data.miscDebits = data.totalDebits - knownDeductions
            
            // Sanity check - ensure we're not showing negative values for misc items
            if data.miscCredits < 0 {
                data.miscCredits = 0
            }
            
            if data.miscDebits < 0 {
                data.miscDebits = 0
            }
            
            return data
        }
    }
} 