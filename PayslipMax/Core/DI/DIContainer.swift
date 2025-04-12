import Foundation
import PDFKit
import SwiftUI

@MainActor
class DIContainer {
    // MARK: - Properties
    
    /// The shared instance of the DI container.
    static let shared = DIContainer()
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool = false
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }
    
    // MARK: - Factory Methods
    
    /// Creates a PDFProcessingService.
    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return PDFProcessingService(
            pdfService: makePDFService(),
            pdfExtractor: makePDFExtractor(),
            parsingCoordinator: makePDFParsingCoordinator(),
            formatDetectionService: makePayslipFormatDetectionService(),
            validationService: makePayslipValidationService(),
            textExtractionService: makePDFTextExtractionService()
        )
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
    
    /// Creates a PDFValidationService instance
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        #if DEBUG
            if useMocks {
                return MockPayslipValidationService()
            }
        #endif
        
        return PayslipValidationService(textExtractionService: makePDFTextExtractionService())
    }
    
    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfHandler: makePDFProcessingHandler(),
            dataHandler: makePayslipDataHandler(),
            chartService: makeChartDataPreparationService(),
            passwordHandler: makePasswordProtectedPDFHandler(),
            errorHandler: makeErrorHandler(),
            navigationCoordinator: makeHomeNavigationCoordinator()
        )
    }
    
    /// Creates a PDFProcessingViewModel.
    func makePDFProcessingViewModel() -> any ObservableObject {
        // Use the updated HomeViewModel constructor
        return makeHomeViewModel()
    }
    
    /// Creates a PayslipDataViewModel.
    func makePayslipDataViewModel() -> any ObservableObject {
        // Fallback - use PayslipsViewModel instead
        return PayslipsViewModel(dataService: makeDataService())
    }
    
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
            return MockDataService()
        }
        #endif
        
        // Create the service without automatic initialization
        let service = DataServiceImpl(securityService: securityService)
        
        // Since initialization is async and DIContainer is sync,
        // we'll rely on the service methods to handle initialization lazily when needed
        return service
    }
    
    /// Creates an auth view model.
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: securityService)
    }
    
    /// Creates a payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: makeDataService())
    }
    
    /// Creates an insights view model.
    func makeInsightsViewModel() -> InsightsViewModel {
        return InsightsViewModel(dataService: makeDataService())
    }
    
    /// Creates a settings view model.
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: securityService, dataService: makeDataService())
    }
    
    /// Creates a security view model (for settings).
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockSecurityService()
        }
        #endif
        return SecurityServiceImpl()
    }
    
    /// Creates a PDF processing handler.
    func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }
    
    /// Creates a payslip data handler.
    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: makeDataService())
    }
    
    /// Creates a chart data preparation service.
    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }
    
    /// Creates a password-protected PDF handler.
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: makePDFService())
    }
    
    /// Creates a home navigation coordinator.
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return HomeNavigationCoordinator()
    }
    
    /// Creates an error handler.
    func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }
    
    /// Creates a PDFTextExtractionService instance
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockPDFTextExtractionService()
        }
        #endif
        
        return PDFTextExtractionService()
    }
    
    /// Creates a PayslipProcessorFactory instance
    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return PayslipProcessorFactory(formatDetectionService: makePayslipFormatDetectionService())
    }
    
    /// Creates a PDFParsingCoordinator instance
    func makePDFParsingCoordinator() -> PDFParsingCoordinator {
        let abbreviationManager = AbbreviationManager()
        return PDFParsingCoordinator(abbreviationManager: abbreviationManager)
    }
    
    /// Creates a PayslipProcessingPipeline instance
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return DefaultPayslipProcessingPipeline(
            validationService: makePayslipValidationService(),
            textExtractionService: makePDFTextExtractionService(),
            formatDetectionService: makePayslipFormatDetectionService(),
            processorFactory: makePayslipProcessorFactory()
        )
    }
    
    /// Creates a PayslipImportCoordinator instance
    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return PayslipImportCoordinator(
            parsingCoordinator: makePDFParsingCoordinator(),
            abbreviationManager: makeAbbreviationManager()
        )
    }
    
    /// Creates an AbbreviationManager instance (assuming singleton for now)
    /// TODO: Review lifecycle and potential need for protocol/mocking
    func makeAbbreviationManager() -> AbbreviationManager {
        // If AbbreviationManager is a simple class, direct instantiation might be okay
        // If it has dependencies or needs mocking, adjust accordingly
        return AbbreviationManager()
    }
    
    /// Creates a DestinationFactory instance
    func makeDestinationFactory() -> DestinationFactoryProtocol {
        return DestinationFactory(
            dataService: makeDataService(),
            pdfManager: PDFUploadManager()
        )
    }
    
    /// Creates a DestinationConverter instance
    func makeDestinationConverter() -> DestinationConverter {
        return DestinationConverter(dataService: makeDataService())
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
    @MainActor
    func makeEncryptionService() -> EncryptionServiceProtocol {
        if useMocks {
            return MockEncryptionService()
        } else {
            return EncryptionService()
        }
    }
    
    // MARK: - Private Properties
    
    /// The security service instance (for internal caching)
    private var _securityService: SecurityServiceProtocol?
    
    /// Access the security service
    var securityService: SecurityServiceProtocol {
        get {
            if _securityService == nil {
                _securityService = makeSecurityService()
            }
            return _securityService!
        }
    }
    
    /// Access the data service
    var dataService: DataServiceProtocol {
        get {
            return makeDataService()
        }
    }
    
    /// Access the PDF service
    var pdfService: PDFServiceProtocol {
        get {
            return makePDFService()
        }
    }
    
    /// Access the PDF extractor
    var pdfExtractor: PDFExtractorProtocol {
        get {
            return makePDFExtractor()
        }
    }
    
    // Keep for backward compatibility
    var biometricAuthService: BiometricAuthService {
        get {
            return BiometricAuthService()
        }
    }
    
    // MARK: - Testing Utilities
    
    static var forTesting: DIContainer {
        return DIContainer(useMocks: true)
    }
    
    static func setShared(_ container: DIContainer) {
        // This method is only meant for testing
        #if DEBUG
        // Use Objective-C runtime to directly modify the shared property
        objc_setAssociatedObject(DIContainer.self, "shared", container, .OBJC_ASSOCIATION_RETAIN)
        #endif
    }
    
    /// Resolves a service of the specified type
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service type
    @MainActor
    func resolve<T>(_ type: T.Type) -> T? {
        switch type {
        case is PDFProcessingServiceProtocol.Type:
            return makePDFProcessingService() as? T
        case is TextExtractionServiceProtocol.Type:
            return makeTextExtractionService() as? T
        case is PayslipFormatDetectionServiceProtocol.Type:
            return makePayslipFormatDetectionService() as? T
        case is PayslipValidationServiceProtocol.Type:
            return makePayslipValidationService() as? T
        case is PDFServiceProtocol.Type:
            return makePDFService() as? T
        case is PDFExtractorProtocol.Type:
            return makePDFExtractor() as? T
        case is DataServiceProtocol.Type:
            return makeDataService() as? T
        case is SecurityServiceProtocol.Type:
            return makeSecurityService() as? T
        case is DestinationFactoryProtocol.Type:
            return makeDestinationFactory() as? T
        case is EncryptionServiceProtocol.Type:
            return makeEncryptionService() as? T
        case is PayslipEncryptionServiceProtocol.Type:
            return makePayslipEncryptionService() as? T
        default:
            return nil
        }
    }
    
    /// Resolves a service of the specified type asynchronously
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service type
    @MainActor
    func resolveAsync<T>(_ type: T.Type) async -> T? {
        // Simply call the synchronous version
        // Since we're already in a @MainActor context, this is safe
        return resolve(type)
    }
} 