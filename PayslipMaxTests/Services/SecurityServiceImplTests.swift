import XCTest
import LocalAuthentication
import CryptoKit
@testable import PayslipMax

@MainActor
class SecurityServiceImplTests: XCTestCase {
    
    var sut: SecurityServiceImpl!
    var mockUserDefaults: MockUserDefaults!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUserDefaults = MockUserDefaults()
        sut = SecurityServiceImpl()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockUserDefaults = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "app_pin")
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialize_SetsInitializedFlag() async throws {
        // Given
        XCTAssertFalse(sut.isInitialized)
        
        // When
        try await sut.initialize()
        
        // Then
        XCTAssertTrue(sut.isInitialized)
    }
    
    func testInitialize_CanBeCalledMultipleTimes() async throws {
        // Given
        try await sut.initialize()
        XCTAssertTrue(sut.isInitialized)
        
        // When
        try await sut.initialize()
        
        // Then
        XCTAssertTrue(sut.isInitialized)
    }
    
    // MARK: - PIN Setup Tests
    
    func testSetupPIN_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        XCTAssertFalse(sut.isInitialized)
        
        // When/Then
        do {
            try await sut.setupPIN(pin: "1234")
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSetupPIN_WhenInitialized_StoresPINSuccessfully() async throws {
        // Given
        try await sut.initialize()
        let testPin = "1234"
        
        // When
        try await sut.setupPIN(pin: testPin)
        
        // Then
        let storedPin = UserDefaults.standard.string(forKey: "app_pin")
        XCTAssertNotNil(storedPin)
        XCTAssertNotEqual(storedPin, testPin) // Should be hashed
    }
    
    func testSetupPIN_HashesThePin() async throws {
        // Given
        try await sut.initialize()
        let testPin = "1234"
        
        // When
        try await sut.setupPIN(pin: testPin)
        
        // Then
        let storedPin = UserDefaults.standard.string(forKey: "app_pin")
        let expectedHash = SHA256.hash(data: Data(testPin.utf8))
        let expectedHashString = expectedHash.compactMap { String(format: "%02x", $0) }.joined()
        
        XCTAssertEqual(storedPin, expectedHashString)
    }
    
    func testSetupPIN_OverwritesExistingPin() async throws {
        // Given
        try await sut.initialize()
        try await sut.setupPIN(pin: "1234")
        let firstPin = UserDefaults.standard.string(forKey: "app_pin")
        
        // When
        try await sut.setupPIN(pin: "5678")
        
        // Then
        let secondPin = UserDefaults.standard.string(forKey: "app_pin")
        XCTAssertNotEqual(firstPin, secondPin)
    }
    
    // MARK: - PIN Verification Tests
    
    func testVerifyPIN_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        XCTAssertFalse(sut.isInitialized)
        
        // When/Then
        do {
            _ = try await sut.verifyPIN(pin: "1234")
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testVerifyPIN_WhenPinNotSet_ThrowsPinNotSetError() async {
        // Given
        do {
            try await sut.initialize()
        } catch {
            XCTFail("Initialization failed: \(error)")
            return
        }
        
        // When/Then
        do {
            _ = try await sut.verifyPIN(pin: "1234")
            XCTFail("Should have thrown pinNotSet error")
        } catch SecurityServiceImpl.SecurityError.pinNotSet {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testVerifyPIN_WithCorrectPin_ReturnsTrue() async throws {
        // Given
        try await sut.initialize()
        let testPin = "1234"
        try await sut.setupPIN(pin: testPin)
        
        // When
        let result = try await sut.verifyPIN(pin: testPin)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testVerifyPIN_WithIncorrectPin_ReturnsFalse() async throws {
        // Given
        try await sut.initialize()
        try await sut.setupPIN(pin: "1234")
        
        // When
        let result = try await sut.verifyPIN(pin: "5678")
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testVerifyPIN_WithEmptyPin_ReturnsFalse() async throws {
        // Given
        try await sut.initialize()
        try await sut.setupPIN(pin: "1234")
        
        // When
        let result = try await sut.verifyPIN(pin: "")
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptData_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        let testData = Data("test data".utf8)
        XCTAssertFalse(sut.isInitialized)
        
        // When/Then
        do {
            _ = try await sut.encryptData(testData)
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testEncryptData_WhenInitialized_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let testData = Data("test data".utf8)
        
        // When
        let encryptedData = try await sut.encryptData(testData)
        
        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }
    
    func testEncryptData_WithEmptyData_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let emptyData = Data()
        
        // When
        let encryptedData = try await sut.encryptData(emptyData)
        
        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }
    
    func testEncryptData_WithLargeData_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let largeData = Data(repeating: 0xFF, count: 100_000)
        
        // When
        let encryptedData = try await sut.encryptData(largeData)
        
        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertNotEqual(encryptedData, largeData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }
    
    // MARK: - Decryption Tests
    
    func testDecryptData_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        let testData = Data("test data".utf8)
        XCTAssertFalse(sut.isInitialized)
        
        // When/Then
        do {
            _ = try await sut.decryptData(testData)
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDecryptData_WithValidEncryptedData_ReturnsOriginalData() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)
        let encryptedData = try await sut.encryptData(originalData)
        
        // When
        let decryptedData = try await sut.decryptData(encryptedData)
        
        // Then
        XCTAssertEqual(decryptedData, originalData)
    }
    
    func testDecryptData_WithInvalidData_ThrowsError() async {
        // Given
        do {
            try await sut.initialize()
        } catch {
            XCTFail("Initialization failed: \(error)")
            return
        }
        let invalidData = Data("invalid encrypted data".utf8)
        
        // When/Then
        do {
            _ = try await sut.decryptData(invalidData)
            XCTFail("Should have thrown decryption error")
        } catch {
            // Success - should throw error for invalid data
        }
    }
    
    func testDecryptData_WithTamperedData_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)
        var encryptedData = try await sut.encryptData(originalData)
        
        // Tamper with the data
        encryptedData[0] = encryptedData[0] ^ 0xFF
        
        // When/Then
        do {
            _ = try await sut.decryptData(encryptedData)
            XCTFail("Should have thrown decryption error for tampered data")
        } catch {
            // Success - should throw error for tampered data
        }
    }
    
    // MARK: - Encrypt/Decrypt Round Trip Tests
    
    func testEncryptDecryptRoundTrip_PreservesOriginalData() async throws {
        // Given
        try await sut.initialize()
        let testCases = [
            Data("simple text".utf8),
            Data(),
            Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]),
            Data(repeating: 0xAA, count: 1000),
            Data("emoji test 🔒🔑💾".utf8)
        ]
        
        // When/Then
        for originalData in testCases {
            let encryptedData = try await sut.encryptData(originalData)
            let decryptedData = try await sut.decryptData(encryptedData)
            
            XCTAssertEqual(decryptedData, originalData, "Round trip failed for data: \(originalData)")
        }
    }
    
    func testEncryptDecryptRoundTrip_ProducesDifferentEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)
        
        // When
        let encrypted1 = try await sut.encryptData(originalData)
        let encrypted2 = try await sut.encryptData(originalData)
        
        // Then
        XCTAssertNotEqual(encrypted1, encrypted2, "Encrypting same data twice should produce different ciphertext")
        
        // But both should decrypt to the same original data
        let decrypted1 = try await sut.decryptData(encrypted1)
        let decrypted2 = try await sut.decryptData(encrypted2)
        
        XCTAssertEqual(decrypted1, originalData)
        XCTAssertEqual(decrypted2, originalData)
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testIsBiometricAuthAvailable_ReturnsExpectedValue() {
        // Given/When
        let isAvailable = sut.isBiometricAuthAvailable
        
        // Then
        // Note: This test depends on the device/simulator configuration
        // On CI/testing environments, biometrics are typically not available
        XCTAssertFalse(isAvailable)
    }
    
    func testAuthenticateWithBiometrics_WhenBiometricsNotAvailable_ThrowsError() async {
        // Given
        // Most test environments don't have biometrics configured
        
        // When/Then
        do {
            _ = try await sut.authenticateWithBiometrics()
            XCTFail("Should have thrown biometricsNotAvailable error")
        } catch SecurityServiceImpl.SecurityError.biometricsNotAvailable {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Error Tests
    
    func testSecurityErrorDescriptions() {
        let errors: [SecurityServiceImpl.SecurityError] = [
            .notInitialized,
            .biometricsNotAvailable,
            .authenticationFailed,
            .encryptionFailed,
            .decryptionFailed,
            .pinNotSet
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() async throws {
        // Given
        try await sut.initialize()
        let testData = Data(repeating: 0xFF, count: 1_000)
        
        // When: Test encryption performance with simplified approach
        var results: [Data] = []
        measure {
            // Run synchronous encryption multiple times
            for _ in 0..<10 {
                do {
                    let encrypted = try sut.encryptData(testData) // Use sync version for performance testing
                    results.append(encrypted)
                } catch {
                    XCTFail("Encryption failed: \(error)")
                    break
                }
            }
        }
        
        // Verify encryption succeeded
        XCTAssertFalse(results.isEmpty, "Should have encrypted data")
        XCTAssertGreaterThan(results.count, 0, "Should have multiple encryption results")
    }
    
    func testDecryptionPerformance() async throws {
        // Given
        try await sut.initialize()
        let testData = Data(repeating: 0xFF, count: 1_000)
        let encryptedData = try await sut.encryptData(testData)
        
        // When: Test decryption performance with simplified approach
        var results: [Data] = []
        measure {
            // Run synchronous decryption multiple times
            for _ in 0..<10 {
                do {
                    let decrypted = try sut.decryptData(encryptedData) // Use sync version for performance testing
                    results.append(decrypted)
                } catch {
                    XCTFail("Decryption failed: \(error)")
                    break
                }
            }
        }
        
        // Verify decryption succeeded
        XCTAssertFalse(results.isEmpty, "Should have decrypted data")
        XCTAssertEqual(results.first, testData, "Decrypted data should match original")
    }
}

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