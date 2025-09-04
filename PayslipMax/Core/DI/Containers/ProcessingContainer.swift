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
    
    /// Creates a PDF parsing coordinator.
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        let abbreviationManager = AbbreviationManager()
        return PDFParsingOrchestrator(abbreviationManager: abbreviationManager)
    }
    
    /// Creates a payslip processing pipeline.
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return DefaultPayslipProcessingPipeline(
            validationService: coreContainer.makePayslipValidationService(),
            textExtractionService: makePDFTextExtractionService(),
            formatDetectionService: coreContainer.makePayslipFormatDetectionService(),
            processorFactory: makePayslipProcessorFactory()
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
    
    // MARK: - Enhanced Text Extraction Services (Currently Disabled)
    // Note: These services have implementation issues and are disabled with fatalError
    // They are preserved here to maintain the interface for future fixes
    
    
    /// Creates an extraction strategy selector (currently disabled - returns fatalError).
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        #if DEBUG
        if useMocks {
            // TODO: Create mock implementation if needed
            // return MockExtractionStrategySelector()
        }
        #endif
        
        // TODO: Fix memory manager type mismatch
        fatalError("ExtractionStrategySelector requires fixing memory manager type mismatch")
    }
    
    
    /// Creates an extraction result validator (currently disabled - returns fatalError).
    func makeExtractionResultValidator() -> ExtractionResultValidatorProtocol {
        #if DEBUG
        if useMocks {
            // TODO: Create mock implementation if needed
            // return MockExtractionResultValidator()
        }
        #endif
        
        // TODO: Fix dependency initialization issues
        fatalError("ExtractionResultValidator requires implementing service dependencies")
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
}