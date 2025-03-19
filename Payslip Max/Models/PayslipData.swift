import Foundation

/// Models namespace to avoid ambiguity with the PayslipData in PageAwarePayslipParser
enum Models {}

extension Models {
    /// A clean data model for displaying payslip information
    /// This serves as the single source of truth for the UI
    struct PayslipData {
        // MARK: - Personal Details
        var name: String = ""
        var rank: String = ""
        var serviceNumber: String = ""
        var postedTo: String = ""
        var location: String = ""
        
        // For backward compatibility
        var accountNumber: String = ""
        var panNumber: String = ""
        var month: String = ""
        var year: Int = 0
        
        // MARK: - Financial Summary
        var totalCredits: Double = 0
        var totalDebits: Double = 0
        var netRemittance: Double = 0
        
        // MARK: - Standard Components
        // Standard earnings
        var basicPay: Double = 0
        var dearnessPay: Double = 0
        var militaryServicePay: Double = 0
        var miscCredits: Double = 0
        
        // Standard deductions
        var dsop: Double = 0
        var agif: Double = 0
        var incomeTax: Double = 0
        var miscDebits: Double = 0
        
        // MARK: - Additional Details
        var allEarnings: [String: Double] = [:]
        var allDeductions: [String: Double] = [:]
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
        }
        
        /// Create from a PayslipItem
        static func from(payslipItem: any PayslipItemProtocol) -> PayslipData {
            var data = PayslipData()
            
            // Personal details
            data.name = payslipItem.name
            // Only set these if they are accessed from PayslipItem, not PayslipItemProtocol
            if let typedPayslip = payslipItem as? PayslipItem {
                data.accountNumber = typedPayslip.accountNumber
                data.panNumber = typedPayslip.panNumber
                data.month = typedPayslip.month
                data.year = typedPayslip.year
            }
            data.location = payslipItem.location
            
            // Financial summary
            data.totalCredits = payslipItem.credits
            data.totalDebits = payslipItem.debits
            data.netRemittance = payslipItem.calculateNetAmount()
            
            // Standard components (from earnings/deductions if available)
            data.allEarnings = payslipItem.earnings
            data.basicPay = payslipItem.earnings["BPAY"] ?? payslipItem.earnings["Basic Pay"] ?? 0
            data.dearnessPay = payslipItem.earnings["DA"] ?? payslipItem.earnings["Dearness Allowance"] ?? 0
            data.militaryServicePay = payslipItem.earnings["MSP"] ?? payslipItem.earnings["Military Service Pay"] ?? 0
            
            data.allDeductions = payslipItem.deductions
            data.agif = payslipItem.deductions["AGIF"] ?? payslipItem.deductions["Army Group Insurance Fund"] ?? 0
            data.dsop = payslipItem.dsop // Use the primary dsop value
            data.incomeTax = payslipItem.tax // Use the primary tax value
            
            // Calculate any missing derived values
            data.calculateDerivedFields()
            
            return data
        }
    }
} 