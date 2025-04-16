import Foundation
import PDFKit

/// Represents different PDF extraction strategies
enum ExtractionStrategy {
    /// Native PDF text extraction - fast but limited to text-based PDFs
    case nativeTextExtraction
    
    /// OCR-based extraction - slower but works with scanned documents
    case ocrExtraction
    
    /// Hybrid approach combining both native and OCR extraction
    case hybridExtraction
    
    /// Specialized strategy for table extraction
    case tableExtraction
    
    /// Strategy for large documents that uses streaming and pagination
    case streamingExtraction
    
    /// Lightweight extraction for previews or thumbnails
    case previewExtraction
}

/// Service responsible for selecting the optimal extraction strategy based on document analysis
class ExtractionStrategyService {
    // MARK: - Properties
    
    /// Optional memory threshold configuration
    private let memoryThreshold: Int64
    
    /// Optional maximum filesize for lightweight processing
    private let maxLightweightFilesize: Int64
    
    // MARK: - Initialization
    
    init(memoryThreshold: Int64 = 500 * 1024 * 1024, maxLightweightFilesize: Int64 = 5 * 1024 * 1024) {
        self.memoryThreshold = memoryThreshold
        self.maxLightweightFilesize = maxLightweightFilesize
    }
    
    // MARK: - Public Methods
    
    /// Determine the optimal extraction strategy based on document analysis
    /// - Parameters:
    ///   - analysis: The document analysis result
    ///   - purpose: The purpose of extraction (optional)
    /// - Returns: The recommended extraction strategy
    func determineStrategy(for analysis: DocumentAnalysis, purpose: ExtractionPurpose = .fullExtraction) -> ExtractionStrategy {
        // For preview purposes, always use lightweight extraction
        if purpose == .preview {
            return .previewExtraction
        }
        
        // If document is very large, use streaming extraction
        if analysis.isLargeDocument && analysis.estimatedMemoryRequirement > memoryThreshold {
            return .streamingExtraction
        }
        
        // For scanned documents, use OCR
        if analysis.containsScannedContent {
            // If the document also has native text content, use hybrid approach
            return analysis.isTextHeavy ? .hybridExtraction : .ocrExtraction
        }
        
        // For complex layouts with tables, use table extraction
        if analysis.hasComplexLayout && containsTables(analysis) {
            return .tableExtraction
        }
        
        // For standard text-based PDFs, use native extraction
        return .nativeTextExtraction
    }
    
    /// Get extraction parameters based on the selected strategy and document characteristics
    /// - Parameters:
    ///   - strategy: The extraction strategy
    ///   - analysis: The document analysis
    /// - Returns: Parameters for the extraction process
    func getExtractionParameters(for strategy: ExtractionStrategy, with analysis: DocumentAnalysis) -> ExtractionParameters {
        var parameters = ExtractionParameters()
        
        switch strategy {
        case .nativeTextExtraction:
            parameters.quality = .standard
            parameters.extractImages = false
            parameters.extractText = true
            parameters.pagesToProcess = nil // Process all pages
            
        case .ocrExtraction:
            parameters.quality = .high
            parameters.extractImages = true
            parameters.extractText = true
            parameters.useOCR = true
            parameters.pagesToProcess = nil // Process all pages
            
        case .hybridExtraction:
            parameters.quality = .high
            parameters.extractImages = true
            parameters.extractText = true
            parameters.useOCR = true
            parameters.preferNativeTextWhenAvailable = true
            parameters.pagesToProcess = nil // Process all pages
            
        case .tableExtraction:
            parameters.quality = .high
            parameters.extractImages = true
            parameters.extractText = true
            parameters.extractTables = true
            parameters.useGridDetection = true
            parameters.pagesToProcess = nil // Process all pages
            
        case .streamingExtraction:
            parameters.quality = .standard
            parameters.extractImages = true
            parameters.extractText = true
            parameters.useStreaming = true
            // Calculate batch size based on memory requirements
            let batchSize = calculateBatchSize(for: analysis)
            parameters.batchSize = batchSize
            parameters.pagesToProcess = nil // Process all pages in batches
            
        case .previewExtraction:
            parameters.quality = .low
            parameters.extractImages = true
            parameters.extractText = true
            // Only process first few pages for preview
            parameters.pagesToProcess = Array(0..<min(5, analysis.pageCount))
            parameters.downscaleFactor = 2.0
        }
        
        // Adjust parameters based on document characteristics
        adjustParametersForDocumentType(&parameters, analysis: analysis)
        
        return parameters
    }
    
