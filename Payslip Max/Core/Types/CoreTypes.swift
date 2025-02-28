import Foundation
import SwiftUI
import SwiftData

// Forward declaration for PayslipItem to avoid circular dependencies
public protocol PayslipItemProtocol {
    var id: UUID { get }
    var timestamp: Date { get }
    var month: String { get }
    var year: Int { get }
    var credits: Double { get }
    var debits: Double { get }
    var dsopf: Double { get }
    var tax: Double { get }
    var location: String { get }
    var name: String { get }
    var accountNumber: String { get }
    var panNumber: String { get }
}

// MARK: - Service Protocols
public protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

public protocol SecurityServiceProtocol: ServiceProtocol {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ data: Data) async throws -> Data
    func authenticate() async throws -> Bool
}

public protocol DataServiceProtocol: ServiceProtocol {
    func save<T: Codable>(_ item: T) async throws
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T]
    func delete<T: Codable>(_ item: T) async throws
}

public protocol PDFServiceProtocol: ServiceProtocol {
    func process(_ url: URL) async throws -> Data
    func extract(_ data: Data) async throws -> Any // Changed to Any to avoid circular reference
}

// MARK: - Network Protocols
public protocol NetworkServiceProtocol: ServiceProtocol {
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL
    func download(from endpoint: String) async throws -> Data
}

public protocol CloudRepositoryProtocol: ServiceProtocol {
    func syncPayslips() async throws
    func backupPayslips() async throws
    func fetchBackups() async throws -> [PayslipBackup]
    func restorePayslips() async throws
}

// MARK: - Error Types
public enum NetworkError: Error {
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

public enum FeatureError: Error {
    case premiumRequired
    case notImplemented
    case notAvailable
    case featureDisabled
}

// MARK: - API Endpoints
public struct APIEndpoints {
    public static let baseURL = "https://api.payslipmax.com"
    public static let apiVersion = "/v1"
    
    public struct Auth {
        public static let login = "/auth/login"
        public static let register = "/auth/register"
        public static let verify = "/auth/verify"
    }
    
    public struct Payslips {
        public static let sync = "/payslips/sync"
        public static let backup = "/payslips/backup"
        public static let backups = "/payslips/backups"
        public static let restore = "/payslips/restore"
    }
    
    public struct Premium {
        public static let status = "/premium/status"
        public static let upgrade = "/premium/upgrade"
        public static let features = "/premium/features"
    }
}

// MARK: - Backup Model
public struct PayslipBackup: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let payslipCount: Int
    public let data: Data
    
    public init(id: UUID, timestamp: Date, payslipCount: Int, data: Data) {
        self.id = id
        self.timestamp = timestamp
        self.payslipCount = payslipCount
        self.data = data
    }
}

// MARK: - Premium Feature Manager
public class PremiumFeatureManager: ObservableObject {
    public static let shared = PremiumFeatureManager()
    
    @Published public private(set) var isPremiumUser = false
    @Published public private(set) var availableFeatures: [PremiumFeature] = []
    
    public enum PremiumFeature: String, CaseIterable {
        case cloudBackup
        case dataSync
        case advancedInsights
        case exportFeatures
        case prioritySupport
        
        public var title: String {
            switch self {
            case .cloudBackup: return "Cloud Backup"
            case .dataSync: return "Data Sync"
            case .advancedInsights: return "Advanced Insights"
            case .exportFeatures: return "Export Features"
            case .prioritySupport: return "Priority Support"
            }
        }
        
        public var description: String {
            switch self {
            case .cloudBackup: return "Securely store your payslips in the cloud"
            case .dataSync: return "Access your payslips on all your devices"
            case .advancedInsights: return "Get deeper insights into your finances"
            case .exportFeatures: return "Export detailed reports in multiple formats"
            case .prioritySupport: return "Get priority support from our team"
            }
        }
        
        public var icon: String {
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
    
    public func checkPremiumStatus() async {
        // This will be implemented in Phase 2
        // For now, do nothing
    }
    
    public func upgradeToPremium() async throws {
        // This will be implemented in Phase 2
        throw FeatureError.notImplemented
    }
    
    public func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        return isPremiumUser && availableFeatures.contains(feature)
    }
    
    // For backward compatibility
    public func isPremiumUser() async -> Bool {
        return isPremiumUser
    }
    
    // For backward compatibility
    public func isFeatureAvailable(_ feature: PremiumFeature) async -> Bool {
        return await Task.detached { self.isFeatureAvailable(feature) }.value
    }
    
    // For backward compatibility
    public func downgradeFromPremium() {
        isPremiumUser = false
        availableFeatures = []
    }
} 