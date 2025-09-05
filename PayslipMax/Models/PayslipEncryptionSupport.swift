import Foundation

// MARK: - Encryption Support for PayslipItem

/// Adapter to make EncryptionService compatible with SensitiveDataEncryptionService
class EncryptionServiceAdapter: EncryptionServiceProtocolInternal {
    private let encryptionService: EncryptionServiceProtocolInternal
    
    init(encryptionService: EncryptionServiceProtocolInternal) {
        self.encryptionService = encryptionService
    }
    
    func encrypt(_ data: Data) throws -> Data {
        return try encryptionService.encrypt(data)
    }
    
    func decrypt(_ data: Data) throws -> Data {
        return try encryptionService.decrypt(data)
    }
}

/// Define the protocol here to avoid import issues
typealias EncryptionServiceProtocolInternal = EncryptionServiceProtocol

// MARK: - Schema Versions

/// Represents the schema versions for the PayslipItem model.
/// Used for tracking data model changes and migrations.
enum PayslipSchemaVersion: Int, Comparable {
    /// Initial version of the schema.
    case v1 = 1
    /// Second version, potentially introducing changes.
    case v2 = 2
    
    static func < (lhs: PayslipSchemaVersion, rhs: PayslipSchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
