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