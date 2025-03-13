import Foundation
import PDFKit

/// Utility class for converting between different payslip data formats
class PayslipParsingUtility {
    
    /// Converts ParsedPayslipData from the enhanced parser to a PayslipItem
    /// - Parameter parsedData: The parsed data from EnhancedPDFParser
    /// - Parameter pdfData: The original PDF data
    /// - Returns: A PayslipItem populated with the parsed data
    static func convertToPayslipItem(from parsedData: ParsedPayslipData, pdfData: Data) -> PayslipItem {
        // Extract month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var month = "Unknown"
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateString = parsedData.metadata["statementDate"], !dateString.isEmpty {
            if let date = dateFormatter.date(from: dateString) {
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM"
                month = monthFormatter.string(from: date)
                year = Calendar.current.component(.year, from: date)
            }
        } else if let monthValue = parsedData.metadata["month"], !monthValue.isEmpty {
            month = monthValue
            
            if let yearValue = parsedData.metadata["year"], let yearInt = Int(yearValue) {
                year = yearInt
            }
        }
        
        // Calculate totals
        let totalEarnings = parsedData.earnings.values.reduce(0, +)
        let totalDeductions = parsedData.deductions.values.reduce(0, +)
        
        // Get tax and DSOP values
        let taxValue = parsedData.taxDetails["incomeTax"] ?? 0
        let dsopValue = parsedData.dsopDetails["subscription"] ?? 0
        
        // Create the payslip item
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: totalEarnings,
            debits: totalDeductions - taxValue - dsopValue,
            dsop: dsopValue,
            tax: taxValue,
            location: parsedData.personalInfo["location"] ?? "",
            name: parsedData.personalInfo["name"] ?? "",
            accountNumber: parsedData.personalInfo["accountNumber"] ?? "",
            panNumber: parsedData.personalInfo["panNumber"] ?? "",
            timestamp: Date(),
            pdfData: pdfData
        )
        
        // Set earnings and deductions
        payslip.earnings = parsedData.earnings
        payslip.deductions = parsedData.deductions
        
        return payslip
    }
    
    /// Normalizes earnings and deductions keys using the MilitaryAbbreviationsService
    /// - Parameter payslip: The payslip to normalize
    /// - Returns: The same payslip with normalized keys
    static func normalizePayslipComponents(_ payslip: PayslipItem) -> PayslipItem {
        // Normalize earnings keys
        var normalizedEarnings: [String: Double] = [:]
        for (key, value) in payslip.earnings {
            let normalizedKey = MilitaryAbbreviationsService.shared.normalizePayComponent(key)
            if let existingValue = normalizedEarnings[normalizedKey] {
                normalizedEarnings[normalizedKey] = existingValue + value
            } else {
                normalizedEarnings[normalizedKey] = value
            }
        }
        payslip.earnings = normalizedEarnings
        
        // Normalize deductions keys
        var normalizedDeductions: [String: Double] = [:]
        for (key, value) in payslip.deductions {
            let normalizedKey = MilitaryAbbreviationsService.shared.normalizePayComponent(key)
            if let existingValue = normalizedDeductions[normalizedKey] {
                normalizedDeductions[normalizedKey] = existingValue + value
            } else {
                normalizedDeductions[normalizedKey] = value
            }
        }
        payslip.deductions = normalizedDeductions
        
        return payslip
    }
    
    /// Extracts additional metadata from ParsedPayslipData to be used in PayslipDetailViewModel
    /// - Parameter parsedData: The parsed data from EnhancedPDFParser
    /// - Returns: A dictionary of extracted data
    static func extractAdditionalData(from parsedData: ParsedPayslipData) -> [String: String] {
        var extractedData: [String: String] = [:]
        
        // Add statement period
        if let statementDate = parsedData.metadata["statementDate"], !statementDate.isEmpty {
            extractedData["statementPeriod"] = statementDate
        }
        
        // Add income tax details
        for (key, value) in parsedData.taxDetails {
            extractedData["incomeTax\(key.capitalized)"] = String(format: "%.0f", value)
        }
        
        // Add DSOP details
        if let openingBalance = parsedData.dsopDetails["openingBalance"] {
            extractedData["dsopOpeningBalance"] = String(format: "%.0f", openingBalance)
        }
        
        if let subscription = parsedData.dsopDetails["subscription"] {
            extractedData["dsopSubscription"] = String(format: "%.0f", subscription)
        }
        
        if let miscAdj = parsedData.dsopDetails["miscAdjustment"] {
            extractedData["dsopMiscAdj"] = String(format: "%.0f", miscAdj)
        }
        
        if let withdrawal = parsedData.dsopDetails["withdrawal"] {
            extractedData["dsopWithdrawal"] = String(format: "%.0f", withdrawal)
        }
        
        if let refund = parsedData.dsopDetails["refund"] {
            extractedData["dsopRefund"] = String(format: "%.0f", refund)
        }
        
        if let closingBalance = parsedData.dsopDetails["closingBalance"] {
            extractedData["dsopClosingBalance"] = String(format: "%.0f", closingBalance)
        }
        
        return extractedData
    }
} 