import Foundation
import PDFKit

/// Extension containing all unified factory delegations for ProcessingContainer.
/// This extension handles the creation and delegation of all processing services
/// through the unified processing factory to maintain separation of concerns.
extension ProcessingContainer {

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

    /// Creates a universal arrears pattern matcher for Phase 3 implementation.
    func makeUniversalArrearsPatternMatcher() -> UniversalArrearsPatternMatcherProtocol {
        return processingFactory.makeUniversalArrearsPatternMatcher()
    }

    /// Creates a universal pay code search engine for Phase 4 implementation.
    func makeUniversalPayCodeSearchEngine() -> UniversalPayCodeSearchEngineProtocol {
        return processingFactory.makeUniversalPayCodeSearchEngine()
    }
}
