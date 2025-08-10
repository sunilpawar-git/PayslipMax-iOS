import Foundation

/// Container for feature-specific services.
/// Handles WebUpload, Quiz, Achievement, and other feature services with their configurations.
@MainActor
class FeatureContainer: FeatureContainerProtocol {
    
    // MARK: - Properties
    
    /// Whether to use mock implementations for testing.
    let useMocks: Bool
    
    // MARK: - Dependencies
    
    /// Core service container for accessing security and storage services
    private let coreContainer: CoreServiceContainerProtocol
    
    // MARK: - WebUpload Configuration
    
    /// Whether to force the use of mock WebUploadService even in release builds
    private var forceWebUploadMock: Bool = false
    
    /// Base URL for API calls
    private var webAPIBaseURL: URL = URL(string: "https://payslipmax.com/api")!
    
    /// Cached instance of WebUploadService
    private var _webUploadService: WebUploadServiceProtocol?
    /// Cached deep link security service
    private var _deepLinkSecurityService: DeepLinkSecurityServiceProtocol?
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }
    
    // MARK: - WebUpload Feature
    
    /// Creates a WebUploadService instance with proper configuration.
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
            print("FeatureContainer: Creating MockWebUploadService")
            _webUploadService = MockWebUploadService()
            return _webUploadService!
        }
        
        print("FeatureContainer: Creating WebUploadCoordinator with base URL: \(webAPIBaseURL.absoluteString)")
        _webUploadService = WebUploadCoordinator.create(
            secureStorage: coreContainer.makeSecureStorage(),
            baseURL: webAPIBaseURL
        )
        return _webUploadService!
    }
    
    /// Creates a WebUploadDeepLinkHandler.
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler {
        return WebUploadDeepLinkHandler(
            webUploadService: makeWebUploadService(),
            securityService: makeDeepLinkSecurityService()
        )
    }
    
    /// Toggle the use of mock WebUploadService.
    /// - Parameter useMock: Whether to use the mock service
    func toggleWebUploadMock(_ useMock: Bool) {
        forceWebUploadMock = useMock
        // Clear any cached instances
        _webUploadService = nil
        print("FeatureContainer: WebUploadService mock mode set to: \(useMock)")
    }
    
    /// Set the base URL for API calls.
    /// - Parameter url: The base URL to use
    func setWebAPIBaseURL(_ url: URL) {
        webAPIBaseURL = url
        // Clear any cached instances to ensure they use the new URL
        _webUploadService = nil
        print("FeatureContainer: WebAPI base URL set to: \(url.absoluteString)")
    }
    
    // MARK: - Gamification Feature
    
    /// Creates a quiz generation service.
    func makeQuizGenerationService() -> QuizGenerationService {
        // Create with required ViewModels for quiz generation
        return QuizGenerationService(
            financialSummaryViewModel: FinancialSummaryViewModel(),
            trendAnalysisViewModel: TrendAnalysisViewModel(),
            chartDataViewModel: ChartDataViewModel()
        )
    }
    
    /// Creates an achievement service.
    func makeAchievementService() -> AchievementService {
        return AchievementService()
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached feature services
    func clearFeatureCaches() {
        _webUploadService = nil
        _deepLinkSecurityService = nil
        print("FeatureContainer: All feature caches cleared")
    }

    // MARK: - Deep Link Security

    func makeDeepLinkSecurityService() -> DeepLinkSecurityServiceProtocol {
        if let s = _deepLinkSecurityService { return s }
        let service = DeepLinkSecurityService(secureStorage: coreContainer.makeSecureStorage())
        _deepLinkSecurityService = service
        return service
    }
}