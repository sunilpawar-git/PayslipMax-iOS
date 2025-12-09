import Foundation
import PDFKit

/// Factory for processing service delegations in the DI container.
/// Handles delegations to processing container services.
@MainActor
class ProcessingFactory {

    // MARK: - Dependencies

    /// Processing container for accessing processing services
    private let processingContainer: ProcessingContainerProtocol

    // MARK: - Initialization

    init(processingContainer: ProcessingContainerProtocol) {
        self.processingContainer = processingContainer
    }

    // MARK: - Processing Service Delegations

    /// Creates a TextExtractor.
    func makeTextExtractor() -> TextExtractor {
        return processingContainer.makeTextExtractor()
    }

    /// Creates an ExtractionStrategySelector.
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        return processingContainer.makeExtractionStrategySelector()
    }

    /// Creates a SimpleValidator.
    func makeSimpleValidator() -> SimpleValidator {
        return processingContainer.makeSimpleValidator()
    }

    /// Creates a DataExtractionService.
    func makeDataExtractionService() -> DataExtractionServiceProtocol {
        return processingContainer.makeDataExtractionService()
    }

    /// Creates a PDFTextExtractionService.
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingContainer.makePDFTextExtractionService()
    }

    /// Creates a PayslipProcessorFactory.
    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return processingContainer.makePayslipProcessorFactory()
    }

    /// Creates a PDFParsingCoordinator.
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return processingContainer.makePDFParsingCoordinator()
    }

    /// Creates a PayslipProcessingPipeline.
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return processingContainer.makePayslipProcessingPipeline()
    }

    /// Creates a PayslipImportCoordinator.
    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return processingContainer.makePayslipImportCoordinator()
    }

    /// Creates an AbbreviationManager.
    func makeAbbreviationManager() -> AbbreviationManager {
        return processingContainer.makeAbbreviationManager()
    }

    // MARK: - Optimized Processing Pipeline Components

    /// Creates ProcessingPipelineStages.
    func makeProcessingPipelineStages() -> ProcessingPipelineStages {
        return processingContainer.makeProcessingPipelineStages()
    }

    /// Creates ProcessingPipelineOptimization.
    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization {
        return processingContainer.makeProcessingPipelineOptimization()
    }

    /// Creates an OptimizedProcessingPipeline.
    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline {
        return processingContainer.makeOptimizedProcessingPipeline()
    }

    // MARK: - Streaming Batch Processing

    /// Creates a StreamingBatchCoordinator.
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return processingContainer.makeStreamingBatchCoordinator()
    }
}
