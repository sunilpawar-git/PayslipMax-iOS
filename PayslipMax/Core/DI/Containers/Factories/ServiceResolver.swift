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
    private lazy var coreServiceFactory = CoreServiceFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer
    )

    /// ViewModel factory
    private lazy var viewModelFactory = ViewModelFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer,
        viewModelContainer: viewModelContainer
    )

    /// Processing factory
    private lazy var processingFactory = ProcessingFactory(processingContainer: processingContainer)

    /// Feature factory
    private lazy var featureFactory = FeatureFactory(
        useMocks: useMocks, featureContainer: featureContainer
    )

    /// Global service factory
    private lazy var globalServiceFactory = GlobalServiceFactory(
        useMocks: useMocks, coreContainer: coreContainer
    )

    // MARK: - Initialization

    init(
        useMocks: Bool = false,
        coreContainer: CoreServiceContainerProtocol,
        processingContainer: ProcessingContainerProtocol,
        viewModelContainer: ViewModelContainerProtocol,
        featureContainer: FeatureContainerProtocol
    ) {
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
        // Try each resolver category in order
        resolveCoreService(type)
            ?? resolveProcessingService(type)
            ?? resolveGlobalService(type)
            ?? resolveFeatureService(type)
    }

    // MARK: - Async Resolution

    /// Async resolution (delegates to sync)
    func resolveAsync<T>(_ type: T.Type) async -> T? {
        return resolve(type)
    }
}

// MARK: - Core Service Resolution

extension ServiceResolver {
    private func resolveCoreService<T>(_ type: T.Type) -> T? {
        if type == PDFProcessingServiceProtocol.self {
            return coreServiceFactory.makePDFProcessingService() as? T
        } else if type == TextExtractionServiceProtocol.self {
            return coreServiceFactory.makeTextExtractionService() as? T
        } else if type == PayslipFormatDetectionServiceProtocol.self {
            return coreServiceFactory.makePayslipFormatDetectionService() as? T
        } else if type == PayslipValidationServiceProtocol.self {
            return coreServiceFactory.makePayslipValidationService() as? T
        } else if type == PDFServiceProtocol.self {
            return coreServiceFactory.makePDFService() as? T
        } else if type == PDFExtractorProtocol.self {
            return coreServiceFactory.makePDFExtractor() as? T
        } else if type == DataServiceProtocol.self {
            return coreServiceFactory.makeDataService() as? T
        } else if type == SecurityServiceProtocol.self {
            return coreServiceFactory.makeSecurityService() as? T
        } else if type == EncryptionServiceProtocol.self {
            return coreServiceFactory.makeEncryptionService() as? T
        } else if type == PayslipEncryptionServiceProtocol.self {
            return coreServiceFactory.makePayslipEncryptionService() as? T
        } else if type == SecureStorageProtocol.self {
            return coreServiceFactory.makeSecureStorage() as? T
        } else if type == FinancialCalculationServiceProtocol.self {
            return coreServiceFactory.makeFinancialCalculationService() as? T
        } else if type == MilitaryAbbreviationServiceProtocol.self {
            return coreServiceFactory.makeMilitaryAbbreviationService() as? T
        } else if type == TabularDataExtractorProtocol.self {
            return coreServiceFactory.makeTabularDataExtractor() as? T
        } else if type == PatternMatchingServiceProtocol.self {
            return coreServiceFactory.makePatternMatchingService() as? T
        } else if type == PayItemCategorizationServiceProtocol.self {
            return coreServiceFactory.makePayItemCategorizationService() as? T
        }
        return nil
    }
}

// MARK: - Processing Service Resolution

extension ServiceResolver {
    private func resolveProcessingService<T>(_ type: T.Type) -> T? {
        if type == ExtractionStrategySelectorProtocol.self {
            return processingFactory.makeExtractionStrategySelector() as? T
        } else if type == SimpleValidator.self {
            return processingFactory.makeSimpleValidator() as? T
        }
        return nil
    }
}

// MARK: - Global Service Resolution

extension ServiceResolver {
    private func resolveGlobalService<T>(_ type: T.Type) -> T? {
        if type == DestinationFactoryProtocol.self {
            return globalServiceFactory.makeDestinationFactory() as? T
        } else if type == GlobalLoadingManager.self {
            return globalServiceFactory.makeGlobalLoadingManager() as? T
        } else if type == GlobalOverlaySystem.self {
            return globalServiceFactory.makeGlobalOverlaySystem() as? T
        } else if type == TabTransitionCoordinator.self {
            return globalServiceFactory.makeTabTransitionCoordinator() as? T
        } else if type == PerformanceCoordinatorProtocol.self {
            return globalServiceFactory.makePerformanceCoordinator() as? T
        } else if type == FPSMonitorProtocol.self {
            return globalServiceFactory.makeFPSMonitor() as? T
        } else if type == MemoryMonitorProtocol.self {
            return globalServiceFactory.makeMemoryMonitor() as? T
        } else if type == CPUMonitorProtocol.self {
            return globalServiceFactory.makeCPUMonitor() as? T
        } else if type == PerformanceReporterProtocol.self {
            return globalServiceFactory.makePerformanceReporter() as? T
        } else if type == PayslipExtractorService.self {
            return globalServiceFactory.makePayslipExtractorService() as? T
        } else if type == BiometricAuthService.self {
            return globalServiceFactory.makeBiometricAuthService() as? T
        } else if type == PDFManager.self {
            return globalServiceFactory.makePDFManager() as? T
        } else if type == GamificationCoordinator.self {
            return globalServiceFactory.makeGamificationCoordinator() as? T
        } else if type == AnalyticsManager.self {
            return globalServiceFactory.makeAnalyticsManager() as? T
        } else if type == BankingPatternsProvider.self {
            return globalServiceFactory.makeBankingPatternsProvider() as? T
        } else if type == FinancialPatternsProvider.self {
            return globalServiceFactory.makeFinancialPatternsProvider() as? T
        } else if type == DocumentAnalysisCoordinator.self {
            return globalServiceFactory.makeDocumentAnalysisCoordinator() as? T
        }
        return nil
    }
}

// MARK: - Feature Service Resolution

extension ServiceResolver {
    private func resolveFeatureService<T>(_ type: T.Type) -> T? {
        if type == WebUploadServiceProtocol.self {
            return featureFactory.makeWebUploadService() as? T
        } else if type == WebUploadDeepLinkHandler.self {
            return featureFactory.makeWebUploadDeepLinkHandler() as? T
        }
        return nil
    }
}
