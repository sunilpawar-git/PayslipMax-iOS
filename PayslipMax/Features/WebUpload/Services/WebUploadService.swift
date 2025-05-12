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
        baseURL: URL = URL(string: "https://api.payslipmax.com")!
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
        // If we already have a token, return it
        if let token = deviceToken {
            return token
        }
        
        // Create a registration request
        let endpoint = baseURL.appendingPathComponent("devices/register")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get device info for registration
        let deviceInfo = [
            "deviceName": await UIDevice.current.name,
            "deviceType": await UIDevice.current.model,
            "osVersion": await UIDevice.current.systemVersion,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        request.httpBody = try JSONEncoder().encode(deviceInfo)
        
        // Make the request
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "WebUploadErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to register device"])
        }
        
        // Parse the response to get the device token
        struct RegisterResponse: Codable {
            let deviceToken: String
        }
        
        let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
        self.deviceToken = registerResponse.deviceToken
        
        // Store the device token securely
        try secureStorage.saveString(key: "web_upload_device_token", value: registerResponse.deviceToken)
        
        return registerResponse.deviceToken
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        print("WebUploadService: Starting download for upload ID: \(uploadInfo.id), StringID: \(uploadInfo.stringID ?? "nil")")
        
        // Update status to downloading
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloading
        updateUpload(updatedInfo)
        
        // Create the download URL using the website's API
        // This should match what the website expects in download.php
        var downloadURLComponents = URLComponents(string: "https://payslipmax.com/api/download.php")!
        
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
            throw NSError(domain: "WebUploadErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }
        
        print("WebUploadService: Downloading from URL: \(downloadEndpoint.absoluteString)")
        
        let request = URLRequest(url: downloadEndpoint)
        
        // Create a destination for the file
        let destinationURL = uploadDirectory.appendingPathComponent(uploadInfo.filename)
        
        // If the file already exists, remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download the file with proper error handling
        print("WebUploadService: Starting download task")
        
        do {
            let (downloadURL, response) = try await urlSession.download(for: request)
            
            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                print("WebUploadService: Received HTTP response code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    // Update status to failed on non-200 response
                    updatedInfo.status = .failed
                    updateUpload(updatedInfo)
                    throw NSError(domain: "WebUploadErrorDomain", code: 2, 
                                 userInfo: [NSLocalizedDescriptionKey: "Failed to download file - server responded with code: \(httpResponse.statusCode)"])
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
                throw NSError(domain: "WebUploadErrorDomain", code: 5, 
                             userInfo: [NSLocalizedDescriptionKey: "Downloaded file is invalid or empty"])
            }
            
            // Update the upload info with the downloaded file url
            updatedInfo.status = .downloaded
            updatedInfo.localURL = destinationURL
            
            // Explicitly save the updatedInfo
            updateUpload(updatedInfo)
            
            // Save the changes to disk
            saveUploads()
            
            // Short delay to ensure files are saved
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            return destinationURL
        } catch {
            print("WebUploadService: File download failed with error: \(error.localizedDescription)")
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw error
        }
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String? = nil) async throws {
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
            
            // First process the PDF data from the URL
            let pdfResult = await pdfProcessingService.processPDF(from: localURL)
            
            // Handle result based on success/failure
            switch pdfResult {
            case .success(let pdfData):
                // Now that we have valid PDF data, we can extract payslip information
                let payslipResult = await pdfProcessingService.processPDFData(pdfData)
                
                switch payslipResult {
                case .success(let payslipItem):
                    print("WebUploadService: Successfully extracted PayslipItem with ID: \(payslipItem.id)")
                    
                    // Ensure the payslip has the PDF data attached
                    if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
                        payslipItem.pdfData = pdfData
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
                        pdfData: pdfData,
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
                
            case .failure(let error):
                print("WebUploadService: Failed to process PDF: \(error)")
                throw error
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
        // Skip if we don't have a device token
        let token: String
        do {
            token = try await registerDevice()
        } catch {
            print("Failed to register device: \(error)")
            throw error
        }
        
        do {
            // Create the request
            let endpoint = baseURL.appendingPathComponent("uploads/pending")
            var request = URLRequest(url: endpoint)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Make the request
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            // Parse the response
            let pendingUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            
            // Merge with existing uploads
            for pendingUpload in pendingUploads {
                if !uploads.contains(where: { $0.id == pendingUpload.id }) {
                    uploads.append(pendingUpload)
                }
            }
            
            // Save the updated list
            saveUploads()
        } catch {
            print("Failed to check for pending uploads: \(error)")
            throw error
        }
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