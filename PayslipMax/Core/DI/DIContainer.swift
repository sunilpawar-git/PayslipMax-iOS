import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

@MainActor
class DIContainer {
    // MARK: - Properties

    /// The shared instance of the DI container.
    static let shared = DIContainer()

    /// Whether to use mock implementations for testing.
    var useMocks: Bool = false

    // MARK: - Container Dependencies

    /// Core services container for PDF, Security, Data, Validation, and Encryption services
    private lazy var coreContainer = CoreServiceContainer(useMocks: useMocks)

    /// Processing container for text extraction, PDF processing, and payslip processing pipelines
    private lazy var processingContainer = ProcessingContainer(useMocks: useMocks, coreContainer: coreContainer)

    /// ViewModel container for all ViewModels and their supporting services
    private lazy var viewModelContainer = ViewModelContainer(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)

    /// Feature container for WebUpload, Quiz, Achievement, and other feature services
    private lazy var featureContainer = FeatureContainer(useMocks: useMocks, coreContainer: coreContainer)

    // MARK: - Factories

    /// Core service factory for core service creation
    private lazy var coreServiceFactory = CoreServiceFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)

    /// ViewModel factory for ViewModel creation
    private lazy var viewModelFactory = ViewModelFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer, viewModelContainer: viewModelContainer)

    /// Processing factory for processing service delegations
    private lazy var processingFactory = ProcessingFactory(processingContainer: processingContainer)

    /// Feature factory for feature-specific services
    private lazy var featureFactory = FeatureFactory(useMocks: useMocks, featureContainer: featureContainer)

    /// Global service factory for global system services
    private lazy var globalServiceFactory = GlobalServiceFactory(useMocks: useMocks, coreContainer: coreContainer)

    /// Unified factory for all DI container services
    private lazy var unifiedFactory = UnifiedDIContainerFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer, viewModelContainer: viewModelContainer, featureContainer: featureContainer)

    /// Service resolver for service resolution by type
    private lazy var serviceResolver = ServiceResolver(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer, viewModelContainer: viewModelContainer, featureContainer: featureContainer)

    /// Public access to feature container
    var featureContainerPublic: FeatureContainerProtocol {
        return featureContainer
    }

    // MARK: - Configuration (moved to FeatureContainer)

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Factory Methods

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return unifiedFactory.makePDFProcessingService()
    }

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return coreServiceFactory.makeTextExtractionService()
    }

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return unifiedFactory.makeStreamingBatchCoordinator()
    }

    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return coreServiceFactory.makePayslipFormatDetectionService()
    }

    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return coreServiceFactory.makePayslipValidationService()
    }

    func makeTextExtractor() -> TextExtractor {
        return processingFactory.makeTextExtractor()
    }

    func makeHomeViewModel() -> HomeViewModel {
        return unifiedFactory.makeHomeViewModel()
    }

    func makePDFProcessingViewModel() -> any ObservableObject {
        return unifiedFactory.makePDFProcessingViewModel()
    }

    func makePayslipDataViewModel() -> any ObservableObject {
        return unifiedFactory.makePayslipDataViewModel()
    }

    func makePDFService() -> PDFServiceProtocol { unifiedFactory.makePDFService() }
    func makePDFExtractor() -> PDFExtractorProtocol { unifiedFactory.makePDFExtractor() }

    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol { coreServiceFactory.makeFinancialCalculationService() }
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol { coreServiceFactory.makeMilitaryAbbreviationService() }

    func makePatternLoader() -> PatternLoaderProtocol { coreServiceFactory.makePatternLoader() }
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol { coreServiceFactory.makeTabularDataExtractor() }
    func makePatternMatchingService() -> PatternMatchingServiceProtocol { coreServiceFactory.makePatternMatchingService() }

    // MARK: - Essential Factory Methods

    /// Creates a PayslipRepository instance
    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        return unifiedFactory.makePayslipRepository(modelContext: modelContext)
    }

    /// Creates a PayslipMigrationUtilities instance with proper dependencies
    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        return unifiedFactory.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    /// Creates a PayslipBatchOperations instance with proper dependencies
    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        return unifiedFactory.makePayslipBatchOperations(modelContext: modelContext)
    }

    // Essential service delegations
    func makeDataService() -> DataServiceProtocol { unifiedFactory.makeDataService() }
    func makeAuthViewModel() -> AuthViewModel { viewModelFactory.makeAuthViewModel() }
    func makePayslipsViewModel() -> PayslipsViewModel { unifiedFactory.makePayslipsViewModel() }
    func makeInsightsCoordinator() -> InsightsCoordinator { unifiedFactory.makeInsightsCoordinator() }
    func makeSettingsViewModel() -> SettingsViewModel { unifiedFactory.makeSettingsViewModel() }
    func makeSecurityViewModel() -> SecurityViewModel { unifiedFactory.makeSecurityViewModel() }
    func makeSecurityService() -> SecurityServiceProtocol { coreServiceFactory.makeSecurityService() }

    // Essential pattern and service methods
    func makePatternManagementViewModel() -> PatternManagementViewModel { viewModelFactory.makePatternManagementViewModel() }
    func makePatternValidationViewModel() -> PatternValidationViewModel { viewModelFactory.makePatternValidationViewModel() }
    func makePatternListViewModel() -> PatternListViewModel { viewModelFactory.makePatternListViewModel() }
    func makePatternItemEditViewModel() -> PatternItemEditViewModel { viewModelFactory.makePatternItemEditViewModel() }
    func makePatternEditViewModel() -> PatternEditViewModel { viewModelFactory.makePatternEditViewModel() }
    func makePayslipExtractorService() -> PayslipExtractorService { globalServiceFactory.makePayslipExtractorService() }
    func makeBiometricAuthService() -> BiometricAuthService { globalServiceFactory.makeBiometricAuthService() }
    func makePDFManager() -> PDFManager { unifiedFactory.makePDFManager() }
    func makeAnalyticsManager() -> AnalyticsManager { unifiedFactory.makeAnalyticsManager() }
    func makeBankingPatternsProvider() -> BankingPatternsProvider { globalServiceFactory.makeBankingPatternsProvider() }
    func makeFinancialPatternsProvider() -> FinancialPatternsProvider { globalServiceFactory.makeFinancialPatternsProvider() }
    func makeDocumentAnalysisCoordinator() -> DocumentAnalysisCoordinator { globalServiceFactory.makeDocumentAnalysisCoordinator() }
    func makePatternTestingViewModel() -> PatternTestingViewModel { viewModelFactory.makePatternTestingViewModel() }
    func makePayslipPatternManager() -> PayslipPatternManager { globalServiceFactory.makePayslipPatternManager() }
    func makeGamificationCoordinator() -> GamificationCoordinator { globalServiceFactory.makeGamificationCoordinator() }
    @MainActor func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator { unifiedFactory.makeBackgroundTaskCoordinator() }

    // Essential handler services
    func makePDFProcessingHandler() -> PDFProcessingHandler { globalServiceFactory.makePDFProcessingHandler() }
    func makePayslipDataHandler() -> PayslipDataHandler { globalServiceFactory.makePayslipDataHandler() }
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator { globalServiceFactory.makeHomeNavigationCoordinator() }
    open func makeErrorHandler() -> ErrorHandler { globalServiceFactory.makeErrorHandler() }

    // Essential processing services
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol { processingFactory.makePDFTextExtractionService() }
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol { processingFactory.makeExtractionStrategySelector() }
    func makeSimpleValidator() -> SimpleValidator { processingFactory.makeSimpleValidator() }
    func makePayslipProcessorFactory() -> PayslipProcessorFactory { processingFactory.makePayslipProcessorFactory() }
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol { processingFactory.makePDFParsingCoordinator() }
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline { processingFactory.makePayslipProcessingPipeline() }
    func makePayslipImportCoordinator() -> PayslipImportCoordinator { processingFactory.makePayslipImportCoordinator() }
    func makeAbbreviationManager() -> AbbreviationManager { processingFactory.makeAbbreviationManager() }

    @MainActor func makeSubscriptionManager() -> SubscriptionManager { featureFactory.makeSubscriptionManager() }
    func makeDestinationFactory() -> DestinationFactoryProtocol { globalServiceFactory.makeDestinationFactory() }
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol { coreServiceFactory.makePayslipEncryptionService() }
    @MainActor func makeEncryptionService() -> EncryptionServiceProtocol { coreServiceFactory.makeEncryptionService() }
    func makePCDAPayslipHandler() -> PCDAPayslipHandler { globalServiceFactory.makePCDAPayslipHandler() }

    // Essential feature services
    func makeQuizGenerationService() -> QuizGenerationService { featureFactory.makeQuizGenerationService() }
    func makeAchievementService() -> AchievementService { featureFactory.makeAchievementService() }
    func makeQuizViewModel() -> QuizViewModel { unifiedFactory.makeQuizViewModel() }
    func toggleWebUploadMock(_ useMock: Bool) { featureFactory.toggleWebUploadMock(useMock) }
    func setWebAPIBaseURL(_ url: URL) { featureFactory.setWebAPIBaseURL(url) }
    func makeWebUploadService() -> WebUploadServiceProtocol { featureFactory.makeWebUploadService() }
    func makeWebUploadViewModel() -> WebUploadViewModel { unifiedFactory.makeWebUploadViewModel() }
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler { featureFactory.makeWebUploadDeepLinkHandler() }
    func makeSecureStorage() -> SecureStorageProtocol { coreServiceFactory.makeSecureStorage() }

    // MARK: - Private Properties

    /// Access the security service
    var securityService: SecurityServiceProtocol {
        get {
            return coreServiceFactory.makeSecurityService()
        }
    }

    /// Access the data service
    var dataService: DataServiceProtocol {
        get {
            return coreServiceFactory.makeDataService()
        }
    }

    /// Access the PDF service
    var pdfService: PDFServiceProtocol {
        get {
            return coreServiceFactory.makePDFService()
        }
    }

    /// Access the PDF extractor
    var pdfExtractor: PDFExtractorProtocol {
        get {
            return coreServiceFactory.makePDFExtractor()
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

    // Cache management (compact)
    @MainActor func clearQuizCache() { /* Delegated to ViewModelContainer */ }
    @MainActor func clearAllCaches() { featureContainer.clearFeatureCaches() }

    // Testing utilities (compact)
    static var forTesting: DIContainer { DIContainer(useMocks: true) }
    static func setShared(_ container: DIContainer) {
        #if DEBUG
        objc_setAssociatedObject(DIContainer.self, "shared", container, .OBJC_ASSOCIATION_RETAIN)
        #endif
    }

    /// Resolves a service of the specified type
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service type
    @MainActor
    func resolve<T>(_ type: T.Type) -> T? {
        return serviceResolver.resolve(type)
    }

    // Async resolution (delegates to sync)
    @MainActor func resolveAsync<T>(_ type: T.Type) async -> T? { resolve(type) }

    // Global system services (shared singletons)
    func makeGlobalLoadingManager() -> GlobalLoadingManager { globalServiceFactory.makeGlobalLoadingManager() }
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem { globalServiceFactory.makeGlobalOverlaySystem() }
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator { globalServiceFactory.makeTabTransitionCoordinator() }

    // Missing methods from DIContainerProtocol
    func makeChartDataPreparationService() -> ChartDataPreparationService { globalServiceFactory.makeChartDataPreparationService() }
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler { globalServiceFactory.makePasswordProtectedPDFHandler() }
}
