import Foundation
@testable import Payslip_Max

// Base protocol for all services
protocol ServiceProtocol: AnyObject {
    // Common service methods can go here
}

// Service locator for dependency injection
class ServiceLocator {
    private static var services: [String: Any] = [:]
    
    static func reset() {
        services = [:]
    }
    
    static func register<T>(type: T.Type, service: Any) {
        let key = String(describing: type)
        services[key] = service
    }
    
    static func resolve<T>() -> T? {
        let key = String(describing: T.self)
        return services[key] as? T
    }
}

// Property wrapper for dependency injection
@propertyWrapper
struct Inject<T> {
    var wrappedValue: T
    
    init() {
        guard let service: T = ServiceLocator.resolve() else {
            fatalError("No service of type \(T.self) registered")
        }
        self.wrappedValue = service
    }
}

// MARK: - Network Service

protocol NetworkServiceProtocol: ServiceProtocol {
    func get(url: URL, headers: [String: String]?) async throws -> Data
    func post(url: URL, body: Data, headers: [String: String]?) async throws -> Data
    func put(url: URL, body: Data, headers: [String: String]?) async throws -> Data
    func delete(url: URL, headers: [String: String]?) async throws -> Data
}

class MockNetworkService: ServiceProtocol, NetworkServiceProtocol {
    var lastURL: URL?
    var lastMethod: String?
    var lastBody: Data?
    var lastHeaders: [String: String]?
    var responseData: Data?
    var error: Error?
    
    func get(url: URL, headers: [String: String]?) async throws -> Data {
        lastURL = url
        lastMethod = "GET"
        lastHeaders = headers
        
        if let error = error {
            throw error
        }
        
        return responseData ?? Data()
    }
    
    func post(url: URL, body: Data, headers: [String: String]?) async throws -> Data {
        lastURL = url
        lastMethod = "POST"
        lastBody = body
        lastHeaders = headers
        
        if let error = error {
            throw error
        }
        
        return responseData ?? Data()
    }
    
    func put(url: URL, body: Data, headers: [String: String]?) async throws -> Data {
        lastURL = url
        lastMethod = "PUT"
        lastBody = body
        lastHeaders = headers
        
        if let error = error {
            throw error
        }
        
        return responseData ?? Data()
    }
    
    func delete(url: URL, headers: [String: String]?) async throws -> Data {
        lastURL = url
        lastMethod = "DELETE"
        lastHeaders = headers
        
        if let error = error {
            throw error
        }
        
        return responseData ?? Data()
    }
}

// MARK: - Models for testing

struct Payslip: Codable {
    let id: String
    let month: String
    let year: Int
    let grossSalary: Double
    let netSalary: Double
    let deductions: [Deduction]
}

struct Deduction: Codable {
    let type: String
    let amount: Double
}

// MARK: - Protocol definitions only (no implementations)

protocol DataServiceProtocol: ServiceProtocol {
    func fetchPayslips() async throws -> [Payslip]
    func fetchPayslip(id: String) async throws -> Payslip
}

protocol SecurityServiceProtocol: ServiceProtocol {
    func encrypt(_ string: String) throws -> String
    func decrypt(_ string: String) throws -> String
}

protocol AuthServiceProtocol: ServiceProtocol {
    func login(username: String, password: String) async throws -> Bool
    func logout() async -> Bool
    var isLoggedIn: Bool { get }
}

// Note: The actual mock implementations are in their respective test files 