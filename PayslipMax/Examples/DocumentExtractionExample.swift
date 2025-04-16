import Foundation
import PDFKit

/// Example class demonstrating the usage of document analysis and extraction strategy services
class DocumentExtractionExample {
    // MARK: - Properties
    
    private let analysisService = DocumentAnalysisService()
    private let strategyService = ExtractionStrategyService()
    
    // MARK: - Public Methods
    
    /// Process a PDF document with optimal extraction strategy
    /// - Parameters:
    ///   - pdfURL: URL to the PDF document
    ///   - purpose: Purpose of extraction (full, preview, metadata only)
    /// - Returns: A tuple containing the extraction strategy and parameters
    func processDocument(at pdfURL: URL, purpose: ExtractionPurpose = .fullExtraction) async throws -> (strategy: ExtractionStrategy, parameters: ExtractionParameters) {
        // 1. Create PDF document from URL
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw DocumentProcessingError.invalidDocument
        }
        
        // 2. Analyze the document
        print("Analyzing document: \(pdfURL.lastPathComponent)")
        let analysis = try analysisService.analyzeDocument(pdfDocument)
        
        // 3. Output analysis results
        printAnalysisResults(analysis)
        
        // 4. Determine optimal extraction strategy
        let strategy = strategyService.determineStrategy(for: analysis, purpose: purpose)
        
        // 5. Get extraction parameters
        let parameters = strategyService.getExtractionParameters(for: strategy, with: analysis)
        
        // 6. Log the selected strategy
        print("Selected extraction strategy: \(describeStrategy(strategy))")
        print("Extraction parameters: \(describeParameters(parameters))")
        
        return (strategy, parameters)
    }
    
    // MARK: - Private Methods
    
    /// Prints the document analysis results in a formatted way
    /// - Parameter analysis: The document analysis results
    private func printAnalysisResults(_ analysis: DocumentAnalysis) {
        print("---- Document Analysis Results ----")
        print("Page count: \(analysis.pageCount)")
        print("Contains scanned content: \(analysis.containsScannedContent)")
        print("Has complex layout: \(analysis.hasComplexLayout)")
        print("Is text heavy: \(analysis.isTextHeavy)")
        print("Contains graphics: \(analysis.containsGraphics)")
        print("Is large document: \(analysis.isLargeDocument)")
        print("Text density: \(analysis.textDensity)")
        print("Estimated memory requirement: \(formatByteSize(analysis.estimatedMemoryRequirement))")
        print("----------------------------------")
    }
    
    /// Returns a descriptive string for the extraction strategy
    /// - Parameter strategy: The extraction strategy
    /// - Returns: A human-readable description
    private func describeStrategy(_ strategy: ExtractionStrategy) -> String {
        switch strategy {
        case .nativeTextExtraction:
            return "Native Text Extraction (Fast, for text-based PDFs)"
        case .ocrExtraction:
            return "OCR Extraction (For scanned documents)"
        case .hybridExtraction:
            return "Hybrid Extraction (Combining native and OCR techniques)"
        case .tableExtraction:
            return "Table Extraction (Specialized for documents with tables)"
        case .streamingExtraction:
            return "Streaming Extraction (For large documents)"
        case .previewExtraction:
            return "Preview Extraction (Quick, lightweight extraction)"
        }
    }
    
    /// Returns a descriptive string for the extraction parameters
    /// - Parameter parameters: The extraction parameters
    /// - Returns: A human-readable description
    private func describeParameters(_ parameters: ExtractionParameters) -> String {
        var descriptions = [String]()
        
        // Add quality
        descriptions.append("Quality: \(parameters.quality)")
        
        // Add extraction capabilities
        var capabilities = [String]()
        if parameters.extractText { capabilities.append("Text") }
        if parameters.extractImages { capabilities.append("Images") }
        if parameters.extractTables { capabilities.append("Tables") }
        descriptions.append("Extracts: \(capabilities.joined(separator: ", "))")
        
        // Add special features
        var features = [String]()
        if parameters.useOCR { features.append("OCR") }
        if parameters.useStreaming { features.append("Streaming (Batch Size: \(parameters.batchSize))") }
        if parameters.preferNativeTextWhenAvailable { features.append("Prefer Native Text") }
        if features.isEmpty { features.append("Standard") }
        descriptions.append("Features: \(features.joined(separator: ", "))")
        
        // Add page info
        if let pages = parameters.pagesToProcess {
            descriptions.append("Pages: \(pages.count) selected")
        } else {
            descriptions.append("Pages: All")
        }
        
        return descriptions.joined(separator: " | ")
    }
    
    /// Formats byte size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted size string (e.g., "5.2 MB")
    private func formatByteSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

/// Errors that can occur during document processing
enum DocumentProcessingError: Error {
    case invalidDocument
}

// MARK: - Example Usage

/* Usage example:

 Task {
     do {
         let example = DocumentExtractionExample()
         
         // Process a document
         let documentURL = URL(fileURLWithPath: "/path/to/document.pdf")
         let (strategy, parameters) = try await example.processDocument(at: documentURL)
         
         // Use strategy and parameters for actual extraction...
         // processExtraction(strategy: strategy, parameters: parameters, document: document)
     } catch {
         print("Error processing document: \(error)")
     }
 }
 
*/ 