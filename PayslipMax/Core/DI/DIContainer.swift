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
    private lazy var viewModelContainer = ViewModelContainer(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer
    )
    private lazy var featureContainer = FeatureContainer(
        useMocks: useMocks, coreContainer: coreContainer
    )

    // MARK: - Factories

    private lazy var coreServiceFactory = CoreServiceFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer
    )
    private lazy var viewModelFactory = ViewModelFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer,
        viewModelContainer: viewModelContainer
    )
    lazy var processingFactory = ProcessingFactory(processingContainer: processingContainer)
    private lazy var featureFactory = FeatureFactory(
        useMocks: useMocks, featureContainer: featureContainer
    )
    private lazy var globalServiceFactory = GlobalServiceFactory(
        useMocks: useMocks, coreContainer: coreContainer
    )
    private lazy var unifiedFactory = UnifiedDIContainerFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer,
        viewModelContainer: viewModelContainer,
        featureContainer: featureContainer
    )
    private lazy var serviceResolver = ServiceResolver(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer,
        viewModelContainer: viewModelContainer,
        featureContainer: featureContainer
    )
    lazy var serviceFactoryHelpers = ServiceFactoryHelpers(
        unifiedFactory: unifiedFactory,
        coreServiceFactory: coreServiceFactory,
        viewModelFactory: viewModelFactory,
        processingFactory: processingFactory,
        globalServiceFactory: globalServiceFactory,
        featureFactory: featureFactory
    )

    /// Public access to feature container
    var featureContainerPublic: FeatureContainerProtocol { return featureContainer }

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Core Factory Methods

    func makePDFProcessingService() -> PDFProcessingServiceProtocol { serviceFactoryHelpers.makePDFProcessingService() }
    func makeTextExtractionService() -> TextExtractionServiceProtocol { serviceFactoryHelpers.makeTextExtractionService() }
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator { serviceFactoryHelpers.makeStreamingBatchCoordinator() }
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol { serviceFactoryHelpers.makePayslipFormatDetectionService() }
    func makePayslipValidationService() -> PayslipValidationServiceProtocol { serviceFactoryHelpers.makePayslipValidationService() }
    func makeTextExtractor() -> TextExtractor { serviceFactoryHelpers.makeTextExtractor() }
    func makeHomeViewModel() -> HomeViewModel { return unifiedFactory.makeHomeViewModel() }
    func makePDFProcessingViewModel() -> any ObservableObject { return unifiedFactory.makePDFProcessingViewModel() }
    func makePayslipDataViewModel() -> any ObservableObject { return unifiedFactory.makePayslipDataViewModel() }
    func makePDFService() -> PDFServiceProtocol { serviceFactoryHelpers.makePDFService() }
    func makePDFExtractor() -> PDFExtractorProtocol { serviceFactoryHelpers.makePDFExtractor() }
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol { serviceFactoryHelpers.makeFinancialCalculationService() }
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol { serviceFactoryHelpers.makeMilitaryAbbreviationService() }
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol { serviceFactoryHelpers.makeTabularDataExtractor() }
    func makePatternMatchingService() -> PatternMatchingServiceProtocol { serviceFactoryHelpers.makePatternMatchingService() }

    // MARK: - Repository Factory Methods

    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        serviceFactoryHelpers.makePayslipRepository(modelContext: modelContext)
    }

    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        serviceFactoryHelpers.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        serviceFactoryHelpers.makePayslipBatchOperations(modelContext: modelContext)
    }

    // MARK: - Essential Service Delegations

    func makeDataService() -> DataServiceProtocol { serviceFactoryHelpers.makeDataService() }
    func makeAuthViewModel() -> AuthViewModel { serviceFactoryHelpers.makeAuthViewModel() }
    func makePayslipsViewModel() -> PayslipsViewModel { serviceFactoryHelpers.makePayslipsViewModel() }
    func makeInsightsCoordinator() -> InsightsCoordinator { serviceFactoryHelpers.makeInsightsCoordinator() }
    func makeSettingsViewModel() -> SettingsViewModel { serviceFactoryHelpers.makeSettingsViewModel() }
    func makeLLMSettingsViewModel() -> LLMSettingsViewModel { serviceFactoryHelpers.makeLLMSettingsViewModel() }
    func makeSecurityViewModel() -> SecurityViewModel { serviceFactoryHelpers.makeSecurityViewModel() }
    func makeSecurityService() -> SecurityServiceProtocol { serviceFactoryHelpers.makeSecurityService() }
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
    func makePDFProcessingHandler() -> PDFProcessingHandler { serviceFactoryHelpers.makePDFProcessingHandler() }
    func makePayslipDataHandler() -> PayslipDataHandler { serviceFactoryHelpers.makePayslipDataHandler() }

    /// Cached PayslipCacheManager - should be singleton to avoid duplicate cache instances
    private var _payslipCacheManager: PayslipCacheManager?
    func makePayslipCacheManager() -> PayslipCacheManager {
        if let cached = _payslipCacheManager { return cached }
        let manager = PayslipCacheManager()
        _payslipCacheManager = manager
        return manager
    }

    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator { serviceFactoryHelpers.makeHomeNavigationCoordinator() }
    open func makeErrorHandler() -> ErrorHandler { serviceFactoryHelpers.makeErrorHandler() }
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
    func makePayslipComparisonService() -> PayslipComparisonServiceProtocol { featureContainer.makePayslipComparisonService() }
    func makeXRaySettingsService() -> any XRaySettingsServiceProtocol { featureContainer.makeXRaySettingsService() }

    // MARK: - Private Properties

    var securityService: SecurityServiceProtocol { coreServiceFactory.makeSecurityService() }
    var dataService: DataServiceProtocol { coreServiceFactory.makeDataService() }
    var pdfService: PDFServiceProtocol { coreServiceFactory.makePDFService() }
    var pdfExtractor: PDFExtractorProtocol { coreServiceFactory.makePDFExtractor() }
    var router: any RouterProtocol { RouterResolver.resolveRouter() }
    var biometricAuthService: BiometricAuthService { BiometricAuthService() }

    @MainActor func clearQuizCache() { /* Delegated to ViewModelContainer */ }
    @MainActor func clearAllCaches() { featureContainer.clearFeatureCaches() }

    static var forTesting: DIContainer { DIContainer(useMocks: true) }
    static func setShared(_ container: DIContainer) {
        #if DEBUG
        objc_setAssociatedObject(DIContainer.self, "shared", container, .OBJC_ASSOCIATION_RETAIN)
        #endif
    }

    @MainActor func resolve<T>(_ type: T.Type) -> T? { return serviceResolver.resolve(type) }
    @MainActor func resolveAsync<T>(_ type: T.Type) async -> T? { resolve(type) }

    func makeGlobalLoadingManager() -> GlobalLoadingManager { serviceFactoryHelpers.makeGlobalLoadingManager() }
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem { serviceFactoryHelpers.makeGlobalOverlaySystem() }
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator { serviceFactoryHelpers.makeTabTransitionCoordinator() }
    func makeChartDataPreparationService() -> ChartDataPreparationService { serviceFactoryHelpers.makeChartDataPreparationService() }
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler { serviceFactoryHelpers.makePasswordProtectedPDFHandler() }
    func makePayslipSharingService() -> PayslipSharingServiceProtocol { serviceFactoryHelpers.makePayslipSharingService() }
    func makePayslipDataEnrichmentService() -> PayslipDataEnrichmentServiceProtocol { serviceFactoryHelpers.makePayslipDataEnrichmentService() }
    func makeComponentCategorizationService() -> ComponentCategorizationServiceProtocol { serviceFactoryHelpers.makeComponentCategorizationService() }
    func makeErrorHandlingUtility() -> ErrorHandlingUtility { serviceFactoryHelpers.makeErrorHandlingUtility() }
    func makePayslipDisplayNameService() -> PayslipDisplayNameServiceProtocol { coreContainer.makePayslipDisplayNameService() }
    func makePDFExtractionTrainer() -> PDFExtractionTrainer { coreContainer.makePDFExtractionTrainer() }
    func makeTrainingDataStore() -> TrainingDataStore { coreContainer.makeTrainingDataStore() }

    // MARK: - Simplified Parsing Services (Phase 4)

    func makeSimplifiedPayslipParser() -> SimplifiedPayslipParser { return processingContainer.makeSimplifiedPayslipParser() }
    func makeSimplifiedPDFProcessingService() -> SimplifiedPDFProcessingService { return processingContainer.makeSimplifiedPDFProcessingService() }
    func makeSimplifiedPayslipDataService(
        modelContext: ModelContext
    ) -> SimplifiedPayslipDataService {
        return SimplifiedPayslipDataServiceImpl(modelContext: modelContext)
    }

    func makeSimplifiedPayslipViewModel(payslip: SimplifiedPayslip, modelContext: ModelContext) -> SimplifiedPayslipViewModel {
        let dataService = makeSimplifiedPayslipDataService(modelContext: modelContext)
        return SimplifiedPayslipViewModel(payslip: payslip, dataService: dataService)
    }
}
