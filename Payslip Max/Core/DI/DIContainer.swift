import Foundation
import SwiftUI
import SwiftData

// MARK: - Protocols

/// A protocol that defines the basic requirements for a service.
///
/// All services in the application should conform to this protocol,
/// which ensures they have a consistent initialization pattern.
protocol ServiceProtocol {
    /// Indicates whether the service has been initialized.
    var isInitialized: Bool { get }
    
    /// Initializes the service.
    ///
    /// This method should be called before using the service.
    /// It performs any necessary setup, such as establishing connections
    /// or loading resources.
    ///
    /// - Throws: An error if initialization fails.
    func initialize() async throws
}

/// A protocol that defines the requirements for a security service.
///
/// The security service provides functionality for encryption, decryption,
/// and authentication.
protocol SecurityServiceProtocol: ServiceProtocol {
    /// Encrypts the provided data.
    ///
    /// - Parameter data: The data to encrypt.
    /// - Returns: The encrypted data.
    /// - Throws: An error if encryption fails.
    func encrypt(_ data: Data) async throws -> Data
    
    /// Decrypts the provided data.
    ///
    /// - Parameter data: The data to decrypt.
    /// - Returns: The decrypted data.
    /// - Throws: An error if decryption fails.
    func decrypt(_ data: Data) async throws -> Data
    
    /// Authenticates the user.
    ///
    /// - Returns: A boolean indicating whether authentication was successful.
    /// - Throws: An error if authentication fails.
    func authenticate() async throws -> Bool
}

/// A protocol that defines the requirements for a data service.
///
/// The data service provides functionality for saving, fetching,
/// and deleting data.
protocol DataServiceProtocol: ServiceProtocol {
    /// Saves the provided item.
    ///
    /// - Parameter item: The item to save.
    /// - Throws: An error if saving fails.
    func save<T: Codable>(_ item: T) async throws
    
    /// Fetches items of the specified type.
    ///
    /// - Parameter type: The type of items to fetch.
    /// - Returns: An array of items of the specified type.
    /// - Throws: An error if fetching fails.
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T]
    
    /// Deletes the provided item.
    ///
    /// - Parameter item: The item to delete.
    /// - Throws: An error if deletion fails.
    func delete<T: Codable>(_ item: T) async throws
}

/// A protocol that defines the requirements for a PDF service.
///
/// The PDF service provides functionality for processing and extracting
/// information from PDF files.
protocol PDFServiceProtocol: ServiceProtocol {
    /// Processes the PDF file at the specified URL.
    ///
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: The processed data.
    /// - Throws: An error if processing fails.
    func process(_ url: URL) async throws -> Data
    
    /// Extracts information from the provided PDF data.
    ///
    /// - Parameter data: The PDF data to extract information from.
    /// - Returns: The extracted information.
    /// - Throws: An error if extraction fails.
    func extract(_ data: Data) async throws -> Any
}

// MARK: - Service Provider Protocols

/// Base protocol for service providers
protocol ServiceProvider {
    /// Initializes the provider with the container
    /// - Parameter container: The DI container
    init(container: DIContainer)
    
    /// Registers services with the container
    func registerServices()
}

/// Provider for security-related services
protocol SecurityServiceProvider: ServiceProvider {
    /// Creates and returns a security service
    func makeSecurityService() -> SecurityServiceProtocol
}

/// Provider for data-related services
protocol DataServiceProvider: ServiceProvider {
    /// Creates and returns a data service
    func makeDataService() -> DataServiceProtocol
}

/// Provider for PDF-related services
protocol PDFServiceProvider: ServiceProvider {
    /// Creates and returns a PDF service
    func makePDFService() -> PDFServiceProtocol
}

/// Provider for view models
protocol ViewModelProvider: ServiceProvider {
    /// Creates a home view model
    func makeHomeViewModel() -> HomeViewModel
    
    /// Creates a payslips view model
    func makePayslipsViewModel() -> PayslipsViewModel
    
    /// Creates a security view model
    func makeSecurityViewModel() -> SecurityViewModel
    
