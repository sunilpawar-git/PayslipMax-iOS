import Foundation
import SwiftUI
import SwiftData

// MARK: - Protocols
protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

protocol SecurityServiceProtocol: ServiceProtocol {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ data: Data) async throws -> Data
    func authenticate() async throws -> Bool
}

protocol DataServiceProtocol: ServiceProtocol {
    func save<T: Codable>(_ item: T) async throws
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T]
    func delete<T: Codable>(_ item: T) async throws
}

protocol PDFServiceProtocol: ServiceProtocol {
    func process(_ url: URL) async throws -> Data
    func extract(_ data: Data) async throws -> Any
}

// MARK: - DIContainer Protocol
@MainActor
protocol DIContainerProtocol {
    // Services
    var securityService: any SecurityServiceProtocol { get }
    var dataService: any DataServiceProtocol { get }
    var pdfService: any PDFServiceProtocol { get }
    
    // ViewModels
    func makeHomeViewModel() -> HomeViewModel
    func makePayslipsViewModel() -> PayslipsViewModel
    func makeSecurityViewModel() -> SecurityViewModel
    func makeAuthViewModel() -> AuthViewModel
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel
    func makeInsightsViewModel() -> InsightsViewModel
    func makeSettingsViewModel() -> SettingsViewModel
}

// MARK: - Container
@MainActor
class DIContainer: DIContainerProtocol {
    // MARK: - Shared Instance
    static var shared = DIContainer()
    
    // MARK: - Testing Helpers
    static func setShared(_ container: DIContainer) {
        shared = container
        // Update the resolver with the new container
        container.setupResolver()
    }
    
    static func resetToDefault() {
        shared = DIContainer()
        // Update the resolver with the new container
        shared.setupResolver()
    }
    
    // MARK: - Properties
    private let modelContext: ModelContext
    
    // MARK: - Services
    // Use lazy initialization to avoid circular dependencies
    private var _securityService: SecurityServiceProtocol?
    var securityService: SecurityServiceProtocol {
        if let service = _securityService {
            return service
        }
        let service = createSecurityService()
        _securityService = service
        return service
    }
    
    private var _dataService: DataServiceProtocol?
    var dataService: DataServiceProtocol {
        if let service = _dataService {
            return service
        }
        let service = createDataService()
        _dataService = service
        return service
    }
    
    private var _pdfService: PDFServiceProtocol?
    var pdfService: PDFServiceProtocol {
        if let service = _pdfService {
            return service
        }
        let service = createPDFService()
        _pdfService = service
        return service
    }
    
    // Factory methods for creating services
    func createSecurityService() -> SecurityServiceProtocol {
        return SecurityServiceImpl()
    }
    
    func createDataService() -> DataServiceProtocol {
        return DataServiceImpl(
            security: securityService,
            modelContext: modelContext
        )
    }
    
    func createPDFService() -> PDFServiceProtocol {
        return PDFServiceImpl(security: securityService)
    }
    
    // MARK: - ViewModels
    func makeHomeViewModel() -> HomeViewModel {
        let pdfManager = PDFUploadManager()
        return HomeViewModel(pdfManager: pdfManager)
    }
    
    func makePayslipsViewModel() -> PayslipsViewModel {
        PayslipsViewModel(dataService: dataService)
    }
    
    func makeSecurityViewModel() -> SecurityViewModel {
        SecurityViewModel()
    }
    
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(securityService: securityService)
    }
    
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel {
        PayslipDetailViewModel(payslip: payslip, securityService: securityService)
    }
    
    func makeInsightsViewModel() -> InsightsViewModel {
        InsightsViewModel(dataService: dataService)
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(securityService: securityService, dataService: dataService)
    }
    
    // MARK: - Initialization
    init() {
        do {
            let schema = Schema([PayslipItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = ModelContext(container)
            
            // Setup the resolver with this container
            self.setupResolver()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Testing Support
    static func forTesting() -> DIContainer {
        // Create a test container with mock services
        class TestDIContainer: DIContainer {
            override func createSecurityService() -> SecurityServiceProtocol {
                return MockSecurityService()
            }
            
            override func createDataService() -> DataServiceProtocol {
                return MockDataService()
            }
            
            override func createPDFService() -> PDFServiceProtocol {
                return MockPDFService()
            }
        }
        
        return TestDIContainer()
    }
    
    // MARK: - Resolver for Property Wrapper
    func setupResolver() {
        DIResolver.shared.setupWithContainer(self)
    }
}

// MARK: - Non-Actor-Isolated Resolver
// This resolver is specifically designed to be used outside of the actor system
final class DIResolver {
    // Singleton instance
    static let shared = DIResolver()
    
    // Services - these are not actor-isolated
    private var securityService: any SecurityServiceProtocol
    private var dataService: any DataServiceProtocol
    private var pdfService: any PDFServiceProtocol
    
    // Private initializer for singleton
    private init() {
        // Initialize with default implementations
        // These will be replaced when setupWithContainer is called
        self.securityService = DefaultSecurityService()
        self.dataService = DefaultDataService()
        self.pdfService = DefaultPDFService()
    }
    
    // Setup method to be called from the MainActor
    @MainActor
    func setupWithContainer(_ container: DIContainer) {
        // Copy references to the services from the container
        self.securityService = container.securityService
        self.dataService = container.dataService
        self.pdfService = container.pdfService
    }
    
    // Resolve method for property wrappers
    func resolve<T>(_ type: T.Type) -> T {
        switch type {
        case is SecurityServiceProtocol.Type:
            return securityService as! T
        case is DataServiceProtocol.Type:
            return dataService as! T
        case is PDFServiceProtocol.Type:
            return pdfService as! T
        default:
            fatalError("No provider found for type \(T.self)")
        }
    }
}

// MARK: - Default Service Implementations
// These are simple placeholders that will be replaced with real implementations
private class DefaultSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func authenticate() async throws -> Bool {
        fatalError("This is a placeholder implementation")
    }
}

private class DefaultDataService: DataServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func save<T: Codable>(_ item: T) async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fatalError("This is a placeholder implementation")
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        fatalError("This is a placeholder implementation")
    }
}

private class DefaultPDFService: PDFServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func process(_ url: URL) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func extract(_ data: Data) async throws -> Any {
        fatalError("This is a placeholder implementation")
    }
}

// MARK: - Property Wrapper
@propertyWrapper
struct Inject<T> {
    var wrappedValue: T {
        DIResolver.shared.resolve(T.self)
    }
} 