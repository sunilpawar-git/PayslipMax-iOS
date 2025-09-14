import Foundation
import Combine

/// Service responsible for handling network response validation and error mapping
protocol NetworkResponseHandlerProtocol {
    func validateResponse(_ data: Data, response: URLResponse) throws -> Data
    func mapURLError(_ error: URLError) -> Error
}

/// Service responsible for handling network response validation and error mapping
class NetworkResponseHandler: NetworkResponseHandlerProtocol {

    /// Validates HTTP response and maps status codes to appropriate errors
    func validateResponse(_ data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw AppError.authenticationFailed("Unauthorized")
        case 403:
            throw AppError.authenticationFailed("Forbidden")
        case 404:
            throw AppError.requestFailed(httpResponse.statusCode)
        case 500...599:
            throw AppError.serverError("Server error with status code: \(httpResponse.statusCode)")
        default:
            throw AppError.requestFailed(httpResponse.statusCode)
        }
    }

    /// Maps URL errors to application-specific errors
    func mapURLError(_ error: URLError) -> Error {
        switch error.code {
        case .notConnectedToInternet:
            return AppError.networkConnectionLost
        case .timedOut:
            return AppError.timeoutError
        default:
            return AppError.unknown(error)
        }
    }
}
