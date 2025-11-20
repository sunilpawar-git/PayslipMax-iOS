import Foundation
import PDFKit

/// Service resolver for the DI container.
/// Handles service resolution by type for dependency injection.
@MainActor
class ServiceResolver {

    // MARK: - Dependencies

    /// Core service container for accessing core services
    private let coreContainer: CoreServiceContainerProtocol

    /// Processing container for accessing processing services
    private let processingContainer: ProcessingContainerProtocol

    /// ViewModel container for accessing ViewModel services
    private let viewModelContainer: ViewModelContainerProtocol

    /// Feature container for accessing feature services
    private let featureContainer: FeatureContainerProtocol

    /// Whether to use mock implementations for testing
    private let useMocks: Bool

    // MARK: - Factories

    /// Core service factory
    private lazy var coreServiceFactory = CoreServiceFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)

    /// ViewModel factory
    private lazy var viewModelFactory = ViewModelFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer, viewModelContainer: viewModelContainer)

    /// Processing factory
    private lazy var processingFactory = ProcessingFactory(processingContainer: processingContainer)

    /// Feature factory
    private lazy var featureFactory = FeatureFactory(useMocks: useMocks, featureContainer: featureContainer)

    /// Global service factory
    private lazy var globalServiceFactory = GlobalServiceFactory(useMocks: useMocks, coreContainer: coreContainer)

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol, processingContainer: ProcessingContainerProtocol, viewModelContainer: ViewModelContainerProtocol, featureContainer: FeatureContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
        self.processingContainer = processingContainer
        self.viewModelContainer = viewModelContainer
        self.featureContainer = featureContainer
    }

    // MARK: - Service Resolution

    /// Resolves a service of the specified type.
    /// - Parameter type: The type of service to resolve
    /// - Returns: An instance of the requested service type
    func resolve<T>(_ type: T.Type) -> T? {
        switch type {
        case is PDFProcessingServiceProtocol.Type:
            return coreServiceFactory.makePDFProcessingService() as? T
        case is TextExtractionServiceProtocol.Type:
            return coreServiceFactory.makeTextExtractionService() as? T
        case is ExtractionStrategySelectorProtocol.Type:
            return processingFactory.makeExtractionStrategySelector() as? T
        case is SimpleValidator.Type:
            return processingFactory.makeSimpleValidator() as? T
        case is PayslipFormatDetectionServiceProtocol.Type:
            return coreServiceFactory.makePayslipFormatDetectionService() as? T
        case is PayslipValidationServiceProtocol.Type:
            return coreServiceFactory.makePayslipValidationService() as? T
        case is PDFServiceProtocol.Type:
            return coreServiceFactory.makePDFService() as? T
        case is PDFExtractorProtocol.Type:
            return coreServiceFactory.makePDFExtractor() as? T
        case is DataServiceProtocol.Type:
            return coreServiceFactory.makeDataService() as? T
        case is SecurityServiceProtocol.Type:
            return coreServiceFactory.makeSecurityService() as? T
        case is DestinationFactoryProtocol.Type:
            return globalServiceFactory.makeDestinationFactory() as? T
        case is EncryptionServiceProtocol.Type:
            return coreServiceFactory.makeEncryptionService() as? T
        case is PayslipEncryptionServiceProtocol.Type:
            return coreServiceFactory.makePayslipEncryptionService() as? T
        case is WebUploadServiceProtocol.Type:
            return featureFactory.makeWebUploadService() as? T
        case is SecureStorageProtocol.Type:
            return coreServiceFactory.makeSecureStorage() as? T
        case is WebUploadDeepLinkHandler.Type:
            return featureFactory.makeWebUploadDeepLinkHandler() as? T
        case is GlobalLoadingManager.Type:
            return globalServiceFactory.makeGlobalLoadingManager() as? T
        case is GlobalOverlaySystem.Type:
            return globalServiceFactory.makeGlobalOverlaySystem() as? T
        case is TabTransitionCoordinator.Type:
            return globalServiceFactory.makeTabTransitionCoordinator() as? T
        case is FinancialCalculationServiceProtocol.Type:
            return coreServiceFactory.makeFinancialCalculationService() as? T
        case is MilitaryAbbreviationServiceProtocol.Type:
            return coreServiceFactory.makeMilitaryAbbreviationService() as? T

        case is TabularDataExtractorProtocol.Type:
            return coreServiceFactory.makeTabularDataExtractor() as? T
        case is PatternMatchingServiceProtocol.Type:
            return coreServiceFactory.makePatternMatchingService() as? T
        case is PerformanceCoordinatorProtocol.Type:
            return globalServiceFactory.makePerformanceCoordinator() as? T
        case is FPSMonitorProtocol.Type:
            return globalServiceFactory.makeFPSMonitor() as? T
        case is MemoryMonitorProtocol.Type:
            return globalServiceFactory.makeMemoryMonitor() as? T
        case is CPUMonitorProtocol.Type:
            return globalServiceFactory.makeCPUMonitor() as? T
        case is PerformanceReporterProtocol.Type:
            return globalServiceFactory.makePerformanceReporter() as? T
        // New service registrations
        case is PayslipExtractorService.Type:
            return globalServiceFactory.makePayslipExtractorService() as? T
        case is BiometricAuthService.Type:
            return globalServiceFactory.makeBiometricAuthService() as? T
        case is PDFManager.Type:
            return globalServiceFactory.makePDFManager() as? T
        case is GamificationCoordinator.Type:
            return globalServiceFactory.makeGamificationCoordinator() as? T
        case is AnalyticsManager.Type:
            return globalServiceFactory.makeAnalyticsManager() as? T
        case is BankingPatternsProvider.Type:
            return globalServiceFactory.makeBankingPatternsProvider() as? T
        case is FinancialPatternsProvider.Type:
            return globalServiceFactory.makeFinancialPatternsProvider() as? T
        case is DocumentAnalysisCoordinator.Type:
            return globalServiceFactory.makeDocumentAnalysisCoordinator() as? T
        case is PayItemCategorizationServiceProtocol.Type:
            return coreServiceFactory.makePayItemCategorizationService() as? T
        default:
            return nil
        }
    }

    // MARK: - Async Resolution

    /// Async resolution (delegates to sync)
    func resolveAsync<T>(_ type: T.Type) async -> T? {
        return resolve(type)
    }
}
