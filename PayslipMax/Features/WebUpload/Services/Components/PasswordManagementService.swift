import Foundation

/// Service responsible for secure password management for password-protected PDFs
protocol PasswordManagementServiceProtocol {
    /// Save password for a password-protected PDF using UUID
    func savePassword(for uploadId: UUID, password: String) throws
    
    /// Save password using string ID
    func savePassword(forStringID stringId: String, password: String) throws
    
    /// Get saved password for a PDF if available using UUID
    func getPassword(for uploadId: UUID) -> String?
    
    /// Get password using string ID
    func getPassword(forStringID stringId: String) -> String?
    
    /// Delete stored password for a PDF
    func deletePassword(for uploadId: UUID) throws
    
    /// Clear all stored passwords
    func clearAllPasswords() throws
}

/// Implementation of password management service for web uploads
class PasswordManagementService: PasswordManagementServiceProtocol {
    private let secureStorage: SecureStorageProtocol
    private let uploadUpdateHandler: (WebUploadInfo) -> Void
    private let uploadProvider: () -> [WebUploadInfo]
    
    private let passwordKeyPrefix = "pdf_password_"
    
    init(
        secureStorage: SecureStorageProtocol,
        uploadUpdateHandler: @escaping (WebUploadInfo) -> Void,
        uploadProvider: @escaping () -> [WebUploadInfo]
    ) {
        self.secureStorage = secureStorage
        self.uploadUpdateHandler = uploadUpdateHandler
        self.uploadProvider = uploadProvider
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        print("PasswordManagementService: Saving password for upload ID: \(uploadId)")
        
        // Create credentials object
        let credentials = WebUploadPDFCredentials(uploadId: uploadId, password: password)
        
        // Convert to data
        let data = try JSONEncoder().encode(credentials)
        
        // Save in secure storage
        let key = passwordKeyPrefix + uploadId.uuidString
        try secureStorage.saveData(key: key, data: data)
        
        // Update the upload status if it exists
        updateUploadStatusAfterPasswordSave(uploadId: uploadId)
        
        print("PasswordManagementService: Successfully saved password for upload ID: \(uploadId)")
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        print("PasswordManagementService: Saving password for string ID: \(stringId)")
        
        // Find the upload with this string ID
        guard let upload = findUploadByStringID(stringId) else {
            print("PasswordManagementService: Upload not found for string ID: \(stringId)")
            throw PasswordManagementError.uploadNotFound(stringId)
        }
        
        // Use the existing method with the UUID
        try savePassword(for: upload.id, password: password)
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        print("PasswordManagementService: Retrieving password for upload ID: \(uploadId)")
        
        do {
            // Get the credentials data
            let key = passwordKeyPrefix + uploadId.uuidString
            guard let data = try secureStorage.getData(key: key) else {
                print("PasswordManagementService: No password found for upload ID: \(uploadId)")
                return nil
            }
            
            // Decode the credentials
            let credentials = try JSONDecoder().decode(WebUploadPDFCredentials.self, from: data)
            print("PasswordManagementService: Successfully retrieved password for upload ID: \(uploadId)")
            return credentials.password
        } catch {
            print("PasswordManagementService: Failed to retrieve password for upload ID \(uploadId): \(error)")
            return nil
        }
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        print("PasswordManagementService: Retrieving password for string ID: \(stringId)")
        
        // Find the upload with this string ID
        guard let upload = findUploadByStringID(stringId) else {
            print("PasswordManagementService: Upload not found for string ID: \(stringId)")
            return nil
        }
        
        // Use the existing method with the UUID
        return getPassword(for: upload.id)
    }
    
    func deletePassword(for uploadId: UUID) throws {
        print("PasswordManagementService: Deleting password for upload ID: \(uploadId)")
        
        let key = passwordKeyPrefix + uploadId.uuidString
        try secureStorage.deleteItem(key: key)
        
        print("PasswordManagementService: Successfully deleted password for upload ID: \(uploadId)")
    }
    
    func clearAllPasswords() throws {
        print("PasswordManagementService: Clearing all stored passwords")
        
        // Get all uploads to find their password keys
        let uploads = uploadProvider()
        
        for upload in uploads {
            do {
                try deletePassword(for: upload.id)
            } catch {
                print("PasswordManagementService: Failed to delete password for upload \(upload.id): \(error)")
                // Continue with other passwords even if one fails
            }
        }
        
        print("PasswordManagementService: Finished clearing all passwords")
    }
    
    // MARK: - Private Methods
    
    private func findUploadByStringID(_ stringId: String) -> WebUploadInfo? {
        return uploadProvider().first { $0.stringID == stringId }
    }
    
    private func updateUploadStatusAfterPasswordSave(uploadId: UUID) {
        let uploads = uploadProvider()
        
        if let upload = uploads.first(where: { $0.id == uploadId }) {
            var updatedUpload = upload
            if updatedUpload.status == .requiresPassword {
                updatedUpload.status = .pending
                uploadUpdateHandler(updatedUpload)
                print("PasswordManagementService: Updated upload status from requiresPassword to pending")
            }
        }
    }
}

// MARK: - Data Models

struct WebUploadPDFCredentials: Codable {
    let uploadId: UUID
    let password: String
    let createdAt: Date
    
    init(uploadId: UUID, password: String) {
        self.uploadId = uploadId
        self.password = password
        self.createdAt = Date()
    }
}

// MARK: - Error Types

enum PasswordManagementError: Error, LocalizedError {
    case uploadNotFound(String)
    case storageError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .uploadNotFound(let stringId):
            return "Upload not found for ID: \(stringId)"
        case .storageError(let error):
            return "Failed to access secure storage: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode password data: \(error.localizedDescription)"
        }
    }
} 