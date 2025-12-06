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

    // MARK: - Subscription Configuration

    /// Cached instance of SubscriptionService
    private var _subscriptionService: SubscriptionServiceProtocol?

    /// Cached instance of SubscriptionValidator
    private var _subscriptionValidator: SubscriptionValidatorProtocol?

    /// Cached instance of SubscriptionManager
    private var _subscriptionManager: SubscriptionManager?

    // MARK: - X-Ray Configuration

    /// Cached instance of XRaySettingsService
    private var _xRaySettingsService: (any XRaySettingsServiceProtocol)?

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

        // ⚠️ TEMPORARY: Web upload disabled - backend not ready
        // Force mock usage until payslipmax.com backend is deployed
        // Re-enable when backend is live (Phase 3 of implementation plan)
        let _ = shouldUseMock  // Suppress warning
        print("FeatureContainer: Creating MockWebUploadService (Web upload feature disabled)")
        _webUploadService = MockWebUploadService()
        return _webUploadService!

        // WebUploadCoordinator disabled until backend is ready - prevents TLS/SSL errors
        // Uncomment below when payslipmax.com backend is deployed:
        //
        // print("FeatureContainer: Creating WebUploadCoordinator with base URL: \(webAPIBaseURL.absoluteString)")
        // _webUploadService = WebUploadCoordinator.create(
        //     secureStorage: coreContainer.makeSecureStorage(),
        //     baseURL: webAPIBaseURL
        // )
        // return _webUploadService!
    }

    /// Creates a WebUploadDeepLinkHandler.
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler {
        return WebUploadDeepLinkHandler(
            webUploadService: makeWebUploadService()
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
        // Create with required ViewModels and repository for quiz generation
        let repository = DIContainer.shared.makeSendablePayslipRepository()
        return QuizGenerationService(
            financialSummaryViewModel: FinancialSummaryViewModel(),
            trendAnalysisViewModel: TrendAnalysisViewModel(),
            chartDataViewModel: ChartDataViewModel(),
            repository: repository
        )
    }

    /// Creates an achievement service with all required dependencies.
    func makeAchievementService() -> AchievementService {
        let definitionsService = makeAchievementDefinitionsService()
        let validationService = makeAchievementValidationService()
        let progressCalculator = makeAchievementProgressCalculator()
        let persistenceService = makeAchievementPersistenceService()

        return AchievementService(
            definitionsService: definitionsService,
            validationService: validationService,
            progressCalculator: progressCalculator,
            persistenceService: persistenceService
        )
    }

    // MARK: - Achievement Supporting Services

    /// Creates an achievement definitions service.
    private func makeAchievementDefinitionsService() -> AchievementDefinitionsServiceProtocol {
        return AchievementDefinitionsService()
    }

    /// Creates an achievement validation service.
    private func makeAchievementValidationService() -> AchievementValidationServiceProtocol {
        return AchievementValidationService()
    }

    /// Creates an achievement progress calculator service.
    private func makeAchievementProgressCalculator() -> AchievementProgressCalculatorProtocol {
        return AchievementProgressCalculator()
    }

    /// Creates an achievement persistence service.
    private func makeAchievementPersistenceService() -> AchievementPersistenceServiceProtocol {
        return AchievementPersistenceService()
    }

    // MARK: - Subscription Feature

    /// Creates a SubscriptionService instance with proper configuration.
    func makeSubscriptionService() -> SubscriptionServiceProtocol {
        // Return cached instance if available
        if let service = _subscriptionService {
            return service
        }

        let paymentProcessor = makePaymentProcessor()
        let persistenceService = makeSubscriptionPersistenceService()

        let service = SubscriptionService(
            paymentProcessor: paymentProcessor,
            persistenceService: persistenceService
        )

        _subscriptionService = service
        return service
    }

    /// Creates a SubscriptionValidator instance with proper configuration.
    func makeSubscriptionValidator() -> SubscriptionValidatorProtocol {
        // Return cached instance if available
        if let validator = _subscriptionValidator {
            return validator
        }

        let subscriptionService = makeSubscriptionService()
        let persistenceService = makeSubscriptionPersistenceService()

        let validator = SubscriptionValidator(
            subscriptionService: subscriptionService,
            persistenceService: persistenceService
        )

        _subscriptionValidator = validator
        return validator
    }

    /// Creates a SubscriptionManager instance with proper configuration.
    func makeSubscriptionManager() -> SubscriptionManager {
        // Return cached instance if available
        if let manager = _subscriptionManager {
            return manager
        }

        let subscriptionService = makeSubscriptionService()
        let subscriptionValidator = makeSubscriptionValidator()

        let manager = SubscriptionManager(
            subscriptionService: subscriptionService,
            subscriptionValidator: subscriptionValidator
        )

        _subscriptionManager = manager
        return manager
    }

    // MARK: - Subscription Supporting Services

    /// Creates a PaymentProcessor instance.
    private func makePaymentProcessor() -> PaymentProcessorProtocol {
        return PaymentProcessor()
    }

    /// Creates a SubscriptionPersistenceService instance.
    private func makeSubscriptionPersistenceService() -> SubscriptionPersistenceProtocol {
        return SubscriptionPersistenceService()
    }

    // MARK: - X-Ray Feature

    /// Creates a PayslipComparisonService instance.
    /// - Returns: A new PayslipComparisonService instance (lightweight, no caching needed)
    func makePayslipComparisonService() -> PayslipComparisonServiceProtocol {
        return PayslipComparisonService()
    }

    /// Creates an XRaySettingsService instance with proper configuration.
    /// - Returns: Cached XRaySettingsService instance
    func makeXRaySettingsService() -> any XRaySettingsServiceProtocol {
        // Return cached instance if available
        if let service = _xRaySettingsService {
            return service
        }

        let subscriptionValidator = makeSubscriptionValidator()
        let service = XRaySettingsService(subscriptionValidator: subscriptionValidator)

        _xRaySettingsService = service
        return service
    }

    // MARK: - Cache Management

    /// Clears all cached feature services
    func clearFeatureCaches() {
        _webUploadService = nil
        _subscriptionService = nil
        _subscriptionValidator = nil
        _subscriptionManager = nil
        _xRaySettingsService = nil
        print("FeatureContainer: All feature caches cleared")
    }

    // MARK: - Achievement Cache Management

    /// Achievement services use protocol-based design and don't require caching
    /// since they are lightweight and can be created on demand
}
