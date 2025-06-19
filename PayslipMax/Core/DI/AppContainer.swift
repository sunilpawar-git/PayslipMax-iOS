import Foundation
import PDFKit
import SwiftData

// Import service files

/// Provides dependency injection for the app
class AppContainer {
    
    /// The shared container instance
    static let shared = AppContainer()
    
    // Dictionary to store dependencies
    private var services: [String: Any] = [:]
    
    private init() {
        registerServices()
    }
    
    /// Register all services in the container
    private func registerServices() {
        registerExtractorServices()
        registerPDFServices()
        registerAnalyticsServices()
        registerNavigationServices()
    }
    
    /// Register extraction related services
    private func registerExtractorServices() {
        // Register pattern-based extraction services
        services["PatternRepositoryProtocol"] = DefaultPatternRepository()
        
        let patternRepository = resolve(PatternRepositoryProtocol.self)!
        services["PayslipExtractorService"] = PayslipExtractorService(patternRepository: patternRepository)
    }
    
    /// Register PDF-related services
    private func registerPDFServices() {
        // Create and register the ModularPDFExtractor
        let patternRepository = resolve(PatternRepositoryProtocol.self)!
        services["PDFExtractorProtocol"] = ModularPDFExtractor(patternRepository: patternRepository)
    }
    
    /// Register analytics services
    private func registerAnalyticsServices() {
        // Register the legacy extraction analytics service
        services["ExtractionAnalyticsProtocol"] = AsyncExtractionAnalytics()
        
        // Register the main analytics manager and providers
        let analyticsManager = AnalyticsManager.shared
        services["AnalyticsProtocol"] = analyticsManager
        
        // Register the FirebaseAnalyticsProvider if feature flag is enabled
        if FeatureFlagManager.shared.isEnabled(.enhancedAnalytics) {
            let firebaseProvider = FirebaseAnalyticsProvider.shared
            analyticsManager.registerProvider(firebaseProvider)
        }
        
        // Register specialized analytics services
        services["PerformanceAnalyticsService"] = PerformanceAnalyticsService.shared
        services["UserAnalyticsService"] = UserAnalyticsService.shared
    }
    
    /// Register navigation services
    private func registerNavigationServices() {
        // Since the router is typically created as a StateObject in the app,
        // we shouldn't create a new instance here. Instead, we'll set it later.
    }
    
    /// Resolve a service from the container
    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)
        
        // For services that are not pre-registered, return nil
        // The caller should handle creating them manually
        return services[key] as? T
    }
    
    /// Registers an instance for a given service type.
    /// Stores the instance as Any, type safety relies on the resolve method.
    func register<ServiceType>(_ serviceType: ServiceType.Type, instance: Any) {
        let key = String(describing: serviceType)
        services[key] = instance
    }
} 