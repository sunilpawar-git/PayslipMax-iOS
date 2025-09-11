import Foundation
import PDFKit

/// Unified factory for all processing services.
/// Combines all processing-related factories into a single, streamlined interface.
@MainActor
class UnifiedProcessingFactory {

    // MARK: - Dependencies

    /// Core service container for accessing validation and format detection services
    private let coreContainer: CoreServiceContainerProtocol

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Sub-factories

    /// Core processing factory for basic processing services
    private lazy var coreProcessingFactory = CoreProcessingFactory(useMocks: useMocks, coreContainer: coreContainer)

    /// Text extraction factory for enhanced extraction services
    private lazy var textExtractionFactory = TextExtractionFactory(useMocks: useMocks)

    /// Pattern application factory for pattern processing
    private lazy var patternApplicationFactory = PatternApplicationFactory(useMocks: useMocks)

    /// Pipeline optimization factory for performance enhancements
    private lazy var pipelineOptimizationFactory = PipelineOptimizationFactory(useMocks: useMocks)

    /// Spatial parsing factory for advanced document analysis
    private lazy var spatialParsingFactory = SpatialParsingFactory(useMocks: useMocks)

    /// PDF processing factory for enhanced document processing
    private lazy var pdfProcessingFactory = PDFProcessingFactory(
        useMocks: useMocks,
        textExtractionFactory: textExtractionFactory,
        spatialParsingFactory: spatialParsingFactory
    )

