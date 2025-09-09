import Foundation
import PDFKit

/// Container for processing services that handle text extraction, PDF processing, and payslip processing pipelines.
/// Handles text extraction, PDF parsing, and processing pipeline coordination.
@MainActor
class ProcessingContainer: ProcessingContainerProtocol {

    // MARK: - Properties

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    // MARK: - Dependencies

    /// Core service container for accessing validation and format detection services
    private let coreContainer: CoreServiceContainerProtocol

    // MARK: - Factory

    /// Unified processing service factory that handles all processing services
    private lazy var processingFactory = UnifiedProcessingFactory(useMocks: useMocks, coreContainer: coreContainer)

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }

    // MARK: - Core Processing Services

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingFactory.makePDFTextExtractionService()
    }

    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return processingFactory.makePDFParsingCoordinator()
    }

    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return processingFactory.makePayslipProcessingPipeline()
    }

    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return processingFactory.makePayslipProcessorFactory()
    }

    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return processingFactory.makePayslipImportCoordinator()
    }

    func makeAbbreviationManager() -> AbbreviationManager {
        return processingFactory.makeAbbreviationManager()
    }

    // MARK: - Text Extraction Services

    func makeTextExtractor() -> TextExtractor {
        return processingFactory.makeTextExtractor()
    }

    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        return processingFactory.makeExtractionStrategySelector()
    }

    func makeSimpleValidator() -> SimpleValidator {
        return processingFactory.makeSimpleValidator()
    }

    // MARK: - Pattern Application Services

    func makePatternApplicationStrategies() -> PatternApplicationStrategies {
        return processingFactory.makePatternApplicationStrategies()
    }

    func makePatternApplicationValidation() -> PatternApplicationValidation {
        return processingFactory.makePatternApplicationValidation()
    }

    func makePatternApplier() -> PatternApplier {
        return processingFactory.makePatternApplier()
    }

    // MARK: - Unified Factory Delegations

    // Essential methods - delegate all protocol requirements to unified factory
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return processingFactory.makeStreamingBatchCoordinator()
    }

    // Protocol conformance methods - all delegate to unified factory
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol {
        return processingFactory.makeSimpleExtractionValidator()
    }

    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol {
        return processingFactory.makeExtractionResultAssembler()
    }

    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol {
        return processingFactory.makeTextPreprocessingService()
    }

    func makeDataExtractionService() -> DataExtractionServiceProtocol {
        return processingFactory.makeDataExtractionService()
    }

    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        return processingFactory.makePatternApplicationEngine()
    }

    func makeEnhancedDeduplicationService() -> EnhancedDeduplicationServiceSimplified {
        return processingFactory.makeEnhancedDeduplicationService()
    }

    func makeOperationCoalescingService() -> OperationCoalescingServiceSimplified {
        return processingFactory.makeOperationCoalescingService()
    }

    func makeDeduplicationMetricsService() -> DeduplicationMetricsServiceSimplified {
        return processingFactory.makeDeduplicationMetricsService()
    }

    func makeOptimizedStageTransitionManager() -> OptimizedStageTransitionManager {
        return processingFactory.makeOptimizedStageTransitionManager()
    }

    func makeIntelligentBatchProcessor() -> IntelligentBatchProcessor {
        return processingFactory.makeIntelligentBatchProcessor()
    }

    func makeEnhancedModularPipeline() -> EnhancedModularPipeline {
        return processingFactory.makeEnhancedModularPipeline()
    }

    func makeProcessingPipelineStages() -> ProcessingPipelineStages {
        return processingFactory.makeProcessingPipelineStages()
    }

    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization {
        return processingFactory.makeProcessingPipelineOptimization()
    }

    func makeEnhancedMemoryManager() -> EnhancedMemoryManager {
        return processingFactory.makeEnhancedMemoryManager()
    }

    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline {
        return processingFactory.makeOptimizedProcessingPipeline()
    }

    func makePositionalElementExtractor() async -> PositionalElementExtractorProtocol {
        return await processingFactory.makePositionalElementExtractor()
    }

    func makeElementTypeClassifier() -> ElementTypeClassifier {
        return processingFactory.makeElementTypeClassifier()
    }

    func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        return processingFactory.makeSpatialAnalyzer()
    }

    func makeEnhancedTabularDataExtractor() -> TabularDataExtractor {
        return processingFactory.makeEnhancedTabularDataExtractor()
    }

    func makeContextualPatternMatcher() -> ContextualPatternMatcher {
        return processingFactory.makeContextualPatternMatcher()
    }

    func makeSpatialDataExtractionService() -> SpatialDataExtractionService {
        return processingFactory.makeSpatialDataExtractionService()
    }

    func makePDFProcessingPerformanceMonitor() -> PDFProcessingPerformanceMonitor {
        return processingFactory.makePDFProcessingPerformanceMonitor()
    }

    func makePDFResultMerger() -> PDFResultMerger {
        return processingFactory.makePDFResultMerger()
    }

    func makeFinancialPatternExtractor() -> FinancialPatternExtractor {
        return processingFactory.makeFinancialPatternExtractor()
    }

    func makeColumnBoundaryDetector() -> ColumnBoundaryDetector {
        return processingFactory.makeColumnBoundaryDetector()
    }

    func makeRowAssociator() -> RowAssociator {
        return processingFactory.makeRowAssociator()
    }

    func makeSpatialSectionClassifier() -> SpatialSectionClassifier {
        return processingFactory.makeSpatialSectionClassifier()
    }

    func makeEnhancedProcessingPipelineIntegrator() -> EnhancedProcessingPipelineIntegratorSimplified {
        return processingFactory.makeEnhancedProcessingPipelineIntegrator()
    }

    func makeEnhancedPDFService() -> PDFService {
        return processingFactory.makeEnhancedPDFService()
    }

    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor {
        return processingFactory.makeEnhancedPDFProcessor()
    }

    func makeStreamingBatchProcessor() -> StreamingBatchProcessor {
        return processingFactory.makeStreamingBatchProcessor()
    }

    func makeBatchConfigurationCalculator() -> BatchConfigurationCalculator {
        return processingFactory.makeBatchConfigurationCalculator()
    }

    func makeBatchProgressTracker() -> BatchProgressTracker {
        return processingFactory.makeBatchProgressTracker()
    }

    func makeResourcePressureMonitor() -> ResourcePressureMonitor {
        return processingFactory.makeResourcePressureMonitor()
    }

    func makeMemoryOptimizedExtractor() -> MemoryOptimizedExtractor {
        return processingFactory.makeMemoryOptimizedExtractor()
    }

    func makeAdaptiveCacheManager() -> AdaptiveCacheManager {
        return processingFactory.makeAdaptiveCacheManager()
    }
}
