import Foundation
import PDFKit

/// Enhanced implementation of the PDFExtractorProtocol
class EnhancedPDFExtractorImpl: PDFExtractorProtocol {
    // MARK: - Properties
    
    /// The parsing coordinator for handling different parsing strategies
    private let parsingCoordinator: PDFParsingCoordinatorProtocol
    
    /// Available parsers for payslip data extraction
    private let parsers: [PayslipDataParser]
    
    // MARK: - Initialization
    
    /// Initializes a new EnhancedPDFExtractorImpl
    /// - Parameter parsingCoordinator: The parsing coordinator to use
    init(parsingCoordinator: PDFParsingCoordinatorProtocol) {
        self.parsingCoordinator = parsingCoordinator
        self.parsers = parsingCoordinator.getAvailableParsers().map { _ in
            // Create a generic parser instance for each available parser
            return GenericPayslipParser()
        }
    }
    
    // MARK: - PDFExtractorProtocol
    
    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        // Use the parsing coordinator to parse the payslip
        return try await parsingCoordinator.parsePayslip(pdfDocument: pdfDocument)
    }
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        var text = ""
        
        // Extract text from each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                text += pageText
                
                // Add a page separator if not the last page
                if i < pdfDocument.pageCount - 1 {
                    text += "\n\n--- Page \(i+1) ---\n\n"
                }
            }
        }
        
        return text
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return parsingCoordinator.getAvailableParsers().map { $0.name }
    }
    
    /// Extracts payslip data from a text
    /// - Parameter text: The text to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        // Use the same parsers as the PDFDocument implementation
        print("EnhancedPDFExtractorImpl: Starting payslip extraction from text")
        
        // Create a timestamp for the extraction
        let timestamp = Date()
        
        // Try all parsers and return the first successful result
        for parser in parsers {
            print("EnhancedPDFExtractorImpl: Trying parser: \(parser.name)")
            
            if let payslipData = parser.extractPayslipData(from: text) {
                print("EnhancedPDFExtractorImpl: Successfully extracted payslip data with parser: \(parser.name)")
                
                // Create a PayslipItem with the extracted data
                let payslip = PayslipItem(
                    id: UUID(),
                    timestamp: timestamp,
                    month: payslipData.month,
                    year: payslipData.year,
                    credits: payslipData.credits,
                    debits: payslipData.debits,
                    dsop: payslipData.dsop,
                    tax: payslipData.tax,
                    name: payslipData.name,
                    accountNumber: payslipData.accountNumber,
                    panNumber: payslipData.panNumber,
                    pdfData: nil
                )
                
                return payslip
            }
        }
        
        // If no parser was successful, try the fallback method
        print("EnhancedPDFExtractorImpl: No parser was successful, trying fallback method")
        
        // Use a fallback basic extraction method based on regex patterns
        if let payslipData = extractPayslipDataUsingFallbackMethod(from: text) {
            return PayslipItem(
                id: UUID(),
                timestamp: timestamp,
                month: payslipData.month,
                year: payslipData.year,
                credits: payslipData.credits,
                debits: payslipData.debits,
                dsop: payslipData.dsop,
                tax: payslipData.tax,
                name: payslipData.name,
                accountNumber: payslipData.accountNumber,
                panNumber: payslipData.panNumber,
                pdfData: nil
            )
        }
        
        print("EnhancedPDFExtractorImpl: Fallback method failed, extraction unsuccessful")
        return nil
    }
    
    // MARK: - Fallback Method
    
    /// Extracts payslip data using a fallback method
    /// - Parameter text: The text to extract data from
    /// - Returns: A PayslipData struct if extraction is successful, nil otherwise
    private func extractPayslipDataUsingFallbackMethod(from text: String) -> EnhancedPayslipData? {
        // Basic fallback extraction using simple patterns
        let lines = text.components(separatedBy: .newlines)
        
        // Initialize variables for extracted data
        var month = ""
        var year = 0
        var credits = 0.0
        var debits = 0.0
        var dsop = 0.0
        var tax = 0.0
        var name = ""
        var accountNumber = ""
        var panNumber = ""
        
        // Simple pattern matching for extraction
        for line in lines {
            if line.contains("Name:") || line.contains("NAME:") {
                name = line.replacingOccurrences(of: ".*Name:|.*NAME:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.contains("Month:") || line.contains("MONTH:") {
                month = line.replacingOccurrences(of: ".*Month:|.*MONTH:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.contains("Year:") || line.contains("YEAR:") {
                if let extractedYear = Int(line.replacingOccurrences(of: ".*Year:|.*YEAR:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)) {
                    year = extractedYear
                }
            } else if line.contains("A/C No:") || line.contains("Account:") {
                accountNumber = line.replacingOccurrences(of: ".*A/C No:|.*Account:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.contains("PAN:") || line.contains("Pan No:") {
                panNumber = line.replacingOccurrences(of: ".*PAN:|.*Pan No:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.contains("Total Credits:") || line.contains("TOTAL CREDITS:") {
                if let extractedCredits = Double(line.replacingOccurrences(of: ".*Total Credits:|.*TOTAL CREDITS:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    credits = extractedCredits
                }
            } else if line.contains("Total Debits:") || line.contains("TOTAL DEBITS:") {
                if let extractedDebits = Double(line.replacingOccurrences(of: ".*Total Debits:|.*TOTAL DEBITS:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    debits = extractedDebits
                }
            } else if line.contains("DSOP:") {
                if let extractedDSOP = Double(line.replacingOccurrences(of: ".*DSOP:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    dsop = extractedDSOP
                }
            } else if line.contains("Tax:") || line.contains("TAX:") {
                if let extractedTax = Double(line.replacingOccurrences(of: ".*Tax:|.*TAX:", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                    tax = extractedTax
                }
            }
        }
        
        // Use current month and year if not found
        if month.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            month = dateFormatter.string(from: Date())
        }
        
        if year == 0 {
            let calendar = Calendar.current
            year = calendar.component(.year, from: Date())
        }
        
        // Create and return the PayslipData
        return EnhancedPayslipData(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            earnings: [:],
            deductions: [:]
        )
    }
}

// MARK: - Support Types

/// Generic payslip parser implementation (Placeholder)
/// Conforms to `PayslipDataParser` but provides a basic, non-functional implementation.
/// This might be used as a fallback or base class.
class GenericPayslipParser: PayslipDataParser {
    /// The name of this generic parser.
    var name: String {
        return "Generic Parser"
    }
    
    /// Placeholder implementation for extracting data.
    /// Currently returns `nil` as it doesn't perform actual parsing.
    /// - Parameter text: The text to extract data from.
    /// - Returns: `nil` in this placeholder implementation.
    func extractPayslipData(from text: String) -> EnhancedPayslipData? {
        // Basic implementation that would typically be more complex
        // Just return nil here as this is a placeholder implementation
        return nil
    }
}

/// Protocol defining the requirements for a parser that extracts structured payslip data from text.
protocol PayslipDataParser {
    /// The unique name identifying the parser.
    var name: String { get }
    /// Attempts to extract payslip data from the provided text.
    /// - Parameter text: The string content to parse.
    /// - Returns: An `EnhancedPayslipData` struct containing the extracted information, or `nil` if parsing fails.
    func extractPayslipData(from text: String) -> EnhancedPayslipData?
}

/// Struct for holding parsed payslip data extracted by `EnhancedPDFExtractorImpl` or its parsers.
struct EnhancedPayslipData {
    /// Extracted month of the payslip period.
    let month: String
    /// Extracted year of the payslip period.
    let year: Int
    /// Extracted total credits (earnings).
    let credits: Double
    /// Extracted total debits (deductions).
    let debits: Double
    /// Extracted DSOP contribution amount.
    let dsop: Double
    /// Extracted tax deduction amount.
    let tax: Double
    /// Extracted name of the payslip owner.
    let name: String
    /// Extracted account number.
    let accountNumber: String
    /// Extracted PAN (Permanent Account Number).
    let panNumber: String
    /// Dictionary of detailed earnings extracted.
    let earnings: [String: Double]
    /// Dictionary of detailed deductions extracted.
    let deductions: [String: Double]
} 