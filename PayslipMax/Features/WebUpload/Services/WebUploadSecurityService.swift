import Foundation

/// Protocol defining security operations for web uploads
protocol WebUploadSecurityServiceProtocol {
    func savePassword(for uploadId: UUID, password: String) throws
    func savePassword(forStringID stringId: String, password: String) throws
    func getPassword(for uploadId: UUID) -> String?
    func getPassword(forStringID stringId: String) -> String?
    func deletePassword(for uploadId: UUID) throws
    func deletePassword(forStringID stringId: String) throws
}

/// Service responsible for secure password storage for web uploads
class WebUploadSecurityService: WebUploadSecurityServiceProtocol {
    // MARK: - Dependencies
    private let secureStorage: SecureStorageProtocol
    
    // MARK: - Constants
    private static let passwordKeyPrefix = "pdf_password_"
    private static let stringIdPasswordKeyPrefix = "pdf_password_string_"
    
    // MARK: - Initialization
    init(secureStorage: SecureStorageProtocol) {
        self.secureStorage = secureStorage
    }
    
    // MARK: - Public Methods
    
    func savePassword(for uploadId: UUID, password: String) throws {
        let key = Self.passwordKeyPrefix + uploadId.uuidString
        
        guard !password.isEmpty else {
            throw WebUploadSecurityError.emptyPassword
        }
        
        do {
            try secureStorage.saveString(key: key, value: password)
            print("WebUploadSecurityService: Saved password for upload ID: \(uploadId)")
        } catch {
            print("WebUploadSecurityService: Failed to save password for upload ID \(uploadId): \(error)")
            throw WebUploadSecurityError.savePasswordFailed(error)
        }
    }
    
    func savePassword(forStringID stringId: String, password: String) throws {
        let key = Self.stringIdPasswordKeyPrefix + stringId
        
        guard !password.isEmpty else {
            throw WebUploadSecurityError.emptyPassword
        }
        
        guard !stringId.isEmpty else {
            throw WebUploadSecurityError.invalidStringID
        }
        
        do {
            try secureStorage.saveString(key: key, value: password)
            print("WebUploadSecurityService: Saved password for string ID: \(stringId)")
        } catch {
            print("WebUploadSecurityService: Failed to save password for string ID \(stringId): \(error)")
            throw WebUploadSecurityError.savePasswordFailed(error)
        }
    }
    
    func getPassword(for uploadId: UUID) -> String? {
        let key = Self.passwordKeyPrefix + uploadId.uuidString
        
        do {
            let password = try secureStorage.getString(key: key)
            if password != nil {
                print("WebUploadSecurityService: Retrieved password for upload ID: \(uploadId)")
            }
            return password
        } catch {
            print("WebUploadSecurityService: Failed to retrieve password for upload ID \(uploadId): \(error)")
            return nil
        }
    }
    
    func getPassword(forStringID stringId: String) -> String? {
        let key = Self.stringIdPasswordKeyPrefix + stringId
        
        guard !stringId.isEmpty else {
            print("WebUploadSecurityService: Cannot retrieve password for empty string ID")
            return nil
        }
        
        do {
            let password = try secureStorage.getString(key: key)
            if password != nil {
                print("WebUploadSecurityService: Retrieved password for string ID: \(stringId)")
            }
            return password
        } catch {
            print("WebUploadSecurityService: Failed to retrieve password for string ID \(stringId): \(error)")
            return nil
        }
    }
    
    func deletePassword(for uploadId: UUID) throws {
        let key = Self.passwordKeyPrefix + uploadId.uuidString
        
        do {
            // Check if password exists before attempting deletion
            if try secureStorage.getString(key: key) != nil {
                try secureStorage.deleteItem(key: key)
                print("WebUploadSecurityService: Deleted password for upload ID: \(uploadId)")
            } else {
                print("WebUploadSecurityService: No password found to delete for upload ID: \(uploadId)")
            }
        } catch {
            print("WebUploadSecurityService: Failed to delete password for upload ID \(uploadId): \(error)")
            throw WebUploadSecurityError.deletePasswordFailed(error)
        }
    }
    
    func deletePassword(forStringID stringId: String) throws {
        let key = Self.stringIdPasswordKeyPrefix + stringId
        
        guard !stringId.isEmpty else {
            throw WebUploadSecurityError.invalidStringID
        }
        
        do {
            // Check if password exists before attempting deletion
            if try secureStorage.getString(key: key) != nil {
                try secureStorage.deleteItem(key: key)
                print("WebUploadSecurityService: Deleted password for string ID: \(stringId)")
            } else {
                print("WebUploadSecurityService: No password found to delete for string ID: \(stringId)")
            }
        } catch {
            print("WebUploadSecurityService: Failed to delete password for string ID \(stringId): \(error)")
            throw WebUploadSecurityError.deletePasswordFailed(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Delete all stored passwords (for cleanup purposes)
    func deleteAllPasswords() throws {
        // This would require enumerating all keychain items with our prefix
        // For now, we'll implement a basic cleanup approach
        print("WebUploadSecurityService: Mass password deletion not implemented yet")
        throw WebUploadSecurityError.operationNotSupported
    }
    
    /// Check if a password exists for the given upload ID
    func hasPassword(for uploadId: UUID) -> Bool {
        return getPassword(for: uploadId) != nil
    }
    
    /// Check if a password exists for the given string ID
    func hasPassword(forStringID stringId: String) -> Bool {
        return getPassword(forStringID: stringId) != nil
    }
    
    /// Validate password strength (optional enhancement)
    private func validatePasswordStrength(_ password: String) -> Bool {
        // Basic validation - can be enhanced based on requirements
        return password.count >= 6 && password.count <= 50
    }
    
    /// Get password statistics (for debugging/monitoring)
    func getPasswordStatistics() -> PasswordStatistics {
        // This would require keychain enumeration
        // For now, return basic stats
        return PasswordStatistics(
            totalStoredPasswords: 0, // Would need to count actual stored passwords
            averagePasswordLength: 0,
            oldestPasswordDate: nil,
            newestPasswordDate: nil
        )
    }
}

// MARK: - Security Error Types

enum WebUploadSecurityError: Error {
    case emptyPassword
    case invalidStringID
    case savePasswordFailed(Error)
    case deletePasswordFailed(Error)
    case operationNotSupported
    case weakPassword
    
    var localizedDescription: String {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty"
        case .invalidStringID:
            return "String ID cannot be empty"
        case .savePasswordFailed(let error):
            return "Failed to save password: \(error.localizedDescription)"
        case .deletePasswordFailed(let error):
            return "Failed to delete password: \(error.localizedDescription)"
        case .operationNotSupported:
            return "Operation not supported"
        case .weakPassword:
            return "Password is too weak"
        }
    }
}

// MARK: - Supporting Types

struct PasswordStatistics {
    let totalStoredPasswords: Int
    let averagePasswordLength: Double
    let oldestPasswordDate: Date?
    let newestPasswordDate: Date?
} 