import Foundation
import PDFKit

/// Extracts structured data from PDF documents by applying a set of predefined patterns.
///
/// This extractor retrieves pattern definitions from a repository and attempts to match them
/// against the raw text content extracted from the PDF document. It prioritizes patterns
/// based on their defined priority within a `PatternDefinition`.
class PatternBasedExtractor {
    
    // MARK: - Dependencies
    
    /// The repository providing access to `PatternDefinition` objects.
    private let patternRepository: PatternRepositoryProtocol
    /// A helper service responsible for applying individual `ExtractorPattern` logic to text.
    private let patternApplier = PatternApplier()
    
    // MARK: - Initialization
    
    /// Initializes the extractor with a pattern repository.
    /// - Parameter patternRepository: An object conforming to `PatternRepositoryProtocol` that supplies the patterns.
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
    }
    
    // MARK: - Public Extraction Methods
    
    /// Extracts data from the entire PDF document using all available patterns from the repository.
    ///
    /// It first extracts the full text content from the PDF, then iterates through all pattern definitions
    /// fetched from the repository, attempting to find a value for each pattern's key.
    ///
    /// - Parameter pdfDocument: The `PDFDocument` to extract data from.
    /// - Returns: A dictionary where keys are the `PatternDefinition.key` and values are the extracted strings.
    /// - Throws: `ExtractionError.pdfTextExtractionFailed` if text cannot be extracted from the PDF.
    func extractData(from pdfDocument: PDFDocument) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            Logger.error("Failed to extract text from the provided PDF document.", category: "PatternExtraction")
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        // Fetch all available pattern definitions
        let patterns = await patternRepository.getAllPatterns()
        
        // Use reduce for a more functional approach to building the dictionary
        let extractedData = patterns.reduce(into: [String: String]()) { (result, patternDef) in
            if let extractedValue = findValue(for: patternDef, in: pdfText) {
                result[patternDef.key] = extractedValue
                // Redacted value in log for privacy
                Logger.debug("Extracted '[REDACTED]' for key '\\(patternDef.key)' using pattern '\\(patternDef.name)'", category: "PatternExtraction")
            } else {
                Logger.debug("No value found for key '\\(patternDef.key)' using pattern '\\(patternDef.name)'", category: "PatternExtraction")
            }
        }
        
        return extractedData
    }
    
    /// Extracts data from the PDF document using only patterns belonging to the specified categories.
    ///
    /// It first extracts the full text content from the PDF. Then, for each specified category,
    /// it fetches the relevant patterns and attempts to extract data, avoiding redundant extractions
    /// if a value for a key has already been found by a pattern in a previous category.
    ///
    /// - Parameters:
    ///   - pdfDocument: The `PDFDocument` to extract data from.
    ///   - categories: An array of `PatternCategory` enums specifying which patterns to use.
    /// - Returns: A dictionary containing extracted key-value pairs relevant to the specified categories.
    /// - Throws: `ExtractionError.pdfTextExtractionFailed` if text cannot be extracted from the PDF.
    func extractData(from pdfDocument: PDFDocument, for categories: [PatternCategory]) async throws -> [String: String] {
        // Extract the text content from the PDF
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            Logger.error("Failed to extract text from the provided PDF document for categories: \\(categories).", category: "PatternExtraction")
            throw ExtractionError.pdfTextExtractionFailed
        }
        
        var extractedData: [String: String] = [:]
        
        // Process patterns category by category
        for category in categories {
            let patternsInCategory = await patternRepository.getPatternsForCategory(category)
            
            for patternDef in patternsInCategory {
                // Only attempt extraction if the key hasn't been populated yet
                if extractedData[patternDef.key] == nil {
                    if let extractedValue = findValue(for: patternDef, in: pdfText) {
                        extractedData[patternDef.key] = extractedValue
                        Logger.debug("Extracted '[REDACTED]' for key '\\(patternDef.key)' (category: \\(category)) using pattern '\\(patternDef.name)'", category: "PatternExtraction")
                    } else {
                        // Log only if no value was found for this specific pattern definition
                        Logger.debug("No value found for key '\\(patternDef.key)' (category: \\(category)) using pattern '\\(patternDef.name)'", category: "PatternExtraction")
                    }
                }
            }
        }
        
        return extractedData
    }
    
    // MARK: - Private Helper Methods
    
    /// Extracts the plain text content from all pages of a `PDFDocument`.
    ///
    /// Iterates through each page, extracts its string content, and concatenates it,
    /// adding page separators for context.
    ///
    /// - Parameter pdfDocument: The `PDFDocument` to process.
    /// - Returns: A single string containing the text from all pages, or `nil` if no text could be extracted.
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var pdfText = ""
        let pageCount = pdfDocument.pageCount
        
        // Iterate through each page using functional approach
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string, !pageText.isEmpty {
                pdfText += pageText
                // Add a separator only if it's not the last page
                if i < pageCount - 1 {
                    pdfText += "\n\n--- Page \(i + 1) ---\n\n"
                }
            }
        }
        
        return pdfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : pdfText
    }
    
    /// Attempts to find a value within the given text using the patterns defined in a `PatternDefinition`.
    ///
    /// Sorts the `ExtractorPattern` objects within the `PatternDefinition` by priority (descending)
    /// and tries each one sequentially using the `PatternApplier`. Returns the first successfully extracted value.
    ///
    /// - Parameters:
    ///   - patternDef: The `PatternDefinition` containing the patterns to try.
    ///   - text: The text content to search within.
    /// - Returns: The extracted string value if any pattern succeeds, otherwise `nil`.
    private func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        // Sort patterns by priority (higher number means higher priority, attempted first)
        let sortedPatterns = patternDef.patterns.sorted { $0.priority > $1.priority }
        
        // Iterate through sorted patterns and return the first successful match
        for pattern in sortedPatterns {
            // Use PatternApplier to handle the actual extraction logic for this pattern
            if let extractedValue = patternApplier.apply(pattern, to: text) {
                Logger.debug("Pattern '\\(pattern.pattern)' (priority \\(pattern.priority)) succeeded for key '\\(patternDef.key)'.", category: "PatternExtraction")
                return extractedValue // Return the first successful extraction
            } else {
                // Log failure for debugging pattern effectiveness
                Logger.debug("Pattern '\\(pattern.pattern)' (priority \\(pattern.priority)) failed for key '\\(patternDef.key)'.", category: "PatternExtraction")
            }
        }
        
        return nil // No pattern within this definition succeeded
    }
}

// Assuming ExtractionError is defined in Core/Error/AppError.swift or similar central location.
// Ensure ExtractionError includes:
// - pdfTextExtractionFailed
// - (Potentially others like patternNotFound, valueExtractionFailed if needed by PatternApplier)

