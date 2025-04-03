import Foundation
import PDFKit
import Combine

/// Main service for extracting data from payslip PDFs
class PayslipExtractorService {
    
    // MARK: - Properties
    
    private let patternExtractor: PatternBasedExtractor
    private let patternRepository: PatternRepositoryProtocol
    
    // MARK: - Initialization
    
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
        self.patternExtractor = PatternBasedExtractor(patternRepository: patternRepository)
    }
    
    // MARK: - Public Methods
    
    /// Extract payslip data from a PDFDocument
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipData {
        // Extract all data using patterns
        let extractedData = try await patternExtractor.extractData(from: pdfDocument)
        
        // Map the extracted data to a PayslipData model
        let payslipData = mapToPayslipData(extractedData)
        
        return payslipData
    }
    
    /// Extract payslip data from a PDF file URL
    func extractPayslipData(from pdfURL: URL) async throws -> PayslipData {
        // Create a PDF document from the URL
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Extract data from the document
        return try await extractPayslipData(from: pdfDocument)
    }
    
    /// Extract payslip data from raw PDF data
    func extractPayslipData(from pdfData: Data) async throws -> PayslipData {
        // Create a PDF document from the data
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Extract data from the document
        return try await extractPayslipData(from: pdfDocument)
    }
    
    // MARK: - Helper Methods
    
    /// Map the extracted data dictionary to a structured PayslipData model
    private func mapToPayslipData(_ extractedData: [String: String]) -> PayslipData {
        var payslipData = PayslipData()
        
        // Map personal information
        payslipData.name = extractedData["name"]
        payslipData.rank = extractedData["rank"]
        
        // Map date information
        if let month = extractedData["month"], let year = extractedData["year"] {
            payslipData.month = month
            payslipData.year = year
            
            // Try to parse the date
            if let monthIndex = getMonthIndex(from: month), let yearInt = Int(year) {
                let dateComponents = DateComponents(year: yearInt, month: monthIndex)
                if let date = Calendar.current.date(from: dateComponents) {
                    payslipData.date = date
                }
            }
        }
        
        // Map earnings
        var earnings = [ExtractedPayslipItem]()
        if let basicPay = extractedData["basicPay"] {
            earnings.append(ExtractedPayslipItem(name: "Basic Pay", value: basicPay))
        }
        if let da = extractedData["da"] {
            earnings.append(ExtractedPayslipItem(name: "Dearness Allowance", value: da))
        }
        if let msp = extractedData["msp"] {
            earnings.append(ExtractedPayslipItem(name: "Military Service Pay", value: msp))
        }
        
        // Add any other earnings found in the data
        for (key, value) in extractedData {
            if key.starts(with: "earnings.") {
                let itemName = String(key.dropFirst("earnings.".count))
                earnings.append(ExtractedPayslipItem(name: itemName, value: value))
            }
        }
        
        payslipData.earnings = earnings
        payslipData.totalEarnings = extractedData["totalCredits"]
        
        // Map deductions
        var deductions = [ExtractedPayslipItem]()
        if let dsop = extractedData["dsop"] {
            deductions.append(ExtractedPayslipItem(name: "DSOP Fund", value: dsop))
        }
        if let agif = extractedData["agif"] {
            deductions.append(ExtractedPayslipItem(name: "AGIF", value: agif))
        }
        if let incomeTax = extractedData["incomeTax"] {
            deductions.append(ExtractedPayslipItem(name: "Income Tax", value: incomeTax))
        }
        
        // Add any other deductions found in the data
        for (key, value) in extractedData {
            if key.starts(with: "deductions.") {
                let itemName = String(key.dropFirst("deductions.".count))
                deductions.append(ExtractedPayslipItem(name: itemName, value: value))
            }
        }
        
        payslipData.deductions = deductions
        payslipData.totalDeductions = extractedData["totalDebits"]
        
        // Calculate net amount if it wasn't explicitly extracted
        if payslipData.netAmount == nil {
            if let totalEarnings = payslipData.totalEarnings?.extractNumber(),
               let totalDeductions = payslipData.totalDeductions?.extractNumber() {
                let netAmount = totalEarnings - totalDeductions
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = "₹"
                if let formattedNet = formatter.string(from: NSNumber(value: netAmount)) {
                    payslipData.netAmount = formattedNet
                }
            }
        }
        
        // Map banking information
        payslipData.accountNumber = extractedData["accountNumber"]
        
        // Map tax information
        payslipData.panNumber = extractedData["panNumber"]
        
        return payslipData
    }
    
    /// Get the month index from a month name
    private func getMonthIndex(from monthName: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        // Try with full month name
        if let date = dateFormatter.date(from: monthName) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Try with abbreviated month name
        dateFormatter.dateFormat = "MMM"
        if let date = dateFormatter.date(from: monthName) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        return nil
    }
}

// MARK: - Helper Extensions

extension String {
    /// Extract a numeric value from a string (e.g., "₹1,234.56" -> 1234.56)
    func extractNumber() -> Double {
        let numericString = self.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(numericString) ?? 0.0
    }
}

// MARK: - Model Structures

/// Represents a payslip data model
struct PayslipData {
    // Personal information
    var name: String?
    var rank: String?
    var date: Date?
    var month: String?
    var year: String?
    
    // Earnings
    var earnings: [ExtractedPayslipItem] = []
    var totalEarnings: String?
    
    // Deductions
    var deductions: [ExtractedPayslipItem] = []
    var totalDeductions: String?
    
    // Net amount
    var netAmount: String?
    
    // Banking information
    var accountNumber: String?
    
    // Tax information
    var panNumber: String?
}

/// Represents a single item in a payslip (either earning or deduction)
struct ExtractedPayslipItem {
    var name: String
    var value: String
} 