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
        
        // If we already have a token, return it
        if let token = deviceToken {
            print("DeviceRegistrationService: Using existing device token")
            return token
        }
        
        // Try to get token from secure storage first
        do {
            if let storedToken = try secureStorage.getString(key: "web_upload_device_token") {
                print("DeviceRegistrationService: Retrieved device token from secure storage")
                self.deviceToken = storedToken
                return storedToken
            }
        } catch {
            print("DeviceRegistrationService: Failed to retrieve device token from secure storage: \(error)")
            // Continue to registration if we couldn't get it from storage
        }
        
        // Create a registration request
        let endpoint = baseURL.appendingPathComponent("devices/register")
        print("DeviceRegistrationService: Registering device at endpoint: \(endpoint.absoluteString)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Get device info for registration
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
            throw NSError(domain: "WebUploadErrorDomain", 
                          code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to prepare registration data: \(error.localizedDescription)"])
        }
        
        // Make the request with better error handling
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // Check for valid response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DeviceRegistrationService: Invalid response type")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: 1002, 
                              userInfo: [NSLocalizedDescriptionKey: "Invalid server response type"])
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                print("DeviceRegistrationService: Server returned success status 200")
                break
                
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
                print("DeviceRegistrationService: Client error \(httpResponse.statusCode): \(errorMessage)")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "Registration failed: \(errorMessage)"])
                
            case 500...599:
                print("DeviceRegistrationService: Server error \(httpResponse.statusCode)")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])
                
            default:
                print("DeviceRegistrationService: Unexpected status code \(httpResponse.statusCode)")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "Unexpected response from server: \(httpResponse.statusCode)"])
            }
            
            // Parse the response to get the device token
            do {
                struct RegisterResponse: Codable {
                    let deviceToken: String
                }
                
                let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
                self.deviceToken = registerResponse.deviceToken
                
                // Store the device token securely
                try secureStorage.saveString(key: "web_upload_device_token", value: registerResponse.deviceToken)
                
                print("DeviceRegistrationService: Successfully registered device with token: \(registerResponse.deviceToken)")
                return registerResponse.deviceToken
            } catch {
                print("DeviceRegistrationService: Failed to decode response: \(error)")
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: 1003, 
                              userInfo: [NSLocalizedDescriptionKey: "Failed to process server response: \(errorMessage)"])
            }
        } catch let urlError as URLError {
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
            
            throw NSError(domain: "WebUploadErrorDomain", 
                          code: urlError.code.rawValue, 
                          userInfo: [NSLocalizedDescriptionKey: errorMessage])
        } catch {
            print("DeviceRegistrationService: Other error during registration: \(error)")
            throw error
        }
    }
    
    func getDeviceToken() async throws -> String {
        return try await registerDevice()
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