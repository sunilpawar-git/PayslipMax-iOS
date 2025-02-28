import Foundation
import SwiftUI
import SwiftData

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL
    func download(from endpoint: String) async throws -> Data
}

// MARK: - Cloud Repository Protocol
protocol CloudRepositoryProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
    func syncPayslips() async throws
    func backupPayslips() async throws
    func fetchBackups() async throws -> [PayslipBackup]
    func restorePayslips() async throws
}

// MARK: - Error Types
enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingFailed
    case unauthorized
    case premiumRequired
    case notImplemented
    case serverError
    case noInternet
    case unknown
}

enum FeatureError: Error {
    case premiumRequired
    case notImplemented
    case notAvailable
    case featureDisabled
}

// MARK: - API Endpoints
struct APIEndpoints {
    static let baseURL = "https://api.payslipmax.com"
    static let apiVersion = "/v1"
    
    struct Auth {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let verify = "/auth/verify"
    }
    
    struct Payslips {
        static let sync = "/payslips/sync"
        static let backup = "/payslips/backup"
        static let backups = "/payslips/backups"
        static let restore = "/payslips/restore"
    }
    
    struct Premium {
        static let status = "/premium/status"
        static let upgrade = "/premium/upgrade"
        static let features = "/premium/features"
    }
}

// MARK: - Backup Model
struct PayslipBackup: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let payslipCount: Int
    let data: Data
    
    init(id: UUID = UUID(), timestamp: Date = Date(), payslipCount: Int, data: Data) {
        self.id = id
        self.timestamp = timestamp
        self.payslipCount = payslipCount
        self.data = data
    }
}

// MARK: - Premium Feature Manager
class PremiumFeatureManager: ObservableObject {
    // Singleton instance
    static let shared = PremiumFeatureManager()
    
    // Premium status
    @Published private(set) var isPremiumUser = false
    @Published private(set) var availableFeatures: [PremiumFeature] = []
    
    // Available premium features
    enum PremiumFeature: String, CaseIterable, Identifiable {
        case cloudBackup = "Cloud Backup"
        case dataSync = "Data Sync"
        case advancedInsights = "Advanced Insights"
        case exportFeatures = "Export Features"
        case prioritySupport = "Priority Support"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .cloudBackup:
                return "Securely back up your payslips to the cloud"
            case .dataSync:
                return "Sync your payslips across all your devices"
            case .advancedInsights:
                return "Get detailed insights and analytics about your finances"
            case .exportFeatures:
                return "Export your payslips in various formats"
            case .prioritySupport:
                return "Get priority support from our team"
            }
        }
        
        var icon: String {
            switch self {
            case .cloudBackup: return "icloud"
            case .dataSync: return "arrow.triangle.2.circlepath"
            case .advancedInsights: return "chart.bar"
            case .exportFeatures: return "square.and.arrow.up"
            case .prioritySupport: return "person.fill.questionmark"
            }
        }
    }
    
    private init() {
        // In the future, this will check for premium status
        // For now, always set to false
        self.isPremiumUser = false
        self.availableFeatures = []
    }
    
    // Check if user is premium
    func isPremiumUser() async -> Bool {
        // In a real implementation, this would check with the server
        // For now, return the local value
        return isPremiumUser
    }
    
    // Check if a specific feature is available
    func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
        return await isPremiumUser()
    }
    
    // Upgrade to premium
    func upgradeToPremium() async throws {
        // In a real implementation, this would initiate a payment flow
        // For now, just set the flag to true
        isPremiumUser = true
        availableFeatures = PremiumFeature.allCases
    }
    
    // Downgrade from premium (for testing)
    func downgradeFromPremium() {
        isPremiumUser = false
        availableFeatures = []
    }
}

// MARK: - Placeholder Network Service
class PlaceholderNetworkService: NetworkServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T {
        throw NetworkError.notImplemented
    }
    
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T {
        throw NetworkError.notImplemented
    }
    
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL {
        throw NetworkError.notImplemented
    }
    
    func download(from endpoint: String) async throws -> Data {
        throw NetworkError.notImplemented
    }
}

// MARK: - Placeholder Cloud Repository
class PlaceholderCloudRepository: CloudRepositoryProtocol {
    private let premiumFeatureManager: PremiumFeatureManager
    var isInitialized: Bool = false
    
    init(premiumFeatureManager: PremiumFeatureManager = .shared) {
        self.premiumFeatureManager = premiumFeatureManager
    }
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func syncPayslips() async throws {
        // Check if user is premium
        guard await premiumFeatureManager.isFeatureAvailable(.dataSync) else {
            throw FeatureError.premiumRequired
        }
        
        // In a real implementation, this would sync with the server
        throw FeatureError.notImplemented
    }
    
    func backupPayslips() async throws {
        // Check if user is premium
        guard await premiumFeatureManager.isFeatureAvailable(.cloudBackup) else {
            throw FeatureError.premiumRequired
        }
        
        // In a real implementation, this would backup to the server
        throw FeatureError.notImplemented
    }
    
    func fetchBackups() async throws -> [PayslipBackup] {
        // Check if user is premium
        guard await premiumFeatureManager.isFeatureAvailable(.cloudBackup) else {
            throw FeatureError.premiumRequired
        }
        
        // In a real implementation, this would fetch from the server
        throw FeatureError.notImplemented
    }
    
    func restorePayslips() async throws {
        // Check if user is premium
        guard await premiumFeatureManager.isFeatureAvailable(.cloudBackup) else {
            throw FeatureError.premiumRequired
        }
        
        // In a real implementation, this would restore from the server
        throw FeatureError.notImplemented
    }
}

// MARK: - Mock Network Service (for testing)
class MockNetworkService: NetworkServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T {
        // Return mock data based on the endpoint
        return try JSONDecoder().decode(T.self, from: Data())
    }
    
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T {
        // Return mock data based on the endpoint and body
        return try JSONDecoder().decode(T.self, from: Data())
    }
    
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL {
        // Return a mock URL
        return URL(string: "https://mock.payslipmax.com/uploads/mock-file.pdf")!
    }
    
    func download(from endpoint: String) async throws -> Data {
        // Return mock data
        return "Mock data for download".data(using: .utf8)!
    }
}

// MARK: - Mock Cloud Repository (for testing)
class MockCloudRepository: CloudRepositoryProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func syncPayslips() async throws {
        // Mock implementation - do nothing
    }
    
    func backupPayslips() async throws {
        // Mock implementation - do nothing
    }
    
    func fetchBackups() async throws -> [PayslipBackup] {
        // Return mock backups
        return [
            PayslipBackup(
                id: UUID(),
                timestamp: Date(),
                payslipCount: 5,
                data: Data()
            ),
            PayslipBackup(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-86400),
                payslipCount: 3,
                data: Data()
            )
        ]
    }
    
    func restorePayslips() async throws {
        // Mock implementation - do nothing
    }
} 