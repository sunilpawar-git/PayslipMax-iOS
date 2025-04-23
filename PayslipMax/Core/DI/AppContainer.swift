import Foundation
import PDFKit

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
        registerDataServices()
        registerStorageServices()
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
    
    /// Register data services
    private func registerDataServices() {
        // Data services would go here
    }
    
    /// Register storage services
    private func registerStorageServices() {
        // Storage services would go here
    }
    
    /// Register analytics services
    private func registerAnalyticsServices() {
        // Register the modern extraction analytics service
        services["ExtractionAnalyticsProtocol"] = AsyncExtractionAnalytics()
    }
    
    /// Register navigation services
    private func registerNavigationServices() {
        // Since the router is typically created as a StateObject in the app,
        // we shouldn't create a new instance here. Instead, we'll set it later.
    }
    
    /// Resolve a service from the container
    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)
        // Attempt to cast, potentially failing if the registered type doesn't match
        // or if it was registered using the Any instance method.
        return services[key] as? T
    }
    
    /// Registers an instance for a given service type.
    /// Stores the instance as Any, type safety relies on the resolve method.
    func register<ServiceType>(_ serviceType: ServiceType.Type, instance: Any) {
        let key = String(describing: serviceType)
        services[key] = instance
    }
} 