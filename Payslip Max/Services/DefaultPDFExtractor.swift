import Foundation
import PDFKit

/// Default implementation of the PDFExtractorProtocol.
///
/// This class provides a basic implementation of PDF data extraction
/// for payslip documents.
class DefaultPDFExtractor: PDFExtractorProtocol {
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document.
    ///
    /// - Parameter document: The PDF document to extract data from.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    func extractPayslipData(from document: PDFDocument) async throws -> any PayslipItemProtocol {
        var extractedText = ""
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            extractedText += page.string ?? ""
        }
        
        if extractedText.isEmpty {
            throw PDFExtractionError.textExtractionFailed
        }
        
        return try parsePayslipData(from: extractedText)
    }
    
    /// Parses payslip data from text.
    ///
    /// - Parameter text: The text to parse.
    /// - Returns: A payslip item containing the parsed data.
    /// - Throws: An error if parsing fails.
    func parsePayslipData(from text: String) throws -> any PayslipItemProtocol {
        // Create a new PayslipItem with all required parameters
        var name = ""
        var credits = 0.0
        var month = "1"
        var year = Calendar.current.component(.year, from: Date())
        var timestamp = Date()
        let location = ""
        let accountNumber = ""
        let panNumber = ""
        var debits = 0.0
        var dspof = 0.0
        var tax = 0.0
        
        // Basic parsing example
        let lines = text.components(separatedBy: .newlines)
        
        // Enhanced parsing logic
        for line in lines {
            // Name extraction
            if line.contains("Name:") || line.contains("Employee Name:") {
                name = extractValue(from: line, prefix: ["Name:", "Employee Name:"])
            }
            
            // Amount/Credits extraction
            if line.contains("Amount:") || line.contains("Gross Pay:") || line.contains("Total Earnings:") {
                let amountString = extractValue(from: line, prefix: ["Amount:", "Gross Pay:", "Total Earnings:"])
                credits = parseAmount(amountString)
            }
            
            // Date extraction
            if line.contains("Date:") || line.contains("Pay Date:") || line.contains("Payment Date:") {
                let dateString = extractValue(from: line, prefix: ["Date:", "Pay Date:", "Payment Date:"])
                if let parsedDate = parseDate(dateString) {
                    timestamp = parsedDate
                    // Also update month and year from the parsed date
                    let calendar = Calendar.current
                    month = getMonthName(from: calendar.component(.month, from: parsedDate))
                    year = calendar.component(.year, from: parsedDate)
                }
            }
            
            // Deductions extraction
            if line.contains("Deductions:") || line.contains("Total Deductions:") {
                let deductionsString = extractValue(from: line, prefix: ["Deductions:", "Total Deductions:"])
                debits = parseAmount(deductionsString)
            }
            
            // Tax extraction
            if line.contains("Tax:") || line.contains("Income Tax:") || line.contains("Tax Deducted:") {
                let taxString = extractValue(from: line, prefix: ["Tax:", "Income Tax:", "Tax Deducted:"])
                tax = parseAmount(taxString)
            }
            
            // DSPOF extraction (Defense Services Officers Provident Fund)
            if line.contains("DSPOF:") || line.contains("Provident Fund:") || line.contains("PF:") {
                let dspofString = extractValue(from: line, prefix: ["DSPOF:", "Provident Fund:", "PF:"])
                dspof = parseAmount(dspofString)
            }
            
            // Location extraction
            if line.contains("Location:") || line.contains("Office:") || line.contains("Branch:") {
                let locationValue = extractValue(from: line, prefix: ["Location:", "Office:", "Branch:"])
                if !locationValue.isEmpty {
                    // Use a mutable local variable since location is a let constant
                    var mutableLocation = location
                    mutableLocation = locationValue
                    // Create a new PayslipItem with the updated location
                    return PayslipItem(
                        month: month,
                        year: year,
                        credits: credits,
                        debits: debits,
                        dspof: dspof,
                        tax: tax,
                        location: mutableLocation,
                        name: name,
                        accountNumber: accountNumber,
                        panNumber: panNumber,
                        timestamp: timestamp
                    )
                }
            }
        }
        
        // Create a new PayslipItem with the parsed data
        return PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dspof: dspof,
            tax: tax,
            location: location,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: timestamp
        )
    }
    
    // MARK: - Helper Methods
    
    /// Extracts a value from a line of text by removing prefixes.
    ///
    /// - Parameters:
    ///   - line: The line of text to extract from.
    ///   - prefixes: The prefixes to remove.
    /// - Returns: The extracted value.
    private func extractValue(from line: String, prefix prefixes: [String]) -> String {
        var result = line
        for prefix in prefixes {
            if result.contains(prefix) {
                result = result.replacingOccurrences(of: prefix, with: "")
                break
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Parses an amount string to a Double.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: The parsed amount.
    private func parseAmount(_ string: String) -> Double {
        // Remove currency symbols and other non-numeric characters
        let cleanedString = string.replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
        return Double(cleanedString) ?? 0.0
    }
    
    /// Parses a date string to a Date.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: The parsed date, or nil if parsing fails.
    private func parseDate(_ string: String) -> Date? {
        let dateFormatters = [
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MMMM d, yyyy"),
            createDateFormatter(format: "d MMMM yyyy")
        ]
        
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        for formatter in dateFormatters {
            if let date = formatter.date(from: cleanedString) {
                return date
            }
        }
        
        return nil
    }
    
    /// Creates a date formatter with the specified format.
    ///
    /// - Parameter format: The date format.
    /// - Returns: A configured date formatter.
    private func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
    /// Gets the month name from a month number.
    ///
    /// - Parameter month: The month number (1-12).
    /// - Returns: The month name.
    private func getMonthName(from month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = month
        
        if let date = calendar.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        
        return String(month)
    }
} 