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
        #if DEBUG
        if useMocks {
            return MockPDFProcessingService()
        }
        #endif
        
        let abbreviationManager = AbbreviationManager()
        let parsingCoordinator = PDFParsingCoordinator(abbreviationManager: abbreviationManager)
        
        return PDFProcessingService(
            pdfService: makePDFService(),
            pdfExtractor: makePDFExtractor(),
            parsingCoordinator: parsingCoordinator
        )
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
        return DataServiceImpl(securityService: securityService)
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
} 