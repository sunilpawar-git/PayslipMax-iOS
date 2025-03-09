import Foundation

// Protocol for encryption service to enable mocking
protocol EncryptionServiceProtocol {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

// Make the real EncryptionService conform to the protocol
extension EncryptionService: EncryptionServiceProtocol {} 