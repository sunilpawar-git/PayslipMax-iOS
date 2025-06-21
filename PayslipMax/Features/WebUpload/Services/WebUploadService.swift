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

/// Legacy facade for WebUploadService - now uses the refactored coordinator pattern
typealias DefaultWebUploadService = WebUploadServiceFacade

/// Facade that provides the original WebUploadService interface using the new coordinator
class WebUploadServiceFacade: WebUploadServiceProtocol {
    // MARK: - Dependencies
    private let coordinator: WebUploadCoordinator
    
    // MARK: - Publishers
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        coordinator.uploadsPublisher
    }
    
    // MARK: - Initialization
    init(
        secureStorage: SecureStorageProtocol,
        pdfService: PDFServiceProtocol? = nil
    ) {
        // Create the service dependencies
        let deviceRegistrationService = DeviceRegistrationService(
            secureStorage: secureStorage
        )
        
        let fileDownloadService = FileDownloadService()
        
        let validationService = WebUploadValidationService()
        
        let qrCodeService = QRCodeGenerationService(
            validationService: validationService
        )
        
        let securityService = WebUploadSecurityService(
            secureStorage: secureStorage
        )
        
        // Create the coordinator with all dependencies
        self.coordinator = WebUploadCoordinator(
            deviceRegistrationService: deviceRegistrationService,
            fileDownloadService: fileDownloadService,
            qrCodeService: qrCodeService,
            validationService: validationService,
            securityService: securityService
        )
    }
    
    // MARK: - WebUploadServiceProtocol Implementation
    
    func registerDevice() async throws -> String {
        return try await coordinator.registerDevice()
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        return try await coordinator.downloadFile(from: uploadInfo)
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        try await coordinator.processDownloadedFile(uploadInfo: uploadInfo, password: password)
    }
    
    func getPendingUploads() async -> [WebUploadInfo] {
        return await coordinator.getPendingUploads()
    }
    
    func getAllUploads() async -> [WebUploadInfo] {
        return await coordinator.getAllUploads()
    }
    
    func deleteUpload(_ upload: WebUploadInfo) async throws {
        try await coordinator.deleteUpload(upload)
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        try coordinator.savePassword(for: uploadId, password: password)
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        try coordinator.savePassword(forStringID: stringId, password: password)
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        return coordinator.getPassword(for: uploadId)
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        return coordinator.getPassword(forStringID: stringId)
    }
}

// MARK: - Factory for WebUploadService Creation

/// Factory for creating WebUploadService instances with proper dependency injection
class WebUploadServiceFactory {
    static func createWebUploadService(
        secureStorage: SecureStorageProtocol,
        pdfService: PDFServiceProtocol? = nil
    ) -> WebUploadServiceProtocol {
        return WebUploadServiceFacade(
            secureStorage: secureStorage,
            pdfService: pdfService
        )
    }
    
    static func createMockWebUploadService() -> WebUploadServiceProtocol {
        // This could return a mock implementation for testing
        let mockSecureStorage = MockSecureStorage()
        return createWebUploadService(secureStorage: mockSecureStorage)
    }
}

// MARK: - Compatibility Extensions

extension WebUploadServiceFacade {
    /// Convenience method for backward compatibility
    func getDeviceToken() async throws -> String {
        return try await coordinator.registerDevice()
    }
    
    /// Get upload statistics for monitoring
    func getUploadStatistics() async -> UploadStatistics {
        let allUploads = await getAllUploads()
        let pendingCount = allUploads.filter { $0.status == .pending }.count
        let downloadedCount = allUploads.filter { $0.status == .downloaded }.count
        let failedCount = allUploads.filter { $0.status == .failed }.count
        
        return UploadStatistics(
            totalUploads: allUploads.count,
            pendingUploads: pendingCount,
            downloadedUploads: downloadedCount,
            failedUploads: failedCount,
            averageFileSize: calculateAverageFileSize(allUploads)
        )
    }
    
    private func calculateAverageFileSize(_ uploads: [WebUploadInfo]) -> Int64 {
        let uploadsWithSize = uploads.compactMap { Int64($0.fileSize) }
        guard !uploadsWithSize.isEmpty else { return 0 }
        
        let totalSize = uploadsWithSize.reduce(0, +)
        return totalSize / Int64(uploadsWithSize.count)
    }
}

// MARK: - Supporting Types

struct UploadStatistics {
    let totalUploads: Int
    let pendingUploads: Int
    let downloadedUploads: Int
    let failedUploads: Int
    let averageFileSize: Int64
    
    var successRate: Double {
        guard totalUploads > 0 else { return 0.0 }
        return Double(downloadedUploads) / Double(totalUploads)
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