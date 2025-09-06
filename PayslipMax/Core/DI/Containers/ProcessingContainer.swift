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
    
    
    /// Creates an extraction strategy selector.
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        #if DEBUG
        if useMocks {
            // TODO: Create mock implementation if needed
            // return MockExtractionStrategySelector()
        }
        #endif
        
        return ExtractionStrategySelector(
            documentAnalyzer: ExtractionDocumentAnalyzer(),
            memoryManager: TextExtractionMemoryManager()
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
    
    /// Creates a pattern application engine.
    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        return PatternApplicationEngine(
            preprocessingService: makeTextPreprocessingService()
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
}