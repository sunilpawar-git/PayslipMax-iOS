import Foundation
import Combine
import UIKit

// MARK: - Web Upload Coordinator Protocol

// Note: We're using the WebUploadServiceProtocol defined in WebUploadServiceProtocol.swift

// MARK: - Web Upload Coordinator Implementation

/// Coordinator that manages all web upload functionality using composed services
final class WebUploadCoordinator: WebUploadServiceProtocol {
    
    // MARK: - Service Dependencies
    
    private let deviceRegistrationService: DeviceRegistrationServiceProtocol
    private let fileDownloadService: FileDownloadServiceProtocol
    private let passwordManagementService: PasswordManagementServiceProtocol
    private let fileProcessingService: FileProcessingServiceProtocol
    private let uploadManagementService: UploadManagementServiceProtocol
    private let dataPersistenceService: DataPersistenceServiceProtocol
    
    // MARK: - State Management
    
    private let uploadSubject = CurrentValueSubject<[WebUploadInfo], Never>([])
    private let uploadsLock = NSLock()
    private var _uploads: [WebUploadInfo] = []
    
    private var uploads: [WebUploadInfo] {
        get {
            uploadsLock.lock()
            defer { uploadsLock.unlock() }
            return _uploads
        }
        set {
            uploadsLock.lock()
            _uploads = newValue
            uploadsLock.unlock()
            uploadSubject.send(newValue)
            dataPersistenceService.saveUploads(newValue)
        }
    }
    
    nonisolated var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        uploadSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(
        deviceRegistrationService: DeviceRegistrationServiceProtocol,
        fileDownloadService: FileDownloadServiceProtocol,
        passwordManagementService: PasswordManagementServiceProtocol,
        fileProcessingService: FileProcessingServiceProtocol,
        uploadManagementService: UploadManagementServiceProtocol,
        dataPersistenceService: DataPersistenceServiceProtocol
    ) {
        self.deviceRegistrationService = deviceRegistrationService
        self.fileDownloadService = fileDownloadService
        self.passwordManagementService = passwordManagementService
        self.fileProcessingService = fileProcessingService
        self.uploadManagementService = uploadManagementService
        self.dataPersistenceService = dataPersistenceService
        
        // Initialize with saved uploads
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public API Implementation
    
    func registerDevice() async throws -> String {
        return try await deviceRegistrationService.registerDevice()
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        // Create upload directory if needed
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
        
        // Download the file
        let downloadedURL = try await fileDownloadService.downloadFile(from: uploadInfo, to: uploadDirectory)
        
        // Create updated upload info with the local URL and downloaded status
        var updatedUploadInfo = uploadInfo
        updatedUploadInfo.localURL = downloadedURL
        updatedUploadInfo.status = .downloaded
        
        // Add/update the upload in our list
        updateUpload(updatedUploadInfo)
        
        print("WebUploadCoordinator: Successfully downloaded and stored upload: \(uploadInfo.id), Local URL: \(downloadedURL.path)")
        
        return downloadedURL
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        let updatedInfo = try await fileProcessingService.processDownloadedFile(
            uploadInfo: uploadInfo,
            password: password
        )
        updateUpload(updatedInfo)
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        // Check for new uploads from server first
        await checkForPendingUploads()
        
        return dataPersistenceService.getPendingUploads(from: uploads)
    }
    
    func getAllUploads() async -> [WebUploadInfo] {
        // Check for new uploads from server first
        await checkForPendingUploads()
        
        return dataPersistenceService.getAllUploads(from: uploads)
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        try await uploadManagementService.deleteUpload(upload)
        
        // Remove from local list
        uploads.removeAll { $0.id == upload.id }
    }
    
    nonisolated func savePassword(for uploadId: UUID, password: String) throws {
        try passwordManagementService.savePassword(for: uploadId, password: password)
        
        // Update upload status if it exists
        if let index = uploads.firstIndex(where: { $0.id == uploadId }) {
            var updatedUpload = uploads[index]
            if updatedUpload.status == .requiresPassword {
                updatedUpload.status = .pending
                uploads[index] = updatedUpload
            }
        }
    }
    
    nonisolated func savePassword(forStringID stringId: String, password: String) throws {
        // Find the upload with this string ID
        guard let upload = uploads.first(where: { $0.stringID == stringId }) else {
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Upload not found"])
        }
        
        // Use the existing method with the UUID
        try savePassword(for: upload.id, password: password)
    }
    
    nonisolated func getPassword(for uploadId: UUID) -> String? {
        return passwordManagementService.getPassword(for: uploadId)
    }
    
    nonisolated func getPassword(forStringID stringId: String) -> String? {
        // Find the upload with this string ID
        guard let upload = uploads.first(where: { $0.stringID == stringId }) else {
            return nil
        }
        
        // Use the existing method with the UUID
        return getPassword(for: upload.id)
    }
    
    // MARK: - Private Helper Methods
    
    private func loadInitialData() async {
        do {
            uploads = try await dataPersistenceService.loadSavedUploads()
            await checkForPendingUploads()
        } catch {
            print("WebUploadCoordinator: Failed to load initial data: \(error)")
        }
    }
    
    private func updateUpload(_ upload: WebUploadInfo) {
        dataPersistenceService.updateUpload(upload, in: &uploads)
    }
    
    private func checkForPendingUploads() async {
        do {
            try await uploadManagementService.checkForPendingUploads()
            // The uploadManagementService handles updating its own uploads list
        } catch {
            print("WebUploadCoordinator: Failed to check for pending uploads: \(error)")
        }
    }
}

// MARK: - Factory for Creating WebUploadCoordinator

extension WebUploadCoordinator {
    
    /// Factory method to create a fully configured WebUploadCoordinator
    static func create(
        secureStorage: SecureStorageProtocol,
        baseURL: URL = URL(string: "https://payslipmax.com/api")!
    ) -> WebUploadCoordinator {
        
        // Create all the service dependencies
        let deviceRegistrationService = DeviceRegistrationService(
            secureStorage: secureStorage,
            baseURL: baseURL
        )
        
        let fileDownloadService = FileDownloadService(baseURL: baseURL)
        
        let passwordManagementService = PasswordManagementService(secureStorage: secureStorage)
        
        let dataPersistenceService = DataPersistenceService()
        
        // Create upload directory for UploadManagementService
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
        
        // Create upload management service
        let uploadManagementService = UploadManagementService(
            deviceRegistrationService: deviceRegistrationService,
            baseURL: baseURL,
            uploadDirectory: uploadDirectory
        )
        
        // Create file processing service with upload update handler
        let fileProcessingService = FileProcessingService { uploadInfo in
            // This closure will be called when uploads need to be updated
            // The coordinator will handle this through its updateUpload method
        }
        
        // Create and return the coordinator
        return WebUploadCoordinator(
            deviceRegistrationService: deviceRegistrationService,
            fileDownloadService: fileDownloadService,
            passwordManagementService: passwordManagementService,
            fileProcessingService: fileProcessingService,
            uploadManagementService: uploadManagementService,
            dataPersistenceService: dataPersistenceService
        )
    }
} 