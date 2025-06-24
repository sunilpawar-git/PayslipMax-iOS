import Foundation
import PDFKit
import SwiftUI
import SwiftData

@MainActor
class DIContainer {
    // MARK: - Properties
    
    /// The shared instance of the DI container.
    static let shared = DIContainer()
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool = false
    
    // MARK: - WebUpload Feature
    
    /// Whether to use the mock WebUploadService even in release builds
    /// This can be toggled at runtime for testing purposes
    private var forceWebUploadMock: Bool = false
    
    /// The base URL to use for API calls
    /// This can be changed at runtime for testing with different environments
    private var webAPIBaseURL: URL = URL(string: "https://payslipmax.com/api")!
    
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
        let pdfHandler = makePDFProcessingHandler()
        let dataHandler = makePayslipDataHandler()
        let chartService = makeChartDataPreparationService()
        let passwordHandler = makePasswordProtectedPDFHandler()
        let errorHandler = makeErrorHandler()
        let navigationCoordinator = makeHomeNavigationCoordinator()
        
        return HomeViewModel(
            pdfHandler: pdfHandler,
            dataHandler: dataHandler,
            chartService: chartService,
            passwordHandler: passwordHandler,
            errorHandler: errorHandler,
            navigationCoordinator: navigationCoordinator
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
    
    /// Creates a PayslipRepository instance
    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        #if DEBUG
        if useMocks {
            // This would be a mock implementation if needed
            return PayslipRepository(modelContext: modelContext)
        }
        #endif
        return PayslipRepository(modelContext: modelContext)
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
    
    /// Creates an auth view model.
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: securityService)
    }
    
    /// Cached view models for state consistency
    private var _payslipsViewModel: PayslipsViewModel?
    
    /// Creates a payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        // Return cached instance if available to maintain state consistency
        if let existingViewModel = _payslipsViewModel {
            return existingViewModel
        }
        
        // Create a new instance and cache it
        let viewModel = PayslipsViewModel(dataService: makeDataService())
        _payslipsViewModel = viewModel
        return viewModel
    }
    
    /// Creates an insights coordinator.
    func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: makeDataService())
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
    
    /// Creates a background task coordinator
    @MainActor
    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator {
        // Use the shared instance for now since BackgroundTaskCoordinator is designed as a singleton
        return BackgroundTaskCoordinator.shared
    }
    
    /// Creates a task priority queue with configurable concurrency
    func makeTaskPriorityQueue(maxConcurrentTasks: Int = 4) -> TaskPriorityQueue {
        return TaskPriorityQueue(maxConcurrentTasks: maxConcurrentTasks)
    }
    
    /// Creates a PDFProcessingHandler instance
    func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }
    
    /// Creates a payslip data handler.
    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: dataService)
    }
    
    /// Creates a chart data preparation service.
    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }
    
    /// Creates a PasswordProtectedPDFHandler instance
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: pdfService)
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
    
    /// Creates a PCDAPayslipHandler.
    func makePCDAPayslipHandler() -> PCDAPayslipHandler {
        #if DEBUG
        if useMocks {
            // In the future, we might want to create a mock implementation
            return PCDAPayslipHandler()
        }
        #endif
        
        return PCDAPayslipHandler()
    }
    
    /// Creates a quiz generation service.
    func makeQuizGenerationService() -> QuizGenerationService {
        return QuizGenerationService(
            financialSummaryViewModel: FinancialSummaryViewModel(),
            trendAnalysisViewModel: TrendAnalysisViewModel(),
            chartDataViewModel: ChartDataViewModel()
        )
    }
    
    /// Creates an achievement service.
    func makeAchievementService() -> AchievementService {
        return AchievementService()
    }
    
    /// Creates a quiz view model.
    func makeQuizViewModel() -> QuizViewModel {
        return QuizViewModel(
            quizGenerationService: makeQuizGenerationService(),
            achievementService: makeAchievementService()
        )
    }
    
    /// Toggle the use of mock WebUploadService
    /// - Parameter useMock: Whether to use the mock service
    func toggleWebUploadMock(_ useMock: Bool) {
        forceWebUploadMock = useMock
        // Clear any cached instances
        _webUploadService = nil
        print("DIContainer: WebUploadService mock mode set to: \(useMock)")
    }
    
    /// Set the base URL for API calls
    /// - Parameter url: The base URL to use
    func setWebAPIBaseURL(_ url: URL) {
        webAPIBaseURL = url
        // Clear any cached instances to ensure they use the new URL
        _webUploadService = nil
        print("DIContainer: WebAPI base URL set to: \(url.absoluteString)")
    }
    
    /// Cached instance of WebUploadService
    private var _webUploadService: WebUploadServiceProtocol?
    
    /// Creates a WebUploadService instance
    func makeWebUploadService() -> WebUploadServiceProtocol {
        // Return cached instance if available
        if let service = _webUploadService {
            return service
        }
        
        // Determine whether to use mock
        #if DEBUG
        let shouldUseMock = useMocks || forceWebUploadMock
        #else
        let shouldUseMock = forceWebUploadMock
        #endif
        
        if shouldUseMock {
            print("DIContainer: Creating MockWebUploadService")
            _webUploadService = MockWebUploadService()
            return _webUploadService!
        }
        
        print("DIContainer: Creating WebUploadCoordinator with base URL: \(webAPIBaseURL.absoluteString)")
        _webUploadService = WebUploadCoordinator.create(
            secureStorage: makeSecureStorage(),
            baseURL: webAPIBaseURL
        )
        return _webUploadService!
    }
    
    /// Creates a WebUploadViewModel
    func makeWebUploadViewModel() -> WebUploadViewModel {
        return WebUploadViewModel(
            webUploadService: makeWebUploadService()
        )
    }
    
    /// Creates a WebUploadDeepLinkHandler
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler {
        return WebUploadDeepLinkHandler(
            webUploadService: makeWebUploadService()
        )
    }
    
    /// Creates a SecureStorage implementation
    func makeSecureStorage() -> SecureStorageProtocol {
        #if DEBUG
        if useMocks {
            // Mock implementation would go here
            return MockSecureStorage()
        }
        #endif
        
        return KeychainSecureStorage()
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
    
    /// Access the global navigation router
    var router: any RouterProtocol {
        get {
            // Check if we already have a router instance
            if let appDelegate = UIApplication.shared.delegate,
               let router = objc_getAssociatedObject(appDelegate, "router") as? (any RouterProtocol) {
                return router
            }
            
            // Try to resolve from the app container
            if let sharedRouter = AppContainer.shared.resolve((any RouterProtocol).self) {
                return sharedRouter
            }
            
            // If we can't find the router, log a warning and create a new one
            // This should rarely happen in production
            print("Warning: Creating a new router instance in DIContainer. This may cause navigation issues.")
            return NavRouter()
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
        case is WebUploadServiceProtocol.Type:
            return makeWebUploadService() as? T
        case is SecureStorageProtocol.Type:
            return makeSecureStorage() as? T
        case is WebUploadDeepLinkHandler.Type:
            return makeWebUploadDeepLinkHandler() as? T
        case is GlobalLoadingManager.Type:
            return makeGlobalLoadingManager() as? T
        case is GlobalOverlaySystem.Type:
            return makeGlobalOverlaySystem() as? T
        case is TabTransitionCoordinator.Type:
            return makeTabTransitionCoordinator() as? T
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
    
    // MARK: - Global System Services
    
    /// Provides access to the global loading manager
    func makeGlobalLoadingManager() -> GlobalLoadingManager {
        return GlobalLoadingManager.shared
    }
    
    /// Provides access to the global overlay system
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem {
        return GlobalOverlaySystem.shared
    }
    
    /// Provides access to the tab transition coordinator
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator {
        return TabTransitionCoordinator.shared
    }
} 