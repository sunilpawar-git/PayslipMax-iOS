import Foundation

// MARK: - Static Factory Methods for Testing

extension PayslipItem {
    /// Static factory for encryption service - used in tests
    private static var encryptionServiceFactory: (() -> EncryptionServiceProtocolInternal)?
    
    /// Set the encryption service factory for testing
    static func setEncryptionServiceFactory(_ factory: @escaping () -> EncryptionServiceProtocolInternal) -> Bool {
        encryptionServiceFactory = factory
        return true
    }
    
    /// Get the current encryption service factory
    static func getEncryptionServiceFactory() -> () -> EncryptionServiceProtocolInternal {
        return encryptionServiceFactory ?? {
            // Return default encryption service if no factory is set
            return EncryptionServiceAdapter(encryptionService: EncryptionService())
        }
    }
    
    /// Reset the encryption service factory to default
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = nil
    }
    
    /// Computed property for backward compatibility with tests
    var date: Date {
        return timestamp
    }
    
    /// Static factory method for creating mock PayslipItem instances
    static func mock() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 300.0
        )
    }
}
