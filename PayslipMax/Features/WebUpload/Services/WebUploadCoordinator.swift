import Foundation
import Combine

/// Coordinator for managing all web upload services and their interactions
class WebUploadCoordinator: WebUploadServiceProtocol {
    // MARK: - Service Dependencies
    private let deviceRegistrationService: DeviceRegistrationServiceProtocol
    private let fileDownloadService: FileDownloadServiceProtocol
    private let qrCodeService: QRCodeGenerationServiceProtocol
    private let validationService: WebUploadValidationServiceProtocol
    private let securityService: WebUploadSecurityServiceProtocol
    
    // MARK: - State Management
    private var uploads: [WebUploadInfo] = [] {
        didSet {
            uploadSubject.send(uploads)
        }
    }
    
    private var uploadSubject = CurrentValueSubject<[WebUploadInfo], Never>([])
    
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        uploadSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        deviceRegistrationService: DeviceRegistrationServiceProtocol,
        fileDownloadService: FileDownloadServiceProtocol,
        qrCodeService: QRCodeGenerationServiceProtocol,
        validationService: WebUploadValidationServiceProtocol,
        securityService: WebUploadSecurityServiceProtocol
    ) {
        self.deviceRegistrationService = deviceRegistrationService
        self.fileDownloadService = fileDownloadService
        self.qrCodeService = qrCodeService
        self.validationService = validationService
        self.securityService = securityService
        
        Task {
            await initializeServices()
        }
    }
    
    // MARK: - WebUploadServiceProtocol Implementation
    
    func registerDevice() async throws -> String {
        return try await deviceRegistrationService.registerDevice()
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        // Validate upload info first
        try validationService.validateUploadInfo(uploadInfo)
        
        // Update status to downloading
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloading
        updateUpload(updatedInfo)
        
        do {
            // Download the file
            let fileURL = try await fileDownloadService.downloadFile(from: uploadInfo)
            
            // Update status based on password protection
            updatedInfo.localURL = fileURL
            updatedInfo.status = uploadInfo.isPasswordProtected ? .requiresPassword : .downloaded
            updateUpload(updatedInfo)
            
            return fileURL
        } catch {
            // Update status to failed
            updatedInfo.status = .failed
            updateUpload(updatedInfo)
            throw error
        }
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        // This will be handled by the PDFProcessingService in coordination
        // For now, just update the status
        var updatedInfo = uploadInfo
        updatedInfo.status = .processed
        updateUpload(updatedInfo)
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        return uploads.filter { $0.status == .pending }
    }
    
    func getAllUploads() async -> [WebUploadInfo] {
        return uploads
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        try await fileDownloadService.deleteUploadedFile(upload)
        try securityService.deletePassword(for: upload.id)
        
        uploads.removeAll { $0.id == upload.id }
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        try securityService.savePassword(for: uploadId, password: password)
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        try securityService.savePassword(forStringID: stringId, password: password)
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        return securityService.getPassword(for: uploadId)
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        return securityService.getPassword(forStringID: stringId)
    }
    
    // MARK: - Private Methods
    
    private func initializeServices() async {
        do {
            // Load any existing uploads
            try await loadSavedUploads()
            
            // Check for pending uploads from server
            try await checkForPendingUploads()
        } catch {
            print("WebUploadCoordinator: Failed to initialize services: \(error)")
        }
    }
    
    private func loadSavedUploads() async throws {
        // This will be implemented by the FileDownloadService
        uploads = try await fileDownloadService.loadSavedUploads()
    }
    
    private func checkForPendingUploads() async throws {
        let pendingUploads = try await deviceRegistrationService.fetchPendingUploads()
        
        // Merge with existing uploads
        for pendingUpload in pendingUploads {
            if !uploads.contains(where: { $0.id == pendingUpload.id }) {
                uploads.append(pendingUpload)
            }
        }
        
        // Save the updated list
        try await fileDownloadService.saveUploads(uploads)
    }
    
    private func updateUpload(_ updatedInfo: WebUploadInfo) {
        if let index = uploads.firstIndex(where: { $0.id == updatedInfo.id }) {
            uploads[index] = updatedInfo
        } else {
            uploads.append(updatedInfo)
        }
        
        // Save updates
        Task {
            try? await fileDownloadService.saveUploads(uploads)
        }
    }
} 