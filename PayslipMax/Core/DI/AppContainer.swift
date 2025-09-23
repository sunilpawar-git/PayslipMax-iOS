import Foundation
import PDFKit
import SwiftData

// Import service files

/// Provides dependency injection for the app
@MainActor
class AppContainer {

    /// The shared container instance
    static let shared = AppContainer()

    // Storage for registered services (nonisolated for cross-actor access)
    private nonisolated(unsafe) var singletons: [String: Any] = [:]
    private nonisolated(unsafe) var factories: [String: () -> Any] = [:]

    private init() {
        registerServices()
    }

    /// Register all services in the container
    private func registerServices() {
        registerExtractorServices()
        registerPDFServices()
        registerAnalyticsServices()
        registerNavigationServices()
        registerUIManagers() // Phase 2: Register UI managers with dual-mode support
    }

    /// Register extraction related services
    private func registerExtractorServices() {
        // Register pattern-based extraction services
        registerSingleton(DefaultPatternRepository(), for: PatternRepositoryProtocol.self)

        let patternRepository = resolve(PatternRepositoryProtocol.self)!
        registerSingleton(PayslipExtractorService(patternRepository: patternRepository), for: PayslipExtractorService.self)

        // Register text extractor with proper DI pattern
        let patternProvider = DefaultPatternProvider()
        registerSingleton(DefaultTextExtractor(patternProvider: patternProvider), for: TextExtractor.self)

        // Register pattern testing services
        registerSingleton(PatternApplicationStrategies(), for: PatternApplicationStrategies.self)
        registerSingleton(createPatternTestingService(), for: PatternTestingServiceProtocol.self)
    }

    /// Create the pattern testing service with all dependencies
    /// - Returns: A fully configured PatternTestingService instance
    private func createPatternTestingService() -> PatternTestingServiceProtocol {
        // Resolve dependencies from container
        let textExtractor = resolve(TextExtractor.self) ?? DefaultTextExtractor(patternProvider: DefaultPatternProvider())
        let analyticsService = resolve(ExtractionAnalyticsProtocol.self) ?? AsyncExtractionAnalytics()

        // Create pattern manager with required dependencies
        let patternProvider = DefaultPatternProvider()
        let validator = PayslipValidator(patternProvider: patternProvider)
        let builder = PayslipBuilder(patternProvider: patternProvider, validator: validator)

        let patternMatcher = UnifiedPatternMatcher()
        let patternValidator = UnifiedPatternValidator(patternProvider: patternProvider)
        let patternDefinitions = UnifiedPatternDefinitions(patternProvider: patternProvider)

        let patternManager = PayslipPatternManager(
            patternMatcher: patternMatcher,
            patternValidator: patternValidator,
            patternDefinitions: patternDefinitions,
            payslipBuilder: builder
        )

        return PatternTestingService(
            textExtractor: textExtractor,
            patternManager: patternManager,
            analyticsService: analyticsService
        )
    }

    /// Register PDF-related services
    private func registerPDFServices() {
        // Create and register the ModularPDFExtractor with all dependencies
        let patternRepository = resolve(PatternRepositoryProtocol.self)!
        let preprocessingService = TextPreprocessingService()
        let _ = PatternApplicationEngine(
            preprocessingService: preprocessingService
        )
        let _ = ExtractionResultAssembler()
        let _ = ExtractionValidator()

        registerSingleton(AsyncModularPDFExtractor(
            patternRepository: patternRepository
        ), for: PDFExtractorProtocol.self)
    }