    /// Creates an authentication view model
    func makeAuthViewModel() -> AuthViewModel
    
    /// Creates a payslip detail view model for the specified payslip
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel
    
    /// Creates an insights view model
    func makeInsightsViewModel() -> InsightsViewModel
    
    /// Creates a settings view model
    func makeSettingsViewModel() -> SettingsViewModel
}

// MARK: - Default Service Providers

/// Default implementation of SecurityServiceProvider
class DefaultSecurityServiceProvider: SecurityServiceProvider {
    private weak var container: DIContainer?
    
    required init(container: DIContainer) {
        self.container = container
    }
    
    func registerServices() {
        container?.registerService(type: SecurityServiceProtocol.self, factory: makeSecurityService)
    }
    
    func makeSecurityService() -> SecurityServiceProtocol {
        return SecurityServiceImpl()
    }
}

/// Default implementation of DataServiceProvider
class DefaultDataServiceProvider: DataServiceProvider {
    private weak var container: DIContainer?
    
    required init(container: DIContainer) {
        self.container = container
    }
    
    func registerServices() {
        container?.registerService(type: DataServiceProtocol.self, factory: makeDataService)
    }
    
    func makeDataService() -> DataServiceProtocol {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return DataServiceImpl(
            security: container.resolve(SecurityServiceProtocol.self),
            modelContext: container.modelContext
        )
    }
}

/// Default implementation of PDFServiceProvider
class DefaultPDFServiceProvider: PDFServiceProvider {
    private weak var container: DIContainer?
    
    required init(container: DIContainer) {
        self.container = container
    }
    
    func registerServices() {
        container?.registerService(type: PDFServiceProtocol.self, factory: makePDFService)
    }
    
    func makePDFService() -> PDFServiceProtocol {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return PDFServiceImpl(security: container.resolve(SecurityServiceProtocol.self))
    }
}

/// Default implementation of ViewModelProvider
class DefaultViewModelProvider: ViewModelProvider {
    private weak var container: DIContainer?
    
    required init(container: DIContainer) {
        self.container = container
    }
    
    func registerServices() {
        // View models are created on demand, no registration needed
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        let pdfManager = PDFUploadManager()
        return HomeViewModel(pdfManager: pdfManager)
    }
    
    func makePayslipsViewModel() -> PayslipsViewModel {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return PayslipsViewModel(dataService: container.resolve(DataServiceProtocol.self))
    }
    
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    func makeAuthViewModel() -> AuthViewModel {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return AuthViewModel(securityService: container.resolve(SecurityServiceProtocol.self))
    }
    
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return PayslipDetailViewModel(
            payslip: payslip,
            securityService: container.resolve(SecurityServiceProtocol.self)
        )
    }
    
    func makeInsightsViewModel() -> InsightsViewModel {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return InsightsViewModel(dataService: container.resolve(DataServiceProtocol.self))
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        guard let container = container else {
            fatalError("Container is nil")
        }
        
        return SettingsViewModel(
            securityService: container.resolve(SecurityServiceProtocol.self),
            dataService: container.resolve(DataServiceProtocol.self)
        )
    }
}

// MARK: - DIContainer Protocol

/// A protocol that defines the requirements for a dependency injection container.
///
/// The container provides access to services and factory methods for creating view models.
@MainActor
protocol DIContainerProtocol {
    // Services
    /// The model context for SwiftData operations
    var modelContext: ModelContext { get }
    
    /// Registers a service factory for the specified type
    /// - Parameters:
    ///   - type: The type of service to register
    ///   - factory: A factory function that creates the service
    func registerService<T>(type: T.Type, factory: @escaping () -> T)
    
    /// Resolves a service of the specified type
    /// - Parameter type: The type of service to resolve
    /// - Returns: A service of the specified type
    func resolve<T>(_ type: T.Type) -> T
    
    // ViewModels
    /// Creates a home view model.
    ///
    /// - Returns: A new home view model.
    func makeHomeViewModel() -> HomeViewModel
    
    /// Creates a payslips view model.
    ///
    /// - Returns: A new payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel
    
