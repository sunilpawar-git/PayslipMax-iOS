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

    /// Private initializer to set up enhanced services
    private init() {
        // Initialize enhanced services after all containers are available
        // Access processingContainer to trigger lazy initialization, then set it in coreContainer
        _ = processingContainer
        initializeEnhancedServices()
    }

    // MARK: - Container Dependencies

    private lazy var coreContainer = CoreServiceContainer(useMocks: useMocks)
    private lazy var processingContainer = ProcessingContainer(useMocks: useMocks, coreContainer: coreContainer)
    private func initializeEnhancedServices() { /* Container composition handles initialization */ }
    private lazy var viewModelContainer = ViewModelContainer(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)
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

    /// Service factory helpers for organized factory method delegations
    private lazy var serviceFactoryHelpers = ServiceFactoryHelpers(
        unifiedFactory: unifiedFactory,
        coreServiceFactory: coreServiceFactory,
        viewModelFactory: viewModelFactory,
        processingFactory: processingFactory,
        globalServiceFactory: globalServiceFactory,
        featureFactory: featureFactory
    )

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
        serviceFactoryHelpers.makePDFProcessingService()
    }

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        serviceFactoryHelpers.makeTextExtractionService()
    }

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        serviceFactoryHelpers.makeStreamingBatchCoordinator()
    }

    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        serviceFactoryHelpers.makePayslipFormatDetectionService()
    }

    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        serviceFactoryHelpers.makePayslipValidationService()
    }

    func makeTextExtractor() -> TextExtractor {
        serviceFactoryHelpers.makeTextExtractor()
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

    func makePDFService() -> PDFServiceProtocol { serviceFactoryHelpers.makePDFService() }
    func makePDFExtractor() -> PDFExtractorProtocol { serviceFactoryHelpers.makePDFExtractor() }

    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol { serviceFactoryHelpers.makeFinancialCalculationService() }
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol { serviceFactoryHelpers.makeMilitaryAbbreviationService() }


    func makeTabularDataExtractor() -> TabularDataExtractorProtocol { serviceFactoryHelpers.makeTabularDataExtractor() }
    func makePatternMatchingService() -> PatternMatchingServiceProtocol { serviceFactoryHelpers.makePatternMatchingService() }

    // MARK: - Essential Factory Methods

    /// Creates a PayslipRepository instance
    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        serviceFactoryHelpers.makePayslipRepository(modelContext: modelContext)
    }

    /// Creates a PayslipMigrationUtilities instance with proper dependencies
    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        serviceFactoryHelpers.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    /// Creates a PayslipBatchOperations instance with proper dependencies
    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        serviceFactoryHelpers.makePayslipBatchOperations(modelContext: modelContext)
    }

    // Essential service delegations
    func makeDataService() -> DataServiceProtocol { serviceFactoryHelpers.makeDataService() }
    func makeAuthViewModel() -> AuthViewModel { serviceFactoryHelpers.makeAuthViewModel() }
    func makePayslipsViewModel() -> PayslipsViewModel { serviceFactoryHelpers.makePayslipsViewModel() }
    func makeInsightsCoordinator() -> InsightsCoordinator { serviceFactoryHelpers.makeInsightsCoordinator() }
    func makeSettingsViewModel() -> SettingsViewModel { serviceFactoryHelpers.makeSettingsViewModel() }
    func makeLLMSettingsViewModel() -> LLMSettingsViewModel { serviceFactoryHelpers.makeLLMSettingsViewModel() }
    func makeSecurityViewModel() -> SecurityViewModel { serviceFactoryHelpers.makeSecurityViewModel() }
    func makeSecurityService() -> SecurityServiceProtocol { serviceFactoryHelpers.makeSecurityService() }

    // Essential pattern and service methods
    func makePatternManagementViewModel() -> PatternManagementViewModel { serviceFactoryHelpers.makePatternManagementViewModel() }
    func makePatternValidationViewModel() -> PatternValidationViewModel { serviceFactoryHelpers.makePatternValidationViewModel() }
    func makePatternListViewModel() -> PatternListViewModel { serviceFactoryHelpers.makePatternListViewModel() }
    func makePatternItemEditViewModel() -> PatternItemEditViewModel { serviceFactoryHelpers.makePatternItemEditViewModel() }
    func makePatternEditViewModel() -> PatternEditViewModel { serviceFactoryHelpers.makePatternEditViewModel() }
    func makePayslipExtractorService() -> PayslipExtractorService { serviceFactoryHelpers.makePayslipExtractorService() }
    func makeBiometricAuthService() -> BiometricAuthService { serviceFactoryHelpers.makeBiometricAuthService() }
    func makePDFManager() -> PDFManager { serviceFactoryHelpers.makePDFManager() }
    func makeAnalyticsManager() -> AnalyticsManager { serviceFactoryHelpers.makeAnalyticsManager() }
    func makeBankingPatternsProvider() -> BankingPatternsProvider { serviceFactoryHelpers.makeBankingPatternsProvider() }
    func makeFinancialPatternsProvider() -> FinancialPatternsProvider { serviceFactoryHelpers.makeFinancialPatternsProvider() }
    func makeDocumentAnalysisCoordinator() -> DocumentAnalysisCoordinator { serviceFactoryHelpers.makeDocumentAnalysisCoordinator() }
    func makePatternTestingViewModel() -> PatternTestingViewModel { serviceFactoryHelpers.makePatternTestingViewModel() }
    func makePayslipPatternManager() -> PayslipPatternManager { serviceFactoryHelpers.makePayslipPatternManager() }
    func makeGamificationCoordinator() -> GamificationCoordinator { serviceFactoryHelpers.makeGamificationCoordinator() }
    @MainActor func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator { serviceFactoryHelpers.makeBackgroundTaskCoordinator() }

    // Essential handler services
    func makePDFProcessingHandler() -> PDFProcessingHandler { serviceFactoryHelpers.makePDFProcessingHandler() }
    func makePayslipDataHandler() -> PayslipDataHandler { serviceFactoryHelpers.makePayslipDataHandler() }
    func makePayslipCacheManager() -> PayslipCacheManager { PayslipCacheManager() }
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator { serviceFactoryHelpers.makeHomeNavigationCoordinator() }
    open func makeErrorHandler() -> ErrorHandler { serviceFactoryHelpers.makeErrorHandler() }

    // Essential processing services
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol { serviceFactoryHelpers.makePDFTextExtractionService() }
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol { serviceFactoryHelpers.makeExtractionStrategySelector() }
    func makeSimpleValidator() -> SimpleValidator { serviceFactoryHelpers.makeSimpleValidator() }
    func makePayslipProcessorFactory() -> PayslipProcessorFactory { serviceFactoryHelpers.makePayslipProcessorFactory() }
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol { serviceFactoryHelpers.makePDFParsingCoordinator() }
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline { serviceFactoryHelpers.makePayslipProcessingPipeline() }
    func makePayslipImportCoordinator() -> PayslipImportCoordinator { serviceFactoryHelpers.makePayslipImportCoordinator() }
    func makeAbbreviationManager() -> AbbreviationManager { serviceFactoryHelpers.makeAbbreviationManager() }

    @MainActor func makeSubscriptionManager() -> SubscriptionManager { serviceFactoryHelpers.makeSubscriptionManager() }
    func makeDestinationFactory() -> DestinationFactoryProtocol { serviceFactoryHelpers.makeDestinationFactory() }
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol { serviceFactoryHelpers.makePayslipEncryptionService() }
    @MainActor func makeEncryptionService() -> EncryptionServiceProtocol { serviceFactoryHelpers.makeEncryptionService() }
    func makePCDAPayslipHandler() -> PCDAPayslipHandler { serviceFactoryHelpers.makePCDAPayslipHandler() }

    // Essential feature services
    func makeQuizGenerationService() -> QuizGenerationService { serviceFactoryHelpers.makeQuizGenerationService() }
    func makeAchievementService() -> AchievementService { serviceFactoryHelpers.makeAchievementService() }
    func makeQuizViewModel() -> QuizViewModel { serviceFactoryHelpers.makeQuizViewModel() }
    func toggleWebUploadMock(_ useMock: Bool) { serviceFactoryHelpers.toggleWebUploadMock(useMock) }
    func setWebAPIBaseURL(_ url: URL) { serviceFactoryHelpers.setWebAPIBaseURL(url) }
    func makeWebUploadService() -> WebUploadServiceProtocol { serviceFactoryHelpers.makeWebUploadService() }
    func makeWebUploadViewModel() -> WebUploadViewModel { serviceFactoryHelpers.makeWebUploadViewModel() }
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler { serviceFactoryHelpers.makeWebUploadDeepLinkHandler() }
    func makeSecureStorage() -> SecureStorageProtocol { serviceFactoryHelpers.makeSecureStorage() }
    func makeLLMSettingsService() -> LLMSettingsServiceProtocol { serviceFactoryHelpers.makeLLMSettingsService() }

    // MARK: - X-Ray Feature Factory Methods

    func makePayslipComparisonService() -> PayslipComparisonServiceProtocol { featureContainer.makePayslipComparisonService() }
    func makeXRaySettingsService() -> XRaySettingsServiceProtocol { featureContainer.makeXRaySettingsService() }

    // MARK: - Private Properties

    var securityService: SecurityServiceProtocol { coreServiceFactory.makeSecurityService() }
    var dataService: DataServiceProtocol { coreServiceFactory.makeDataService() }
    var pdfService: PDFServiceProtocol { coreServiceFactory.makePDFService() }
    var pdfExtractor: PDFExtractorProtocol { coreServiceFactory.makePDFExtractor() }

    /// Access the global navigation router
    var router: any RouterProtocol {
        RouterResolver.resolveRouter()
    }

    // Backward compatibility
    var biometricAuthService: BiometricAuthService { BiometricAuthService() }

    // Cache management
    @MainActor func clearQuizCache() { /* Delegated to ViewModelContainer */ }
    @MainActor func clearAllCaches() { featureContainer.clearFeatureCaches() }

    // Testing utilities
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
    func makeGlobalLoadingManager() -> GlobalLoadingManager { serviceFactoryHelpers.makeGlobalLoadingManager() }
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem { serviceFactoryHelpers.makeGlobalOverlaySystem() }
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator { serviceFactoryHelpers.makeTabTransitionCoordinator() }

    // Missing methods from DIContainerProtocol
    func makeChartDataPreparationService() -> ChartDataPreparationService { serviceFactoryHelpers.makeChartDataPreparationService() }
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler { serviceFactoryHelpers.makePasswordProtectedPDFHandler() }

    // Utility services for ViewModel support
    // Note: CurrencyFormatter is a struct in Shared/Utilities, accessed statically
    func makePayslipSharingService() -> PayslipSharingServiceProtocol { serviceFactoryHelpers.makePayslipSharingService() }
    func makePayslipDataEnrichmentService() -> PayslipDataEnrichmentServiceProtocol { serviceFactoryHelpers.makePayslipDataEnrichmentService() }
    func makeComponentCategorizationService() -> ComponentCategorizationServiceProtocol { serviceFactoryHelpers.makeComponentCategorizationService() }
    func makeErrorHandlingUtility() -> ErrorHandlingUtility { serviceFactoryHelpers.makeErrorHandlingUtility() }
    func makePayslipDisplayNameService() -> PayslipDisplayNameServiceProtocol { coreContainer.makePayslipDisplayNameService() }

    // MARK: - Phase 2C: Service Layer Migration Factory Methods

    /// Creates a PDF extraction trainer for ML training and improvement
    func makePDFExtractionTrainer() -> PDFExtractionTrainer { coreContainer.makePDFExtractionTrainer() }

    /// Creates a training data store for ML data persistence
    func makeTrainingDataStore() -> TrainingDataStore { coreContainer.makeTrainingDataStore() }

    // Note: UnifiedCacheFactory is in Services/Extraction/Memory/ outside PayslipMax module
    // Access through Services/Extraction/Memory/UnifiedCacheFactory.swift directly when needed

    // MARK: - Simplified Parsing Services (Phase 4)

    /// Creates a SimplifiedPayslipParser for essential-only extraction
    func makeSimplifiedPayslipParser() -> SimplifiedPayslipParser {
        return processingContainer.makeSimplifiedPayslipParser()
    }

    /// Creates a SimplifiedPDFProcessingService
    func makeSimplifiedPDFProcessingService() -> SimplifiedPDFProcessingService {
        return processingContainer.makeSimplifiedPDFProcessingService()
    }

    /// Creates a SimplifiedPayslipDataService for data persistence
    func makeSimplifiedPayslipDataService(modelContext: ModelContext) -> SimplifiedPayslipDataService {
        return SimplifiedPayslipDataServiceImpl(modelContext: modelContext)
    }

    /// Creates a SimplifiedPayslipViewModel
    func makeSimplifiedPayslipViewModel(payslip: SimplifiedPayslip, modelContext: ModelContext) -> SimplifiedPayslipViewModel {
        let dataService = makeSimplifiedPayslipDataService(modelContext: modelContext)
        return SimplifiedPayslipViewModel(payslip: payslip, dataService: dataService)
    }
}
