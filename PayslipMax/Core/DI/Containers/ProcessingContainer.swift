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
        #if DEBUG
        if useMocks {
            return MockPDFTextExtractionService()
        }
        #endif
        
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
    
    /// Creates a text extraction engine. Until dependencies are fixed, return a safe unavailable stub.
    func makeTextExtractionEngine() -> TextExtractionEngineProtocol {
        #if DEBUG
        if useMocks {
            return UnavailableExtractionStubs.TextExtractionEngineStub()
        }
        #endif
        return UnavailableExtractionStubs.TextExtractionEngineStub()
    }
    
    /// Creates an extraction strategy selector. Returns a safe unavailable stub.
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        #if DEBUG
        if useMocks {
            return UnavailableExtractionStubs.ExtractionStrategySelectorStub()
        }
        #endif
        return UnavailableExtractionStubs.ExtractionStrategySelectorStub()
    }
    
    /// Creates a text processing pipeline. Returns a safe unavailable stub.
    func makeTextProcessingPipeline() -> TextProcessingPipelineProtocol {
        #if DEBUG
        if useMocks {
            return UnavailableExtractionStubs.TextProcessingPipelineStub()
        }
        #endif
        return UnavailableExtractionStubs.TextProcessingPipelineStub()
    }
    
    /// Creates an extraction result validator. Returns a safe unavailable stub.
    func makeExtractionResultValidator() -> ExtractionResultValidatorProtocol {
        #if DEBUG
        if useMocks {
            return UnavailableExtractionStubs.ExtractionResultValidatorStub()
        }
        #endif
        return UnavailableExtractionStubs.ExtractionResultValidatorStub()
    }
    
    /// Creates a simple extraction validator for PayslipItem validation.
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol {
        #if DEBUG
        if useMocks {
            return MockExtractionValidator()
        }
        #endif
        
        return ExtractionValidator()
    }
    
    /// Creates an extraction result assembler.
    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol {
        #if DEBUG
        if useMocks {
            return MockExtractionResultAssembler()
        }
        #endif
        
        return ExtractionResultAssembler()
    }
    
    /// Creates a text preprocessing service.
    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockTextPreprocessingService()
        }
        #endif
        
        return TextPreprocessingService()
    }
    
    /// Creates a pattern application engine.
    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        #if DEBUG
        if useMocks {
            return MockPatternApplicationEngine()
        }
        #endif
        
        return PatternApplicationEngine(
            preprocessingService: makeTextPreprocessingService()
        )
    }
}