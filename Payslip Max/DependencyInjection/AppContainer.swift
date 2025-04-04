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
    
    /// Resolve a service from the container
    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)
        return services[key] as? T
    }
} 