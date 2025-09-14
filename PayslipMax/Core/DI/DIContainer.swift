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

    /// Factory method organizer for organizing complex factory methods
    private lazy var factoryOrganizer = DIFactoryMethodOrganizer(
        coreServiceFactory: coreServiceFactory,
        viewModelFactory: viewModelFactory,
        processingFactory: processingFactory,
        featureFactory: featureFactory,
        globalServiceFactory: globalServiceFactory,
        unifiedFactory: unifiedFactory
    )

    // MARK: - Initialization

    /// Initialize after all containers are created
    private func initializeEnhancedServices() {
        // Enhanced services initialized through lazy dependencies
        // Processing container reference handled through factory methods
    }

    /// Public initializer for testing
    init(useMocks: Bool = false) {
        self.useMocks = useMocks
        // Don't call initializeEnhancedServices here as containers aren't initialized yet
    }

    /// Public access to feature container
    var featureContainerPublic: FeatureContainerProtocol {
        return featureContainer
    }

    // MARK: - Core Factory Methods (Frequently Used)

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return factoryOrganizer.makePDFProcessingService()
    }

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return factoryOrganizer.makeTextExtractionService()
    }

    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return factoryOrganizer.makePayslipFormatDetectionService()
    }

    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return factoryOrganizer.makePayslipValidationService()
    }

    // MARK: - ViewModel Factory Methods

    func makeHomeViewModel() -> HomeViewModel {
        return factoryOrganizer.makeHomeViewModel()
    }

    func makePayslipsViewModel() -> PayslipsViewModel {
        return factoryOrganizer.makePayslipsViewModel()
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        return factoryOrganizer.makeSettingsViewModel()
    }

    func makeAuthViewModel() -> AuthViewModel {
        return factoryOrganizer.makeAuthViewModel()
    }

    // MARK: - Data Service Factory Methods

    func makeDataService() -> DataServiceProtocol {
        return factoryOrganizer.makeDataService()
    }

    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        return factoryOrganizer.makePayslipRepository(modelContext: modelContext)
    }

    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        return factoryOrganizer.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        return factoryOrganizer.makePayslipBatchOperations(modelContext: modelContext)
    }

    // MARK: - Convenience Methods for Backward Compatibility

    func makePDFService() -> PDFServiceProtocol { 
        return unifiedFactory.makePDFService() 
    }
    
    func makePDFExtractor() -> PDFExtractorProtocol { 
        return unifiedFactory.makePDFExtractor() 
    }

    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return unifiedFactory.makeStreamingBatchCoordinator()
    }

    func makeTextExtractor() -> TextExtractor {
        return processingFactory.makeTextExtractor()
    }

    func makePDFProcessingViewModel() -> any ObservableObject {
        return unifiedFactory.makePDFProcessingViewModel()
    }

    func makePayslipDataViewModel() -> any ObservableObject {
        return unifiedFactory.makePayslipDataViewModel()
    }

    // MARK: - Pattern and Financial Services

    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol { 
        return coreServiceFactory.makeFinancialCalculationService() 
    }
    
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol { 
        return coreServiceFactory.makeMilitaryAbbreviationService() 
    }

    func makePatternLoader() -> PatternLoaderProtocol { 
        return factoryOrganizer.makePatternLoader() 
    }
    
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol { 
        return factoryOrganizer.makeTabularDataExtractor() 
    }
    
    func makePatternMatchingService() -> PatternMatchingServiceProtocol { 
        return factoryOrganizer.makePatternMatchingService() 
    }

    // MARK: - Additional Services via Organizer

    var organizer: DIFactoryMethodOrganizerProtocol {
        return factoryOrganizer
    }

    // MARK: - Additional Missing Services for Compatibility

    func makePatternManagementViewModel() -> PatternManagementViewModel {
        return viewModelFactory.makePatternManagementViewModel()
    }
    
    func makePatternValidationViewModel() -> PatternValidationViewModel {
        return viewModelFactory.makePatternValidationViewModel()
    }
    
    func makePatternListViewModel() -> PatternListViewModel {
        return viewModelFactory.makePatternListViewModel()
    }
    
    var dataService: DataServiceProtocol {
        return factoryOrganizer.makeDataService()
    }
    
    var securityService: SecurityServiceProtocol {
        return factoryOrganizer.makeSecurityService()
    }
    
    func makeDestinationFactory() -> DestinationFactoryProtocol {
        return globalServiceFactory.makeDestinationFactory()
    }

    // MARK: - Configuration and Utility Methods

    func toggleWebUploadMock(_ useMock: Bool) { 
        featureFactory.toggleWebUploadMock(useMock) 
    }
    
    func setWebAPIBaseURL(_ url: URL) { 
        featureFactory.setWebAPIBaseURL(url) 
    }

    @MainActor func clearQuizCache() { 
        /* Delegated to ViewModelContainer */ 
    }
    
    @MainActor func clearAllCaches() { 
        featureContainer.clearFeatureCaches() 
    }

    // MARK: - Singleton Management

    static func setShared(_ container: DIContainer) {
        // Implementation for setting shared instance if needed
    }

    // MARK: - Service Resolution

    func resolve<T>(_ type: T.Type) -> T? {
        return serviceResolver.resolve(type)
    }

    @MainActor func resolveAsync<T>(_ type: T.Type) async -> T? { 
        return resolve(type) 
    }
}