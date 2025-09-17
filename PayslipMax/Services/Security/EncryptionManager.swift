import Foundation
import CryptoKit

/// Protocol defining encryption and decryption operations
@MainActor
protocol EncryptionManagerProtocol {
    /// Flag indicating whether the encryption manager has been initialized
    var isInitialized: Bool { get }

    /// Initializes the encryption manager by generating the symmetric encryption key
    func initialize() async throws

    /// Encrypts the provided data using AES-GCM with the generated symmetric key
    func encryptData(_ data: Data) async throws -> Data

    /// Decrypts the provided data using AES-GCM with the generated symmetric key
    func decryptData(_ data: Data) async throws -> Data

    /// Synchronous encryption for tests
    func encryptData(_ data: Data) throws -> Data

    /// Synchronous decryption for tests
    func decryptDataSync(_ data: Data) throws -> Data
}

/// Manager responsible for data encryption and decryption operations.
/// Uses AES-GCM encryption with symmetric keys for secure data handling.
/// This component is isolated for better testability and single responsibility.
@MainActor
final class EncryptionManager: EncryptionManagerProtocol {
    /// The symmetric key used for AES-GCM encryption/decryption. Generated on initialization.
    private var symmetricKey: SymmetricKey?

    /// Flag indicating whether the encryption manager has been initialized
    var isInitialized: Bool = false

    /// Default initializer.
    init() {}

    /// Initializes the encryption manager by generating the symmetric encryption key.
    /// Must be called before performing encryption or decryption operations.
    func initialize() async throws {
        // Generate or retrieve encryption key
        symmetricKey = SymmetricKey(size: .bits256)
        isInitialized = true
    }

    /// Encrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the manager to be initialized first.
    /// - Parameter data: The raw `Data` to encrypt.
    /// - Returns: The encrypted data (combined nonce, ciphertext, and tag).
    /// - Throws: `SecurityError.notInitialized` if the manager is not initialized.
    ///         `SecurityError.encryptionFailed` if the AES-GCM sealing process fails.
    func encryptData(_ data: Data) async throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return encrypted
    }

    /// Decrypts the provided data using AES-GCM with the generated symmetric key.
    /// Requires the manager to be initialized first.
    /// - Parameter data: The encrypted data (combined nonce, ciphertext, and tag) to decrypt.
    /// - Returns: The original raw `Data`.
    /// - Throws: `SecurityError.notInitialized` if the manager is not initialized.
    ///         `SecurityError.decryptionFailed` if the AES-GCM opening process fails.
    func decryptData(_ data: Data) async throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Synchronous encryption for tests
    /// - Parameter data: The raw `Data` to encrypt.
    /// - Returns: The encrypted data.
    /// - Throws: `SecurityError.notInitialized` if the manager is not initialized.
    ///         `SecurityError.encryptionFailed` if the AES-GCM sealing process fails.
    func encryptData(_ data: Data) throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return encrypted
    }

    /// Synchronous decryption for tests
    /// - Parameter data: The encrypted data to decrypt.
    /// - Returns: The original raw `Data`.
    /// - Throws: `SecurityError.notInitialized` if the manager is not initialized.
    ///         `SecurityError.decryptionFailed` if the AES-GCM opening process fails.
    func decryptDataSync(_ data: Data) throws -> Data {
        guard isInitialized, let key = symmetricKey else {
            throw SecurityError.notInitialized
        }

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return decrypted
        } catch {
            throw SecurityError.decryptionFailed
        }
    }
}
