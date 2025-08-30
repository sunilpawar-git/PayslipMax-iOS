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

    /// AI container for LiteRT-powered services and intelligent document processing
    private lazy var aiContainer = AIContainer(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)

    /// Public access to AI container for service registration
    var aiContainerInstance: AIContainerProtocol {
        return aiContainer
    }
    
    // MARK: - Configuration (moved to FeatureContainer)
    
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
    
    // Simple core service delegations (one-liners for efficiency)
    func makeTextExtractionService() -> TextExtractionServiceProtocol { coreContainer.makeTextExtractionService() }
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol { coreContainer.makePayslipFormatDetectionService() }
    func makePayslipValidationService() -> PayslipValidationServiceProtocol { coreContainer.makePayslipValidationService() }
    
    // ViewModel delegations (compact format)
    func makeHomeViewModel() -> HomeViewModel { viewModelContainer.makeHomeViewModel() }
    func makePDFProcessingViewModel() -> any ObservableObject { viewModelContainer.makePDFProcessingViewModel() }
    func makePayslipDataViewModel() -> any ObservableObject { viewModelContainer.makePayslipDataViewModel() }
    
    // More core service delegations  
    func makePDFService() -> PDFServiceProtocol { coreContainer.makePDFService() }
    func makePDFExtractor() -> PDFExtractorProtocol { coreContainer.makePDFExtractor() }
    
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
    
    // Additional service and ViewModel delegations (compact)
    func makeDataService() -> DataServiceProtocol { coreContainer.makeDataService() }
    func makeAuthViewModel() -> AuthViewModel { viewModelContainer.makeAuthViewModel() }
    func makePayslipsViewModel() -> PayslipsViewModel { viewModelContainer.makePayslipsViewModel() }
    func makeInsightsCoordinator() -> InsightsCoordinator { viewModelContainer.makeInsightsCoordinator() }
    func makeSettingsViewModel() -> SettingsViewModel { viewModelContainer.makeSettingsViewModel() }
    func makeSecurityViewModel() -> SecurityViewModel { viewModelContainer.makeSecurityViewModel() }
    func makeSecurityService() -> SecurityServiceProtocol { coreContainer.makeSecurityService() }
    
    /// Creates a background task coordinator
    @MainActor
    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator {
        return viewModelContainer.makeBackgroundTaskCoordinator()
    }
    
    /// Creates a task priority queue with configurable concurrency
    /// TEMPORARILY DISABLED: TaskPriorityQueue is disabled during BackgroundTaskCoordinator refactoring
    /// This will be re-enabled once the refactoring is complete and proper dependency structure is established
    // func makeTaskPriorityQueue(maxConcurrentTasks: Int = 4) -> TaskPriorityQueue {
    //     return TaskPriorityQueue(maxConcurrentTasks: maxConcurrentTasks)
    // }
    
    // Handler services (backwards compatibility - compact)
    func makePDFProcessingHandler() -> PDFProcessingHandler { PDFProcessingHandler(pdfProcessingService: makePDFProcessingService()) }
    func makePayslipDataHandler() -> PayslipDataHandler { PayslipDataHandler(dataService: dataService) }
    func makeChartDataPreparationService() -> ChartDataPreparationService { ChartDataPreparationService() }
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler { PasswordProtectedPDFHandler(pdfService: pdfService) }
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator { HomeNavigationCoordinator() }
    open func makeErrorHandler() -> ErrorHandler { ErrorHandler() }
    
    // Processing service delegations (compact format)
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol { processingContainer.makePDFTextExtractionService() }
    func makeTextExtractionEngine() -> TextExtractionEngineProtocol { processingContainer.makeTextExtractionEngine() }
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol { processingContainer.makeExtractionStrategySelector() }
    func makeTextProcessingPipeline() -> TextProcessingPipelineProtocol { processingContainer.makeTextProcessingPipeline() }
    func makeExtractionResultValidator() -> ExtractionResultValidatorProtocol { processingContainer.makeExtractionResultValidator() }
    
    // Helper services (private, compact)
    private func makeStreamingPDFProcessor() -> StreamingPDFProcessor { StreamingPDFProcessor() }
    private func makePDFProcessingCache() -> PDFProcessingCache { PDFProcessingCache.shared }
    private func makeExtractionDocumentAnalyzer() -> ExtractionDocumentAnalyzer { ExtractionDocumentAnalyzer() }
    private func makeExtractionMemoryManager() -> TextExtractionMemoryManager { TextExtractionMemoryManager() }
    private func makeProgressSubject() -> PassthroughSubject<(pageIndex: Int, progress: Double), Never> { PassthroughSubject() }
    
    // Processing pipeline delegations (compact)
    func makePayslipProcessorFactory() -> PayslipProcessorFactory { processingContainer.makePayslipProcessorFactory() }
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol { processingContainer.makePDFParsingCoordinator() }
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline { processingContainer.makePayslipProcessingPipeline() }
    func makePayslipImportCoordinator() -> PayslipImportCoordinator { processingContainer.makePayslipImportCoordinator() }
    
    // Additional processing service
    func makeAbbreviationManager() -> AbbreviationManager { processingContainer.makeAbbreviationManager() }
    
    // Navigation and destination services (compact)
    func makeDestinationFactory() -> DestinationFactoryProtocol { DestinationFactory(dataService: makeDataService(), pdfManager: PDFUploadManager()) }
    func makeDestinationConverter() -> DestinationConverter { DestinationConverter(dataService: makeDataService()) }
    
    // Encryption service delegations (compact)
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol { coreContainer.makePayslipEncryptionService() }
    @MainActor func makeEncryptionService() -> EncryptionServiceProtocol { coreContainer.makeEncryptionService() }
    
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
    
    // Feature service delegations (compact)
    func makeQuizGenerationService() -> QuizGenerationService { featureContainer.makeQuizGenerationService() }
    func makeAchievementService() -> AchievementService { featureContainer.makeAchievementService() }
    func makeQuizViewModel() -> QuizViewModel { viewModelContainer.makeQuizViewModel() }
    
    // WebUpload feature delegations (compact)
    func toggleWebUploadMock(_ useMock: Bool) { featureContainer.toggleWebUploadMock(useMock) }
    func setWebAPIBaseURL(_ url: URL) { featureContainer.setWebAPIBaseURL(url) }
    func makeWebUploadService() -> WebUploadServiceProtocol { featureContainer.makeWebUploadService() }
    func makeWebUploadViewModel() -> WebUploadViewModel { viewModelContainer.makeWebUploadViewModel() }
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler { featureContainer.makeWebUploadDeepLinkHandler() }
    func makeSecureStorage() -> SecureStorageProtocol { coreContainer.makeSecureStorage() }

    // Phase 4 Adaptive Learning Services
    func makeAdaptiveLearningEngine() -> AdaptiveLearningEngineProtocol { aiContainer.makeAdaptiveLearningEngine() }
    func makeUserFeedbackProcessor() -> UserFeedbackProcessorProtocol { aiContainer.makeUserFeedbackProcessor() }
    func makePersonalizedInsightsEngine() -> PersonalizedInsightsEngineProtocol { aiContainer.makePersonalizedInsightsEngine() }
    func makeUserLearningStore() -> UserLearningStoreProtocol { aiContainer.makeUserLearningStore() }
    func makePerformanceTracker() -> PerformanceTrackerProtocol { aiContainer.makePerformanceTracker() }
    func makePrivacyPreservingLearningManager() -> PrivacyPreservingLearningManagerProtocol { aiContainer.makePrivacyPreservingLearningManager() }
    func makeABTestingFramework() -> ABTestingFrameworkProtocol { aiContainer.makeABTestingFramework() }
    func makeLearningEnhancedParser(baseParser: PayslipParserProtocol, parserName: String) -> LearningEnhancedParserProtocol { aiContainer.makeLearningEnhancedParser(baseParser: baseParser, parserName: parserName) }
    
    // MARK: - Private Properties
    
    /// Access the security service
    var securityService: SecurityServiceProtocol {
        get {
            return coreContainer.securityService
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
            if let appDelegate = UIApplication.shared.delegate,
               let router = objc_getAssociatedObject(appDelegate, "router") as? (any RouterProtocol) {
                return router
            }
            if let sharedRouter: (any RouterProtocol) = ServiceRegistry.shared.resolve((any RouterProtocol).self) {
                return sharedRouter
            }
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
        if let registered: T = ServiceRegistry.shared.resolve(type) {
            return registered
        }
        switch type {
        case is PDFProcessingServiceProtocol.Type:
            return makePDFProcessingService() as? T
        case is TextExtractionServiceProtocol.Type:
            return makeTextExtractionService() as? T
        case is TextExtractionEngineProtocol.Type:
            return makeTextExtractionEngine() as? T
        case is ExtractionStrategySelectorProtocol.Type:
            return makeExtractionStrategySelector() as? T
        case is TextProcessingPipelineProtocol.Type:
            return makeTextProcessingPipeline() as? T
        case is ExtractionResultValidatorProtocol.Type:
            return makeExtractionResultValidator() as? T
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

        // Phase 4 Adaptive Learning Services
        case is AdaptiveLearningEngineProtocol.Type:
            return makeAdaptiveLearningEngine() as? T
        case is UserFeedbackProcessorProtocol.Type:
            return makeUserFeedbackProcessor() as? T
        case is PersonalizedInsightsEngineProtocol.Type:
            return makePersonalizedInsightsEngine() as? T
        case is UserLearningStoreProtocol.Type:
            return makeUserLearningStore() as? T
        case is PerformanceTrackerProtocol.Type:
            return makePerformanceTracker() as? T
        case is PrivacyPreservingLearningManagerProtocol.Type:
            return makePrivacyPreservingLearningManager() as? T
        case is ABTestingFrameworkProtocol.Type:
            return makeABTestingFramework() as? T

        default:
            return nil
        }
    }
    
    // Async resolution (delegates to sync)
    @MainActor func resolveAsync<T>(_ type: T.Type) async -> T? { resolve(type) }
    
    // Global system services (shared singletons)
    func makeGlobalLoadingManager() -> GlobalLoadingManager { GlobalLoadingManager.shared }
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem { GlobalOverlaySystem.shared }
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator { TabTransitionCoordinator.shared }
} 