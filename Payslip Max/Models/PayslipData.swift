import Foundation

/// Models namespace to avoid ambiguity with the PayslipData in PageAwarePayslipParser
enum Models {}

extension Models {
    /// A clean data model for displaying payslip information
    /// This serves as the single source of truth for the UI
    struct PayslipData: PayslipItemProtocol {
        // MARK: - PayslipItemProtocol Properties
        var id: UUID = UUID()
        var timestamp: Date = Date()
        
        // MARK: - Personal Details
        var name: String = ""
        var rank: String = ""
        var serviceNumber: String = ""
        var postedTo: String = ""
        
        // For backward compatibility
        var accountNumber: String = ""
        var panNumber: String = ""
        var month: String = ""
        var year: Int = 0
        
        // MARK: - Financial Summary
        var credits: Double = 0
        var debits: Double = 0
        var dsop: Double = 0
        var tax: Double = 0
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
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
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
        
        // MARK: - PayslipItemProtocol Methods
        func encryptSensitiveData() throws {
            // No-op for now since this is a value type
        }
        
        func decryptSensitiveData() throws {
            // No-op for now since this is a value type
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
    }
} 