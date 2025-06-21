import Foundation
import Combine
import UIKit

/// Protocol defining web upload service functionality
protocol WebUploadServiceProtocol {
    /// Register device for receiving web uploads
    func registerDevice() async throws -> String
    
    /// Download file from the web service
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL
    
    /// Process a downloaded file
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws
    
    /// Get list of pending uploads
    func getPendingUploads() async -> [WebUploadInfo]
    
    /// Get all uploads, including processed ones
    func getAllUploads() async -> [WebUploadInfo]
    
    /// Delete a specific upload
    func deleteUpload(_ upload: WebUploadInfo) async throws
    
    /// Save password for a password-protected PDF
    func savePassword(for uploadId: UUID, password: String) throws
    
    /// Save password using string ID
    func savePassword(forStringID stringId: String, password: String) throws
    
    /// Get saved password for a PDF if available
    func getPassword(for uploadId: UUID) -> String?
    
    /// Get password using string ID
    func getPassword(forStringID stringId: String) -> String?
    
    /// Track uploads via publisher
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> { get }
}

/// Implementation of WebUploadService
class DefaultWebUploadService: WebUploadServiceProtocol {
    private let urlSession: URLSession
    private let secureStorage: SecureStorageProtocol
    private let fileManager: FileManager
    private let pdfService: PDFServiceProtocol
    private let baseURL: URL
    
