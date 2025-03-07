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

// MARK: - DIContainer Protocol

/// A protocol that defines the requirements for a dependency injection container.
///
/// The container provides access to services and factory methods for creating view models.
@MainActor
protocol DIContainerProtocol {
    // Services
    /// The security service.
    var securityService: any SecurityServiceProtocol { get }
    
    /// The data service.
    var dataService: any DataServiceProtocol { get }
    
    /// The PDF service.
    var pdfService: any PDFServiceProtocol { get }
    
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
    func makePayslipDetailViewModel(for payslip: any PayslipItemProtocol) -> PayslipDetailViewModel
    
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
/// It uses lazy initialization to avoid circular dependencies.
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
        // Update the resolver with the new container
        container.setupResolver()
    }
    
    /// Resets the shared instance of the container to the default implementation.
    static func resetToDefault() {
        shared = DIContainer()
        // Update the resolver with the new container
        shared.setupResolver()
    }
    
    // MARK: - Properties
    
    /// The model context for SwiftData operations.
    private let modelContext: ModelContext
    
    // MARK: - Services
    
    /// The backing storage for the security service.
    private var _securityService: SecurityServiceProtocol?
    
    /// The security service.
    ///
    /// This property uses lazy initialization to avoid circular dependencies.
    /// The service is created the first time it is accessed.
    var securityService: SecurityServiceProtocol {
        if let service = _securityService {
            return service
        }
        let service = createSecurityService()
        _securityService = service
        return service
    }
    
    /// The backing storage for the data service.
    private var _dataService: DataServiceProtocol?
    
    /// The data service.
    ///
    /// This property uses lazy initialization to avoid circular dependencies.
    /// The service is created the first time it is accessed.
    var dataService: DataServiceProtocol {
        if let service = _dataService {
            return service
        }
        let service = createDataService()
        _dataService = service
        return service
    }
    
    /// The backing storage for the PDF service.
    private var _pdfService: PDFServiceProtocol?
    
    /// The PDF service.
    ///
    /// This property uses lazy initialization to avoid circular dependencies.
    /// The service is created the first time it is accessed.
    var pdfService: PDFServiceProtocol {
        if let service = _pdfService {
            return service
        }
        let service = createPDFService()
        _pdfService = service
        return service
    }
    
    // MARK: - Factory Methods
    
    /// Creates a security service.
    ///
    /// - Returns: A new security service.
    func createSecurityService() -> SecurityServiceProtocol {
        return SecurityServiceImpl()
    }
    
    /// Creates a data service.
    ///
    /// - Returns: A new data service.
    func createDataService() -> DataServiceProtocol {
        return DataServiceImpl(
            security: securityService,
            modelContext: modelContext
        )
    }
    
    /// Creates a PDF service.
    ///
    /// - Returns: A new PDF service.
    func createPDFService() -> PDFServiceProtocol {
        return PDFServiceImpl(
            security: securityService,
            pdfExtractor: createPDFExtractor()
        )
    }
    
    /// Creates a PDF extractor.
    ///
    /// - Returns: A new PDF extractor.
    func createPDFExtractor() -> PDFExtractorProtocol {
        return DefaultPDFExtractor()
    }
    
    // MARK: - ViewModels
    
    /// Creates a home view model.
    ///
    /// - Returns: A new home view model.
    func makeHomeViewModel() -> HomeViewModel {
        let pdfManager = PDFUploadManager()
        return HomeViewModel(pdfManager: pdfManager)
    }
    
    /// Creates a payslips view model.
    ///
    /// - Returns: A new payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        PayslipsViewModel(dataService: dataService)
    }
    
    /// Creates a security view model.
    ///
    /// - Returns: A new security view model.
    func makeSecurityViewModel() -> SecurityViewModel {
        SecurityViewModel()
    }
    
    /// Creates an authentication view model.
    ///
    /// - Returns: A new authentication view model.
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(securityService: securityService)
    }
    
    /// Creates a payslip detail view model for the specified payslip.
    ///
    /// - Parameter payslip: The payslip to create a view model for.
    /// - Returns: A new payslip detail view model.
    func makePayslipDetailViewModel(for payslip: any PayslipItemProtocol) -> PayslipDetailViewModel {
        PayslipDetailViewModel(payslip: payslip, securityService: securityService)
    }
    
    /// Creates an insights view model.
    ///
    /// - Returns: A new insights view model.
    func makeInsightsViewModel() -> InsightsViewModel {
        InsightsViewModel(dataService: dataService)
    }
    
    /// Creates a settings view model.
    ///
    /// - Returns: A new settings view model.
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(securityService: securityService, dataService: dataService)
    }
    
    // MARK: - Initialization
    
    /// Initializes the container.
    ///
    /// This method sets up the model context and resolver.
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
    
    /// Creates a container for testing.
    ///
    /// This method returns a container with mock services.
    ///
    /// - Returns: A container for testing.
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
    
    /// Sets up the resolver with this container.
    ///
    /// This method updates the resolver with the services from this container.
    func setupResolver() {
        DIResolver.shared.setupWithContainer(self)
    }
}

// MARK: - Non-Actor-Isolated Resolver

/// A resolver that provides access to services outside of the actor system.
///
/// This class is specifically designed to be used with the `@Inject` property wrapper.
final class DIResolver {
    // MARK: - Shared Instance
    
    /// The shared instance of the resolver.
    static let shared = DIResolver()
    
    // MARK: - Properties
    
    /// The security service.
    private var securityService: any SecurityServiceProtocol
    
    /// The data service.
    private var dataService: any DataServiceProtocol
    
    /// The PDF service.
    private var pdfService: any PDFServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the resolver with default implementations.
    ///
    /// The default implementations are placeholders that will be replaced
    /// when `setupWithContainer` is called.
    private init() {
        // Initialize with default implementations
        // These will be replaced when setupWithContainer is called
        self.securityService = DefaultSecurityService()
        self.dataService = DefaultDataService()
        self.pdfService = DefaultPDFService()
    }
    
    // MARK: - Setup
    
    /// Sets up the resolver with the specified container.
    ///
    /// This method updates the resolver with the services from the container.
    ///
    /// - Parameter container: The container to set up the resolver with.
    @MainActor
    func setupWithContainer(_ container: DIContainer) {
        // Copy references to the services from the container
        self.securityService = container.securityService
        self.dataService = container.dataService
        self.pdfService = container.pdfService
    }
    
    // MARK: - Resolution
    
    /// Resolves a service of the specified type.
    ///
    /// - Parameter type: The type of service to resolve.
    /// - Returns: A service of the specified type.
    /// - Precondition: The type must be one of the supported service types.
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
        DIResolver.shared.resolve(T.self)
    }
} 