import Foundation
import PDFKit

/// Centralized factory for creating PayslipItem instances from various data sources
/// Eliminates duplicate creation logic across multiple services
class PayslipItemFactory {
    
    /// Creates an empty PayslipItem for initialization purposes
    /// - Returns: A basic PayslipItem with default values
    static func createEmpty() -> PayslipItem {
        return PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Unknown",
            year: Calendar.current.component(.year, from: Date()),
            credits: 0.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            name: "",
            accountNumber: "",
            panNumber: "",
            pdfData: nil
        )
    }
    
    /// Creates a sample PayslipItem for testing and preview purposes
    /// - Returns: A PayslipItem with realistic sample data
    static func createSample() -> PayslipItem {
        let sampleData = Data("Sample PDF data for testing".utf8)
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2024,
            credits: 75000.0,
            debits: 15000.0,
            dsop: 5000.0,
            tax: 8000.0,
            name: "John Doe",
            accountNumber: "12345678901",
            panNumber: "ABCDE1234F",
            pdfData: sampleData
        )
        
        // Add sample earnings
        payslip.earnings = [
            "BASIC PAY": 50000.0,
            "DA": 15000.0,
            "HRA": 10000.0
        ]
        
        // Add sample deductions
        payslip.deductions = [
            "CGHS": 1500.0,
            "NPS": 6000.0,
            "INSURANCE": 2000.0
        ]
        
        return payslip
    }
    
    /// Creates a PayslipItem from raw extracted data
    /// - Parameters:
    ///   - data: Dictionary of extracted key-value pairs
    ///   - pdfData: Raw PDF data to include in the PayslipItem
    /// - Returns: A configured PayslipItem with all financial data properly calculated
    static func createPayslipItem(
        from data: [String: String],
        pdfData: Data? = nil
    ) -> PayslipItem? {
        
        // Extract basic information with validation
        guard let basicInfo = extractBasicInfo(from: data) else {
            print("PayslipItemFactory: Insufficient basic data for PayslipItem creation")
            return nil
        }
        
        // Extract financial data
        let financialData = extractFinancialData(from: data)
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: basicInfo.month,
            year: basicInfo.year,
            credits: financialData.credits,
            debits: financialData.debits,
            dsop: financialData.dsop,
            tax: financialData.tax,
            name: basicInfo.name,
            accountNumber: basicInfo.accountNumber,
            panNumber: basicInfo.panNumber,
            pdfData: pdfData
        )
        
        // Add detailed earnings and deductions if available
        payslip.earnings = extractEarnings(from: data)
        payslip.deductions = extractDeductions(from: data)
        
        return payslip
    }
    
    /// Creates a PayslipItem from financial data dictionary (for pipeline processing)
    /// - Parameters:
    ///   - financialData: Dictionary containing financial values
    ///   - month: Optional month string
    ///   - year: Optional year integer
    ///   - pdfData: PDF data to include
    /// - Returns: A configured PayslipItem
    static func createPayslipItem(
        from financialData: [String: Double],
        month: String? = nil,
        year: Int? = nil,
        pdfData: Data
    ) -> PayslipItem {
        
        // Determine month and year
        let currentDate = Date()
        let calendar = Calendar.current
        let defaultYear = calendar.component(.year, from: currentDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let defaultMonth = dateFormatter.string(from: currentDate)
        
        let payslipMonth = month ?? defaultMonth
        let payslipYear = year ?? defaultYear
        
        // Extract financial values with safe defaults
        let credits = financialData["credits"] ?? 0.0
        let debits = financialData["debits"] ?? 0.0
        let dsop = financialData["DSOP"] ?? 0.0
        let tax = financialData["ITAX"] ?? 0.0
        
        // Create payslip
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: payslipMonth,
            year: payslipYear,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: "Military Personnel",
            accountNumber: "",
            panNumber: "",
            pdfData: pdfData
        )
        
        // Build earnings from financial data
        var earnings = [String: Double]()
        ["BPAY", "DA", "MSP", "RH12", "TPTA"].forEach { key in
            if let value = financialData[key] {
                earnings[key] = value
            }
        }
        payslip.earnings = earnings
        
        return payslip
    }
}

// MARK: - Private Helper Methods

private extension PayslipItemFactory {
    
    struct BasicInfo {
        let month: String
        let year: Int
        let name: String
        let accountNumber: String
        let panNumber: String
    }
    
    struct FinancialData {
        let credits: Double
        let debits: Double
        let tax: Double
        let dsop: Double
    }
    
    static func extractBasicInfo(from data: [String: String]) -> BasicInfo? {
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Validation
        guard !month.isEmpty, !yearString.isEmpty else {
            return nil
        }
        
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        return BasicInfo(
            month: month,
            year: year,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
    }
    
    static func extractFinancialData(from data: [String: String]) -> FinancialData {
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        return FinancialData(
            credits: credits,
            debits: debits,
            tax: tax,
            dsop: dsop
        )
    }
    
    static func extractEarnings(from data: [String: String]) -> [String: Double] {
        var earnings = [String: Double]()
        
        // Common earnings keys
        let earningsKeys = ["BPAY", "DA", "MSP", "RH12", "TPTA", "basicPay", "allowances"]
        
        for key in earningsKeys {
            if let valueString = data[key], let value = Double(valueString), value > 0 {
                earnings[key] = value
            }
        }
        
        return earnings
    }
    
    static func extractDeductions(from data: [String: String]) -> [String: Double] {
        var deductions = [String: Double]()
        
        // Common deductions keys
        let deductionsKeys = ["ITAX", "DSOP", "insurance", "pension", "deductions"]
        
        for key in deductionsKeys {
            if let valueString = data[key], let value = Double(valueString), value > 0 {
                deductions[key] = value
            }
        }
        
        return deductions
    }
    
    static func extractDouble(from string: String) -> Double {
        // Handle common number formats
        let cleanString = string
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanString) ?? 0.0
    }
}
