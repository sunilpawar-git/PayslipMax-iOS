import Foundation

// Import the FeatureError enum
enum FeatureError: Error {
    case premiumRequired
    case notImplemented
    case notAvailable
}

class PlaceholderNetworkService: NetworkServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func get<T: Decodable>(from endpoint: String, headers: [String: String]? = nil) async throws -> T {
        throw FeatureError.notImplemented
    }
    
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]? = nil) async throws -> T {
        throw FeatureError.notImplemented
    }
    
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL {
        throw FeatureError.notImplemented
    }
    
    func download(from endpoint: String) async throws -> Data {
        throw FeatureError.notImplemented
    }
} 