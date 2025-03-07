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
        let payslip = PayslipItemFactory.createEmpty()
        
        // Basic parsing example
        let lines = text.components(separatedBy: .newlines)
        
        var name = ""
        var credits = 0.0
        var month = "1"
        var year = Calendar.current.component(.year, from: Date())
        var timestamp = Date()
        
        for line in lines {
            if line.contains("Name:") {
                name = line.replacingOccurrences(of: "Name:", with: "").trimmingCharacters(in: .whitespaces)
            }
            if line.contains("Amount:") {
                let amountString = line.replacingOccurrences(of: "Amount:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let amount = Double(amountString) {
                    credits = amount
                }
            }
            if line.contains("Date:") {
                // Parse the date string into a proper Date object
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy" // Adjust format based on your PDF date format
                
                let dateString = line.replacingOccurrences(of: "Date:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if let parsedDate = dateFormatter.date(from: dateString) {
                    timestamp = parsedDate
                    // Also update month and year from the parsed date
                    let calendar = Calendar.current
                    month = String(calendar.component(.month, from: parsedDate)) // Convert month Int to String
                    year = calendar.component(.year, from: parsedDate)
                }
            }
            // Add more field parsing as needed
        }
        
        // Update the payslip with the parsed data
        payslip.name = name
        payslip.credits = credits
        payslip.month = month
        payslip.year = year
        payslip.timestamp = timestamp
        
        return payslip
    }
} 