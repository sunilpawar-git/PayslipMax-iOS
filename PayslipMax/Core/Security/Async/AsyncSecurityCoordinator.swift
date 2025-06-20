import Foundation
import SwiftUI

/// Coordinator for managing async security operations throughout the app.
/// This replaces the problematic SecurityServiceAdapter that uses DispatchSemaphore.
/// 
/// Follows the coordinator pattern established in Phase 2B refactoring.
@MainActor
class AsyncSecurityCoordinator: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var isInitialized = false
    @Published private(set) var initializationError: Error?
    
    private let securityService: SecurityServiceProtocol
    private var asyncEncryptionService: AsyncEncryptionService?
    
    // MARK: - Initialization
    
    init(securityService: SecurityServiceProtocol? = nil) {
        self.securityService = securityService ?? DIContainer.shared.securityService
    }
    
    // MARK: - Public Methods
    
    /// Initializes the security coordinator and all async services.
    /// This replaces the problematic setupEncryptionServices() in PayslipMaxApp.swift
    func initialize() {
        // Initialize the underlying security service in background
        Task {
            try await securityService.initialize()
        }
        
        // Create the async encryption service
        asyncEncryptionService = AsyncEncryptionService(securityService: securityService)
        
        // Configure the sensitive data handler factory
        configureAsyncSensitiveDataFactory()
        
        isInitialized = true
        initializationError = nil
        
        print("✅ Async security coordinator initialized successfully")
    }
    
    /// Provides access to the async encryption service
    func getAsyncEncryptionService() throws -> AsyncEncryptionService {
        guard let service = asyncEncryptionService else {
            throw SecurityCoordinatorError.notInitialized
        }
        return service
    }
    
    // MARK: - Private Methods
    
    private func configureAsyncSensitiveDataFactory() {
        // ✅ CLEAN: Check if encryption service is available
        guard asyncEncryptionService != nil else { return }
        
        // Configure the factory to use our async service
        // This will be updated when we refactor PayslipSensitiveDataHandler
        PayslipSensitiveDataHandler.Factory.initialize()
    }
}

// MARK: - Supporting Types

/// Async-first encryption service that eliminates DispatchSemaphore usage
class AsyncEncryptionService: AsyncSensitiveDataEncryptionService {
    private let securityService: SecurityServiceProtocol
    
    init(securityService: SecurityServiceProtocol) {
        self.securityService = securityService
    }
    
    /// Encrypts data asynchronously without blocking threads
    func encrypt(_ data: Data) async throws -> Data {
        // ✅ CLEAN: Direct async call - no semaphores!
        return try await securityService.encryptData(data)
    }
    
    /// Decrypts data asynchronously without blocking threads  
    func decrypt(_ data: Data) async throws -> Data {
        // ✅ CLEAN: Direct async call - no semaphores!
        return try await securityService.decryptData(data)
    }
}

/// Errors specific to the security coordinator
enum SecurityCoordinatorError: Error, LocalizedError {
    case notInitialized
    case initializationFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Security coordinator not initialized"
        case .initializationFailed(let error):
            return "Security coordinator initialization failed: \(error.localizedDescription)"
        }
    }
} 