import Foundation
import PDFKit
import CoreGraphics
import Vision

/// Default implementation of positional element extraction
/// Extracts text elements with their spatial positions from PDF pages
/// while preserving geometric relationships for improved parsing accuracy
@MainActor
final class DefaultPositionalElementExtractor: PositionalElementExtractorProtocol {
    
    // MARK: - Properties
    
    /// Whether the service has been initialized
    var isInitialized: Bool = false
    
    /// Configuration for extraction operations
    let configuration: ExtractionConfiguration
    
    /// Element type classifier for categorizing extracted elements
    private let elementClassifier: ElementTypeClassifier
    
    /// Weak reference to progress delegate for monitoring
    weak var progressDelegate: ExtractionProgressDelegate?
    
    // MARK: - Initialization
    
    /// Initializes the extractor with configuration
    /// - Parameters:
    ///   - configuration: Extraction configuration (defaults to payslip optimized)
    ///   - elementClassifier: Classifier for element types
    init(
        configuration: ExtractionConfiguration = .payslipDefault,
        elementClassifier: ElementTypeClassifier? = nil
    ) {
        self.configuration = configuration
        self.elementClassifier = elementClassifier ?? ElementTypeClassifier()
    }
    
    /// Initializes the service asynchronously
    func initialize() async throws {
        try await elementClassifier.initialize()
        isInitialized = true
    }
    
    // MARK: - PositionalElementExtractorProtocol Implementation
    
    /// Extracts positional elements from a single PDF page
    func extractPositionalElements(from page: PDFPage, pageIndex: Int) async throws -> [PositionalElement] {
        guard isInitialized else {
            throw PDFExtractionError.invalidInput("Service not initialized")
        }
        
        let startTime = Date()
        
        // Extract positional elements from the page
        let annotations = try await extractTextSelections(from: page, pageIndex: pageIndex)
        
        // Update page index for each element
        let elementsWithPageIndex = annotations.map { element in
            PositionalElement(
                text: element.text,
                bounds: element.bounds,
                type: element.type,
                confidence: element.confidence,
                metadata: element.metadata,
                fontSize: element.fontSize,
                isBold: element.isBold,
                pageIndex: pageIndex
            )
        }
        
        // Apply size filtering if configured
        let filteredAnnotations = ElementProcessingUtils.filterBySize(elementsWithPageIndex, configuration: configuration)
        
        // Limit elements if configured
        let limitedAnnotations = ElementProcessingUtils.limitElements(filteredAnnotations, configuration: configuration)
        
        // Classify elements if enabled
        var elements = limitedAnnotations
        if configuration.enableClassification {
            elements = try await ElementProcessingUtils.classifyElements(limitedAnnotations, classifier: elementClassifier)
        }
        
        // Sort by reading order
        elements.sort { first, second in
            if abs(first.center.y - second.center.y) > configuration.alignmentTolerance {
                return first.center.y < second.center.y
            }
            return first.center.x < second.center.x
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("DefaultPositionalElementExtractor: Extracted \(elements.count) elements from page \(pageIndex) in \(String(format: "%.2f", processingTime))s")
        
        return elements
    }
    
    /// Extracts positional elements from an entire PDF document
    func extractStructuredDocument(from document: PDFDocument) async throws -> StructuredDocument {
        return try await extractStructuredDocument(from: document, progressCallback: nil)
    }
    
    /// Extracts positional elements with progress reporting
    func extractStructuredDocument(
        from document: PDFDocument,
        progressCallback: ((Double) -> Void)? = nil
    ) async throws -> StructuredDocument {
        let startTime = Date()
        let pageCount = document.pageCount
        
        guard pageCount > 0 else {
            throw PDFExtractionError.invalidInput("Document has no pages")
        }
        
        progressDelegate?.extractionDidStart(totalPages: pageCount)
        progressCallback?(0.0)
        
        var structuredPages: [StructuredPage] = []
        
        // Process each page
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else {
                throw PDFExtractionError.invalidPage(pageIndex: pageIndex)
            }
            
            // Extract original text for backward compatibility
            let originalText = page.string ?? ""
            
            // Extract positional elements
            let elements = try await extractPositionalElements(from: page, pageIndex: pageIndex)
            
            // Create structured page
            let structuredPage = StructuredPage(
                text: originalText,
                bounds: page.bounds(for: .mediaBox),
                elements: elements,
                pageIndex: pageIndex,
                metadata: ElementProcessingUtils.extractPageMetadata(from: page)
            )
            
            structuredPages.append(structuredPage)
            
            // Report progress
            let progress = Double(pageIndex + 1) / Double(pageCount)
            progressDelegate?.extractionDidCompletePage(
                pageIndex: pageIndex,
                elementsExtracted: elements.count,
                progress: progress
            )
            progressCallback?(progress)
        }
        
        let processingDuration = Date().timeIntervalSince(startTime)
        
        // Create structured document
        let structuredDocument = StructuredDocument(
            pages: structuredPages,
            metadata: ElementProcessingUtils.extractDocumentMetadata(from: document),
            processingDuration: processingDuration
        )
        
        progressDelegate?.extractionDidComplete(result: structuredDocument)
        
        print("DefaultPositionalElementExtractor: Completed document processing in \(String(format: "%.2f", processingDuration))s")
        print("Total elements extracted: \(structuredDocument.totalElementCount)")
        
        return structuredDocument
    }
    
    /// Classifies the type of a text element
    func classifyElement(
        text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) async -> (type: ElementType, confidence: Double) {
        return await elementClassifier.classify(
            text: text,
            bounds: bounds,
            context: context
        )
    }
    
    /// Validates extraction results
    func validateExtractionResults(_ elements: [PositionalElement]) async -> SpatialExtractionValidationResult {
        return await ElementValidation.validateExtractionResults(elements)
    }
    
    // MARK: - Private Helper Methods
    
    
    /// Creates mock positional elements from PDF page text
    /// This is a simplified implementation for Phase 1 validation
    private func extractTextSelections(from page: PDFPage, pageIndex: Int) async throws -> [PositionalElement] {
        let elements: [PositionalElement] = []
        
        // Get the full page text
        guard let pageString = page.string, !pageString.isEmpty else {
            return elements
        }
        
        // Create mock positional elements for testing
        let pageBounds = page.bounds(for: .mediaBox)
        return ElementProcessingUtils.createMockElements(from: pageString, pageIndex: pageIndex, pageBounds: pageBounds)
    }
    
    
}
