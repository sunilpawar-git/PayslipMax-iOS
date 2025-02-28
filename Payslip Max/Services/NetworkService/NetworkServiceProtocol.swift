import Foundation

/// Enum representing possible network errors
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized
    case serverError(Int)
    case noInternet
    case timeout
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .noInternet:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

/// Protocol defining network service operations
protocol NetworkServiceProtocol {
    /// Performs a GET request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func get(from endpoint: String, headers: [String: String]?) async throws -> Data
    
    /// Performs a POST request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body data to send
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func post(to endpoint: String, body: Data, headers: [String: String]?) async throws -> Data
    
    /// Performs a PUT request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body data to send
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func put(to endpoint: String, body: Data, headers: [String: String]?) async throws -> Data
    
    /// Performs a DELETE request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func delete(from endpoint: String, headers: [String: String]?) async throws -> Data
    
    /// Uploads a file
    /// - Parameters:
    ///   - fileURL: The URL of the file to upload
    ///   - endpoint: The API endpoint to upload to
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func uploadFile(from fileURL: URL, to endpoint: String, headers: [String: String]?) async throws -> Data
    
    /// Downloads a file
    /// - Parameters:
    ///   - endpoint: The API endpoint to download from
    ///   - destination: The URL where the file should be saved
    ///   - headers: Optional HTTP headers
    /// - Returns: The URL where the file was saved
    func downloadFile(from endpoint: String, to destination: URL, headers: [String: String]?) async throws -> URL
} 