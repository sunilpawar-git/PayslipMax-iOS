import Foundation
import PDFKit
import CoreGraphics

/// Protocol for extracting positional elements from PDF pages
/// Defines the interface for spatial PDF parsing services that preserve
/// geometric relationships between text elements
@MainActor
protocol PositionalElementExtractorProtocol: ServiceProtocol {
    
    /// Configuration for extraction operations
    var configuration: ExtractionConfiguration { get }
    
    /// Extracts positional elements from a single PDF page
    /// - Parameters:
    ///   - page: The PDF page to process
    ///   - pageIndex: The 0-based index of the page in the document
    /// - Returns: Array of positional elements found on the page
    /// - Throws: PDFExtractionError if extraction fails
    func extractPositionalElements(from page: PDFPage, pageIndex: Int) async throws -> [PositionalElement]
    
    /// Extracts positional elements from an entire PDF document
    /// - Parameter document: The PDF document to process
    /// - Returns: Structured document with all pages and elements
    /// - Throws: PDFExtractionError if extraction fails
    func extractStructuredDocument(from document: PDFDocument) async throws -> StructuredDocument
    
    /// Extracts positional elements with progress reporting
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressCallback: Optional callback for progress updates (0.0 to 1.0)
    /// - Returns: Structured document with all pages and elements
    /// - Throws: PDFExtractionError if extraction fails
    func extractStructuredDocument(
        from document: PDFDocument,
        progressCallback: ((Double) -> Void)?
    ) async throws -> StructuredDocument
    
    /// Classifies the type of a text element based on content and context
    /// - Parameters:
    ///   - text: The text content to classify
    ///   - bounds: The element's bounding rectangle
    ///   - context: Surrounding elements for context analysis
    /// - Returns: Tuple of element type and confidence score
    func classifyElement(
        text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) async -> (type: ElementType, confidence: Double)
    
    /// Validates extraction results for quality assurance
    /// - Parameter elements: Array of extracted elements to validate
    /// - Returns: Validation result with quality metrics
    func validateExtractionResults(_ elements: [PositionalElement]) async -> SpatialExtractionValidationResult
}

/// Result of spatial extraction validation
struct SpatialExtractionValidationResult: Codable {
    /// Whether the extraction passed basic quality checks
    let isValid: Bool
    /// Overall quality score from 0.0 to 1.0
    let qualityScore: Double
    /// Number of elements extracted
    let elementCount: Int
    /// Number of classified elements (non-unknown types)
    let classifiedCount: Int
    /// Detected issues during extraction
    let issues: [SpatialValidationIssue]
    /// Validation timestamp
    let validatedAt: Date
    
    /// Classification accuracy (percentage of non-unknown elements)
    var classificationAccuracy: Double {
        guard elementCount > 0 else { return 0.0 }
        return Double(classifiedCount) / Double(elementCount)
    }
    
    init(
        isValid: Bool,
        qualityScore: Double,
        elementCount: Int,
        classifiedCount: Int,
        issues: [SpatialValidationIssue] = []
    ) {
        self.isValid = isValid
        self.qualityScore = min(1.0, max(0.0, qualityScore))
        self.elementCount = elementCount
        self.classifiedCount = classifiedCount
        self.issues = issues
        self.validatedAt = Date()
    }
}

/// Types of spatial validation issues that can be detected
enum SpatialValidationIssue: String, Codable, CaseIterable {
    /// Too few elements extracted for document size
    case lowElementCount = "Low element count"
    /// High percentage of unclassified elements
    case poorClassification = "Poor classification accuracy"
    /// Elements with overlapping bounds (potential duplication)
    case overlappingElements = "Overlapping elements detected"
    /// Inconsistent element sizes suggesting extraction errors
    case inconsistentSizing = "Inconsistent element sizing"
    /// Missing expected structural elements (headers, tables)
    case missingStructure = "Missing expected document structure"
    /// Elements outside page bounds
    case elementsOutOfBounds = "Elements outside page boundaries"
    
