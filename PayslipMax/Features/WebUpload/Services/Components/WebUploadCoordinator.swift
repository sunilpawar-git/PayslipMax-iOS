import Foundation
import Combine

/// Main coordinator service that orchestrates all web upload operations
class WebUploadCoordinator: WebUploadServiceProtocol {
    
    // MARK: - Injected Services
    private let deviceRegistrationService: DeviceRegistrationServiceProtocol
    private let fileDownloadService: FileDownloadServiceProtocol
    private let pdfProcessingService: WebUploadPDFProcessingServiceProtocol
    private let passwordManagementService: PasswordManagementServiceProtocol
    private let uploadManagementService: UploadManagementServiceProtocol
    
    // MARK: - Configuration
    private let uploadDirectory: URL
    
    // MARK: - Initialization
    init(
        urlSession: URLSession = .shared,
        secureStorage: SecureStorageProtocol,
        fileManager: FileManager = .default,
        pdfService: PDFServiceProtocol,
        baseURL: URL = URL(string: "http://localhost:8000/api")!
    ) {
        // Create upload directory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        
        // Ensure upload directory exists
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
        
        // Initialize device registration service
        self.deviceRegistrationService = DeviceRegistrationService(
            urlSession: urlSession,
            secureStorage: secureStorage,
            baseURL: baseURL
        )
        
        // Initialize file download service
        self.fileDownloadService = FileDownloadService(
            urlSession: urlSession,
            fileManager: fileManager,
            baseURL: baseURL
        )
        
        // Initialize upload management service
        self.uploadManagementService = UploadManagementService(
            deviceRegistrationService: deviceRegistrationService,
            baseURL: baseURL,
            urlSession: urlSession,
            uploadDirectory: uploadDirectory,
            fileManager: fileManager
        )
        
        // Store the upload management service for use in closures
        let uploadManagement = self.uploadManagementService
        
        // Initialize PDF processing service
        self.pdfProcessingService = WebUploadPDFProcessingService(
            pdfService: pdfService,
            uploadUpdateHandler: { upload in
                uploadManagement.updateUpload(upload)
            }
        )
        
        // Initialize password management service
        self.passwordManagementService = PasswordManagementService(
            secureStorage: secureStorage,
            uploadUpdateHandler: { upload in
                uploadManagement.updateUpload(upload)
            },
            uploadProvider: {
                Task {
                    return await uploadManagement.getAllUploads()
                }
                // For now, return empty array since we can't await in sync context
                // The services will handle this properly in their async methods
                return []
            }
        )
        
        // Initialize the coordinator with loading saved uploads
        Task {
            await initializeCoordinator()
        }
    }
    
    // MARK: - WebUploadServiceProtocol Implementation
    
    func registerDevice() async throws -> String {
        print("WebUploadCoordinator: Delegating device registration")
        return try await deviceRegistrationService.registerDevice()
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        print("WebUploadCoordinator: Starting download and processing workflow for upload: \(uploadInfo.id)")
        
        // Update status to downloading
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloading
        uploadManagementService.updateUpload(updatedInfo)
        
        // Download the file
        let localURL = try await fileDownloadService.downloadFile(from: uploadInfo, to: uploadDirectory)
        
        // Update upload info with local URL and new status
        updatedInfo.localURL = localURL
        updatedInfo.status = uploadInfo.isPasswordProtected ? .requiresPassword : .downloaded
        uploadManagementService.updateUpload(updatedInfo)
        
        print("WebUploadCoordinator: Successfully downloaded file to: \(localURL.path)")
        return localURL
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        print("WebUploadCoordinator: Delegating PDF processing for upload: \(uploadInfo.id)")
        try await pdfProcessingService.processDownloadedFile(uploadInfo: uploadInfo, password: password)
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        return await uploadManagementService.getPendingUploads()
    }
    
    func getAllUploads() async -> [WebUploadInfo] {
        return await uploadManagementService.getAllUploads()
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        // Delete any stored password first
        try? passwordManagementService.deletePassword(for: upload.id)
        
        // Delete the upload
        try await uploadManagementService.deleteUpload(upload)
        
        print("WebUploadCoordinator: Successfully deleted upload: \(upload.id)")
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        try passwordManagementService.savePassword(for: uploadId, password: password)
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        try passwordManagementService.savePassword(forStringID: stringId, password: password)
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        return passwordManagementService.getPassword(for: uploadId)
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        return passwordManagementService.getPassword(forStringID: stringId)
    }
    
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        return uploadManagementService.uploadsPublisher
    }
    
    // MARK: - Private Methods
    
    private func initializeCoordinator() async {
        print("WebUploadCoordinator: Initializing coordinator services")
        
        do {
            // Load any existing uploads
            try await uploadManagementService.loadSavedUploads()
            
            // Check for pending uploads from server
            try await uploadManagementService.checkForPendingUploads()
            
            print("WebUploadCoordinator: Successfully initialized")
        } catch {
            print("WebUploadCoordinator: Failed to initialize: \(error)")
        }
    }
}

// MARK: - Factory for Creating Coordinator

extension WebUploadCoordinator {
    /// Factory method to create a properly configured WebUploadCoordinator
    static func create(
        with container: DIContainer
    ) async -> WebUploadCoordinator {
        let secureStorage = await container.makeSecureStorage()
        let pdfService = await container.makePDFService()
        
        return WebUploadCoordinator(
            secureStorage: secureStorage,
            pdfService: pdfService
        )
    }
} 