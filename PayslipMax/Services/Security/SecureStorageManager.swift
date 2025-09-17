import Foundation

/// Protocol defining secure storage operations
@MainActor
protocol SecureStorageManagerProtocol {
    /// Stores secure data in instance-specific storage
    func storeSecureData(_ data: Data, forKey key: String) -> Bool

    /// Retrieves secure data from instance-specific storage
    func retrieveSecureData(forKey key: String) -> Data?

    /// Deletes secure data from instance-specific storage
    func deleteSecureData(forKey key: String) -> Bool

    /// Clears all secure data from instance-specific storage
    func clearAllSecureData()
}

/// Manager responsible for secure data storage operations.
/// Provides instance-specific secure storage for sensitive data.
/// This component is isolated for better testability and single responsibility.
@MainActor
final class SecureStorageManager: SecureStorageManagerProtocol {
    /// Instance-specific storage for secure data (simulates isolated storage per service instance)
    private var secureDataStorage: [String: Data] = [:]

    /// Default initializer.
    init() {}

    /// Stores secure data in instance-specific storage
    /// - Parameters:
    ///   - data: The data to store securely
    ///   - key: The key to associate with the data
    /// - Returns: `true` if the data was stored successfully, `false` otherwise
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        // Instance-specific storage for test isolation
        secureDataStorage[key] = data
        return true
    }

    /// Retrieves secure data from instance-specific storage
    /// - Parameter key: The key associated with the data
    /// - Returns: The stored data if found, `nil` otherwise
    func retrieveSecureData(forKey key: String) -> Data? {
        return secureDataStorage[key]
    }

    /// Deletes secure data from instance-specific storage
    /// - Parameter key: The key associated with the data to delete
    /// - Returns: `true` if the data was deleted successfully, `false` otherwise
    func deleteSecureData(forKey key: String) -> Bool {
        secureDataStorage.removeValue(forKey: key)
        return true
    }

    /// Clears all secure data from instance-specific storage
    func clearAllSecureData() {
        secureDataStorage.removeAll()
    }
}