    /// Register analytics services
    private func registerAnalyticsServices() {
        // Register the legacy extraction analytics service
        singletons["ExtractionAnalyticsProtocol"] = AsyncExtractionAnalytics()

        // Register analytics manager with dual-mode support (Phase 2)
        registerDualMode(
            singleton: AnalyticsManager.shared,
            factory: { AnalyticsManager() },
            featureFlag: .diAnalyticsManager,
            for: (any AnalyticsManagerProtocol).self
        )

        // Register the FirebaseAnalyticsProvider
        registerSingleton(FirebaseAnalyticsProvider.shared, for: FirebaseAnalyticsProvider.self)

        // Register specialized analytics services (singleton-only due to private init)
        registerSingleton(PerformanceAnalyticsService.shared, for: PerformanceAnalyticsService.self)
        registerSingleton(UserAnalyticsService.shared, for: UserAnalyticsService.self)
    }

    /// Register navigation services
    private func registerNavigationServices() {
        // Since the router is typically created as a StateObject in the app,
        // we shouldn't create a new instance here. Instead, we'll set it later.
    }

    /// Register UI managers with dual-mode support (Phase 2)
    private func registerUIManagers() {
        // Register GlobalLoadingManager with dual-mode support
        registerDualMode(
            singleton: GlobalLoadingManager.shared,
            factory: { GlobalLoadingManager() },
            featureFlag: .diGlobalLoadingManager,
            for: (any GlobalLoadingManagerProtocol).self
        )

        // Register TabTransitionCoordinator with dual-mode support
        registerDualMode(
            singleton: TabTransitionCoordinator.shared,
            factory: { TabTransitionCoordinator() },
            featureFlag: .diTabTransitionCoordinator,
            for: (any TabTransitionCoordinatorProtocol).self
        )

        // Register AppearanceManager with dual-mode support
        registerDualMode(
            singleton: AppearanceManager.shared,
            factory: { AppearanceManager() },
            featureFlag: .diAppearanceManager,
            for: (any AppearanceManagerProtocol).self
        )

        // Register PerformanceMetrics with dual-mode support
        registerDualMode(
            singleton: PerformanceMetrics.shared,
            factory: { PerformanceMetrics() },
            featureFlag: .diPerformanceMetrics,
            for: (any PerformanceMetricsProtocol).self
        )
    }

    // MARK: - Registration Methods (Phase 2: Dual-Mode Support)

    /// Register a singleton instance
    func registerSingleton<T>(_ instance: T, for serviceType: T.Type) {
        let key = String(describing: serviceType)
        singletons[key] = instance
    }

    /// Register a factory function
    func registerFactory<T>(_ factory: @escaping () -> T, for serviceType: T.Type) {
        let key = String(describing: serviceType)
        factories[key] = factory
    }

    /// Register a service with feature flag-based resolution
    func registerDualMode<T>(
        singleton: T,
        factory: @escaping () -> T,
        featureFlag: Feature,
        for serviceType: T.Type
    ) {
        let key = String(describing: serviceType)
        singletons[key] = singleton
        factories[key] = factory
        // Store feature flag mapping for resolution
        singletons["\(key)_featureFlag"] = featureFlag
    }

    // MARK: - Resolution Methods (Enhanced for Phase 2)

    /// Resolve a service from the container
    /// Note: Feature flag-based resolution requires MainActor context
    nonisolated func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)

        // Basic singleton resolution (feature flag logic requires MainActor)
        return singletons[key] as? T
    }

    /// Resolve a service with feature flag support (MainActor required)
    func resolveWithFeatureFlags<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)

        // Check for feature flag-based dual-mode resolution
        if let featureFlag = singletons["\(key)_featureFlag"] as? Feature {
            if FeatureFlagManager.shared.isEnabled(featureFlag) {
                // Use factory method when feature flag is enabled
                if let factory = factories[key] {
                    return factory() as? T
                }
            } else {
                // Use singleton when feature flag is disabled
                if let singleton = singletons[key] {
                    return singleton as? T
                }
            }
        }

        // Fallback to singleton resolution
        return singletons[key] as? T
    }

    /// Registers an instance for a given service type (legacy compatibility).
    /// Stores the instance as Any, type safety relies on the resolve method.
    func register<ServiceType>(_ serviceType: ServiceType.Type, instance: Any) {
        let key = String(describing: serviceType)
        singletons[key] = instance
    }
}
