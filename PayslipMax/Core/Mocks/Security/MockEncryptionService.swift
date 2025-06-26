import Foundation

/// Mock implementation of EncryptionServiceProtocol for testing purposes.
///
/// This mock service provides simple base64 encoding/decoding to simulate
/// encryption and decryption operations. It includes controllable failure
/// modes for testing error handling scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockEncryptionService: EncryptionServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether encryption operations should fail
    var shouldFailEncryption = false
    
    /// Controls whether decryption operations should fail
    var shouldFailDecryption = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
    }
    
    // MARK: - EncryptionServiceProtocol Implementation
    
    func encrypt(_ data: Data) throws -> Data {
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        guard let decodedData = Data(base64Encoded: data) else {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        return decodedData
    }
} 