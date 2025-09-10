import Foundation
import PDFKit

/// Protocol defining the interface for processing services container.
/// This container handles text extraction, PDF processing, and payslip processing pipeline services.
@MainActor
protocol ProcessingContainerProtocol {
    // MARK: - Configuration

    /// Whether to use mock implementations for testing.
    var useMocks: Bool { get }

    // MARK: - Core Processing Services

    /// Creates a PDF text extraction service.
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol

    /// Creates a PDF parsing coordinator using the unified pipeline.
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol

    /// Creates a payslip processing pipeline.
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline

    /// Creates a payslip processor factory.
    func makePayslipProcessorFactory() -> PayslipProcessorFactory

    /// Creates a payslip import coordinator.
    func makePayslipImportCoordinator() -> PayslipImportCoordinator

    /// Creates an abbreviation manager.
    func makeAbbreviationManager() -> AbbreviationManager

    // MARK: - Enhanced Text Extraction Services (Currently Disabled)
    // Note: These are disabled due to implementation issues but defined for future use

    /// Creates a text extractor with pattern-based extraction capabilities.
    func makeTextExtractor() -> TextExtractor

    /// Creates an extraction strategy selector (currently disabled - returns fatalError).
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol

    /// Creates a simple text validator for basic extraction validation.
    func makeSimpleValidator() -> SimpleValidator

    /// Creates a simple extraction validator for PayslipItem validation.
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol

    /// Creates an extraction result assembler.
    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol

    /// Creates a text preprocessing service.
    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol

    /// Creates a data extraction service with all required dependencies.
    func makeDataExtractionService() -> DataExtractionServiceProtocol

    /// Creates a pattern application engine.
    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol

    /// Creates pattern application strategies for handling different pattern types.
    func makePatternApplicationStrategies() -> PatternApplicationStrategies

    /// Creates pattern application validation for validating patterns and extracted values.
    func makePatternApplicationValidation() -> PatternApplicationValidation

    /// Creates a pattern applier with proper dependency injection.
    func makePatternApplier() -> PatternApplier

    /// Creates an enhanced deduplication service with semantic fingerprinting.
    func makeEnhancedDeduplicationService() -> EnhancedDeduplicationServiceSimplified

    /// Creates an operation coalescing service for sharing results between identical requests.
    func makeOperationCoalescingService() -> OperationCoalescingServiceSimplified

    /// Creates a deduplication metrics service for monitoring optimization effectiveness.
    func makeDeduplicationMetricsService() -> DeduplicationMetricsServiceSimplified

    /// Creates an optimized stage transition manager for efficient pipeline processing.
    func makeOptimizedStageTransitionManager() -> OptimizedStageTransitionManager

    /// Creates an intelligent batch processor for adaptive batch optimization.
    func makeIntelligentBatchProcessor() -> IntelligentBatchProcessor

    /// Creates an enhanced modular pipeline with optimized stage transitions.
    func makeEnhancedModularPipeline() -> EnhancedModularPipeline

    /// Creates processing pipeline stages for cache management and operation coordination.
    func makeProcessingPipelineStages() -> ProcessingPipelineStages

    /// Creates processing pipeline optimization for performance tracking and memory pressure handling.
    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization

    /// Creates an enhanced memory manager for memory pressure monitoring.
    func makeEnhancedMemoryManager() -> EnhancedMemoryManager

    /// Creates an optimized processing pipeline with proper dependency injection.
    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline

    /// Creates a positional element extractor for spatial PDF parsing.
    func makePositionalElementExtractor() async -> PositionalElementExtractorProtocol

    /// Creates an element type classifier for categorizing extracted elements.
    func makeElementTypeClassifier() -> ElementTypeClassifier

    /// Creates a spatial analyzer for understanding element relationships.
    func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol

    /// Creates an enhanced tabular data extractor with spatial intelligence.
    func makeEnhancedTabularDataExtractor() -> TabularDataExtractor

    /// Creates a contextual pattern matcher with spatial validation.
    func makeContextualPatternMatcher() -> ContextualPatternMatcher

    /// Creates a spatial data extraction service for enhanced processing.
    func makeSpatialDataExtractionService() -> SpatialDataExtractionService

    /// Creates a performance monitoring service for PDF processing.
    func makePDFProcessingPerformanceMonitor() -> PDFProcessingPerformanceMonitor

    /// Creates a result merger for combining legacy and enhanced extraction results.
    func makePDFResultMerger() -> PDFResultMerger

    /// Creates a financial pattern extractor for legacy extraction compatibility.
    func makeFinancialPatternExtractor() -> FinancialPatternExtractor

    /// Creates a column boundary detector for table structure analysis.
    func makeColumnBoundaryDetector() -> ColumnBoundaryDetector

    /// Creates a row associator for organizing elements into table rows.
    func makeRowAssociator() -> RowAssociator

    /// Creates a spatial section classifier for identifying document sections.
    func makeSpatialSectionClassifier() -> SpatialSectionClassifier

    /// Creates an enhanced processing pipeline integrator with advanced deduplication.
    func makeEnhancedProcessingPipelineIntegrator() -> EnhancedProcessingPipelineIntegratorSimplified

    // MARK: - Phase 4 Enhanced Processing Services

    /// Creates an enhanced PDF service with spatial extraction capabilities
    func makeEnhancedPDFService() -> PDFService

    /// Creates an enhanced PDF processor with dual-mode processing capabilities
    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor

    // MARK: - Streaming Batch Processing Services

    /// Creates a streaming batch coordinator for memory-efficient PDF processing
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator

    /// Creates a streaming batch processor for executing page batches
    func makeStreamingBatchProcessor() -> StreamingBatchProcessor

    /// Creates a batch configuration calculator for adaptive settings
    func makeBatchConfigurationCalculator() -> BatchConfigurationCalculator

    /// Creates a batch progress tracker for monitoring and reporting
    func makeBatchProgressTracker() -> BatchProgressTracker

    /// Creates a resource pressure monitor for memory management
    func makeResourcePressureMonitor() -> ResourcePressureMonitor

    /// Creates a memory optimized extractor for text processing
    func makeMemoryOptimizedExtractor() -> MemoryOptimizedExtractor

    /// Creates an adaptive cache manager for result caching
    func makeAdaptiveCacheManager() -> AdaptiveCacheManager
    
    // MARK: - Section-Aware Processing Services
    
    /// Creates a section-aware pattern matcher with Universal RH and Arrears support
    func makeSectionAwarePatternMatcher() -> SectionAwarePatternMatcherProtocol
}
