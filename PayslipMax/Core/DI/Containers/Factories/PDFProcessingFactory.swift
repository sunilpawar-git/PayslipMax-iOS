import Foundation
import PDFKit

/// Factory for enhanced PDF processing services.
/// Handles dual-mode PDF processing with legacy and spatial intelligence capabilities.
@MainActor
class PDFProcessingFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    /// Text extraction factory for universal systems
    private let textExtractionFactory: TextExtractionFactory

    /// Spatial parsing factory for spatial intelligence
    private let spatialParsingFactory: SpatialParsingFactory

    // MARK: - Initialization

    init(useMocks: Bool = false,
         textExtractionFactory: TextExtractionFactory,
         spatialParsingFactory: SpatialParsingFactory) {
        self.useMocks = useMocks
        self.textExtractionFactory = textExtractionFactory
        self.spatialParsingFactory = spatialParsingFactory
    }

    // MARK: - Enhanced PDF Processing Services

    /// Creates an enhanced PDF processor with dual-mode processing capabilities
    /// Combines legacy text extraction with spatial intelligence for maximum accuracy
    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor {
        return EnhancedPDFProcessor(
            legacyPDFService: spatialParsingFactory.makeEnhancedPDFService(),
            spatialExtractionService: makeSpatialDataExtractionService(),
            performanceMonitor: makePDFProcessingPerformanceMonitor(),
            resultMerger: makePDFResultMerger(),
            configuration: .default
        )
    }

    /// Creates a spatial data extraction service for enhanced processing with Phase 5 universal systems integration
    func makeSpatialDataExtractionService() -> SpatialDataExtractionService {
        return SpatialDataExtractionService(
            patternExtractor: makeFinancialPatternExtractor(),
            spatialAnalyzer: makeSpatialAnalyzer(),
            columnDetector: makeColumnBoundaryDetector(),
            rowAssociator: makeRowAssociator(),
            sectionClassifier: makeSpatialSectionClassifier(),
            extractionUtilities: SpatialExtractionUtilities(),
            universalIntegrator: makeUniversalSystemsIntegrator()
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

    /// Creates a spatial analyzer using spatial parsing factory
    private func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        return spatialParsingFactory.makeSpatialAnalyzer()
    }

    /// Creates a universal pay code search engine using text extraction factory
    private func makeUniversalPayCodeSearchEngine() -> UniversalPayCodeSearchEngineProtocol {
        return textExtractionFactory.makeUniversalPayCodeSearchEngine()
    }

    /// Creates a universal arrears pattern matcher using text extraction factory
    private func makeUniversalArrearsPatternMatcher() -> UniversalArrearsPatternMatcherProtocol {
        return textExtractionFactory.makeUniversalArrearsPatternMatcher()
    }

    /// Creates a universal systems integrator for Phase 5 integration
    private func makeUniversalSystemsIntegrator() -> UniversalSystemsIntegrator {
        return UniversalSystemsIntegrator(
            universalPayCodeSearch: makeUniversalPayCodeSearchEngine(),
            universalArrearsPattern: makeUniversalArrearsPatternMatcher(),
            patternExtractor: makeFinancialPatternExtractor()
        )
    }
}
