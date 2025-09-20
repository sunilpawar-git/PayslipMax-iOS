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
        // Always use real implementation for now
        return PDFServiceAdapter(DefaultPDFService())
    }

    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        // Use the async-first implementation that eliminates DispatchSemaphore usage
        if let patternRepository = AppContainer.shared.resolve(PatternRepositoryProtocol.self) {
            // Create the async modular PDF extractor - cleaner concurrency, no semaphores
            return AsyncModularPDFExtractor(patternRepository: patternRepository)
        }

        // Unified architecture: Use AsyncModularPDFExtractor as fallback
        return AsyncModularPDFExtractor(patternRepository: DefaultPatternRepository())
    }

    /// Creates a data service.
    func makeDataService() -> DataServiceProtocol {
        // Create the service without automatic initialization
        let service = try! DataServiceImpl(securityService: securityService)

        // Since initialization is async and DIContainer is sync,
        // we'll rely on the service methods to handle initialization lazily when needed
        return service
    }

    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        return SecurityServiceImpl()
    }

    /// Creates a text extraction service
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        // Unified architecture: Use PDFTextExtractionService with adapter
        return PDFTextExtractionServiceAdapter(PDFTextExtractionService())
    }

    /// Creates a payslip format detection service
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return PayslipFormatDetectionService(textExtractionService: makeTextExtractionService())
    }

    /// Creates a payslip validation service
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        // Note: This creates a dependency on PDF text extraction service
        // We'll need to provide this dependency from the processing container
        // For now, create our own instance to avoid circular dependency
        let textExtractionService = PDFTextExtractionService()

        return PayslipValidationService(textExtractionService: textExtractionService)
    }

    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        do {
            return try PayslipEncryptionService.Factory.create()
        } catch {
            // Log the error and create a simple fallback
            print("Error creating PayslipEncryptionService: \(error.localizedDescription)")
            // For now, create a simple handler as fallback
            do {
                let fallbackHandler = try PayslipSensitiveDataHandler.Factory.create()
                return PayslipEncryptionService(sensitiveDataHandler: fallbackHandler)
            } catch {
                // If all else fails, we have a serious problem - use fatalError for now
                fatalError("Unable to create PayslipEncryptionService: \(error.localizedDescription)")
            }
        }
    }

    /// Creates an encryption service
    func makeEncryptionService() -> EncryptionServiceProtocol {
        return EncryptionService()
    }

    /// Creates a secure storage service
    func makeSecureStorage() -> SecureStorageProtocol {
        return KeychainSecureStorage()
    }

    // MARK: - Network Services

    /// Creates a network service for API communication
    func makeNetworkService() -> NetworkServiceProtocol {
        let responseHandler = makeNetworkResponseHandler()
        let uploadService = makeNetworkUploadService()

        return NetworkService(
            responseHandler: responseHandler,
            uploadService: uploadService
        )
    }

    /// Creates a network response handler service
    func makeNetworkResponseHandler() -> NetworkResponseHandlerProtocol {
        return NetworkResponseHandler()
    }

    /// Creates a network upload service
    func makeNetworkUploadService() -> NetworkUploadServiceProtocol {
        return NetworkUploadService()
    }

    /// Creates a document structure identifier service
    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol {
        return DocumentStructureIdentifier()
    }

    /// Creates a document section extractor service
    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol {
        return DocumentSectionExtractor()
    }

    /// Creates a personal info section parser service
    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol {
        return PersonalInfoSectionParser()
    }

    /// Creates a financial data section parser service
    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol {
        return FinancialDataSectionParser()
    }

    /// Creates a contact info section parser service
    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol {
        return ContactInfoSectionParser()
    }

    /// Creates a document metadata extractor service
    func makeDocumentMetadataExtractor() -> DocumentMetadataExtractorProtocol {
        return DocumentMetadataExtractor()
    }

    // MARK: - Business Logic Services

    /// Creates a financial calculation service.
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return the default implementation
            return FinancialCalculationService()
        }
        #endif

        // Use the singleton for now to maintain backward compatibility
        return FinancialCalculationUtility.shared
    }

    /// Creates a military abbreviation service.
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return a fresh instance
            return MilitaryAbbreviationService()
        }
        #endif

        // Use the bridge for now to maintain backward compatibility
        return MilitaryAbbreviationServiceBridge()
    }

    // MARK: - Pattern Extraction Services

    /// Creates a pattern loader service.
    func makePatternLoader() -> PatternLoaderProtocol {
        // Always return real implementation for now
        // TODO: Add mock support when MockPatternLoader is implemented
        return PatternLoader()
    }

    /// Creates a tabular data extractor service.
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol {
        // Always return real implementation for now
        // TODO: Add mock support when MockTabularDataExtractor is implemented
        return TabularDataExtractor()
    }

    /// Creates a pattern matching service.
    func makePatternMatchingService() -> PatternMatchingServiceProtocol {
        // Always return real implementation for now
        // TODO: Add mock support when MockPatternMatchingService is implemented
        return PatternMatchingService()
    }

    // MARK: - Performance Monitoring Services

    /// Creates a performance coordinator for unified performance monitoring
    func makePerformanceCoordinator() -> PerformanceCoordinatorProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return mock implementations if available
            return PerformanceCoordinator()
        }
        #endif

        return PerformanceCoordinator()
    }

    /// Creates an FPS monitor for frame rate tracking
    func makeFPSMonitor() -> FPSMonitorProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return mock implementation if available
            return PerformanceFPSMonitor()
        }
        #endif

        return PerformanceFPSMonitor()
    }

    /// Creates a memory monitor for memory usage tracking
    func makeMemoryMonitor() -> MemoryMonitorProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return mock implementation if available
            return PerformanceMemoryMonitor()
        }
        #endif

        return PerformanceMemoryMonitor()
    }

    /// Creates a CPU monitor for CPU usage tracking
    func makeCPUMonitor() -> CPUMonitorProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return mock implementation if available
            return PerformanceCPUMonitor()
        }
        #endif

        return PerformanceCPUMonitor()
    }

    /// Creates a performance reporter for generating reports
    func makePerformanceReporter() -> PerformanceReporterProtocol {
        #if DEBUG
        if useMocks {
            // For testing, return mock implementation if available
            return PerformanceReporter()
        }
        #endif

        return PerformanceReporter()
    }

    /// Creates a payslip display name service for clean UI presentation
    /// Enhanced for Phase 4: Universal Dual-Section Implementation
    func makePayslipDisplayNameService() -> PayslipDisplayNameServiceProtocol {
        let arrearsFormatter = ArrearsDisplayFormatter()
        return PayslipDisplayNameService(arrearsFormatter: arrearsFormatter)
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
