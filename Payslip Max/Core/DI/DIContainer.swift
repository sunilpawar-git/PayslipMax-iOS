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
    func extract(_ data: Data) async throws -> PayslipItem
}

// MARK: - Container
@MainActor
final class DIContainer {
    // MARK: - Shared Instance
    static let shared = DIContainer()
    
    // MARK: - Properties
    private let modelContext: ModelContext
    
    // MARK: - Services
    private(set) lazy var securityService: any SecurityServiceProtocol = {
        let service = SecurityServiceImpl()
        return service
    }()
    
    private(set) lazy var dataService: any DataServiceProtocol = {
        let service = DataServiceImpl(
            security: securityService,
            modelContext: modelContext
        )
        return service
    }()
    
    private(set) lazy var pdfService: any PDFServiceProtocol = {
        let service = PDFServiceImpl(security: securityService)
        return service
    }()
    
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
    private init() {
        do {
            let schema = Schema([PayslipItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = ModelContext(container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
} 