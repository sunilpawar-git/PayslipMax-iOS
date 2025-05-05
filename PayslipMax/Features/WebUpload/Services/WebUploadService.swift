import Foundation
import Combine

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
    
    /// Save password for a password-protected PDF
    func savePassword(for uploadId: UUID, password: String) throws
    
    /// Get saved password for a PDF if available
    func getPassword(for uploadId: UUID) -> String?
    
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
        
        // Load any existing uploads
        Task {
            await loadSavedUploads()
            await checkForPendingUploads()
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
            "deviceName": UIDevice.current.name,
            "deviceType": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion,
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
        // Update status to downloading
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloading
        updateUpload(updatedInfo)
        
        // Create the download URL
        let endpoint = baseURL.appendingPathComponent("uploads/\(uploadInfo.id)")
        var request = URLRequest(url: endpoint)
        
        // Add the secure token if we have one
        if let token = uploadInfo.secureToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create a destination for the file
        let destinationURL = uploadDirectory.appendingPathComponent(uploadInfo.filename)
        
        // If the file already exists, remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download the file
        let (downloadURL, response) = try await urlSession.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            // Update status to failed
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw NSError(domain: "WebUploadErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download file"])
        }
        
        // Move the file to our destination
        try fileManager.moveItem(at: downloadURL, to: destinationURL)
        
        // Update the upload info
        updatedInfo.status = .downloaded
        updatedInfo.localURL = destinationURL
        updateUpload(updatedInfo)
        
        return destinationURL
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String? = nil) async throws {
        guard let localURL = uploadInfo.localURL else {
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not downloaded"])
        }
        
        var updatedInfo = uploadInfo
        
        do {
            // Process the PDF using the PDF service
            _ = try await pdfService.processPDF(at: localURL, password: password)
            
            // Update the status to processed
            updatedInfo.status = .processed
            updateUpload(updatedInfo)
        } catch let error as PDFProcessingError where error == .passwordRequired {
            // If password is required, update status
            updatedInfo.status = .requiresPassword
            updatedInfo.isPasswordProtected = true
            updateUpload(updatedInfo)
            throw error
        } catch {
            // If processing failed, update status
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw error
        }
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        // Check for new uploads from the server
        await checkForPendingUploads()
        
        // Return uploads that are not yet processed
        return uploads.filter { $0.status != .processed }
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
    
    // MARK: - Private Methods
    
    private func updateUpload(_ upload: WebUploadInfo) {
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
            uploads[index] = upload
        } else {
            uploads.append(upload)
        }
        
        // Save the updated list
        saveUploads()
    }
    
    private func saveUploads() {
        do {
            let data = try JSONEncoder().encode(uploads)
            try data.write(to: uploadDirectory.appendingPathComponent("uploads.json"))
        } catch {
            print("Failed to save uploads: \(error)")
        }
    }
    
    private func loadSavedUploads() async {
        let uploadsFile = uploadDirectory.appendingPathComponent("uploads.json")
        
        guard fileManager.fileExists(atPath: uploadsFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: uploadsFile)
            let loadedUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            uploads = loadedUploads
        } catch {
            print("Failed to load uploads: \(error)")
        }
    }
    
    private func checkForPendingUploads() async {
        // Skip if we don't have a device token
        guard let token = try? await registerDevice() else { return }
        
        do {
            // Create the request
            let endpoint = baseURL.appendingPathComponent("uploads/pending")
            var request = URLRequest(url: endpoint)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Get pending uploads
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }
            
            // Decode the response
            let pendingUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            
            // Add any new uploads
            for upload in pendingUploads {
                if !uploads.contains(where: { $0.id == upload.id }) {
                    uploads.append(upload)
                }
            }
            
            // Save the updated list
            saveUploads()
        } catch {
            print("Failed to check for pending uploads: \(error)")
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