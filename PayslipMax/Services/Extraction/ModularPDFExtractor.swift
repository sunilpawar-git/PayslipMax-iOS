import Foundation
import PDFKit

/// A modular implementation of the PDF extractor that breaks the extraction process into discrete stages.
///
/// The ModularPDFExtractor employs a pattern-based approach to extract structured data from PDF documents,
/// with each pattern defined in a repository and applied systematically through a pipeline architecture.
/// This approach offers several advantages over monolithic extraction:
///
/// - **Modularity**: Each extraction pattern can be defined, tested, and maintained independently
/// - **Flexibility**: New patterns can be added without modifying the core extraction logic
/// - **Prioritization**: Patterns can be prioritized to ensure the most reliable patterns are tried first
/// - **Pre/Post-processing**: Each pattern can specify custom text preprocessing and result postprocessing steps
/// - **Category-based extraction**: Patterns are grouped by category (e.g., personal info, financial data) for organized extraction
///
/// The extraction process follows these stages:
/// 1. Text extraction: Convert PDF to text representation
/// 2. Pattern retrieval: Load all patterns from the repository
/// 3. Pattern application: Apply patterns by category, respecting priority
/// 4. Result assembly: Combine extracted values into a structured PayslipItem
/// 5. Validation: Ensure essential data was extracted successfully
///
/// This extractor is designed to handle diverse payslip formats by relying on flexible pattern definitions
/// rather than hardcoded parsing logic.
class ModularPDFExtractor: PDFExtractorProtocol {
    
    /// The repository that stores and provides all extraction patterns.
    private let patternRepository: PatternRepositoryProtocol
    
    /// The pattern application engine for applying extraction patterns to text
    private let patternApplicationEngine: PatternApplicationEngineProtocol
    
    /// The result assembler for converting extracted data to PayslipItem
    private let resultAssembler: ExtractionResultAssemblerProtocol
    
    /// The validator for ensuring data quality and completeness
    private let validator: SimpleExtractionValidatorProtocol
    
    /// Initializes a new modular PDF extractor with the specified services.
    /// - Parameters:
    ///   - patternRepository: The repository containing all pattern definitions
    ///   - patternApplicationEngine: The engine for applying patterns to text
    ///   - resultAssembler: The service for assembling PayslipItems from extracted data
    ///   - validator: The service for validating extraction quality
    init(
        patternRepository: PatternRepositoryProtocol,
        patternApplicationEngine: PatternApplicationEngineProtocol,
        resultAssembler: ExtractionResultAssemblerProtocol,
        validator: SimpleExtractionValidatorProtocol
    ) {
        self.patternRepository = patternRepository
        self.patternApplicationEngine = patternApplicationEngine
        self.resultAssembler = resultAssembler
        self.validator = validator
    }
    
    /// Extracts payslip data from a PDF document (async)
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        guard let pdfData = pdfDocument.dataRepresentation() else {
            print("ModularPDFExtractor: Failed to get PDF data representation")
            return nil
        }
        do {
            let item = try await extractData(from: pdfDocument, pdfData: pdfData)
            return item
        } catch {
            print("ModularPDFExtractor: Error extracting payslip data - \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Extracts payslip data from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        // This implementation is a simplified version as we don't have the original PDF data
        print("ModularPDFExtractor: Attempting to extract data from text only")
        
        // Create a dummy PDF document to satisfy the protocol
        let dummyPDF = PDFDocument()
        let dummyPage = PDFPage(image: UIImage())
        if let page = dummyPage {
            dummyPDF.insert(page, at: 0)
        }
        
        // Get all patterns from the repository (now async-friendly)
        let patterns: [PatternDefinition] = await patternRepository.getAllPatterns()
        
        if patterns.isEmpty {
            print("ModularPDFExtractor: Error - No patterns loaded")
            return nil
        }
        
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority (using a simple method, not the SortComparator which is causing issues)
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = patternApplicationEngine.findValue(for: pattern, in: text) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Use the validator and assembler services
        do {
            try validator.validateEssentialData(data)
            let dummyData = Data() // For text-only processing
            let payslip = try resultAssembler.assemblePayslipItem(from: data, pdfData: dummyData)
            
            guard validator.validatePayslipItem(payslip) else {
                print("ModularPDFExtractor: PayslipItem validation failed")
                return nil
            }
            
            return payslip
        } catch {
            print("ModularPDFExtractor: Error processing text-based extraction: \(error)")
            return nil
        }
    }
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        return extractTextFromPDF(pdfDocument) ?? ""
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return ["ModularParser"]
    }
    