    var description: String {
        return rawValue
    }
}

/// Errors that can occur during positional element extraction
enum PDFExtractionError: Error, LocalizedError, Equatable {
    /// Unable to access the PDF page
    case invalidPage(pageIndex: Int)
    /// PDF document is corrupted or unreadable
    case corruptedDocument
    /// Insufficient memory to process large document
    case memoryError
    /// Processing timeout exceeded
    case timeout
    /// Unsupported PDF version or features
    case unsupportedFormat
    /// Invalid input parameters
    case invalidInput(String)
    /// Element classification failed
    case classificationFailed
    /// Unknown error during extraction
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPage(let pageIndex):
            return "Cannot access page \(pageIndex) of PDF document"
        case .corruptedDocument:
            return "PDF document appears to be corrupted or unreadable"
        case .memoryError:
            return "Insufficient memory to process PDF document"
        case .timeout:
            return "PDF processing timeout exceeded"
        case .unsupportedFormat:
            return "Unsupported PDF format or features"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .classificationFailed:
            return "Failed to classify extracted elements"
        case .unknown(let message):
            return "Unknown extraction error: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidPage:
            return "Page index out of bounds or page is inaccessible"
        case .corruptedDocument:
            return "Document structure is invalid or damaged"
        case .memoryError:
            return "Document too large for available memory"
        case .timeout:
            return "Processing took longer than allowed timeout"
        case .unsupportedFormat:
            return "PDF uses features not supported by extractor"
        case .invalidInput:
            return "Provided parameters are invalid"
        case .classificationFailed:
            return "Element type classification algorithm failed"
        case .unknown:
            return "Unexpected error occurred during processing"
        }
    }
}

/// Configuration options for positional element extraction
struct ExtractionConfiguration: Codable {
    /// Timeout for extraction operations in seconds
    let timeoutSeconds: TimeInterval
    /// Whether to enable detailed element classification
    let enableClassification: Bool
    /// Maximum number of elements to extract per page (0 = unlimited)
    let maxElementsPerPage: Int
    /// Minimum element size to consider (smaller elements ignored)
    let minimumElementSize: CGSize
    /// Whether to enable text clustering for table detection
    let enableTextClustering: Bool
    /// Tolerance for element alignment detection
    let alignmentTolerance: CGFloat
    /// Whether to extract font information
    let extractFontInfo: Bool
    
    /// Default configuration optimized for payslip parsing
    static let payslipDefault = ExtractionConfiguration(
        timeoutSeconds: 30.0,
        enableClassification: true,
        maxElementsPerPage: 1000,
        minimumElementSize: CGSize(width: 5, height: 5),
        enableTextClustering: true,
        alignmentTolerance: 10.0,
        extractFontInfo: true
    )
    
    /// Lightweight configuration for fast preview extraction
    static let fastPreview = ExtractionConfiguration(
        timeoutSeconds: 10.0,
        enableClassification: false,
        maxElementsPerPage: 200,
        minimumElementSize: CGSize(width: 10, height: 10),
        enableTextClustering: false,
        alignmentTolerance: 15.0,
        extractFontInfo: false
    )
}

/// Protocol for monitoring extraction progress and performance
@MainActor
protocol ExtractionProgressDelegate: AnyObject {
    /// Called when extraction starts
    /// - Parameter totalPages: Total number of pages to process
    func extractionDidStart(totalPages: Int)
    
    /// Called when a page is completed
    /// - Parameters:
    ///   - pageIndex: Index of completed page (0-based)
    ///   - elementsExtracted: Number of elements found on this page
    ///   - progress: Overall progress (0.0 to 1.0)
    func extractionDidCompletePage(pageIndex: Int, elementsExtracted: Int, progress: Double)
    
    /// Called when extraction completes successfully
    /// - Parameter result: The completed structured document
    func extractionDidComplete(result: StructuredDocument)
    
    /// Called when extraction fails
    /// - Parameter error: The error that caused failure
    func extractionDidFail(error: PDFExtractionError)
}