    // MARK: - Private Methods
    
    /// Determine if document analysis indicates tables
    /// - Parameter analysis: The document analysis
    /// - Returns: True if tables are likely present
    private func containsTables(_ analysis: DocumentAnalysis) -> Bool {
        // Complex layouts with structured content likely contain tables
        return analysis.hasComplexLayout && analysis.isTextHeavy
    }
    
    /// Calculate optimal batch size for streaming extraction
    /// - Parameter analysis: The document analysis
    /// - Returns: Recommended batch size
    private func calculateBatchSize(for analysis: DocumentAnalysis) -> Int {
        let memoryPerPage = analysis.estimatedMemoryRequirement / Int64(max(1, analysis.pageCount))
        
        // Calculate how many pages can be processed at once within memory threshold
        let pagesPerBatch = max(1, Int(memoryThreshold / max(1, memoryPerPage)))
        
        // Cap at reasonable values
        return min(max(1, pagesPerBatch), 20)
    }
    
    /// Adjust extraction parameters based on document characteristics
    /// - Parameters:
    ///   - parameters: The extraction parameters to adjust
    ///   - analysis: The document analysis
    private func adjustParametersForDocumentType(_ parameters: inout ExtractionParameters, analysis: DocumentAnalysis) {
        // For graphics-heavy documents, improve image extraction
        if analysis.containsGraphics {
            parameters.imageQuality = .high
            parameters.extractVectorGraphics = true
        }
        
        // For text-heavy documents, optimize text extraction
        if analysis.isTextHeavy {
            parameters.maintainTextOrder = true
            parameters.preserveFormatting = true
        }
        
        // For very small documents, we can use higher quality
        if !analysis.isLargeDocument && analysis.pageCount < 10 {
            parameters.quality = .high
        }
    }
}

// MARK: - Supporting Types

/// Purpose of the extraction process
enum ExtractionPurpose {
    /// Full extraction of document content
    case fullExtraction
    
    /// Quick preview/thumbnail generation
    case preview
    
    /// Extract metadata only
    case metadataOnly
}

/// Parameters for the extraction process
struct ExtractionParameters {
    /// Quality level for extraction
    enum Quality {
        case low, standard, high
    }
    
    /// The extraction quality level
    var quality: Quality = .standard
    
    /// Whether to extract text content
    var extractText: Bool = true
    
    /// Whether to extract images
    var extractImages: Bool = false
    
    /// Whether to extract tables
    var extractTables: Bool = false
    
    /// Whether to use OCR for text extraction
    var useOCR: Bool = false
    
    /// Whether to use streaming for large documents
    var useStreaming: Bool = false
    
    /// Whether to prefer native text extraction when available
    var preferNativeTextWhenAvailable: Bool = false
    
    /// Whether to use grid detection for tables
    var useGridDetection: Bool = false
    
    /// Whether to extract vector graphics
    var extractVectorGraphics: Bool = false
    
    /// Whether to maintain the original text order
    var maintainTextOrder: Bool = true
    
    /// Whether to preserve text formatting (bold, italic, etc.)
    var preserveFormatting: Bool = false
    
    /// The quality level for extracted images
    var imageQuality: Quality = .standard
    
    /// Batch size for streaming extraction
    var batchSize: Int = 10
    
    /// Factor to downscale images (1.0 = original size)
    var downscaleFactor: Double = 1.0
    
    /// Specific pages to process (nil means all pages)
    var pagesToProcess: [Int]? = nil
} 