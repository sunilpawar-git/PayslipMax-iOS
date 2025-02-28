import Foundation

/// Errors that can occur during network operations
public enum NetworkError: Error {
    /// Invalid URL provided
    case invalidURL
    
    /// Request failed with an error
    case requestFailed(Error)
    
    /// Server returned an error status code
    case serverError(Int)
    
    /// No data received in the response
    case noData
    
    /// Response data could not be decoded
    case decodingFailed(Error)
    
    /// File operation failed
    case fileOperationFailed(Error)
    
    /// Invalid response received
    case invalidResponse
    
    /// Unauthorized access
    case unauthorized
    
    /// User description of the error
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .noData:
            return "No data received from the server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .fileOperationFailed(let error):
            return "File operation failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response received from the server"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
} 