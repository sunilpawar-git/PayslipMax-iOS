import Foundation
@testable import Payslip_Max

/// A mock encryption service for testing.
class MockEncryptionService: EncryptionServiceProtocolInternal {
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    var lastEncryptedData: Data?
    var lastDecryptedData: Data?
    
    // For backward compatibility with tests that use shouldFail
    var shouldFail: Bool {
        get {
            return shouldFailEncryption && shouldFailDecryption
        }
        set {
            shouldFailEncryption = newValue
            shouldFailDecryption = newValue
        }
    }
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption {
            throw MockSecurityError.encryptionFailed
        }
        lastEncryptedData = data
        // For testing, we'll just return the base64 encoded data
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption {
            throw MockSecurityError.decryptionFailed
        }
        lastDecryptedData = data
        // For testing, we'll assume the data is base64 encoded
        if let decodedData = Data(base64Encoded: data) {
            return decodedData
        }
        // If it's not base64 encoded, just return the original data
        return data
    }
    
    func reset() {
        encryptionCount = 0
        decryptionCount = 0
        shouldFailEncryption = false
        shouldFailDecryption = false
        lastEncryptedData = nil
        lastDecryptedData = nil
    }
}

/// Mock errors for testing.
enum MockEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidData
} 