    /// Creates a security view model.
    ///
    /// - Returns: A new security view model.
    func makeSecurityViewModel() -> SecurityViewModel
    
    /// Creates an authentication view model.
    ///
    /// - Returns: A new authentication view model.
    func makeAuthViewModel() -> AuthViewModel
    
    /// Creates a payslip detail view model for the specified payslip.
    ///
    /// - Parameter payslip: The payslip to create a view model for.
    /// - Returns: A new payslip detail view model.
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel
    
    /// Creates an insights view model.
    ///
    /// - Returns: A new insights view model.
    func makeInsightsViewModel() -> InsightsViewModel
    
    /// Creates a settings view model.
    ///
    /// - Returns: A new settings view model.
    func makeSettingsViewModel() -> SettingsViewModel
}

// MARK: - Container

/// The dependency injection container for the application.
///
/// This class provides access to services and factory methods for creating view models.
/// It uses a modular approach with service providers to reduce complexity.
@MainActor
class DIContainer: DIContainerProtocol {
    // MARK: - Shared Instance
    
    /// The shared instance of the container.
    static var shared = DIContainer()
    
    // MARK: - Testing Helpers
    
    /// Sets the shared instance of the container.
    ///
    /// - Parameter container: The container to set as the shared instance.
    static func setShared(_ container: DIContainer) {
        shared = container
    }
    
    /// Resets the shared instance of the container to the default implementation.
    static func resetToDefault() {
        shared = DIContainer()
    }
    
    // MARK: - Properties
    
    /// The model context for SwiftData operations.
    let modelContext: ModelContext
    
    /// Service factories mapped by type
    private var serviceFactories: [String: () -> Any] = [:]
    
    /// Service providers
    private var providers: [ServiceProvider] = []
    
    /// View model provider
    private var viewModelProvider: ViewModelProvider
    
    // MARK: - Initialization
    
