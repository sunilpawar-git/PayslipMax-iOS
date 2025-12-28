import Foundation
import UIKit

/// Protocol for device registration functionality
protocol DeviceRegistrationServiceProtocol {
    func registerDevice() async throws -> String
    func getDeviceToken() async throws -> String
}

/// Service responsible for device registration with the web upload API
class DeviceRegistrationService: DeviceRegistrationServiceProtocol {
    private let urlSession: URLSession
    private let secureStorage: SecureStorageProtocol
    private let baseURL: URL

    private var deviceToken: String?

    init(
        urlSession: URLSession = .shared,
        secureStorage: SecureStorageProtocol,
        baseURL: URL
    ) {
        self.urlSession = urlSession
        self.secureStorage = secureStorage
        self.baseURL = baseURL
    }

    func registerDevice() async throws -> String {
        print("DeviceRegistrationService: Attempting to register device")

        if let token = deviceToken {
            print("DeviceRegistrationService: Using existing device token")
            return token
        }

        if let storedToken = try? retrieveStoredToken() {
            return storedToken
        }

        return try await performRegistration()
    }

    func getDeviceToken() async throws -> String {
        return try await registerDevice()
    }

    // MARK: - Private Methods

    private func retrieveStoredToken() throws -> String? {
        do {
            if let storedToken = try secureStorage.getString(key: "web_upload_device_token") {
                print("DeviceRegistrationService: Retrieved device token from secure storage")
                self.deviceToken = storedToken
                return storedToken
            }
        } catch {
            print("DeviceRegistrationService: Failed to retrieve device token from secure storage: \(error)")
        }
        return nil
    }

    private func performRegistration() async throws -> String {
        let endpoint = baseURL.appendingPathComponent("devices/register")
        print("DeviceRegistrationService: Registering device at endpoint: \(endpoint.absoluteString)")

        let request = try await buildRegistrationRequest(for: endpoint)

        do {
            let (data, response) = try await urlSession.data(for: request)
            return try processRegistrationResponse(data: data, response: response)
        } catch let urlError as URLError {
            throw buildNetworkError(from: urlError)
        }
    }

    private func buildRegistrationRequest(for endpoint: URL) async throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let deviceInfo = [
            "deviceName": await UIDevice.current.name,
            "deviceType": await UIDevice.current.model,
            "osVersion": await UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]

        do {
            request.httpBody = try JSONEncoder().encode(deviceInfo)
        } catch {
            print("DeviceRegistrationService: Failed to encode device info: \(error)")
            throw NSError(domain: "WebUploadErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare registration data: \(error.localizedDescription)"])
        }

        return request
    }

    private func processRegistrationResponse(data: Data, response: URLResponse) throws -> String {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DeviceRegistrationService: Invalid response type")
            throw NSError(domain: "WebUploadErrorDomain", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid server response type"])
        }

        try validateHTTPStatusCode(httpResponse, data: data)
        return try decodeAndStoreToken(from: data)
    }

    private func validateHTTPStatusCode(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200:
            print("DeviceRegistrationService: Server returned success status 200")
            return

        case 400...499:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
            print("DeviceRegistrationService: Client error \(response.statusCode): \(errorMessage)")
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Registration failed: \(errorMessage)"])

        case 500...599:
            print("DeviceRegistrationService: Server error \(response.statusCode)")
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])

        default:
            print("DeviceRegistrationService: Unexpected status code \(response.statusCode)")
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from server: \(response.statusCode)"])
        }
    }

    private func decodeAndStoreToken(from data: Data) throws -> String {
        do {
            struct RegisterResponse: Codable {
                let deviceToken: String
            }

            let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
            self.deviceToken = registerResponse.deviceToken

            try secureStorage.saveString(key: "web_upload_device_token", value: registerResponse.deviceToken)

            print("DeviceRegistrationService: Successfully registered device with token: \(registerResponse.deviceToken)")
            return registerResponse.deviceToken
        } catch {
            print("DeviceRegistrationService: Failed to decode response: \(error)")
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "WebUploadErrorDomain", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to process server response: \(errorMessage)"])
        }
    }

    private func buildNetworkError(from urlError: URLError) -> NSError {
        print("DeviceRegistrationService: URLError during registration: \(urlError)")

        let errorMessage: String
        switch urlError.code {
        case .notConnectedToInternet:
            errorMessage = "No internet connection. Please check your network and try again."
        case .timedOut:
            errorMessage = "Request timed out. Server may be busy, please try again later."
        case .cannotFindHost, .cannotConnectToHost:
            errorMessage = "Cannot connect to server. Please verify the API is available."
        default:
            errorMessage = "Network error: \(urlError.localizedDescription)"
        }

        return NSError(domain: "WebUploadErrorDomain", code: urlError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
}

// MARK: - Error Types

enum DeviceRegistrationError: Error, LocalizedError {
    case encodingError(Error)
    case invalidResponse
    case networkError(URLError)
    case clientError(Int, String)
    case serverError(Int)
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .encodingError(let error):
            return "Failed to prepare registration data: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response type"
        case .networkError(let urlError):
            return createNetworkErrorMessage(urlError)
        case .clientError(_, let message):
            return "Registration failed: \(message)"
        case .serverError(let code):
            return "Server error occurred (\(code)). Please try again later."
        case .unexpectedStatusCode(let code):
            return "Unexpected response from server: \(code)"
        }
    }

    private func createNetworkErrorMessage(_ urlError: URLError) -> String {
        switch urlError.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network and try again."
        case .timedOut:
            return "Request timed out. Server may be busy, please try again later."
        case .cannotFindHost, .cannotConnectToHost:
            return "Cannot connect to server. Please verify the API is available."
        default:
            return "Network error: \(urlError.localizedDescription)"
        }
    }
}