    private var deviceToken: String?
    private var uploadSubject = CurrentValueSubject<[WebUploadInfo], Never>([])
    private var uploads: [WebUploadInfo] = [] {
        didSet {
            uploadSubject.send(uploads)
        }
    }
    
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        uploadSubject.eraseToAnyPublisher()
    }
    
    private let uploadDirectory: URL
    
    init(
        urlSession: URLSession = .shared,
        secureStorage: SecureStorageProtocol,
        fileManager: FileManager = .default,
        pdfService: PDFServiceProtocol,
        baseURL: URL = URL(string: "http://localhost:8000/api")!
    ) {
        self.urlSession = urlSession
        self.secureStorage = secureStorage
        self.fileManager = fileManager
        self.pdfService = pdfService
        self.baseURL = baseURL
        
        // Create a directory for web uploads
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
        
        // Load any existing uploads - Use structured concurrency with MainActor
        Task {
            do {
                try await Task.sleep(nanoseconds: 100_000_000) // Small delay to ensure initialization
                try await self.loadSavedUploads()
                try await self.checkForPendingUploads()
            } catch {
                print("Failed to initialize WebUploadService: \(error)")
            }
        }
    }
    
    private func initialize() async throws {
        do {
            try await loadSavedUploads()
            try await checkForPendingUploads()
        } catch {
            print("Failed to initialize WebUploadService: \(error)")
            throw error
        }
    }
    
    func registerDevice() async throws -> String {
        print("WebUploadService: Attempting to register device")
        
        // If we already have a token, return it
        if let token = deviceToken {
            print("WebUploadService: Using existing device token")
            return token
        }
        
        // Try to get token from secure storage first
        do {
            if let storedToken = try secureStorage.getString(key: "web_upload_device_token") {
                print("WebUploadService: Retrieved device token from secure storage")
                self.deviceToken = storedToken
                return storedToken
            }
        } catch {
            print("WebUploadService: Failed to retrieve device token from secure storage: \(error)")
            // Continue to registration if we couldn't get it from storage
        }
        
        // Create a registration request
        let endpoint = baseURL.appendingPathComponent("devices/register")
        print("WebUploadService: Registering device at endpoint: \(endpoint.absoluteString)")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Increase timeout to 30 seconds
        
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
            print("WebUploadService: Failed to encode device info: \(error)")
            throw NSError(domain: "WebUploadErrorDomain", 
                          code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to prepare registration data: \(error.localizedDescription)"])
        }
        
        // Make the request with better error handling
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // Check for valid response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("WebUploadService: Invalid response type")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: 1002, 
                              userInfo: [NSLocalizedDescriptionKey: "Invalid server response type"])
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - continue processing
                print("WebUploadService: Server returned success status 200")
                break
                
            case 400...499:
                // Client errors
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
                print("WebUploadService: Client error \(httpResponse.statusCode): \(errorMessage)")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "Registration failed: \(errorMessage)"])
                
            case 500...599:
                // Server errors
                print("WebUploadService: Server error \(httpResponse.statusCode)")
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: httpResponse.statusCode, 
                              userInfo: [NSLocalizedDescriptionKey: "Server error occurred. Please try again later."])
                
            default:
                // Unexpected status code
                print("WebUploadService: Unexpected status code \(httpResponse.statusCode)")
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
                
                print("WebUploadService: Successfully registered device with token: \(registerResponse.deviceToken)")
                return registerResponse.deviceToken
            } catch {
                print("WebUploadService: Failed to decode response: \(error)")
                
                // Try to get the error message from response
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "WebUploadErrorDomain", 
                              code: 1003, 
                              userInfo: [NSLocalizedDescriptionKey: "Failed to process server response: \(errorMessage)"])
            }
        } catch let urlError as URLError {
            // Handle specific networking errors
            print("WebUploadService: URLError during registration: \(urlError)")
            
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
            // Re-throw any other errors
            print("WebUploadService: Other error during registration: \(error)")
            throw error
        }
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        print("WebUploadService: Starting download for upload ID: \(uploadInfo.id), StringID: \(uploadInfo.stringID ?? "nil")")
        
        // Update status to downloading
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloading
        updateUpload(updatedInfo)
        
        // Create the download URL using the website's API
        var downloadURLComponents = URLComponents(url: baseURL.appendingPathComponent("download"), resolvingAgainstBaseURL: true)!
        
        // Use the original string ID if available, otherwise use the UUID
        let idParameter = uploadInfo.stringID ?? uploadInfo.id.uuidString
        
        // Add required query parameters
        downloadURLComponents.queryItems = [
            URLQueryItem(name: "id", value: idParameter)
        ]
        
        // Add the secure token if we have one
        if let token = uploadInfo.secureToken {
            downloadURLComponents.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        
        guard let downloadEndpoint = downloadURLComponents.url else {
            print("WebUploadService: Failed to create download URL")
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw NSError(domain: "WebUploadErrorDomain", 
                          code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }
        
        print("WebUploadService: Downloading from URL: \(downloadEndpoint.absoluteString)")
        
        var request = URLRequest(url: downloadEndpoint)
        request.timeoutInterval = 60 // Increase timeout for large files
        
        // Create a destination for the file
        let destinationURL = uploadDirectory.appendingPathComponent(uploadInfo.filename)
        
        // If the file already exists, remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download the file with proper error handling and retry
        print("WebUploadService: Starting download task")
        
        // Maximum number of retries
        let maxRetries = 3
        var retryCount = 0
        var lastError: Error? = nil
        
        // Retry loop
        while retryCount < maxRetries {
            do {
                let (downloadURL, response) = try await urlSession.download(for: request)
                
                // Log response
                if let httpResponse = response as? HTTPURLResponse {
                    print("WebUploadService: Received HTTP response code: \(httpResponse.statusCode)")
                    
                    // Handle different status codes
                    switch httpResponse.statusCode {
                    case 200:
                        // Success - continue with download handling
                        break
                        
                    case 401, 403:
                        // Authentication error
                        updatedInfo.status = .failed
                        updateUpload(updatedInfo)
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Authentication error: Not authorized to download this file"])
                        
                    case 404:
                        // File not found
                        updatedInfo.status = .failed
                        updateUpload(updatedInfo)
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "File not found on server"])
                        
                    case 400...499:
                        // Other client errors
                        updatedInfo.status = .failed
                        updateUpload(updatedInfo)
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Download failed - client error: \(httpResponse.statusCode)"])
                        
                    case 500...599:
                        // Server errors - these might be temporary, so we'll retry
                        print("WebUploadService: Server error \(httpResponse.statusCode) - will retry")
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Server error \(httpResponse.statusCode)"])
                        
                    default:
                        // Unexpected status codes
                        print("WebUploadService: Unexpected status code \(httpResponse.statusCode)")
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(httpResponse.statusCode)"])
                    }
                }
                
                // Move the file to our destination
                try fileManager.moveItem(at: downloadURL, to: destinationURL)
                print("WebUploadService: File downloaded successfully to: \(destinationURL.path)")
                
                // Verify the file exists and has content
                guard fileManager.fileExists(atPath: destinationURL.path),
                      let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
                      let fileSize = attributes[.size] as? Int,
                      fileSize > 0 else {
                    
                    print("WebUploadService: Downloaded file is invalid or empty")
                    updatedInfo.status = .failed
                    updateUpload(updatedInfo)
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: 1006, 
                                 userInfo: [NSLocalizedDescriptionKey: "Downloaded file is invalid or empty"])
                }
                
                // Update upload info with local URL
                updatedInfo.localURL = destinationURL
                updatedInfo.status = uploadInfo.isPasswordProtected ? .requiresPassword : .downloaded
                updateUpload(updatedInfo)
                
                // Return the URL where the file was saved
                return destinationURL
                
            } catch let urlError as URLError {
                // Network-related errors that might be worth retrying
                lastError = urlError
                retryCount += 1
                
                print("WebUploadService: Download attempt \(retryCount) failed with URLError: \(urlError.localizedDescription)")
                
                // Check if we should retry based on the error
                let shouldRetry: Bool
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                    // These are network issues worth retrying
                    shouldRetry = true
                default:
                    // Other URL errors might not be worth retrying
                    shouldRetry = false
                }
                
                if retryCount >= maxRetries || !shouldRetry {
                    print("WebUploadService: Giving up after \(retryCount) attempts")
                    updatedInfo.status = .failed
                    updateUpload(updatedInfo)
                    
                    // Create a more helpful error message
                    let errorMessage: String
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "No internet connection. Please check your network and try again."
                    case .timedOut:
                        errorMessage = "Download timed out. The file may be too large or server is busy."
                    case .cannotFindHost, .cannotConnectToHost:
                        errorMessage = "Cannot connect to server. Please verify the API is available."
                    default:
                        errorMessage = "Network error: \(urlError.localizedDescription)"
                    }
                    
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: urlError.code.rawValue, 
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                
                // Add exponential backoff delay before retrying
                let delaySeconds = Double(1 << retryCount) // 2, 4, 8... seconds
                print("WebUploadService: Retrying in \(delaySeconds) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                
            } catch {
                // Other errors
                print("WebUploadService: Download failed with error: \(error)")
                lastError = error
                retryCount += 1
                
                // For server errors, we might want to retry
                let shouldRetry = (error as NSError).domain == "WebUploadErrorDomain" && 
                                 (error as NSError).code >= 500 && 
                                 (error as NSError).code < 600
                
                if retryCount >= maxRetries || !shouldRetry {
                    print("WebUploadService: Giving up after \(retryCount) attempts")
                    updatedInfo.status = .failed
                    updateUpload(updatedInfo)
                    throw error
                }
                
                // Add exponential backoff delay before retrying
                let delaySeconds = Double(1 << retryCount) // 2, 4, 8... seconds
                print("WebUploadService: Retrying in \(delaySeconds) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        
        // If we got here, we ran out of retries
        print("WebUploadService: Max retries exceeded")
        updatedInfo.status = .failed
        updateUpload(updatedInfo)
        
        throw lastError ?? NSError(domain: "WebUploadErrorDomain", 
                                  code: 1000, 
                                  userInfo: [NSLocalizedDescriptionKey: "Download failed after \(maxRetries) attempts"])
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        print("WebUploadService: Processing downloaded file - ID: \(uploadInfo.id), StringID: \(uploadInfo.stringID ?? "nil"), LocalURL: \(uploadInfo.localURL?.path ?? "nil")")
        
        guard let localURL = uploadInfo.localURL else {
            print("WebUploadService: LocalURL is nil for upload \(uploadInfo.id)")
            
            // Try to find a valid URL by checking other uploads with the same ID
            let matchingUploads = uploads.filter { $0.id == uploadInfo.id || $0.stringID == uploadInfo.stringID }
            for upload in matchingUploads {
                if let url = upload.localURL {
                    print("WebUploadService: Found alternative localURL in matching upload: \(url.path)")
                    var updatedInfo = uploadInfo
                    updatedInfo.localURL = url
                    return try await processDownloadedFile(uploadInfo: updatedInfo, password: password)
                }
            }
            
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not downloaded"])
        }
        
        // Verify the file exists at the localURL
        guard fileManager.fileExists(atPath: localURL.path) else {
            print("WebUploadService: File does not exist at path: \(localURL.path)")
            throw NSError(domain: "WebUploadErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "File not found at expected location"])
        }
        
        var updatedInfo = uploadInfo
        
        do {
            print("WebUploadService: Starting PDF processing for file at \(localURL.path)")
            
            // Get the current date components for setting month and year in case we need them
            let dateComponents = Calendar.current.dateComponents([.month, .year], from: Date())
            let currentMonth = Calendar.current.monthSymbols[dateComponents.month! - 1] // Convert 1-based month to month name
            let currentYear = dateComponents.year!
            
            // Process the PDF using the PDF processing service to extract data
            let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
            
            // First check if the PDF is password protected
            let (data, requiresPassword) = try await checkPasswordProtection(url: localURL, password: password)
            
            if requiresPassword {
                // Mark as requiring password and throw the appropriate error
                print("WebUploadService: PDF is password protected")
                // Create a new instance with updated values rather than modifying the let constant
                let passwordProtectedInfo = WebUploadInfo(
                    id: updatedInfo.id,
                    stringID: updatedInfo.stringID,
                    filename: updatedInfo.filename,
                    uploadedAt: updatedInfo.uploadedAt,
                    fileSize: updatedInfo.fileSize,
                    isPasswordProtected: true,
                    source: updatedInfo.source,
                    status: .requiresPassword,
                    secureToken: updatedInfo.secureToken,
                    localURL: updatedInfo.localURL
                )
                updateUpload(passwordProtectedInfo)
                throw PDFProcessingError.passwordProtected
            }
            
            // If we got here, we have valid PDF data to process
            // Pass the processed data to the payslip processing
            let payslipResult = await pdfProcessingService.processPDFData(data)
            
            switch payslipResult {
            case .success(let payslipItem):
                print("WebUploadService: Successfully extracted PayslipItem with ID: \(payslipItem.id)")
                
                // Ensure the payslip has the PDF data attached
                if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
                    payslipItem.pdfData = data
                }
                
                // Save to data service
                let dataService = await DIContainer.shared.dataService
                try await dataService.save(payslipItem)
                print("WebUploadService: Successfully saved PayslipItem to database")
        
                // Update the status to processed
                updatedInfo.status = .processed
                updateUpload(updatedInfo)
                print("WebUploadService: Successfully processed file")
                
            case .failure(let error):
                print("WebUploadService: Failed to extract payslip data: \(error)")
                // Create a basic PayslipItem with the PDF data
                let payslipItem = PayslipItem(
                    id: UUID(),
                    timestamp: Date(),
                    month: currentMonth,
                    year: currentYear,
                    credits: 0,
                    debits: 0,
                    dsop: 0,
                    tax: 0,
                    name: localURL.lastPathComponent,
                    accountNumber: "",
                    panNumber: "",
                    pdfData: data,
                    source: "Web Upload"
                )
                
                // Save basic PayslipItem to data service
                let dataService = await DIContainer.shared.dataService
                try await dataService.save(payslipItem)
                print("WebUploadService: Saved basic PayslipItem to database with ID: \(payslipItem.id)")
                
                // Mark as processed even though we couldn't extract detailed data
                updatedInfo.status = .processed
                updateUpload(updatedInfo)
                print("WebUploadService: Marked as processed with basic data")
            }
            
        } catch let error as PDFProcessingError where error == .passwordProtected {
            // If password is required, update status
            print("WebUploadService: PDF is password protected")
            updatedInfo.status = .requiresPassword
            // Create a new copy with the password protection flag set to true
            let mutableInfo = WebUploadInfo(
                id: uploadInfo.id,
                stringID: uploadInfo.stringID,
                filename: uploadInfo.filename,
                uploadedAt: uploadInfo.uploadedAt,
                fileSize: uploadInfo.fileSize,
                isPasswordProtected: true,
                source: uploadInfo.source,
                status: .requiresPassword,
                secureToken: uploadInfo.secureToken,
                localURL: uploadInfo.localURL
            )
            updateUpload(mutableInfo)
            throw error
        } catch {
            // If processing failed, update status
            print("WebUploadService: Failed to process PDF: \(error)")
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw error
        }
    }
    
    // Helper method to check if a PDF is password protected and handle unlocking
    private func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool) {
        print("WebUploadService: Checking password protection for file at \(url.path)")
        
        // Get the PDF processing service for password handling
        let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
        
        // First try to load the PDF data - Use a Task to load the data to avoid blocking the main thread
        let pdfData: Data
        do {
            pdfData = try Data(contentsOf: url)
        } catch {
            print("WebUploadService: Failed to load PDF data: \(error)")
            throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF data"])
        }
        
        // Check if it's password protected
        if await pdfProcessingService.isPasswordProtected(pdfData) {
            print("WebUploadService: PDF is password protected")
            
            // If no password provided, indicate it needs a password
            guard let providedPassword = password, !providedPassword.isEmpty else {
                return (Data(), true)
            }
            
            // Try to unlock with the provided password
            print("WebUploadService: Attempting to unlock PDF with provided password")
            let unlockResult = await pdfProcessingService.unlockPDF(pdfData, password: providedPassword)
            
            switch unlockResult {
            case .success(let unlockedData):
                print("WebUploadService: Successfully unlocked PDF")
                return (unlockedData, false)
            case .failure:
                print("WebUploadService: Failed to unlock PDF with provided password")
                return (Data(), true)
            }
        }
        
        // Not password protected
        return (pdfData, false)
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        // Check for new uploads from the server
        do {
            try await checkForPendingUploads()
        } catch {
            print("Error checking for pending uploads: \(error)")
        }
        
        // Return uploads that are not yet processed
        return uploads.filter { $0.status != .processed }
    }
    
    /// Get all uploads, including processed ones
    func getAllUploads() async -> [WebUploadInfo] {
        // Check for new uploads from the server
        do {
            try await checkForPendingUploads()
        } catch {
            print("Error checking for pending uploads: \(error)")
        }
        
        // Return all uploads without filtering
        return uploads
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        // Create credentials object
        let credentials = PDFSecureCredentials(uploadId: uploadId, password: password)
        
        // Convert to data
        let data = try JSONEncoder().encode(credentials)
        
        // Save in secure storage
        try secureStorage.saveData(key: "pdf_password_\(uploadId.uuidString)", data: data)
        
        // Update the upload status if it exists
        if let index = uploads.firstIndex(where: { $0.id == uploadId }) {
            var updatedUpload = uploads[index]
            if updatedUpload.status == .requiresPassword {
                updatedUpload.status = .pending
                uploads[index] = updatedUpload
            }
        }
    }
    
    /// Save password using string ID
    func savePassword(forStringID stringId: String, password: String) throws {
        // Find the upload with this string ID
        guard let upload = uploads.first(where: { $0.stringID == stringId }) else {
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Upload not found"])
        }
        
        // Use the existing method with the UUID
        try savePassword(for: upload.id, password: password)
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        do {
            // Get the credentials data
            guard let data = try secureStorage.getData(key: "pdf_password_\(uploadId.uuidString)") else {
                return nil
            }
            
            // Decode the credentials
            let credentials = try JSONDecoder().decode(PDFSecureCredentials.self, from: data)
            return credentials.password
        } catch {
            return nil
        }
    }
    
    /// Get password using string ID
    func getPassword(forStringID stringId: String) -> String? {
        // Find the upload with this string ID
        guard let upload = uploads.first(where: { $0.stringID == stringId }) else {
            return nil
        }
        
        // Use the existing method with the UUID
        return getPassword(for: upload.id)
    }
    
    // MARK: - Private Methods
    
    /// Get device token, registering if necessary
    private func getDeviceToken() async throws -> String {
        // If we already have a token in memory, use it
        if let token = deviceToken {
            print("WebUploadService: Using cached device token")
            return token
        }
        
        // Try to get token from secure storage
        do {
            if let storedToken = try secureStorage.getString(key: "web_upload_device_token") {
                print("WebUploadService: Retrieved device token from secure storage")
                self.deviceToken = storedToken
                return storedToken
            }
        } catch {
            print("WebUploadService: Failed to retrieve device token from secure storage: \(error)")
            // Continue to registration if we couldn't get it from storage
        }
        
        // Register device to get a new token
        print("WebUploadService: No existing token found, registering device")
        do {
            return try await registerDevice()
        } catch {
            print("WebUploadService: Failed to register device: \(error)")
            throw error
        }
    }
    
    private func updateUpload(_ upload: WebUploadInfo) {
        print("WebUploadService: Updating upload - ID: \(upload.id), StringID: \(upload.stringID ?? "nil"), Status: \(upload.status), LocalURL: \(upload.localURL?.path ?? "nil")")
        
        // Try to find the upload either by UUID or by string ID
        let index = uploads.firstIndex { existingUpload in
            if existingUpload.id == upload.id {
                return true
            }
            if let uploadStringID = upload.stringID,
               let existingStringID = existingUpload.stringID,
               uploadStringID == existingStringID {
                return true
            }
            return false
        }
        
        if let index = index {
            // Update existing
            print("WebUploadService: Updating existing upload at index \(index)")
            uploads[index] = upload
        } else {
            // Add new
            print("WebUploadService: Adding new upload")
            uploads.append(upload)
        }
        
        // Save the updated list
        saveUploads()
    }
    
    private func saveUploads() {
        do {
            let data = try JSONEncoder().encode(uploads)
            let savePath = uploadDirectory.appendingPathComponent("uploads.json")
            print("WebUploadService: Saving uploads to \(savePath.path)")
            try data.write(to: savePath)
            print("WebUploadService: Successfully saved \(uploads.count) uploads")
        } catch {
            print("WebUploadService: Failed to save uploads: \(error)")
        }
    }
    
    private func loadSavedUploads() async throws {
        let uploadsFile = uploadDirectory.appendingPathComponent("uploads.json")
        
        guard fileManager.fileExists(atPath: uploadsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: uploadsFile)
            let loadedUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            uploads = loadedUploads
        } catch {
            print("Failed to load uploads: \(error)")
            throw error
        }
    }
    
    private func checkForPendingUploads() async throws {
        print("WebUploadService: Checking for pending uploads")
        
        // Make sure we have a device token
        let token = try await getDeviceToken()
        
        // Create the request
        let endpoint = baseURL.appendingPathComponent("uploads/pending")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 30 // 30 second timeout
        
        // Add the device token as an authorization header
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Maximum number of retries
        let maxRetries = 2
        var retryCount = 0
        var lastError: Error? = nil
        
        // Retry loop
        while retryCount <= maxRetries {
            do {
                print("WebUploadService: Fetching pending uploads (attempt \(retryCount + 1))")
                
                // Make the request
                let (data, response) = try await urlSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("WebUploadService: Invalid response type")
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: 2001, 
                                 userInfo: [NSLocalizedDescriptionKey: "Invalid server response type"])
                }
                
                // Handle different status codes
                switch httpResponse.statusCode {
                case 200:
                    // Success - continue processing
                    print("WebUploadService: Successfully fetched pending uploads")
                    
                    // Parse the response
                    let pendingUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
                    print("WebUploadService: Found \(pendingUploads.count) pending uploads")
                    
                    // Merge with existing uploads
                    for pendingUpload in pendingUploads {
                        if !uploads.contains(where: { $0.id == pendingUpload.id }) {
                            uploads.append(pendingUpload)
                        }
                    }
                    
                    // Save the updated list
                    saveUploads()
                    return
                    
                case 401, 403:
                    // Authentication error - our token might be invalid
                    print("WebUploadService: Authentication failed (status: \(httpResponse.statusCode))")
                    
                    // Clear the token and try to register again if this is our first retry
                    if retryCount == 0 {
                        print("WebUploadService: Clearing token and re-registering")
                        deviceToken = nil
                        try secureStorage.deleteItem(key: "web_upload_device_token")
                        // Get a new token on next iteration
                        let newToken = try await registerDevice()
                        request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    } else {
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Authentication failed. Please re-register your device."])
                    }
                    
                case 400...499:
                    // Other client errors
                    print("WebUploadService: Client error: \(httpResponse.statusCode)")
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown client error"
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: httpResponse.statusCode, 
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to fetch uploads: \(errorMessage)"])
                    
                case 500...599:
                    // Server errors - these might be temporary, so we'll retry
                    print("WebUploadService: Server error: \(httpResponse.statusCode) - will retry")
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: httpResponse.statusCode, 
                                 userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
                    
                default:
                    // Unexpected status codes
                    print("WebUploadService: Unexpected status code: \(httpResponse.statusCode)")
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: httpResponse.statusCode, 
                                 userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(httpResponse.statusCode)"])
                }
                
            } catch let urlError as URLError {
                // Network-related errors that might be worth retrying
                print("WebUploadService: URLError during pending uploads check: \(urlError)")
                lastError = urlError
                
                // Check if we should retry based on the error
                let shouldRetry: Bool
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                    // These are network issues worth retrying
                    shouldRetry = true
                default:
                    // Other URL errors might not be worth retrying
                    shouldRetry = false
                }
                
                if retryCount >= maxRetries || !shouldRetry {
                    // We've exhausted our retries or this error isn't worth retrying
                    throw urlError
                }
                
            } catch {
                // Other errors
                print("WebUploadService: Other error during pending uploads check: \(error)")
                lastError = error
                
                // For server errors, we might want to retry
                let shouldRetry = (error as NSError).domain == "WebUploadErrorDomain" && 
                                 (error as NSError).code >= 500 && 
                                 (error as NSError).code < 600
                
                if retryCount >= maxRetries || !shouldRetry {
                    throw error
                }
            }
            
            // Increment retry count
            retryCount += 1
            
            // Add exponential backoff delay before retrying
            if retryCount <= maxRetries {
                let delaySeconds = Double(1 << retryCount) // 2, 4, 8... seconds
                print("WebUploadService: Retrying in \(delaySeconds) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        
        // If we got here, we ran out of retries
        throw lastError ?? NSError(domain: "WebUploadErrorDomain", 
                                  code: 2000, 
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to check for pending uploads after multiple attempts"])
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        print("WebUploadService: Deleting upload - ID: \(upload.id), StringID: \(upload.stringID ?? "nil")")
        
        // Find the index of the upload in the array
        guard let index = uploads.firstIndex(where: { $0.id == upload.id || $0.stringID == upload.stringID }) else {
            print("WebUploadService: Upload not found for deletion")
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Upload not found"])
        }
        
        // Delete the PDF file if it exists
        if let localURL = upload.localURL, fileManager.fileExists(atPath: localURL.path) {
            do {
                try fileManager.removeItem(at: localURL)
                print("WebUploadService: Deleted file at \(localURL.path)")
            } catch {
                print("WebUploadService: Failed to delete file: \(error)")
                // Continue with deletion of the record even if file deletion fails
            }
        }
        
        // Remove the entry from the array
        uploads.remove(at: index)
        
        // Delete any saved password
        do {
            if let _ = try? secureStorage.getData(key: "pdf_password_\(upload.id.uuidString)") {
                try secureStorage.deleteItem(key: "pdf_password_\(upload.id.uuidString)")
                print("WebUploadService: Deleted password for upload ID: \(upload.id)")
            }
        } catch {
            print("WebUploadService: Failed to delete password: \(error)")
            // Continue with save even if password deletion fails
        }
        
        // Save the updated uploads list
        saveUploads()
        
        print("WebUploadService: Successfully deleted upload")
    }
}

// MARK: - Secure Storage Protocol

/// Protocol for secure storage operations
protocol SecureStorageProtocol {
    /// Save data securely
    func saveData(key: String, data: Data) throws
    
    /// Retrieve data securely
    func getData(key: String) throws -> Data?
    
    /// Save string securely
    func saveString(key: String, value: String) throws
    
    /// Retrieve string securely
    func getString(key: String) throws -> String?
    
    /// Delete item from secure storage
    func deleteItem(key: String) throws
} 