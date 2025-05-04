import Foundation
@testable import PayslipMax

// MARK: - Mock Encryption Service
class MockEncryptionService: SensitiveDataEncryptionService {
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    var shouldFailKeyManagement = false
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return Data(base64Encoded: data) ?? data
    }
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        shouldFailKeyManagement = false
        encryptionCount = 0
        decryptionCount = 0
    }
} 