import Foundation
import SwiftData

/// Container for security-related services.
@MainActor
class SecurityServicesContainer {

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    /// Cached security service instance for consistency
    private var _securityService: SecurityServiceProtocol?

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    /// Access the security service (cached for consistency)
    var securityService: SecurityServiceProtocol {
        if _securityService == nil {
            _securityService = makeSecurityService()
        }
        return _securityService!
    }

    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        return SecurityServiceImpl()
    }

    /// Creates an encryption service
    func makeEncryptionService() -> EncryptionServiceProtocol {
        return EncryptionService()
    }

    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        do {
            return try PayslipEncryptionService.Factory.create()
        } catch {
            // Log the error and create a simple fallback
            print("Error creating PayslipEncryptionService: \(error.localizedDescription)")
            // For now, create a simple fallback
            do {
                let fallbackHandler = try PayslipSensitiveDataHandler.Factory.create()
                return PayslipEncryptionService(sensitiveDataHandler: fallbackHandler)
            } catch {
                // If all else fails, we have a serious problem - use fatalError for now
                fatalError("Unable to create PayslipEncryptionService: \(error.localizedDescription)")
            }
        }
    }

    /// Creates a secure storage service
    func makeSecureStorage() -> SecureStorageProtocol {
        return KeychainSecureStorage()
    }
}
