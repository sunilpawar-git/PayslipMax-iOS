import Foundation
import SwiftUI

/// Protocol defining the interface for core services container.
/// This container handles fundamental services that other components depend on.
@MainActor 
protocol CoreServiceContainerProtocol {
    // MARK: - Configuration
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool { get }
    
    // MARK: - Core Services
    
    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol
    
    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol
    
    /// Creates a data service.
    func makeDataService() -> DataServiceProtocol
    
    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol
    
    /// Creates a text extraction service.
    func makeTextExtractionService() -> TextExtractionServiceProtocol
    
    /// Creates a payslip format detection service.
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol
    
    /// Creates a payslip validation service.
    func makePayslipValidationService() -> PayslipValidationServiceProtocol
    
    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol
    
    /// Creates an encryption service.
    func makeEncryptionService() -> EncryptionServiceProtocol
    
    /// Creates a secure storage service.
    func makeSecureStorage() -> SecureStorageProtocol
    
    /// Creates a document structure identifier service.
    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol
    
    /// Creates a document section extractor service.
    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol
    
    /// Creates a personal info section parser service.
    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol
    
    /// Creates a financial data section parser service.
    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol
    
    /// Creates a contact info section parser service.
    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol
    
    /// Creates a document metadata extractor service.
    func makeDocumentMetadataExtractor() -> DocumentMetadataExtractorProtocol

    /// Creates a financial calculation service.
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol

    /// Creates a military abbreviation service.
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol

    /// Creates a pattern loader service.
    func makePatternLoader() -> PatternLoaderProtocol

    /// Creates a tabular data extractor service.
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol

    /// Creates a pattern matching service.
    func makePatternMatchingService() -> PatternMatchingServiceProtocol

    /// Creates a performance coordinator.
    func makePerformanceCoordinator() -> PerformanceCoordinatorProtocol

    /// Creates an FPS monitor.
    func makeFPSMonitor() -> FPSMonitorProtocol

    /// Creates a memory monitor.
    func makeMemoryMonitor() -> MemoryMonitorProtocol

    /// Creates a CPU monitor.
    func makeCPUMonitor() -> CPUMonitorProtocol

    /// Creates a performance reporter.
    func makePerformanceReporter() -> PerformanceReporterProtocol
}