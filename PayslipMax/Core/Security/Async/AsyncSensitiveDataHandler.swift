import Foundation

/// Async-first protocol for encryption services.
/// This replaces the synchronous SensitiveDataEncryptionService that caused DispatchSemaphore usage.
protocol AsyncSensitiveDataEncryptionService {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ data: Data) async throws -> Data
}

/// Async-first sensitive data handler that eliminates all DispatchSemaphore usage.
/// This replaces the synchronous PayslipSensitiveDataHandler for new async workflows.
/// 
/// Follows the single responsibility principle established in Phase 2B refactoring.
class AsyncSensitiveDataHandler {
    // MARK: - Properties
    
    private let encryptionService: AsyncSensitiveDataEncryptionService
    
    // MARK: - Initialization
    
    init(encryptionService: AsyncSensitiveDataEncryptionService) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - Public Async Methods
    
    /// Encrypts a string value asynchronously.
    /// No blocking operations - pure structured concurrency.
    func encryptString(_ value: String, fieldName: String) async throws -> String {
        let data = value.data(using: .utf8) ?? Data()
        
        do {
            let encryptedData = try await encryptionService.encrypt(data)
            return encryptedData.base64EncodedString()
        } catch {
            // Preserve error context for debugging
            throw AsyncSensitiveDataError.encryptionFailed(field: fieldName, underlying: error)
        }
    }
    
    /// Decrypts a base64-encoded string value asynchronously.
    /// No blocking operations - pure structured concurrency.
    func decryptString(_ value: String, fieldName: String) async throws -> String {
        guard let data = Data(base64Encoded: value) else {
            throw AsyncSensitiveDataError.invalidBase64Data(field: fieldName)
        }
        
        do {
            let decryptedData = try await encryptionService.decrypt(data)
            
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw AsyncSensitiveDataError.decodingFailed(field: fieldName)
            }
            
            return decryptedString
        } catch {
            if let asyncError = error as? AsyncSensitiveDataError {
                throw asyncError
            }
            throw AsyncSensitiveDataError.decryptionFailed(field: fieldName, underlying: error)
        }
    }
    
    /// Encrypts multiple sensitive fields asynchronously in parallel.
    /// Uses structured concurrency for optimal performance.
    func encryptSensitiveFields(
        name: String, 
        accountNumber: String, 
        panNumber: String
    ) async throws -> (name: String, accountNumber: String, panNumber: String) {
        
        // ✅ CLEAN: Parallel async operations using structured concurrency
        async let encryptedName = encryptString(name, fieldName: "name")
        async let encryptedAccountNumber = encryptString(accountNumber, fieldName: "account number")
        async let encryptedPanNumber = encryptString(panNumber, fieldName: "PAN number")
        
        return try await (encryptedName, encryptedAccountNumber, encryptedPanNumber)
    }
    
    /// Decrypts multiple sensitive fields asynchronously in parallel.
    /// Uses structured concurrency for optimal performance.
    func decryptSensitiveFields(
        name: String, 
        accountNumber: String, 
        panNumber: String
    ) async throws -> (name: String, accountNumber: String, panNumber: String) {
        
        // ✅ CLEAN: Parallel async operations using structured concurrency
        async let decryptedName = decryptString(name, fieldName: "name")
        async let decryptedAccountNumber = decryptString(accountNumber, fieldName: "account number")
        async let decryptedPanNumber = decryptString(panNumber, fieldName: "PAN number")
        
        return try await (decryptedName, decryptedAccountNumber, decryptedPanNumber)
    }
}

// MARK: - Error Handling

/// Async-specific errors for sensitive data operations.
/// Provides better error context than the original SensitiveDataError.
enum AsyncSensitiveDataError: Error, LocalizedError {
    case invalidBase64Data(field: String)
    case decodingFailed(field: String)
    case encryptionFailed(field: String, underlying: Error)
    case decryptionFailed(field: String, underlying: Error)
    case serviceNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .invalidBase64Data(let field):
            return "Invalid base64 data for \(field)"
        case .decodingFailed(let field):
            return "Failed to decode \(field) data"
        case .encryptionFailed(let field, let error):
            return "Failed to encrypt \(field): \(error.localizedDescription)"
        case .decryptionFailed(let field, let error):
            return "Failed to decrypt \(field): \(error.localizedDescription)"
        case .serviceNotInitialized:
            return "Async sensitive data service not initialized"
        }
    }
}

// MARK: - Factory

extension AsyncSensitiveDataHandler {
    /// Factory for creating async sensitive data handlers.
    /// Follows the same pattern as the original but with async-first design.
    class Factory {
        private static var encryptionServiceFactory: (() async throws -> AsyncSensitiveDataEncryptionService)?
        
        /// Sets the async encryption service factory.
        static func setAsyncEncryptionServiceFactory(
            _ factory: @escaping () async throws -> AsyncSensitiveDataEncryptionService
        ) {
            encryptionServiceFactory = factory
        }
        
        /// Creates an async sensitive data handler.
        static func create() async throws -> AsyncSensitiveDataHandler {
            guard let factory = encryptionServiceFactory else {
                throw AsyncSensitiveDataError.serviceNotInitialized
            }
            
            let encryptionService = try await factory()
            return AsyncSensitiveDataHandler(encryptionService: encryptionService)
        }
        
        /// Resets the factory (useful for testing).
        static func reset() {
            encryptionServiceFactory = nil
        }
    }
} 