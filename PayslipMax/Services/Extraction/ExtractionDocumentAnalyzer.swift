import Foundation
import PDFKit

// Import data models from Phase 1
// Note: TextExtractionModels provides ExtractionOptions and ExtractionMetrics

/// Specialized document analyzer for PDF extraction optimization
///
/// This analyzer handles document characteristic analysis to determine optimal extraction strategies.
/// It provides comprehensive analysis of PDF documents including content type detection,
/// layout complexity assessment, and memory requirement estimation.
///
/// Extracted from EnhancedTextExtractionService as part of Phase 4 refactoring.
///
/// ## Key Features:
/// - Document characteristic analysis
/// - Scanned content detection
/// - Layout complexity assessment
/// - Memory requirement analysis
/// - Extraction strategy recommendations
class ExtractionDocumentAnalyzer {
    
    // MARK: - Dependencies
    
    /// Document analysis service for detailed analysis
    private let documentAnalysisService: PayslipMax.DocumentAnalysisService
    
    // MARK: - Initialization
    
    /// Initialize the document analyzer
    /// - Parameter documentAnalysisService: Optional document analysis service (default: creates new instance)
    init(documentAnalysisService: PayslipMax.DocumentAnalysisService? = nil) {
        self.documentAnalysisService = documentAnalysisService ?? PayslipMax.DocumentAnalysisService()
    }
    
    // MARK: - Document Analysis
    
    /// Analyzes a PDF document to determine its characteristics using `DocumentAnalysisService`.
    ///
    /// This method leverages the specialized `DocumentAnalysisService` to extract detailed information
    /// about the document's properties. This analysis is critical for the strategy selection process
    /// in `extractTextWithOptimalStrategy`, allowing the service to tailor the extraction approach
    /// to each document's specific characteristics.
    ///
    /// **Analyzed Characteristics:**
    /// - **Page Count:** Affects total processing time and memory requirements
    /// - **Scanned Content:** Determines if OCR-optimized processing is needed
    /// - **Layout Complexity:** Influences preprocessing requirements and parallel vs. sequential decisions
    /// - **Text Density:** Affects the expected extraction quality and processing approach
    /// - **Memory Requirements:** Helps determine if streaming processing is needed
    /// - **Tables:** Presence of tabular data influences extraction strategy
    /// - **Form Elements:** Presence of form fields may require special handling
    ///
    /// If the analysis service encounters an error, a default analysis with conservative
    /// assumptions is returned to ensure processing can continue, though potentially
    /// with suboptimal settings.
    ///
    /// - Parameter document: The `PDFDocument` to analyze.
    /// - Returns: A `DocumentAnalysis` struct containing the determined characteristics.
    func analyzeDocument(_ document: PDFDocument) -> PayslipMax.DocumentAnalysis {
        do {
            return try documentAnalysisService.analyzeDocument(document)
        } catch {
            print("[ExtractionDocumentAnalyzer] Error analyzing document: \(error)")
            // Return default analysis if analysis fails
            return PayslipMax.DocumentAnalysis(
                pageCount: document.pageCount,
                containsScannedContent: false,
                hasComplexLayout: false,
                textDensity: 0.5,
                estimatedMemoryRequirement: 0,
                containsTables: false,
                containsFormElements: false
            )
        }
    }
    
    /// Provides a basic heuristic check to determine if a document likely contains scanned content.
    ///
    /// This is a simpler, faster alternative to the full document analysis when only the presence
    /// of scanned content needs to be determined. It examines character density on sample pages
    /// to make a judgment.
    ///
    /// **Detection Approach:**
    /// The method counts the number of text characters in the first few pages (up to 5).
    /// A low character count per page (below 500) suggests the document may be scanned rather
    /// than containing native text, as OCR typically extracts less text from scanned documents
    /// than is present in native PDF text.
    ///
    /// **Limitations:**
    /// This is a simple heuristic that may produce false positives or negatives:
    /// - Some legitimate text documents may have very little text per page
    /// - Some scanned documents with good OCR may have high character counts
    /// - Image-heavy documents may be misclassified as scanned
    ///
    /// For more accurate analysis, use the full `analyzeDocument` method which examines
    /// additional characteristics like text positioning, font information, and image content.
    ///
    /// - Parameter document: The `PDFDocument` to check.
    /// - Returns: `true` if the document is heuristically determined to contain scanned content, `false` otherwise.
    func detectScannedContent(in document: PDFDocument) -> Bool {
        // Basic heuristic: check text density
        var totalChars = 0
        let pageCount = document.pageCount
        
        for pageIndex in 0..<min(pageCount, 5) {
            if let page = document.page(at: pageIndex), let pageText = page.string {
                totalChars += pageText.count
            }
        }
        
        let avgCharsPerPage = pageCount > 0 ? Double(totalChars) / Double(min(pageCount, 5)) : 0
        let containsScannedContent = avgCharsPerPage < 500 // Threshold for scanned content
        
        return containsScannedContent
    }
    
    // MARK: - Strategy Recommendations
    
    /// Recommends optimal extraction options based on document analysis
    ///
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Optimized ExtractionOptions for the document
    func recommendOptimalExtractionOptions(for document: PDFDocument) -> ExtractionOptions {
        let analysis = analyzeDocument(document)
        
        var options = ExtractionOptions()
        
        if analysis.hasScannedContent {
            // For scanned content, use OCR-appropriate settings
            options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: 2,
                preprocessText: true,
                useAdaptiveBatching: true,
                maxBatchSize: 2 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 300
            )
        } else if analysis.isLargeDocument {
            // For large documents, use memory-efficient settings
            options = ExtractionOptions(
                useParallelProcessing: false,
                maxConcurrentOperations: 1,
                preprocessText: false,
                useAdaptiveBatching: true,
                maxBatchSize: 1 * 1024 * 1024,
                collectDetailedMetrics: false,
                useCache: true,
                memoryThresholdMB: 100
            )
        } else if analysis.hasComplexLayout {
            // For complex layouts, use layout-aware settings
            options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: 4,
                preprocessText: true,
                useAdaptiveBatching: true,
                maxBatchSize: 3 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 200
            )
        } else if analysis.isTextHeavy {
            // For text-heavy documents, use standard settings
            options = ExtractionOptions()
        }
        
        return options
    }
    
    // MARK: - Additional Methods for Strategy Selection
    
    /// Analyzes document characteristics for strategy selection
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Document characteristics (placeholder)
    func analyzeDocumentCharacteristics(_ document: PDFDocument) -> Any {
        // Placeholder implementation
        return "Document characteristics analysis"
    }
    
    /// Checks if document has scanned content
    /// - Parameter document: The PDF document to check
    /// - Returns: Whether document contains scanned content
    func hasScannedContent(_ document: PDFDocument) -> Bool {
        return detectScannedContent(in: document)
    }
} 