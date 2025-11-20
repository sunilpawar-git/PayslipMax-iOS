import Foundation
import PDFKit

/// Factory for core processing services in the processing container.
/// Handles basic PDF text extraction, parsing coordination, and processing pipeline creation.
@MainActor
class CoreProcessingFactory {

    // MARK: - Dependencies

    /// Core service container for accessing validation and format detection services
    private let coreContainer: CoreServiceContainerProtocol

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

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
            processingStep: AnyPayslipProcessingStep(PayslipProcessingStepImpl(
                processorFactory: makePayslipProcessorFactory()))
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
        return PayslipProcessorFactory(
            formatDetectionService: coreContainer.makePayslipFormatDetectionService()
        )
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

    // MARK: - Deduplication Services (Integrated)

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
}
