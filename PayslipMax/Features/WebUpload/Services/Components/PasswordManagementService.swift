import Foundation

/// Protocol for password management functionality
protocol PasswordManagementServiceProtocol {
    func savePassword(for uploadId: UUID, password: String) throws
    func savePassword(forStringID stringId: String, password: String) throws
    func getPassword(for uploadId: UUID) -> String?
    func getPassword(forStringID stringId: String) -> String?
}

/// Service responsible for managing passwords for PDF files
class PasswordManagementService: PasswordManagementServiceProtocol {
    private let secureStorage: SecureStorageProtocol
    
    init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
    }
    
    func savePassword(for uploadId: UUID, password: String) throws {
        let key = "pdf_password_\(uploadId.uuidString)"
        try secureStorage.saveString(key: key, value: password)
        print("PasswordManagementService: Password saved for upload ID: \(uploadId)")
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        let key = "pdf_password_string_\(stringId)"
        try secureStorage.saveString(key: key, value: password)
        print("PasswordManagementService: Password saved for string ID: \(stringId)")
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        do {
            let key = "pdf_password_\(uploadId.uuidString)"
            let password = try secureStorage.getString(key: key)
            print("PasswordManagementService: Retrieved password for upload ID: \(uploadId)")
            return password
        } catch {
            print("PasswordManagementService: Failed to retrieve password for upload ID \(uploadId): \(error)")
            return nil
        }
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        do {
            let key = "pdf_password_string_\(stringId)"
            let password = try secureStorage.getString(key: key)
            print("PasswordManagementService: Retrieved password for string ID: \(stringId)")
            return password
        } catch {
            print("PasswordManagementService: Failed to retrieve password for string ID \(stringId): \(error)")
            return nil
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