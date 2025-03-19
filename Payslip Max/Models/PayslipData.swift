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
                
                // Check for DSOP opening and closing balances
                if let dsopOpeningStr = typedPayslip.earnings["dsopOpeningBalance"] ?? typedPayslip.deductions["dsopOpeningBalance"],
                   dsopOpeningStr > 0 {
                    data.dsopOpeningBalance = dsopOpeningStr
                    print("PayslipData: Found DSOP opening balance: \(dsopOpeningStr)")
                }
                
                if let dsopClosingStr = typedPayslip.earnings["dsopClosingBalance"] ?? typedPayslip.deductions["dsopClosingBalance"],
                   dsopClosingStr > 0 {
                    data.dsopClosingBalance = dsopClosingStr
                    print("PayslipData: Found DSOP closing balance: \(dsopClosingStr)")
                }
                
                // Populate contact details - only extract ones that look like contact info
                for (key, value) in typedPayslip.earnings.merging(typedPayslip.deductions, uniquingKeysWith: { (first, _) in first }) {
                    if key.hasPrefix("contact") || key.contains("contact") || 
                       key.contains("email") || key.contains("website") || 
                       key.contains("phone") || key.contains("SAO") || 
                       key.contains("AAO") {
                        let displayKey = key.replacingOccurrences(of: "contact", with: "")
                                            .replacingOccurrences(of: "Email", with: "")
                                            .capitalized
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        data.contactDetails[displayKey] = String(describing: value)
                        print("PayslipData: Added contact detail: \(displayKey) = \(value)")
                    }
                }
            }
            data.location = payslipItem.location
            
            // Try to get the actual gross pay from the extracted earnings dictionary
            let grossPay = payslipItem.earnings["grossPay"] ?? payslipItem.earnings["Gross Pay"] ?? 0
            print("PayslipData: Raw grossPay value: \(grossPay), credits value: \(payslipItem.credits)")
            
            // Financial summary - prioritize grossPay if available, otherwise use credits
            data.totalCredits = grossPay > 0 ? grossPay : payslipItem.credits
            data.totalDebits = payslipItem.debits
            data.netRemittance = data.totalCredits - data.totalDebits
            
            print("PayslipData: Using totalCredits: \(data.totalCredits)")
            
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
            data.incomeTax = payslipItem.tax // Use the primary tax value
            
            // Calculate miscDebits as the difference between total debits and known components
            let knownDeductions = data.dsop + data.incomeTax + data.agif
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