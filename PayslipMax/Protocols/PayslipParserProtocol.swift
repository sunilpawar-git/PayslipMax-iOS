/*
 NOTE: This file now contains the PayslipParser and PDFParsingCoordinatorProtocol protocols
 that were moved from ParsingModels.swift and PDFParsingCoordinator.swift.
*/

import Foundation
import PDFKit

// MARK: - Parser Protocols

/// Protocol for payslip parsers
/// This protocol defines the contract for components that can parse PDF payslips
protocol PayslipParser {
    /// Name of the parser for identification
    var name: String { get }
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    /// - Throws: An error if parsing fails.
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem?
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence
}

// MARK: - Specialized Parser Protocols

/// Protocol for military payslip parsers
/// This protocol defines the contract for parsers that specifically handle military payslips
protocol MilitaryPayslipParser: PayslipParser {
    /// The abbreviation manager to use for handling military abbreviations
    var abbreviationManager: AbbreviationManager { get }
    
    /// Determines if the parser can handle a specific military format
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: True if the parser can handle this format, false otherwise
    func canHandleMilitaryFormat(text: String) -> Bool
    
    /// Extracts military-specific details from the payslip
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: A dictionary of extracted military-specific details
    func extractMilitaryDetails(from text: String) -> [String: String]
    
    /// Parse military abbreviations in the payslip
    /// - Parameter text: The text containing abbreviations
    /// - Returns: A dictionary mapping abbreviations to their full meanings
    func parseMilitaryAbbreviations(in text: String) -> [String: String]
}

// Corporate payslip parser protocol removed - PayslipMax is exclusively for defense personnel

// MARK: - Parser Extensions

/// Default implementations for PayslipParser protocol
extension PayslipParser {
    /// Default implementation for evaluating confidence based on common metrics
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Evaluate confidence based on completeness of data
        var score = 0
        
        // Check if we have earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if !payslipItem.name.isEmpty && 
           !payslipItem.month.isEmpty && 
           payslipItem.year > 2000 {
            score += 1
        }
        
        // Check if we have a reasonable number of items
        if !payslipItem.earnings.isEmpty && !payslipItem.deductions.isEmpty {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 3 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
}

/// Default implementations for MilitaryPayslipParser protocol
extension MilitaryPayslipParser {
    /// Default implementation for checking if a parser can handle military format
    func canHandleMilitaryFormat(text: String) -> Bool {
        // Common military terms that indicate a military payslip
        let militaryTerms = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", 
            "PCDA", "CDA", "Defence", "DSOP FUND", "Military",
            "SERVICE NO", "ARMY NO", "UNIT"
        ]
        
        // Check if any military term appears in the text
        for term in militaryTerms {
            if text.contains(term) {
                return true
            }
        }
        
        return false
    }
    
    /// Default implementation for parsing military abbreviations
    func parseMilitaryAbbreviations(in text: String) -> [String: String] {
        var result = [String: String]()
        
        // Regular expression to find potential abbreviations (uppercase words)
        let pattern = "\\b[A-Z][A-Z0-9]{1,}\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let abbreviation = nsString.substring(with: match.range)
                if let fullName = abbreviationManager.getFullName(for: abbreviation) {
                    result[abbreviation] = fullName
                }
            }
        } catch {
            print("Error parsing military abbreviations: \(error)")
        }
        
        return result
    }
}

// Corporate payslip parser extension removed - PayslipMax is exclusively for defense personnel

// MARK: - Registry Protocol

/// Protocol for managing payslip parsers
/// Defines a system for registering, retrieving, and selecting parsers
protocol PayslipParserRegistry {
    /// All registered parsers
    var parsers: [PayslipParser] { get }
    
    /// Register a parser with the registry
    /// - Parameter parser: The parser to register
    func register(parser: PayslipParser)
    
    /// Register multiple parsers with the registry
    /// - Parameter parsers: The parsers to register
    func register(parsers: [PayslipParser])
    
    /// Remove a parser from the registry
    /// - Parameter name: The name of the parser to remove
    func removeParser(withName name: String)
    
    /// Get a parser by name
    /// - Parameter name: The name of the parser to retrieve
    /// - Returns: The parser with the specified name, or nil if not found
    func getParser(withName name: String) -> PayslipParser?
    
    /// Select the best parser for a given PDF text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The most suitable parser for the text, or nil if no suitable parser is found
    func selectBestParser(for text: String) -> PayslipParser?
}

// MARK: - Coordinator Protocol

/// Protocol for PDF parsing coordinator
/// Defines the contract for components that coordinate parsing operations
protocol PDFParsingCoordinatorProtocol {
    /// Parses a PDF document using available parsers
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: The best parsing result (PayslipItem), or nil if parsing failed.
    /// - Throws: Errors related to text extraction or parser failures.
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem?
    
    /// Parses a PDF document using a specific parser
    /// - Parameters:
    ///   - pdfDocument: The PDF document to parse
    ///   - parserName: The name of the parser to use
    /// - Returns: The parsing result, or nil if the parser failed or was not found
    /// - Throws: An error if parsing fails
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem?
    
    /// Selects the best parser for a given text
    /// - Parameter text: The text to analyze
    /// - Returns: The best parser for the text, or nil if no suitable parser is found
    func selectBestParser(for text: String) -> PayslipParser?
    
    /// Extracts full text from a PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractFullText(from document: PDFDocument) -> String?
    
    /// Gets all available parsers
    /// - Returns: An array of all registered parsers
    func getAvailableParsers() -> [PayslipParser]
} 