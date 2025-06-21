import Foundation
import UIKit

/// Protocol defining device registration functionality
protocol DeviceRegistrationServiceProtocol {
    func registerDevice() async throws -> String
    func fetchPendingUploads() async throws -> [WebUploadInfo]
    func getDeviceToken() async throws -> String
}

/// Service responsible for device registration and token management
class DeviceRegistrationService: DeviceRegistrationServiceProtocol {
    // MARK: - Dependencies
    private let urlSession: URLSession
    private let secureStorage: SecureStorageProtocol
    private let baseURL: URL
    
    // MARK: - State
    private var deviceToken: String?
    
    // MARK: - Initialization
    init(
        urlSession: URLSession = .shared,
        secureStorage: SecureStorageProtocol,
        baseURL: URL = URL(string: "http://localhost:8000/api")!
    ) {
        self.urlSession = urlSession
        self.secureStorage = secureStorage
        self.baseURL = baseURL
    }
    
    // MARK: - Public Methods
    
    func registerDevice() async throws -> String {
        print("DeviceRegistrationService: Attempting to register device")
        
        // If we already have a token, return it
        if let token = deviceToken {
            print("DeviceRegistrationService: Using existing device token")
            return token
        }
        
        // Try to get token from secure storage first
        if let storedToken = try? secureStorage.getString(key: "web_upload_device_token") {
            print("DeviceRegistrationService: Retrieved device token from secure storage")
            self.deviceToken = storedToken
            return storedToken
        }
        
        // Register new device
        let token = try await performDeviceRegistration()
        
        // Store the token securely
        try secureStorage.saveString(key: "web_upload_device_token", value: token)
        self.deviceToken = token
        
        print("DeviceRegistrationService: Successfully registered device with token: \(token)")
        return token
    }
    
    func fetchPendingUploads() async throws -> [WebUploadInfo] {
        print("DeviceRegistrationService: Checking for pending uploads")
        
        // Get device token
        let token = try await getDeviceToken()
        
        // Create the request
        let endpoint = baseURL.appendingPathComponent("uploads/pending")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Make request with retry logic
        return try await makeRequestWithRetry(request: request) { data in
            let pendingUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            print("DeviceRegistrationService: Found \(pendingUploads.count) pending uploads")
            return pendingUploads
        }
    }
    
    func getDeviceToken() async throws -> String {
        if let token = deviceToken {
            return token
        }
        
        if let storedToken = try? secureStorage.getString(key: "web_upload_device_token") {
            deviceToken = storedToken
            return storedToken
        }
        
        // Register if we don't have a token
        return try await registerDevice()
    }
    
    // MARK: - Private Methods
    
    private func performDeviceRegistration() async throws -> String {
        let endpoint = baseURL.appendingPathComponent("devices/register")
        print("DeviceRegistrationService: Registering device at endpoint: \(endpoint.absoluteString)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Get device info for registration
        let deviceInfo = await getDeviceInfo()
        request.httpBody = try JSONEncoder().encode(deviceInfo)
        
        // Make the request
        return try await makeRequestWithRetry(request: request) { data in
            struct RegisterResponse: Codable {
                let deviceToken: String
            }
            
            let response = try JSONDecoder().decode(RegisterResponse.self, from: data)
            return response.deviceToken
        }
    }
    
    private func getDeviceInfo() async -> [String: String] {
        return [
            "deviceName": await UIDevice.current.name,
            "deviceType": await UIDevice.current.model,
            "osVersion": await UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
    }
    
    private func makeRequestWithRetry<T>(
        request: URLRequest,
        maxRetries: Int = 2,
        decoder: (Data) throws -> T
    ) async throws -> T {
        var currentRequest = request
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await urlSession.data(for: currentRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return try decoder(data)
                    
                case 401, 403:
                    if attempt == 0 {
                        // Clear token and retry
                        deviceToken = nil
                        try? secureStorage.deleteItem(key: "web_upload_device_token")
                        continue
                    } else {
                        throw NetworkError.authenticationFailed
                    }
                    
                case 400...499:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
                    throw NetworkError.clientError(httpResponse.statusCode, errorMessage)
                    
                case 500...599:
                    throw NetworkError.serverError(httpResponse.statusCode)
                    
                default:
                    throw NetworkError.unexpectedResponse(httpResponse.statusCode)
                }
                
            } catch let urlError as URLError {
                lastError = urlError
                
                // Check if we should retry
                let shouldRetry = shouldRetryForURLError(urlError)
                if attempt >= maxRetries || !shouldRetry {
                    break
                }
                
                // Exponential backoff
                let delaySeconds = Double(1 << attempt)
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                
            } catch {
                lastError = error
                
                // For server errors, retry
                if let networkError = error as? NetworkError,
                   case .serverError = networkError {
                    if attempt < maxRetries {
                        let delaySeconds = Double(1 << attempt)
                        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                        continue
                    }
                }
                
                throw error
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    private func shouldRetryForURLError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}

// MARK: - Network Error Types

enum NetworkError: Error {
    case invalidResponse
    case authenticationFailed
    case clientError(Int, String)
    case serverError(Int)
    case unexpectedResponse(Int)
    case maxRetriesExceeded
} 