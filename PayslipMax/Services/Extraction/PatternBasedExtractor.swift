import Foundation
import PDFKit

/// A service responsible for extracting data from PDF text content based on a collection
/// of predefined `PatternDefinition` objects.
///
/// It utilizes a `PatternRepositoryProtocol` to fetch the relevant patterns and then applies
/// them sequentially (considering priority) to the extracted text from a `PDFDocument`.
class PatternBasedExtractor {
    
    // MARK: - Properties
    
    /// The repository used to fetch pattern definitions.
    private let patternRepository: PatternRepositoryProtocol
    /// Helper responsible for applying individual patterns.
    private let patternApplier = PatternApplier()
    
    // MARK: - Initialization
    
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
    }
    
    // MARK: - Extraction Methods
    
    /// Extract all data from PDF document using patterns
    func extractData(from pdfDocument: PDFDocument) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Get all patterns to use for extraction
        let patterns = await patternRepository.getAllPatterns()
        
        // Create a dictionary to store the extracted values
        var extractedData: [String: String] = [:]
        
        // Process each pattern and extract values
        for patternDef in patterns {
            if let extractedValue = findValue(for: patternDef, in: pdfText) {
                extractedData[patternDef.key] = extractedValue
                 Logger.debug("Extracted '[REDACTED]' for key '\\(patternDef.key)' using pattern '\\(patternDef.name)'", category: "PatternExtraction")
            } else {
                 Logger.debug("No value found for key '\\(patternDef.key)' using pattern '\\(patternDef.name)'", category: "PatternExtraction")
            }
        }
        
        return extractedData
    }
    
    /// Extract data for specific categories from PDF
    func extractData(from pdfDocument: PDFDocument, for categories: [PatternCategory]) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Create a dictionary to store the extracted values
        var extractedData: [String: String] = [:]
        
        // Process each category
        for category in categories {
            let patterns = await patternRepository.getPatternsForCategory(category)
            
            // Process each pattern in the category
            for patternDef in patterns {
                // Avoid re-extracting if already found by a previous category/pattern
                if extractedData[patternDef.key] == nil,
                   let extractedValue = findValue(for: patternDef, in: pdfText) {
                    extractedData[patternDef.key] = extractedValue
                    Logger.debug("Extracted '[REDACTED]' for key '\\(patternDef.key)' (category: \\(category)) using pattern '\\(patternDef.name)'", category: "PatternExtraction")
                } else if extractedData[patternDef.key] == nil {
                    Logger.debug("No value found for key '\\(patternDef.key)' (category: \\(category)) using pattern '\\(patternDef.name)'", category: "PatternExtraction")
                }
            }
        }
        
        return extractedData
    }
    
    /// Extract text content from PDF document
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var pdfText = ""
        
        // Iterate through each page
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                pdfText += pageText + "\n\n--- Page \(i + 1) ---\n\n" // Add page separators
            }
        }
        
        return pdfText.isEmpty ? nil : pdfText
    }
    
    // MARK: - Pattern Processing
    
    /// Find a value in the text using the given pattern definition by trying its patterns in order of priority.
    private func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        // Sort patterns by priority (highest first)
        let sortedPatterns = patternDef.patterns.sorted { $0.priority > $1.priority }
        
        // Try each pattern in order of priority
        for pattern in sortedPatterns {
            if let extractedValue = patternApplier.apply(pattern, to: text) {
                 Logger.debug("Pattern '\\(pattern.pattern)' (priority \\(pattern.priority)) succeeded for key '\\(patternDef.key)'.", category: "PatternExtraction")
                return extractedValue
            } else {
                 Logger.debug("Pattern '\\(pattern.pattern)' (priority \\(pattern.priority)) failed for key '\\(patternDef.key)'.", category: "PatternExtraction")
            }
        }
        
        return nil // No pattern within the definition succeeded
    }
    
    // Note: applyPattern, applyRegexPattern, applyKeywordPattern, applyPositionBasedPattern,
    // applyPreprocessing, applyPostprocessing, and formatAsCurrency methods have been moved to PatternApplier.swift
}

// Define ExtractionError if not defined elsewhere (can be moved to a dedicated Error file)
// Ensure this is defined only once in the project.
/*
enum ExtractionError: Error {
    case pdfTextExtractionFailed
    case patternNotFound
    case valueExtractionFailed
} 
*/ 

