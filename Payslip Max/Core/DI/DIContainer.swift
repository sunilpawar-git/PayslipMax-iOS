import Foundation
import SwiftUI
import SwiftData

// Import the CoreTypes
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Date
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

// No special imports needed - Swift will find these types in the module

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
    func extract(_ data: Data) async throws -> PayslipItem
}

// MARK: - DIContainer Protocol
@MainActor
protocol DIContainerProtocol {
    // Services
    var securityService: any SecurityServiceProtocol { get }
    var dataService: any DataServiceProtocol { get }
    var pdfService: any PDFServiceProtocol { get }
    var networkService: any NetworkServiceProtocol { get }
    var cloudRepository: any CloudRepositoryProtocol { get }
    var premiumFeatureManager: PremiumFeatureManager { get }
    
    // ViewModels
    func makeHomeViewModel() -> HomeViewModel
    func makePayslipsViewModel() -> PayslipsViewModel
    func makeSecurityViewModel() -> SecurityViewModel
    func makeAuthViewModel() -> AuthViewModel
    func makePayslipDetailViewModel(for payslip: PayslipItem) -> PayslipDetailViewModel
    func makeInsightsViewModel() -> InsightsViewModel
    func makeSettingsViewModel() -> SettingsViewModel
    func makePremiumUpgradeViewModel() -> PremiumUpgradeViewModel
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
    var securityService: any SecurityServiceProtocol
    var dataService: any DataServiceProtocol
    var pdfService: any PDFServiceProtocol
    var networkService: any NetworkServiceProtocol
    var cloudRepository: any CloudRepositoryProtocol
    var premiumFeatureManager: PremiumFeatureManager
    
    // MARK: - ViewModels
    func makeHomeViewModel() -> HomeViewModel {
        let pdfManager = PDFUploadManager()
        return HomeViewModel(pdfManager: pdfManager)
    }
    
    func makePayslipsViewModel() -> PayslipsViewModel {
        PayslipsViewModel(
            dataService: dataService,
            cloudRepository: cloudRepository,
            premiumFeatureManager: premiumFeatureManager
        )
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
    
    func makePremiumUpgradeViewModel() -> PremiumUpgradeViewModel {
        PremiumUpgradeViewModel(
            premiumFeatureManager: premiumFeatureManager,
            cloudRepository: cloudRepository
        )
    }
    
    // MARK: - Initialization
    init() {
        do {
            let schema = Schema([PayslipItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = ModelContext(container)
            
            // Initialize services
            self.securityService = SecurityServiceImpl()
            self.dataService = DataServiceImpl(
                security: self.securityService,
                modelContext: self.modelContext
            )
            self.pdfService = PDFServiceImpl(security: self.securityService)
            
            // Initialize premium feature manager
            self.premiumFeatureManager = PremiumFeatureManager.shared
            
            // Initialize network services
            self.networkService = PlaceholderNetworkService()
            self.cloudRepository = PlaceholderCloudRepository(
                premiumFeatureManager: self.premiumFeatureManager
            )
            
            // Setup the resolver with this container
            self.setupResolver()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Testing Support
    static func forTesting() -> DIContainer {
        // Create a test container with mock services
        let testContainer = DIContainer()
        
        // Replace services with mocks
        testContainer.securityService = MockSecurityService()
        testContainer.dataService = MockDataService()
        testContainer.pdfService = MockPDFService()
        testContainer.networkService = MockNetworkService()
        testContainer.cloudRepository = MockCloudRepository()
        
        // Update the resolver with the new services
        testContainer.setupResolver()
        
        return testContainer
    }
    
    // MARK: - Resolver Setup
    func setupResolver() {
        // This is a placeholder for the resolver setup
        // It will be implemented in Phase 2
    }
} 