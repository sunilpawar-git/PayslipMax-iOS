import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

/// Unified factory for all DI container services.
/// Combines all DI-related factories into a single, streamlined interface.
@MainActor
class UnifiedDIContainerFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    /// Core service container for accessing core services
    private let coreContainer: CoreServiceContainerProtocol

    /// Processing container for accessing processing services
    private let processingContainer: ProcessingContainerProtocol

    /// ViewModel container for accessing ViewModel services
    private let viewModelContainer: ViewModelContainerProtocol

    /// Feature container for accessing feature services
    private let featureContainer: FeatureContainerProtocol

    // MARK: - Sub-factories

    /// Core service factory for core service creation
    private lazy var coreServiceFactory = CoreServiceFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer
    )

    /// ViewModel factory for ViewModel creation
    private lazy var viewModelFactory = ViewModelFactory(
        useMocks: useMocks,
        coreContainer: coreContainer,
        processingContainer: processingContainer,
        viewModelContainer: viewModelContainer
    )

    /// Processing factory for processing service delegations
    private lazy var processingFactory = ProcessingFactory(processingContainer: processingContainer)

    /// Feature factory for feature-specific services
    private lazy var featureFactory = FeatureFactory(
        useMocks: useMocks, featureContainer: featureContainer
    )

    /// Global service factory for global system services
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

    // MARK: - Core Services

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return coreServiceFactory.makePDFProcessingService()
    }

    func makePDFService() -> PDFServiceProtocol {
        return coreServiceFactory.makePDFService()
    }

    func makePDFExtractor() -> PDFExtractorProtocol {
        return coreServiceFactory.makePDFExtractor()
    }

    func makeDataService() -> DataServiceProtocol {
        return coreServiceFactory.makeDataService()
    }

    func makeSecurityService() -> SecurityServiceProtocol {
        return coreServiceFactory.makeSecurityService()
    }

    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        return coreServiceFactory.makePayslipRepository(modelContext: modelContext)
    }

    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        return coreServiceFactory.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        return coreServiceFactory.makePayslipBatchOperations(modelContext: modelContext)
    }

    // MARK: - ViewModels

    func makeHomeViewModel() -> HomeViewModel {
        return viewModelFactory.makeHomeViewModel()
    }

    func makePDFProcessingViewModel() -> any ObservableObject {
        return viewModelFactory.makePDFProcessingViewModel()
    }

    func makePayslipDataViewModel() -> any ObservableObject {
        return viewModelFactory.makePayslipDataViewModel()
    }

    func makePayslipsViewModel() -> PayslipsViewModel {
        return viewModelFactory.makePayslipsViewModel()
    }

    func makeInsightsCoordinator() -> InsightsCoordinator {
        return viewModelFactory.makeInsightsCoordinator()
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        return viewModelFactory.makeSettingsViewModel()
    }

    func makeSecurityViewModel() -> SecurityViewModel {
        return viewModelFactory.makeSecurityViewModel()
    }

    func makeAuthViewModel() -> AuthViewModel {
        return viewModelFactory.makeAuthViewModel()
    }

    func makeQuizViewModel() -> QuizViewModel {
        return viewModelFactory.makeQuizViewModel()
    }

    func makeWebUploadViewModel() -> WebUploadViewModel {
        return viewModelFactory.makeWebUploadViewModel()
    }

    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator {
        return viewModelFactory.makeBackgroundTaskCoordinator()
    }

    // MARK: - Global Services

    func makeGlobalLoadingManager() -> GlobalLoadingManager {
        return globalServiceFactory.makeGlobalLoadingManager()
    }

    func makeGlobalOverlaySystem() -> GlobalOverlaySystem {
        return globalServiceFactory.makeGlobalOverlaySystem()
    }

    func makeTabTransitionCoordinator() -> TabTransitionCoordinator {
        return globalServiceFactory.makeTabTransitionCoordinator()
    }

    func makePDFManager() -> PDFManager {
        return globalServiceFactory.makePDFManager()
    }

    func makeAnalyticsManager() -> AnalyticsManager {
        return globalServiceFactory.makeAnalyticsManager()
    }

    // MARK: - Processing Services

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return processingFactory.makeStreamingBatchCoordinator()
    }
}
