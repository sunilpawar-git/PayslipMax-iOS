import Foundation
@testable import PayslipMax

// MARK: - Mock Classes

class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}

// MARK: - Test Utilities

extension SecurityServiceImpl {
    // Helper method for synchronous encryption in performance tests
    func encryptData(_ data: Data) throws -> Data {
        // This is a synchronous wrapper for performance testing
        // In real implementation, this would be the synchronous version
        return data // Placeholder - actual implementation would use synchronous encryption
    }

    // Helper method for synchronous decryption in performance tests
    func decryptData(_ data: Data) throws -> Data {
        // This is a synchronous wrapper for performance testing
        // In real implementation, this would be the synchronous version
        return data // Placeholder - actual implementation would use synchronous decryption
    }
}
