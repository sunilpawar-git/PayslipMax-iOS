import Foundation
import PDFKit

/// Factory for enhanced PDF processing services.
/// Handles dual-mode PDF processing with legacy and spatial intelligence capabilities.
@MainActor
class PDFProcessingFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Enhanced PDF Processing Services

    /// Creates an enhanced PDF processor with dual-mode processing capabilities
    /// Combines legacy text extraction with spatial intelligence for maximum accuracy
    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor {
        return EnhancedPDFProcessor(
            legacyPDFService: makeEnhancedPDFService(),
            spatialExtractionService: makeSpatialDataExtractionService(),
            performanceMonitor: makePDFProcessingPerformanceMonitor(),
            resultMerger: makePDFResultMerger(),
            configuration: .default
        )
    }

    /// Creates a spatial data extraction service for enhanced processing
    func makeSpatialDataExtractionService() -> SpatialDataExtractionService {
        return SpatialDataExtractionService(
            patternExtractor: makeFinancialPatternExtractor(),
            spatialAnalyzer: makeSpatialAnalyzer(),
            columnDetector: makeColumnBoundaryDetector(),
            rowAssociator: makeRowAssociator(),
            sectionClassifier: makeSpatialSectionClassifier()
        )
    }

    /// Creates a performance monitoring service for PDF processing
    func makePDFProcessingPerformanceMonitor() -> PDFProcessingPerformanceMonitor {
        return PDFProcessingPerformanceMonitor()
    }

    /// Creates a result merger for combining legacy and enhanced extraction results
    func makePDFResultMerger() -> PDFResultMerger {
        return PDFResultMerger(configuration: .default)
    }

    /// Creates a financial pattern extractor for legacy extraction compatibility
    func makeFinancialPatternExtractor() -> FinancialPatternExtractor {
        return FinancialPatternExtractor()
    }

    /// Creates a column boundary detector for table structure analysis
    func makeColumnBoundaryDetector() -> ColumnBoundaryDetector {
        return ColumnBoundaryDetector()
    }

    /// Creates a row associator for organizing elements into table rows
    func makeRowAssociator() -> RowAssociator {
        return RowAssociator()
    }

    /// Creates a spatial section classifier for identifying document sections
    func makeSpatialSectionClassifier() -> SpatialSectionClassifier {
        return SpatialSectionClassifier(configuration: .payslipDefault)
    }

    // MARK: - Private Methods

    /// Creates an enhanced PDF service (placeholder - actual implementation in SpatialParsingFactory)
    private func makeEnhancedPDFService() -> PDFService {
        // This is a placeholder - in actual usage, this would be injected from SpatialParsingFactory
        fatalError("This method should be overridden or injected from SpatialParsingFactory")
    }

    /// Creates a spatial analyzer (placeholder - actual implementation in SpatialParsingFactory)
    private func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        // This is a placeholder - in actual usage, this would be injected from SpatialParsingFactory
        fatalError("This method should be overridden or injected from SpatialParsingFactory")
    }
}
