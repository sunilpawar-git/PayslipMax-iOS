import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingFailed
    case unauthorized
    case premiumRequired
    case notImplemented
}

// Import the ServiceProtocol
protocol NetworkServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
    
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL
    func download(from endpoint: String) async throws -> Data
} 