    /// Streaming batch factory for memory-efficient processing
    private lazy var streamingBatchFactory = StreamingBatchFactory(useMocks: useMocks)

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }

    // MARK: - Core Processing Services

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return coreProcessingFactory.makePDFTextExtractionService()
    }

    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return coreProcessingFactory.makePDFParsingCoordinator()
    }

    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return coreProcessingFactory.makePayslipProcessingPipeline()
    }

    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return coreProcessingFactory.makePayslipProcessorFactory()
    }

    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return coreProcessingFactory.makePayslipImportCoordinator()
    }

    func makeAbbreviationManager() -> AbbreviationManager {
        return coreProcessingFactory.makeAbbreviationManager()
    }

    // MARK: - Text Extraction Services

    func makeTextExtractor() -> TextExtractor {
        return textExtractionFactory.makeTextExtractor()
    }

    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        return textExtractionFactory.makeExtractionStrategySelector()
    }

    func makeSimpleValidator() -> SimpleValidator {
        return textExtractionFactory.makeSimpleValidator()
    }

    // MARK: - Pattern Application Services

    func makePatternApplicationStrategies() -> PatternApplicationStrategies {
        return patternApplicationFactory.makePatternApplicationStrategies()
    }

    func makePatternApplicationValidation() -> PatternApplicationValidation {
        return patternApplicationFactory.makePatternApplicationValidation()
    }

    func makePatternApplier() -> PatternApplier {
        return patternApplicationFactory.makePatternApplier()
    }

    // MARK: - Pipeline Optimization Services

    func makeProcessingPipelineStages() -> ProcessingPipelineStages {
        return pipelineOptimizationFactory.makeProcessingPipelineStages()
    }

    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization {
        return pipelineOptimizationFactory.makeProcessingPipelineOptimization()
    }

    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline {
        return pipelineOptimizationFactory.makeOptimizedProcessingPipeline()
    }

    // MARK: - Spatial Parsing Services

    func makePositionalElementExtractor() async -> PositionalElementExtractorProtocol {
        return await spatialParsingFactory.makePositionalElementExtractor()
    }

    func makeElementTypeClassifier() -> ElementTypeClassifier {
        return spatialParsingFactory.makeElementTypeClassifier()
    }

    func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        return spatialParsingFactory.makeSpatialAnalyzer()
    }

    func makeEnhancedTabularDataExtractor() -> TabularDataExtractor {
        return spatialParsingFactory.makeEnhancedTabularDataExtractor()
    }

    func makeContextualPatternMatcher() -> ContextualPatternMatcher {
        return spatialParsingFactory.makeContextualPatternMatcher()
    }

    func makeEnhancedPDFService() -> PDFService {
        return spatialParsingFactory.makeEnhancedPDFService()
    }

    // MARK: - PDF Processing Services

    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor {
        return pdfProcessingFactory.makeEnhancedPDFProcessor()
    }

    func makeSpatialDataExtractionService() -> SpatialDataExtractionService {
        return pdfProcessingFactory.makeSpatialDataExtractionService()
    }

    func makePDFProcessingPerformanceMonitor() -> PDFProcessingPerformanceMonitor {
        return pdfProcessingFactory.makePDFProcessingPerformanceMonitor()
    }

    func makePDFResultMerger() -> PDFResultMerger {
        return pdfProcessingFactory.makePDFResultMerger()
    }

    func makeFinancialPatternExtractor() -> FinancialPatternExtractor {
        return pdfProcessingFactory.makeFinancialPatternExtractor()
    }

    func makeColumnBoundaryDetector() -> ColumnBoundaryDetector {
        return pdfProcessingFactory.makeColumnBoundaryDetector()
    }

    func makeRowAssociator() -> RowAssociator {
        return pdfProcessingFactory.makeRowAssociator()
    }

    func makeSpatialSectionClassifier() -> SpatialSectionClassifier {
        return pdfProcessingFactory.makeSpatialSectionClassifier()
    }

    // MARK: - Streaming Batch Services

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return streamingBatchFactory.makeStreamingBatchCoordinator()
    }

    func makeStreamingBatchProcessor() -> StreamingBatchProcessor {
        return streamingBatchFactory.makeStreamingBatchProcessor()
    }

    func makeBatchConfigurationCalculator() -> BatchConfigurationCalculator {
        return streamingBatchFactory.makeBatchConfigurationCalculator()
    }

    func makeBatchProgressTracker() -> BatchProgressTracker {
        return streamingBatchFactory.makeBatchProgressTracker()
    }

    func makeResourcePressureMonitor() -> ResourcePressureMonitor {
        return streamingBatchFactory.makeResourcePressureMonitor()
    }

    func makeMemoryOptimizedExtractor() -> MemoryOptimizedExtractor {
        return streamingBatchFactory.makeMemoryOptimizedExtractor()
    }

    func makeAdaptiveCacheManager() -> AdaptiveCacheManager {
        return streamingBatchFactory.makeAdaptiveCacheManager()
    }

    // Additional methods for protocol conformance
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol {
        return textExtractionFactory.makeSimpleExtractionValidator()
    }

    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol {
        return textExtractionFactory.makeExtractionResultAssembler()
    }

    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol {
        return textExtractionFactory.makeTextPreprocessingService()
    }

    func makeDataExtractionService() -> DataExtractionServiceProtocol {
        return textExtractionFactory.makeDataExtractionService()
    }

    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        return textExtractionFactory.makePatternApplicationEngine()
    }

    func makeEnhancedDeduplicationService() -> EnhancedDeduplicationServiceSimplified {
        return coreProcessingFactory.makeEnhancedDeduplicationService()
    }

    func makeOperationCoalescingService() -> OperationCoalescingServiceSimplified {
        return coreProcessingFactory.makeOperationCoalescingService()
    }

    func makeDeduplicationMetricsService() -> DeduplicationMetricsServiceSimplified {
        return coreProcessingFactory.makeDeduplicationMetricsService()
    }

    func makeOptimizedStageTransitionManager() -> OptimizedStageTransitionManager {
        return pipelineOptimizationFactory.makeOptimizedStageTransitionManager()
    }

    func makeIntelligentBatchProcessor() -> IntelligentBatchProcessor {
        return pipelineOptimizationFactory.makeIntelligentBatchProcessor()
    }

    func makeEnhancedModularPipeline() -> EnhancedModularPipeline {
        return pipelineOptimizationFactory.makeEnhancedModularPipeline()
    }

    func makeEnhancedMemoryManager() -> EnhancedMemoryManager {
        return pipelineOptimizationFactory.makeEnhancedMemoryManager()
    }

    func makeEnhancedProcessingPipelineIntegrator() -> EnhancedProcessingPipelineIntegratorSimplified {
        return coreProcessingFactory.makeEnhancedProcessingPipelineIntegrator()
    }

    /// Creates a universal arrears pattern matcher for Phase 3 implementation.
    func makeUniversalArrearsPatternMatcher() -> UniversalArrearsPatternMatcherProtocol {
        return textExtractionFactory.makeUniversalArrearsPatternMatcher()
    }

    /// Creates a universal pay code search engine for Phase 4 implementation.
    func makeUniversalPayCodeSearchEngine() -> UniversalPayCodeSearchEngineProtocol {
        return textExtractionFactory.makeUniversalPayCodeSearchEngine()
    }
}
