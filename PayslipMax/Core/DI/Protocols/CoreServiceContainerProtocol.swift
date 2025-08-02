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
}