    /// Initializes the container with default providers.
    init() {
        do {
            let schema = Schema([PayslipItem.self, PersonalInfo.self, FinancialData.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = ModelContext(container)
            
            // Create and register providers
            let securityProvider = DefaultSecurityServiceProvider(container: self)
            let dataProvider = DefaultDataServiceProvider(container: self)
            let pdfProvider = DefaultPDFServiceProvider(container: self)
            self.viewModelProvider = DefaultViewModelProvider(container: self)
            
            self.providers = [securityProvider, dataProvider, pdfProvider, viewModelProvider]
            
            // Register services
            for provider in providers {
                provider.registerServices()
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    /// Initializes the container with custom providers.
    init(securityProvider: SecurityServiceProvider,
         dataProvider: DataServiceProvider,
         pdfProvider: PDFServiceProvider,
         viewModelProvider: ViewModelProvider,
         modelContext: ModelContext) {
        self.modelContext = modelContext
        self.viewModelProvider = viewModelProvider
        
        self.providers = [securityProvider, dataProvider, pdfProvider, viewModelProvider]
        
        // Register services
        for provider in providers {
            provider.registerServices()
        }
    }
    
    // MARK: - Service Registration and Resolution
    
    /// Registers a service factory for the specified type
    /// - Parameters:
    ///   - type: The type of service to register
    ///   - factory: A factory function that creates the service
    func registerService<T>(type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        serviceFactories[key] = factory
    }
    
    /// Resolves a service of the specified type
    /// - Parameter type: The type of service to resolve
    /// - Returns: A service of the specified type
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        guard let factory = serviceFactories[key] as? () -> T else {
            fatalError("No factory registered for type \(key)")
        }
        
        return factory()
    }
    
    // MARK: - ViewModels
    
    /// Creates a home view model.
    ///
    /// - Returns: A new home view model.
    func makeHomeViewModel() -> HomeViewModel {
        return viewModelProvider.makeHomeViewModel()
    }
    
    /// Creates a payslips view model.
    ///
    /// - Returns: A new payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        return viewModelProvider.makePayslipsViewModel()
    }
    
    /// Creates a security view model.
    ///
    /// - Returns: A new security view model.
    func makeSecurityViewModel() -> SecurityViewModel {
        return viewModelProvider.makeSecurityViewModel()
    }
    
    /// Creates an authentication view model.
    ///
    /// - Returns: A new authentication view model.
    func makeAuthViewModel() -> AuthViewModel {
        return viewModelProvider.makeAuthViewModel()
    }
    
    /// Creates a payslip detail view model for the specified payslip.
    ///
    /// - Parameter payslip: The payslip to create a view model for.
    /// - Returns: A new payslip detail view model.
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel {
        return viewModelProvider.makePayslipDetailViewModel(for: payslip)
    }
    
    /// Creates an insights view model.
    ///
    /// - Returns: A new insights view model.
    func makeInsightsViewModel() -> InsightsViewModel {
        return viewModelProvider.makeInsightsViewModel()
    }
    
    /// Creates a settings view model.
    ///
    /// - Returns: A new settings view model.
    func makeSettingsViewModel() -> SettingsViewModel {
        return viewModelProvider.makeSettingsViewModel()
    }
    
    // MARK: - Testing Support
    
    /// Creates a container for testing.
    ///
    /// This method returns a container with mock services.
    ///
    /// - Returns: A container for testing.
    static func forTesting() -> DIContainer {
        do {
            // Create an in-memory model container for testing
            let schema = Schema([PayslipItem.self, PersonalInfo.self, FinancialData.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let modelContext = ModelContext(container)
            
            // Create mock providers
            class MockSecurityServiceProvider: SecurityServiceProvider {
                private weak var container: DIContainer?
                
                required init(container: DIContainer) {
                    self.container = container
                }
                
                func registerServices() {
                    container?.registerService(type: SecurityServiceProtocol.self, factory: makeSecurityService)
                }
                
                func makeSecurityService() -> SecurityServiceProtocol {
                    return MockSecurityService()
                }
            }
            
            class MockDataServiceProvider: DataServiceProvider {
                private weak var container: DIContainer?
                
                required init(container: DIContainer) {
                    self.container = container
                }
                
                func registerServices() {
                    container?.registerService(type: DataServiceProtocol.self, factory: makeDataService)
                }
                
                func makeDataService() -> DataServiceProtocol {
                    return MockDataService()
                }
            }
            
            class MockPDFServiceProvider: PDFServiceProvider {
                private weak var container: DIContainer?
                
                required init(container: DIContainer) {
                    self.container = container
                }
                
                func registerServices() {
                    container?.registerService(type: PDFServiceProtocol.self, factory: makePDFService)
                }
                
                func makePDFService() -> PDFServiceProtocol {
                    return MockPDFService()
                }
            }
            
            // Create the test container with mock providers
            let testContainer = DIContainer(
                securityProvider: MockSecurityServiceProvider(container: DIContainer.shared),
                dataProvider: MockDataServiceProvider(container: DIContainer.shared),
                pdfProvider: MockPDFServiceProvider(container: DIContainer.shared),
                viewModelProvider: DefaultViewModelProvider(container: DIContainer.shared),
                modelContext: modelContext
            )
            
            return testContainer
        } catch {
            fatalError("Could not create test ModelContainer: \(error)")
        }
    }
}

// MARK: - Default Service Implementations

/// A default implementation of the security service.
///
/// This class is a placeholder that will be replaced with a real implementation.
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

/// A default implementation of the data service.
///
/// This class is a placeholder that will be replaced with a real implementation.
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

/// A default implementation of the PDF service.
///
/// This class is a placeholder that will be replaced with a real implementation.
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

/// A property wrapper that injects a service from the container.
///
/// This property wrapper resolves a service of the specified type
/// from the container.
///
/// Example usage:
/// ```
/// @Inject var securityService: SecurityServiceProtocol
/// ```
@propertyWrapper
struct Inject<T> {
    /// The wrapped value.
    ///
    /// This property resolves a service of the specified type
    /// from the container.
    var wrappedValue: T {
        DIContainer.shared.resolve(T.self)
    }
} 