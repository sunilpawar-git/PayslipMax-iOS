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
    
    /// Creates an extraction strategy selector (currently disabled - returns fatalError).
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol
    
    /// Creates a simple text validator for basic extraction validation.
    func makeSimpleValidator() -> SimpleValidator
    
    // MARK: - Phase 4 Enhanced Processing Services
    
    /// Creates an enhanced PDF service with spatial extraction capabilities
    func makeEnhancedPDFService() -> PDFService
    
    /// Creates an enhanced PDF processor with dual-mode processing capabilities
    func makeEnhancedPDFProcessor() -> EnhancedPDFProcessor
}