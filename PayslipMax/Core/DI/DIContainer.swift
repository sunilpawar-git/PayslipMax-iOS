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
        return coreContainer.makeTextExtractionService()
    }
    
    /// Creates a payslip format detection service
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return coreContainer.makePayslipFormatDetectionService()
    }
    
    /// Creates a PDFValidationService instance
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return coreContainer.makePayslipValidationService()
    }
    
    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel {
        return viewModelContainer.makeHomeViewModel()
    }
    
    /// Creates a PDFProcessingViewModel.
    func makePDFProcessingViewModel() -> any ObservableObject {
        return viewModelContainer.makePDFProcessingViewModel()
    }
    
    /// Creates a PayslipDataViewModel.
    func makePayslipDataViewModel() -> any ObservableObject {
        return viewModelContainer.makePayslipDataViewModel()
    }
    
    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol {
        return coreContainer.makePDFService()
    }
    
    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        return coreContainer.makePDFExtractor()
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
        return coreContainer.makeDataService()
    }
    
    /// Creates an auth view model.
    func makeAuthViewModel() -> AuthViewModel {
        return viewModelContainer.makeAuthViewModel()
    }
    
    /// Creates a payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        return viewModelContainer.makePayslipsViewModel()
    }
    
    /// Creates an insights coordinator.
    func makeInsightsCoordinator() -> InsightsCoordinator {
        return viewModelContainer.makeInsightsCoordinator()
    }
    
    /// Creates a settings view model.
    func makeSettingsViewModel() -> SettingsViewModel {
        return viewModelContainer.makeSettingsViewModel()
    }
    
    /// Creates a security view model (for settings).
    func makeSecurityViewModel() -> SecurityViewModel {
        return viewModelContainer.makeSecurityViewModel()
    }
    
    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        return coreContainer.makeSecurityService()
    }
    
    /// Creates a background task coordinator
    @MainActor
    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator {
        // Use the shared instance for now since BackgroundTaskCoordinator is designed as a singleton
        return BackgroundTaskCoordinator.shared
    }
    
    /// Creates a task priority queue with configurable concurrency
    /// TEMPORARILY DISABLED: TaskPriorityQueue is disabled during BackgroundTaskCoordinator refactoring
    /// This will be re-enabled once the refactoring is complete and proper dependency structure is established
    // func makeTaskPriorityQueue(maxConcurrentTasks: Int = 4) -> TaskPriorityQueue {
    //     return TaskPriorityQueue(maxConcurrentTasks: maxConcurrentTasks)
    // }
    
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
    open func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }
    
    /// Creates a PDFTextExtractionService instance
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingContainer.makePDFTextExtractionService()
    }
    
    // MARK: - Enhanced Text Extraction Services
    
    /// Creates a TextExtractionEngine instance
    func makeTextExtractionEngine() -> TextExtractionEngineProtocol {
        return processingContainer.makeTextExtractionEngine()
    }
    
    /// Creates an ExtractionStrategySelector instance
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        return processingContainer.makeExtractionStrategySelector()
    }
    
    /// Creates a TextProcessingPipeline instance
    func makeTextProcessingPipeline() -> TextProcessingPipelineProtocol {
        return processingContainer.makeTextProcessingPipeline()
    }
    
    /// Creates an ExtractionResultValidator instance
    func makeExtractionResultValidator() -> ExtractionResultValidatorProtocol {
        return processingContainer.makeExtractionResultValidator()
    }
    
    // MARK: - Supporting Services for Enhanced Text Extraction
    
    /// Creates a ParallelTextExtractor instance (existing service)
    private func makeParallelTextExtractor() -> ParallelTextExtractor {
        // This service already exists, so we use it directly
        // TODO: Fix TextPreprocessor and progress subject dependencies
        fatalError("ParallelTextExtractor initialization requires fixing dependencies")
    }
    
    /// Creates a SequentialTextExtractor instance (existing service)
    private func makeSequentialTextExtractor() -> SequentialTextExtractor {
        // This service already exists, so we use it directly
        // TODO: Fix memory manager type mismatch
        fatalError("SequentialTextExtractor initialization requires fixing memory manager type mismatch")
    }
    
    /// Creates a StreamingPDFProcessor instance (existing service)
    private func makeStreamingPDFProcessor() -> StreamingPDFProcessor {
        // This service already exists, so we use it directly
        return StreamingPDFProcessor()
    }
    
    /// Creates a PDFProcessingCache instance (existing service)
    private func makePDFProcessingCache() -> PDFProcessingCache {
        // Use the shared instance
        return PDFProcessingCache.shared
    }
    
    /// Creates an ExtractionDocumentAnalyzer instance (existing service)
    private func makeExtractionDocumentAnalyzer() -> ExtractionDocumentAnalyzer {
        // This service already exists, so we use it directly
        return ExtractionDocumentAnalyzer()
    }
    
    /// Creates a TextExtractionMemoryManager instance
    private func makeExtractionMemoryManager() -> TextExtractionMemoryManager {
        return TextExtractionMemoryManager()
    }
    
    /// Creates supporting services for text processing pipeline
    private func makeTextCleaningService() -> TextCleaningService {
        // TODO: Implement actual TextCleaningServiceImpl
        fatalError("TextCleaningService implementation not yet available")
    }
    
    private func makeTextNormalizationService() -> TextNormalizationService {
        // TODO: Implement actual TextNormalizationServiceImpl
        fatalError("TextNormalizationService implementation not yet available")
    }
    
    private func makeTextStructureDetector() -> TextStructureDetector {
        // TODO: Implement actual TextStructureDetectorImpl
        fatalError("TextStructureDetector implementation not yet available")
    }
    
    private func makeTextEnhancementService() -> TextEnhancementService {
        // TODO: Implement actual TextEnhancementServiceImpl
        fatalError("TextEnhancementService implementation not yet available")
    }
    
    private func makeProcessingValidationService() -> ProcessingValidationService {
        // TODO: Implement actual ProcessingValidationServiceImpl
        fatalError("ProcessingValidationService implementation not yet available")
    }
    
    private func makeTextFormattingService() -> TextFormattingService {
        // TODO: Implement actual TextFormattingServiceImpl
        fatalError("TextFormattingService implementation not yet available")
    }
    
    /// Creates supporting services for result validation
    private func makeContentQualityAnalyzer() -> ContentQualityAnalyzer {
        // TODO: Implement actual ContentQualityAnalyzerImpl
        fatalError("ContentQualityAnalyzer implementation not yet available")
    }
    
    private func makeFormatIntegrityChecker() -> FormatIntegrityChecker {
        // TODO: Implement actual FormatIntegrityCheckerImpl
        fatalError("FormatIntegrityChecker implementation not yet available")
    }
    
    private func makePerformanceMetricsValidator() -> PerformanceMetricsValidator {
        // TODO: Implement actual PerformanceMetricsValidatorImpl
        fatalError("PerformanceMetricsValidator implementation not yet available")
    }
    
    private func makeCompletenessAnalyzer() -> CompletenessAnalyzer {
        // TODO: Implement actual CompletenessAnalyzerImpl
        fatalError("CompletenessAnalyzer implementation not yet available")
    }
    
    private func makeExtractionErrorDetector() -> ExtractionErrorDetector {
        // TODO: Implement actual ExtractionErrorDetectorImpl
        fatalError("ExtractionErrorDetector implementation not yet available")
    }
    
    private func makeComplianceChecker() -> ComplianceChecker {
        // TODO: Implement actual ComplianceCheckerImpl
        fatalError("ComplianceChecker implementation not yet available")
    }
    
    /// Creates supporting helper services
    private func makeTextPreprocessor() -> TextPreprocessor {
        // TODO: Implement actual TextPreprocessor
        fatalError("TextPreprocessor implementation not yet available")
    }
    
    private func makeProgressSubject() -> PassthroughSubject<(pageIndex: Int, progress: Double), Never> {
        return PassthroughSubject<(pageIndex: Int, progress: Double), Never>()
    }
    
    /// Creates a PayslipProcessorFactory instance
    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return processingContainer.makePayslipProcessorFactory()
    }
    
    /// Creates a PDFParsingCoordinator instance (now using PDFParsingOrchestrator)
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return processingContainer.makePDFParsingCoordinator()
    }
    
    /// Creates a PayslipProcessingPipeline instance
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return processingContainer.makePayslipProcessingPipeline()
    }
    
    /// Creates a PayslipImportCoordinator instance
    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return processingContainer.makePayslipImportCoordinator()
    }
    
    /// Creates an AbbreviationManager instance (assuming singleton for now)
    /// TODO: Review lifecycle and potential need for protocol/mocking
    func makeAbbreviationManager() -> AbbreviationManager {
        return processingContainer.makeAbbreviationManager()
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
        return coreContainer.makePayslipEncryptionService()
    }
    
    /// Creates an encryption service
    @MainActor
    func makeEncryptionService() -> EncryptionServiceProtocol {
        return coreContainer.makeEncryptionService()
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
        // This will be moved to FeatureContainer in a future phase
        // For now, delegate to ViewModelContainer
        return QuizGenerationService(
            financialSummaryViewModel: FinancialSummaryViewModel(),
            trendAnalysisViewModel: TrendAnalysisViewModel(),
            chartDataViewModel: ChartDataViewModel()
        )
    }
    
    /// Creates an achievement service.
    func makeAchievementService() -> AchievementService {
        // This will be moved to FeatureContainer in a future phase
        // For now, create directly
        return AchievementService()
    }
    
    /// Creates a quiz view model.
    func makeQuizViewModel() -> QuizViewModel {
        return viewModelContainer.makeQuizViewModel()
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
        return viewModelContainer.makeWebUploadViewModel()
    }
    
    /// Creates a WebUploadDeepLinkHandler
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler {
        return WebUploadDeepLinkHandler(
            webUploadService: makeWebUploadService()
        )
    }
    
    /// Creates a SecureStorage implementation
    func makeSecureStorage() -> SecureStorageProtocol {
        return coreContainer.makeSecureStorage()
    }
    
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
    
    // MARK: - Cache Management
    
    /// Clears cached quiz-related instances to force recreation
    /// Useful for testing or when user data needs to be refreshed
    @MainActor
    func clearQuizCache() {
        // Quiz-related caches are now managed by ViewModelContainer
        // This method is kept for backwards compatibility but does nothing
        // TODO: Remove this method in future versions or delegate to ViewModelContainer
    }
    
    /// Clears all cached instances
    @MainActor
    func clearAllCaches() {
        // Cached ViewModels are now managed by ViewModelContainer
        // Clear any remaining cached services in the main container
        _webUploadService = nil
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