import Foundation
import Combine

/// Service responsible for managing upload state and CRUD operations
protocol UploadManagementServiceProtocol {
    /// Get list of pending uploads
    func getPendingUploads() async -> [WebUploadInfo]
    
    /// Get all uploads, including processed ones
    func getAllUploads() async -> [WebUploadInfo]
    
    /// Delete a specific upload
    func deleteUpload(_ upload: WebUploadInfo) async throws
    
    /// Update an upload's information
    func updateUpload(_ upload: WebUploadInfo)
    
    /// Load saved uploads from storage
    func loadSavedUploads() async throws
    
    /// Check for pending uploads from server
    func checkForPendingUploads() async throws
    
    /// Track uploads via publisher
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> { get }
}

/// Implementation of upload management service
class UploadManagementService: UploadManagementServiceProtocol {
    private let deviceRegistrationService: DeviceRegistrationServiceProtocol
    private let baseURL: URL
    private let urlSession: URLSession
    private let uploadDirectory: URL
    private let fileManager: FileManager
    
    private var uploadSubject = CurrentValueSubject<[WebUploadInfo], Never>([])
    private var uploads: [WebUploadInfo] = [] {
        didSet {
            uploadSubject.send(uploads)
            saveUploadsToCache()
        }
    }
    
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        uploadSubject.eraseToAnyPublisher()
    }
    
    init(
        deviceRegistrationService: DeviceRegistrationServiceProtocol,
        baseURL: URL,
        urlSession: URLSession = .shared,
        uploadDirectory: URL,
        fileManager: FileManager = .default
    ) {
        self.deviceRegistrationService = deviceRegistrationService
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.uploadDirectory = uploadDirectory
        self.fileManager = fileManager
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        // Check for new uploads from the server
        do {
            try await checkForPendingUploads()
        } catch {
            print("UploadManagementService: Error checking for pending uploads: \(error)")
        }
        
        // Return uploads that are not yet processed
        return uploads.filter { $0.status != .processed }
    }
    
    func getAllUploads() async -> [WebUploadInfo] {
        // Check for new uploads from the server
        do {
            try await checkForPendingUploads()
        } catch {
            print("UploadManagementService: Error checking for pending uploads: \(error)")
        }
        
        // Return all uploads without filtering
        return uploads
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        print("UploadManagementService: Deleting upload: \(upload.id)")
        
        // Remove from local array
        uploads.removeAll { $0.id == upload.id }
        
        // Delete local file if it exists
        if let localURL = upload.localURL,
           fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
            print("UploadManagementService: Deleted local file at: \(localURL.path)")
        }
        
        print("UploadManagementService: Successfully deleted upload: \(upload.id)")
    }
    
    func updateUpload(_ upload: WebUploadInfo) {
        print("UploadManagementService: Updating upload: \(upload.id) with status: \(upload.status)")
        
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
            uploads[index] = upload
        } else {
            uploads.append(upload)
        }
    }
    
    func loadSavedUploads() async throws {
        print("UploadManagementService: Loading saved uploads from cache")
        
        let cacheURL = uploadDirectory.appendingPathComponent("uploads_cache.json")
        
        guard fileManager.fileExists(atPath: cacheURL.path) else {
            print("UploadManagementService: No cache file found, starting with empty uploads")
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let cachedUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            
            // Verify that local files still exist for cached uploads
            let validUploads = cachedUploads.filter { upload in
                guard let localURL = upload.localURL else { return true }
                return fileManager.fileExists(atPath: localURL.path)
            }
            
            self.uploads = validUploads
            print("UploadManagementService: Loaded \(validUploads.count) uploads from cache")
            
        } catch {
            print("UploadManagementService: Failed to load uploads from cache: \(error)")
            // Don't throw, just start with empty uploads
        }
    }
    
    func checkForPendingUploads() async throws {
        print("UploadManagementService: Checking for pending uploads from server")
        
        // Get device token
        do {
            let deviceToken = try await deviceRegistrationService.getDeviceToken()
            
            // Create request to check for pending uploads
            let endpoint = baseURL.appendingPathComponent("uploads/pending")
            var request = URLRequest(url: endpoint)
            request.addValue("Bearer \(deviceToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 15
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("UploadManagementService: Invalid response type from server")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("UploadManagementService: Server returned status code: \(httpResponse.statusCode)")
                return
            }
            
            // Parse the response
            let pendingUploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            
            // Merge with existing uploads (avoid duplicates)
            for pendingUpload in pendingUploads {
                if !uploads.contains(where: { $0.id == pendingUpload.id }) {
                    uploads.append(pendingUpload)
                    print("UploadManagementService: Added new pending upload: \(pendingUpload.id)")
                }
            }
            
            print("UploadManagementService: Processed \(pendingUploads.count) pending uploads from server")
            
        } catch {
            print("UploadManagementService: Failed to get device token or check for pending uploads: \(error)")
            // Don't throw, this is a background operation
        }
    }
    
    // MARK: - Private Methods
    
    private func saveUploadsToCache() {
        print("UploadManagementService: Saving uploads to cache")
        
        let cacheURL = uploadDirectory.appendingPathComponent("uploads_cache.json")
        
        do {
            let data = try JSONEncoder().encode(uploads)
            try data.write(to: cacheURL)
            print("UploadManagementService: Successfully saved \(uploads.count) uploads to cache")
        } catch {
            print("UploadManagementService: Failed to save uploads to cache: \(error)")
        }
    }
}

// MARK: - Error Types

enum UploadManagementError: Error, LocalizedError {
    case fileNotFound(String)
    case cachingError(Error)
    case serverError(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .cachingError(let error):
            return "Failed to access upload cache: \(error.localizedDescription)"
        case .serverError(let error):
            return "Server error while managing uploads: \(error.localizedDescription)"
        }
    }
} 