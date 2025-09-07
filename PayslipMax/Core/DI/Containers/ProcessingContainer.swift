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
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }
    
    // MARK: - Core Processing Services
    
    /// Creates a PDF text extraction service.
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return PDFTextExtractionService()
    }
    
    /// Creates a PDF parsing coordinator using the unified processing pipeline.
    /// Uses direct pipeline integration without adapter layer for better performance.
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        let pipeline = makePayslipProcessingPipeline()
        return UnifiedPDFParsingCoordinator(pipeline: pipeline)
    }
    
    /// Creates a unified modular payslip processing pipeline.
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return ModularPayslipProcessingPipeline(
            validationStep: AnyPayslipProcessingStep(ValidationProcessingStep(validationService: coreContainer.makePayslipValidationService())),
            textExtractionStep: AnyPayslipProcessingStep(TextExtractionProcessingStep(
                textExtractionService: makePDFTextExtractionService(),
                validationService: coreContainer.makePayslipValidationService())),
            formatDetectionStep: AnyPayslipProcessingStep(FormatDetectionProcessingStep(
                formatDetectionService: coreContainer.makePayslipFormatDetectionService())),
            processingStep: AnyPayslipProcessingStep(PatternExtractionProcessingStep())
        )
    }
    
    /// Creates an enhanced processing pipeline integrator with advanced deduplication.
    func makeEnhancedProcessingPipelineIntegrator() -> EnhancedProcessingPipelineIntegratorSimplified {
        return EnhancedProcessingPipelineIntegratorSimplified(
            originalPipeline: makePayslipProcessingPipeline() as! ModularPayslipProcessingPipeline,
            deduplicationService: makeEnhancedDeduplicationService(),
            coalescingService: makeOperationCoalescingService()
        )
    }
    
    /// Creates a payslip processor factory.
    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return PayslipProcessorFactory(formatDetectionService: coreContainer.makePayslipFormatDetectionService())
    }
    
    /// Creates a payslip import coordinator.
    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return PayslipImportCoordinator(
            parsingCoordinator: makePDFParsingCoordinator(),
            abbreviationManager: makeAbbreviationManager()
        )
    }
    
    /// Creates an abbreviation manager.
    func makeAbbreviationManager() -> AbbreviationManager {
        // Note: Using as singleton pattern for now
        // TODO: Review lifecycle and potential need for protocol/mocking
        return AbbreviationManager()
    }
    
    // MARK: - Enhanced Text Extraction Services
    // Note: Advanced text extraction services with strategy selection and optimization
    
    /// Creates a text extractor with pattern-based extraction capabilities.
    func makeTextExtractor() -> TextExtractor {
        let patternProvider = DefaultPatternProvider()
        return DefaultTextExtractor(patternProvider: patternProvider)
    }
    
    /// Creates an extraction strategy selector.
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        #if DEBUG
        if useMocks {
            // TODO: Create mock implementation if needed
            // return MockExtractionStrategySelector()
        }
        #endif

        // Create with proper dependencies according to extracted component architecture
        return ExtractionStrategySelector(
            strategies: ExtractionStrategies(),
            evaluationRules: ExtractionStrategies.defaultEvaluationRules()
        )
    }
    
    
    /// Creates a simple text validator for basic extraction validation.
    func makeSimpleValidator() -> SimpleValidator {
        return SimpleValidator()
    }
    
    /// Creates a simple extraction validator for PayslipItem validation.
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol {
        return ExtractionValidator()
    }
    
    /// Creates an extraction result assembler.
    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol {
        return ExtractionResultAssembler()
    }
    
    /// Creates a text preprocessing service.
    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol {
        return TextPreprocessingService()
    }
    
    /// Creates a data extraction service with all required dependencies.
    func makeDataExtractionService() -> DataExtractionServiceProtocol {
        return DataExtractionService(
            algorithms: DataExtractionAlgorithms(),
            validation: DataExtractionValidation()
        )
    }
    
    /// Creates a pattern application engine.
    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        return PatternApplicationEngine(
            preprocessingService: makeTextPreprocessingService()
        )
    }
    
    // MARK: - Pattern Application Components (Phase 2 Refactored)
    
    /// Creates pattern application strategies for handling different pattern types
    func makePatternApplicationStrategies() -> PatternApplicationStrategies {
        return PatternApplicationStrategies()
    }
    
    /// Creates pattern application validation for validating patterns and extracted values
    func makePatternApplicationValidation() -> PatternApplicationValidation {
        return PatternApplicationValidation()
    }
    
    /// Creates a pattern applier with proper dependency injection
    func makePatternApplier() -> PatternApplier {
        return PatternApplier(
            strategies: makePatternApplicationStrategies(),
            validation: makePatternApplicationValidation()
        )
    }
    
    // MARK: - Enhanced Deduplication Services (Phase 3)
    
    /// Creates an enhanced deduplication service with semantic fingerprinting.
    func makeEnhancedDeduplicationService() -> EnhancedDeduplicationServiceSimplified {
        return EnhancedDeduplicationServiceSimplified()
    }
    
    /// Creates an operation coalescing service for sharing results between identical requests.
    func makeOperationCoalescingService() -> OperationCoalescingServiceSimplified {
        return OperationCoalescingServiceSimplified()
    }
    
    /// Creates a deduplication metrics service for monitoring optimization effectiveness.
    func makeDeduplicationMetricsService() -> DeduplicationMetricsServiceSimplified {
        return DeduplicationMetricsServiceSimplified()
    }
    
    // MARK: - Stage Transition Optimization Components
    
    /// Creates an optimized stage transition manager for efficient pipeline processing.
    func makeOptimizedStageTransitionManager() -> OptimizedStageTransitionManager {
        return OptimizedStageTransitionManager()
    }
    
    /// Creates an intelligent batch processor for adaptive batch optimization.
    func makeIntelligentBatchProcessor() -> IntelligentBatchProcessor {
        return IntelligentBatchProcessor()
    }
    
    /// Creates an enhanced modular pipeline with optimized stage transitions.
    func makeEnhancedModularPipeline() -> EnhancedModularPipeline {
        return EnhancedModularPipeline(
            originalPipeline: makePayslipProcessingPipeline() as! ModularPayslipProcessingPipeline,
            stageTransitionManager: makeOptimizedStageTransitionManager(),
            batchProcessor: makeIntelligentBatchProcessor()
        )
    }
    
    // MARK: - Optimized Processing Pipeline Components
    
    /// Creates processing pipeline stages for cache management and operation coordination
    func makeProcessingPipelineStages() -> ProcessingPipelineStages {
        return ProcessingPipelineStages()
    }
    
    /// Creates processing pipeline optimization for performance tracking and memory pressure handling
    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization {
        return ProcessingPipelineOptimization(memoryManager: makeEnhancedMemoryManager())
    }
    
    /// Creates an enhanced memory manager for memory pressure monitoring
    func makeEnhancedMemoryManager() -> EnhancedMemoryManager {
        return EnhancedMemoryManager()
    }
    
    /// Creates an optimized processing pipeline with proper dependency injection
    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline {
        return OptimizedProcessingPipeline(
            stages: makeProcessingPipelineStages(),
            optimization: makeProcessingPipelineOptimization()
        )
    }
    
    // MARK: - Spatial Parsing Services (Phase 1 Enhancement)
    
    /// Creates a positional element extractor for spatial PDF parsing
    func makePositionalElementExtractor() async -> PositionalElementExtractorProtocol {
        return await MainActor.run {
            DefaultPositionalElementExtractor(
                configuration: .payslipDefault,
                elementClassifier: makeElementTypeClassifier()
            )
        }
    }
    
    /// Creates an element type classifier for categorizing extracted elements
    func makeElementTypeClassifier() -> ElementTypeClassifier {
        return ElementTypeClassifier()
    }
    
    /// Creates a spatial analyzer for understanding element relationships
    func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        return SpatialAnalyzer(configuration: .payslipDefault)
    }
    
    /// Creates an enhanced tabular data extractor with spatial intelligence
    func makeEnhancedTabularDataExtractor() -> TabularDataExtractor {
        return TabularDataExtractor(spatialAnalyzer: makeSpatialAnalyzer())
    }
    
    /// Creates a contextual pattern matcher with spatial validation
    func makeContextualPatternMatcher() -> ContextualPatternMatcher {
        return ContextualPatternMatcher(
            configuration: .payslipDefault,
            spatialAnalyzer: makeSpatialAnalyzer()
        )
    }
    
    /// Creates an enhanced PDF service with spatial extraction capabilities
    func makeEnhancedPDFService() -> PDFService {
        return DefaultPDFService(positionalExtractor: nil) // Will be created lazily when needed
    }
    
    // MARK: - Enhanced PDF Processing Services (Phase 4)
    
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
    
    // MARK: - Streaming Batch Processing Services
    
    /// Creates a streaming batch coordinator for memory-efficient PDF processing
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return StreamingBatchCoordinator(
            pressureMonitor: makeResourcePressureMonitor(),
            batchProcessor: makeStreamingBatchProcessor(),
            configurationCalculator: makeBatchConfigurationCalculator(),
            progressTracker: makeBatchProgressTracker()
        )
    }
    
    /// Creates a streaming batch processor for executing page batches
    func makeStreamingBatchProcessor() -> StreamingBatchProcessor {
        return StreamingBatchProcessor(
            memoryExtractor: makeMemoryOptimizedExtractor(),
            cacheManager: makeAdaptiveCacheManager()
        )
    }
    
    /// Creates a batch configuration calculator for adaptive settings
    func makeBatchConfigurationCalculator() -> BatchConfigurationCalculator {
        return BatchConfigurationCalculator(
            pressureMonitor: makeResourcePressureMonitor()
        )
    }
    
    /// Creates a batch progress tracker for monitoring and reporting
    func makeBatchProgressTracker() -> BatchProgressTracker {
        return BatchProgressTracker()
    }
    
    /// Creates a resource pressure monitor for memory management
    func makeResourcePressureMonitor() -> ResourcePressureMonitor {
        return ResourcePressureMonitor()
    }
    
    /// Creates a memory optimized extractor for text processing
    func makeMemoryOptimizedExtractor() -> MemoryOptimizedExtractor {
        return MemoryOptimizedExtractor()
    }
    
    /// Creates an adaptive cache manager for result caching
    func makeAdaptiveCacheManager() -> AdaptiveCacheManager {
        return AdaptiveCacheManager()
    }
}