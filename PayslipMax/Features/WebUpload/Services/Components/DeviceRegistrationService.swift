import Foundation
import UIKit

/// Service responsible for device registration with the web upload system
protocol DeviceRegistrationServiceProtocol {
    /// Register device for receiving web uploads
    func registerDevice() async throws -> String
    
    /// Get cached device token if available
    func getCachedDeviceToken() async -> String?
    
    /// Clear stored device token
    func clearDeviceToken() async throws
}

/// Implementation of device registration service
class DeviceRegistrationService: DeviceRegistrationServiceProtocol {
    private let urlSession: URLSession
    private let secureStorage: SecureStorageProtocol
    private let baseURL: URL
    
    private var deviceToken: String?
    private let deviceTokenKey = "web_upload_device_token"
    
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
        
        // If we already have a token, return it
        if let token = deviceToken {
            print("DeviceRegistrationService: Using existing device token")
            return token
        }
        
        // Try to get token from secure storage first
        if let storedToken = await getCachedDeviceToken() {
            print("DeviceRegistrationService: Retrieved device token from secure storage")
            self.deviceToken = storedToken
            return storedToken
        }
        
        // Create a registration request
        let endpoint = baseURL.appendingPathComponent("devices/register")
        print("DeviceRegistrationService: Registering device at endpoint: \(endpoint.absoluteString)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Get device info for registration
        let deviceInfo = await createDeviceInfo()
        
        do {
            request.httpBody = try JSONEncoder().encode(deviceInfo)
        } catch {
            print("DeviceRegistrationService: Failed to encode device info: \(error)")
            throw DeviceRegistrationError.encodingError(error)
        }
        
        // Make the request with comprehensive error handling
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DeviceRegistrationService: Invalid response type")
                throw DeviceRegistrationError.invalidResponse
            }
            
            try await handleRegistrationResponse(httpResponse: httpResponse, data: data)
            
            // Parse the response to get the device token
            let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
            self.deviceToken = registerResponse.deviceToken
            
            // Store the device token securely
            try secureStorage.saveString(key: deviceTokenKey, value: registerResponse.deviceToken)
            
            print("DeviceRegistrationService: Successfully registered device with token: \(registerResponse.deviceToken)")
            return registerResponse.deviceToken
            
        } catch let urlError as URLError {
            print("DeviceRegistrationService: URLError during registration: \(urlError)")
            throw DeviceRegistrationError.networkError(urlError)
        } catch {
            print("DeviceRegistrationService: Other error during registration: \(error)")
            throw error
        }
    }
    
    func getCachedDeviceToken() async -> String? {
        do {
            return try secureStorage.getString(key: deviceTokenKey)
        } catch {
            print("DeviceRegistrationService: Failed to retrieve device token from secure storage: \(error)")
            return nil
        }
    }
    
    func clearDeviceToken() async throws {
        deviceToken = nil
        try secureStorage.deleteItem(key: deviceTokenKey)
        print("DeviceRegistrationService: Device token cleared")
    }
    
    // MARK: - Private Methods
    
    private func createDeviceInfo() async -> [String: String] {
        return [
            "deviceName": await UIDevice.current.name,
            "deviceType": await UIDevice.current.model,
            "osVersion": await UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
    }
    
    private func handleRegistrationResponse(httpResponse: HTTPURLResponse, data: Data) async throws {
        switch httpResponse.statusCode {
        case 200:
            print("DeviceRegistrationService: Server returned success status 200")
            return
            
        case 400...499:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
            print("DeviceRegistrationService: Client error \(httpResponse.statusCode): \(errorMessage)")
            throw DeviceRegistrationError.clientError(httpResponse.statusCode, errorMessage)
            
        case 500...599:
            print("DeviceRegistrationService: Server error \(httpResponse.statusCode)")
            throw DeviceRegistrationError.serverError(httpResponse.statusCode)
            
        default:
            print("DeviceRegistrationService: Unexpected status code \(httpResponse.statusCode)")
            throw DeviceRegistrationError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}

// MARK: - Data Models

private struct RegisterResponse: Codable {
    let deviceToken: String
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
        case .clientError(let code, let message):
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