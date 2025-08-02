import Foundation
import PDFKit
import SwiftUI
import SwiftData

/// Container for core services that other components depend on.
/// Handles PDF, Security, Data, Validation, and Encryption services.
@MainActor
class CoreServiceContainer: CoreServiceContainerProtocol {
    
    // MARK: - Properties
    
    /// Whether to use mock implementations for testing.
    let useMocks: Bool
    
    // MARK: - Private Cached Services
    
    /// Cached security service instance for consistency
    private var _securityService: SecurityServiceProtocol?
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }
    
    // MARK: - Core Services
    
    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockPDFService()
        }
        #endif
        return PDFServiceAdapter(DefaultPDFService())
    }
    
    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        #if DEBUG
        if useMocks {
            return MockPDFExtractor()
        }
        #endif
        
        // Check if we can get a pattern repository from AppContainer
        if let patternRepository = AppContainer.shared.resolve(PatternRepositoryProtocol.self) {
            return ModularPDFExtractor(patternRepository: patternRepository)
        }
        
        // Fall back to the old implementation if pattern repository is not available
        return DefaultPDFExtractor()
    }
    
    /// Creates a data service.
    func makeDataService() -> DataServiceProtocol {
        #if DEBUG
        if useMocks {
            // Create a DataServiceImpl with the mock security service instead of using MockDataService
            return DataServiceImpl(securityService: securityService)
        }
        #endif
        
        // Create the service without automatic initialization
        let service = DataServiceImpl(securityService: securityService)
        
        // Since initialization is async and DIContainer is sync,
        // we'll rely on the service methods to handle initialization lazily when needed
        return service
    }
    
    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        #if DEBUG
        if useMocks {
            return CoreMockSecurityService()
        }
        #endif
        return SecurityServiceImpl()
    }
    
    /// Creates a text extraction service
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockTextExtractionService()
        }
        #endif
        
        return TextExtractionService()
    }
    
    /// Creates a payslip format detection service
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockPayslipFormatDetectionService()
        }
        #endif
        
        return PayslipFormatDetectionService(textExtractionService: makeTextExtractionService())
    }
    
    /// Creates a payslip validation service
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        #if DEBUG
            if useMocks {
                return MockPayslipValidationService()
            }
        #endif
        
        // Note: This creates a dependency on PDF text extraction service
        // We'll need to provide this dependency from the processing container
        // For now, create our own instance to avoid circular dependency
        let textExtractionService: PDFTextExtractionServiceProtocol
        #if DEBUG
        if useMocks {
            textExtractionService = MockPDFTextExtractionService()
        } else {
            textExtractionService = PDFTextExtractionService()
        }
        #else
        textExtractionService = PDFTextExtractionService()
        #endif
        
        return PayslipValidationService(textExtractionService: textExtractionService)
    }
    
    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        #if DEBUG
        if useMocks {
            // Use a mock when available
            return MockPayslipEncryptionService()
        }
        #endif
        
        do {
            return try PayslipEncryptionService.Factory.create()
        } catch {
            // Log the error
            print("Error creating PayslipEncryptionService: \(error.localizedDescription)")
            // Return a fallback implementation that will report errors when used
            return FallbackPayslipEncryptionService(error: error)
        }
    }
    
    /// Creates an encryption service
    func makeEncryptionService() -> EncryptionServiceProtocol {
        if useMocks {
            return MockEncryptionService()
        } else {
            return EncryptionService()
        }
    }
    
    /// Creates a secure storage service
    func makeSecureStorage() -> SecureStorageProtocol {
        #if DEBUG
        if useMocks {
            return MockSecureStorage()
        }
        #endif
        
        return KeychainSecureStorage()
    }
    
    /// Creates a document structure identifier service
    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol {
        #if DEBUG
        if useMocks {
            return MockDocumentStructureIdentifier()
        }
        #endif
        
        return DocumentStructureIdentifier()
    }
    
    /// Creates a document section extractor service
    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol {
        #if DEBUG
        if useMocks {
            return MockDocumentSectionExtractor()
        }
        #endif
        
        return DocumentSectionExtractor()
    }
    
    /// Creates a personal info section parser service
    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol {
        #if DEBUG
        if useMocks {
            return MockPersonalInfoSectionParser()
        }
        #endif
        
        return PersonalInfoSectionParser()
    }
    
    /// Creates a financial data section parser service
    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol {
        #if DEBUG
        if useMocks {
            return MockFinancialDataSectionParser()
        }
        #endif
        
        return FinancialDataSectionParser()
    }
    
    /// Creates a contact info section parser service
    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol {
        #if DEBUG
        if useMocks {
            return MockContactInfoSectionParser()
        }
        #endif
        
        return ContactInfoSectionParser()
    }
    
    // MARK: - Internal Access
    
    /// Access the security service (cached for consistency)
    var securityService: SecurityServiceProtocol {
        get {
            if _securityService == nil {
                _securityService = makeSecurityService()
            }
            return _securityService!
        }
    }
}