    /// Extract data from a PDF document and return a PayslipItem
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract data from
    ///   - pdfData: The raw data representation of the PDF document
    /// - Returns: A PayslipItem containing the extracted data
    /// - Throws: A ModularExtractionError if extraction fails at any stage
    func extractData(from pdfDocument: PDFDocument, pdfData: Data) async throws -> PayslipItem {
        // Log PDF details for debugging
        logPdfDetails(pdfDocument)
        
        // Extract text from the PDF document
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            print("ModularPDFExtractor: Failed to extract text from PDF")
            throw ModularExtractionError.pdfTextExtractionFailed
        }
        
        print("ModularPDFExtractor: Extracted \(pdfText.count) characters from PDF")
        
        // Stage 1: Get all patterns from the repository
        let patterns = await patternRepository.getAllPatterns()
        print("ModularPDFExtractor: Loaded \(patterns.count) patterns")
        
        // Stage 2: Process patterns against the PDF text using the pattern application engine
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        print("ModularPDFExtractor: Processing patterns by category")
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = patternApplicationEngine.findValue(for: pattern, in: pdfText) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Stage 3: Validate essential data
        try validator.validateEssentialData(data)
        
        // Stage 4: Assemble PayslipItem from extracted data
        let payslip = try resultAssembler.assemblePayslipItem(from: data, pdfData: pdfData)
        
        // Stage 5: Final validation of the assembled PayslipItem
        guard validator.validatePayslipItem(payslip) else {
            print("ModularPDFExtractor: PayslipItem validation failed")
            throw ModularExtractionError.insufficientData
        }
        
        print("ModularPDFExtractor: Successfully created and validated PayslipItem")
        return payslip
    }
    
    /// Retrieves the priority value of a pattern definition.
    /// Higher values indicate higher priority.
    /// - Parameter pattern: The pattern definition to get the priority from.
    /// - Returns: The priority value of the first pattern in the definition, or 0 if none exists.
    private func getPatternPriority(_ pattern: PatternDefinition) -> Int {
        // Return the priority of the first pattern, or a default value
        return pattern.patterns.first?.priority ?? 0
    }
    
    /// Extracts all text content from a PDF document, concatenating text from all pages.
    /// - Parameter pdfDocument: The PDF document to extract text from.
    /// - Returns: A string containing all text from the document, or nil if no text could be extracted.
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var allText = ""
        
        // Iterate through all pages
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                allText += pageText + "\n"
            }
        }
        
        return allText.isEmpty ? nil : allText
    }
    

    

    

    

    
    /// Logs detailed information about the provided PDF document for debugging purposes.
    ///
    /// This function prints diagnostic information to the console, including:
    /// - The size of the PDF data in bytes.
    /// - The total number of pages in the document.
    /// - For each page: its dimensions (width x height) based on the media box.
    /// - For each page: the number of characters extracted or a message indicating no text content was found.
    ///
    /// This is useful for understanding the structure and content characteristics of a PDF during development or troubleshooting.
    ///
    /// - Parameter pdfDocument: The `PDFDocument` instance to analyze and log details for.
    private func logPdfDetails(_ pdfDocument: PDFDocument) {
        let pdfData = pdfDocument.dataRepresentation()
        print("ModularPDFExtractor: PDF data size: \(pdfData?.count ?? 0) bytes")
        print("ModularPDFExtractor: PDF has \(pdfDocument.pageCount) pages")
        
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                print("ModularPDFExtractor: Page \(i+1) size: \(pageRect.size.width) x \(pageRect.size.height)")
                
                if let text = page.string, !text.isEmpty {
                    print("ModularPDFExtractor: Page \(i+1) has \(text.count) characters of text")
                } else {
                    print("ModularPDFExtractor: Page \(i+1) has no text content")
                }
            }
        }
    }
}

/// Custom error types encountered during the modular PDF extraction process.
enum ModularExtractionError: Error {
    /// Indicates that the provided PDF data is invalid, corrupted, or cannot be opened.
    case invalidPdf
    /// Indicates that text content could not be successfully extracted from the PDF document.
    case pdfTextExtractionFailed
    /// Indicates that despite successful text extraction, no defined patterns matched the content.
    case patternMatchingFailed
    /// Indicates that essential data fields (like month, year, credits) could not be extracted, 
    /// making the resulting PayslipItem invalid.
    case insufficientData
}