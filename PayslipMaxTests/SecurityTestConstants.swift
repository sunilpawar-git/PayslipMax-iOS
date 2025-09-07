import Foundation

/// Test constants and data for security service tests
/// Centralized constants to ensure consistency across test files
/// Follows SOLID principles with single responsibility focus
enum SecurityTestConstants {

    // MARK: - Test PINs
    static let validTestPIN = "1234"
    static let alternativeTestPIN = "5678"
    static let wrongTestPIN = "9999"
    static let specialCharacterPIN = "AbC!@#"
    static let longTestPIN = String(repeating: "9", count: 100)
    static let emptyPIN = ""
    static let unicodePIN = "🔐123"

    // MARK: - Test Data Strings
    static let simpleTestString = "Hello, World!"
    static let emptyTestString = ""
    static let specialCharactersString = "String with special characters: !@#$%^&*()_+{}[]|\\:;\"'<>?,./"
    static let largeTestString = String(repeating: "A", count: 1000)
    static let emojiTestString = "🔒🗝️💰📊"
    static let unicodeTestString = "Hello 世界 🌍"
    static let controlCharactersString = "Control chars: \n\t\r"

    // MARK: - Test Keys
    static let testKey = "test_key"
    static let alternativeTestKey = "alt_test_key"
    static let nonExistentKey = "non_existent_key"
    static let specialKey = "key-with-dashes"
    static let unicodeKey = "🔑_key"
    static let emptyKey = ""

    // MARK: - Test Data Arrays
    static let testStrings = [
        simpleTestString,
        emptyTestString,
        specialCharactersString,
        largeTestString,
        emojiTestString,
        unicodeTestString,
        controlCharactersString
    ]

    static let testPINs = [
        validTestPIN,
        alternativeTestPIN,
        specialCharacterPIN,
        longTestPIN,
        unicodePIN
    ]

    static let testKeys = [
        testKey,
        alternativeTestKey,
        specialKey,
        unicodeKey
    ]

    // MARK: - Binary Data
    static let smallBinaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])
    static let largeBinaryData = Data(repeating: 0x41, count: 100 * 1024) // 100KB
    static let emptyBinaryData = Data()

    // MARK: - Performance Test Constants
    static let stressTestIterations = 100
    static let memoryPressureIterations = 10
    static let concurrentOperationsCount = 5

    // MARK: - Policy Test Constants
    static let defaultSessionTimeout = 30
    static let defaultMaxFailedAttempts = 3
    static let modifiedSessionTimeout = 60
    static let modifiedMaxFailedAttempts = 5
    static let extremeSessionTimeout = 1440
    static let extremeMaxFailedAttempts = 10

    // MARK: - Error Test Constants
    static let expectedErrorDescriptions: [String: String] = [
        "notInitialized": "Security service not initialized",
        "biometricsNotAvailable": "Biometric authentication not available",
        "authenticationFailed": "Authentication failed",
        "encryptionFailed": "Failed to encrypt data",
        "decryptionFailed": "Failed to decrypt data",
        "pinNotSet": "PIN has not been set"
    ]

    // MARK: - Cross-Platform Test Data
    static let crossPlatformTestStrings = [
        "ASCII: Hello World",
        "Unicode: 你好世界 🌍",
        "Control chars: \n\t\r",
        "Numbers: 1234567890",
        "Symbols: !@#$%^&*()_+-=[]{}|;:,.<>?",
        "Empty: ",
        "Very long: " + String(repeating: "x", count: 10000)
    ]

    // MARK: - Session Test Constants
    static let sessionTestTimeout: TimeInterval = 1.0
    static let concurrentSessionOperations = 2

    // MARK: - Data Storage Test Constants
    static let dataStorageTestData = "Secure Test Data"
    static let dataStorageLargeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB

    // MARK: - Helper Methods
    static func createTestData(_ content: String = simpleTestString) -> Data {
        return content.data(using: .utf8)!
    }

    static func createTestDataArray(count: Int = 10) -> [Data] {
        return (0..<count).map { createTestData("Test data \($0)") }
    }

    static func createTestKeyArray(count: Int = 10) -> [String] {
        return (0..<count).map { "test_key_\($0)" }
    }

    static func createLargeTestData(sizeInMB: Int = 10) -> Data {
        return Data(repeating: 0x41, count: sizeInMB * 1024 * 1024)
    }

    static func createRandomBinaryData(size: Int = 1024) -> Data {
        return Data((0..<size).map { _ in UInt8.random(in: 0...255) })
    }

    // MARK: - Performance Benchmarks
    static let encryptionPerformanceThreshold: TimeInterval = 0.1 // seconds
    static let decryptionPerformanceThreshold: TimeInterval = 0.1 // seconds
    static let storagePerformanceThreshold: TimeInterval = 0.05 // seconds
    static let retrievalPerformanceThreshold: TimeInterval = 0.05 // seconds
}
