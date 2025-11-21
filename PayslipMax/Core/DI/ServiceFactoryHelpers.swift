import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

/// Service factory helpers for DI container delegations
/// Provides organized access to factory methods grouped by functionality
@MainActor
class ServiceFactoryHelpers {
    private let unifiedFactory: UnifiedDIContainerFactory
    private let coreServiceFactory: CoreServiceFactory
    private let viewModelFactory: ViewModelFactory
    private let processingFactory: ProcessingFactory
    private let globalServiceFactory: GlobalServiceFactory
    private let featureFactory: FeatureFactory

    init(
        unifiedFactory: UnifiedDIContainerFactory,
        coreServiceFactory: CoreServiceFactory,
        viewModelFactory: ViewModelFactory,
        processingFactory: ProcessingFactory,
        globalServiceFactory: GlobalServiceFactory,
        featureFactory: FeatureFactory
    ) {
        self.unifiedFactory = unifiedFactory
        self.coreServiceFactory = coreServiceFactory
        self.viewModelFactory = viewModelFactory
        self.processingFactory = processingFactory
        self.globalServiceFactory = globalServiceFactory
        self.featureFactory = featureFactory
    }

    // MARK: - Core Factory Methods

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        unifiedFactory.makePDFProcessingService()
    }

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        coreServiceFactory.makeTextExtractionService()
    }

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        unifiedFactory.makeStreamingBatchCoordinator()
    }

    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        coreServiceFactory.makePayslipFormatDetectionService()
    }

    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        coreServiceFactory.makePayslipValidationService()
    }

    func makeTextExtractor() -> TextExtractor {
        processingFactory.makeTextExtractor()
    }

    func makePDFService() -> PDFServiceProtocol { unifiedFactory.makePDFService() }
    func makePDFExtractor() -> PDFExtractorProtocol { unifiedFactory.makePDFExtractor() }

    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol {
        coreServiceFactory.makeFinancialCalculationService()
    }

    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol {
        coreServiceFactory.makeMilitaryAbbreviationService()
    }


    func makeTabularDataExtractor() -> TabularDataExtractorProtocol { coreServiceFactory.makeTabularDataExtractor() }
    func makePatternMatchingService() -> PatternMatchingServiceProtocol { coreServiceFactory.makePatternMatchingService() }

    // MARK: - Essential Factory Methods

    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        unifiedFactory.makePayslipRepository(modelContext: modelContext)
    }

    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        unifiedFactory.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        unifiedFactory.makePayslipBatchOperations(modelContext: modelContext)
    }

    // MARK: - Essential Service Delegations

    func makeDataService() -> DataServiceProtocol { unifiedFactory.makeDataService() }
    func makeAuthViewModel() -> AuthViewModel { viewModelFactory.makeAuthViewModel() }
    func makePayslipsViewModel() -> PayslipsViewModel { unifiedFactory.makePayslipsViewModel() }
    func makeInsightsCoordinator() -> InsightsCoordinator { unifiedFactory.makeInsightsCoordinator() }
    func makeSettingsViewModel() -> SettingsViewModel { unifiedFactory.makeSettingsViewModel() }
    func makeLLMSettingsViewModel() -> LLMSettingsViewModel { viewModelFactory.makeLLMSettingsViewModel() }
    func makeSecurityViewModel() -> SecurityViewModel { unifiedFactory.makeSecurityViewModel() }
    func makeSecurityService() -> SecurityServiceProtocol { coreServiceFactory.makeSecurityService() }

    // MARK: - Essential Pattern and Service Methods

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
    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator { unifiedFactory.makeBackgroundTaskCoordinator() }

    // MARK: - Essential Handler Services

    func makePDFProcessingHandler() -> PDFProcessingHandler { globalServiceFactory.makePDFProcessingHandler() }
    func makePayslipDataHandler() -> PayslipDataHandler { globalServiceFactory.makePayslipDataHandler() }
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator { globalServiceFactory.makeHomeNavigationCoordinator() }
    func makeErrorHandler() -> ErrorHandler { globalServiceFactory.makeErrorHandler() }

    // MARK: - Essential Processing Services

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol { processingFactory.makePDFTextExtractionService() }
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol { processingFactory.makeExtractionStrategySelector() }
    func makeSimpleValidator() -> SimpleValidator { processingFactory.makeSimpleValidator() }
    func makePayslipProcessorFactory() -> PayslipProcessorFactory { processingFactory.makePayslipProcessorFactory() }
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol { processingFactory.makePDFParsingCoordinator() }
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline { processingFactory.makePayslipProcessingPipeline() }
    func makePayslipImportCoordinator() -> PayslipImportCoordinator { processingFactory.makePayslipImportCoordinator() }
    func makeAbbreviationManager() -> AbbreviationManager { processingFactory.makeAbbreviationManager() }

    // MARK: - Essential Feature Services

    func makeSubscriptionManager() -> SubscriptionManager { featureFactory.makeSubscriptionManager() }
    func makeDestinationFactory() -> DestinationFactoryProtocol { globalServiceFactory.makeDestinationFactory() }
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol { coreServiceFactory.makePayslipEncryptionService() }
    func makeEncryptionService() -> EncryptionServiceProtocol { coreServiceFactory.makeEncryptionService() }
    func makePCDAPayslipHandler() -> PCDAPayslipHandler { globalServiceFactory.makePCDAPayslipHandler() }

    func makeQuizGenerationService() -> QuizGenerationService { featureFactory.makeQuizGenerationService() }
    func makeAchievementService() -> AchievementService { featureFactory.makeAchievementService() }
    func makeQuizViewModel() -> QuizViewModel { unifiedFactory.makeQuizViewModel() }
    func toggleWebUploadMock(_ useMock: Bool) { featureFactory.toggleWebUploadMock(useMock) }
    func setWebAPIBaseURL(_ url: URL) { featureFactory.setWebAPIBaseURL(url) }
    func makeWebUploadService() -> WebUploadServiceProtocol { featureFactory.makeWebUploadService() }
    func makeWebUploadViewModel() -> WebUploadViewModel { unifiedFactory.makeWebUploadViewModel() }
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler { featureFactory.makeWebUploadDeepLinkHandler() }
    func makeSecureStorage() -> SecureStorageProtocol { coreServiceFactory.makeSecureStorage() }

    // MARK: - Global System Services

    func makeGlobalLoadingManager() -> GlobalLoadingManager { globalServiceFactory.makeGlobalLoadingManager() }
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem { globalServiceFactory.makeGlobalOverlaySystem() }
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator { globalServiceFactory.makeTabTransitionCoordinator() }

    // MARK: - Missing Methods

    func makeChartDataPreparationService() -> ChartDataPreparationService { globalServiceFactory.makeChartDataPreparationService() }
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler { globalServiceFactory.makePasswordProtectedPDFHandler() }

    // MARK: - Utility Services

    func makePayslipSharingService() -> PayslipSharingServiceProtocol { PayslipSharingService() }
    func makePayslipDataEnrichmentService() -> PayslipDataEnrichmentServiceProtocol { PayslipDataEnrichmentService() }
    func makeComponentCategorizationService() -> ComponentCategorizationServiceProtocol { ComponentCategorizationService() }
    func makeErrorHandlingUtility() -> ErrorHandlingUtility { ErrorHandlingUtility.shared }
}
