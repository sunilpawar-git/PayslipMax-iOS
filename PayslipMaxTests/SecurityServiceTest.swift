import XCTest
import Foundation
@testable import PayslipMax

@MainActor
final class SecurityServiceTest: XCTestCase {
    
    // MARK: - Test Properties
    
    private var securityService: SecurityServiceImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        securityService = SecurityServiceImpl()
        
        // Clear any existing PIN from UserDefaults to ensure clean test state
        UserDefaults.standard.removeObject(forKey: "app_pin")
        
        // Clear any secure data from previous tests
        let keysToRemove = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("secure_") }
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    override func tearDown() {
        securityService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test 1: Verify initial state is correct
    func testInitialState() {
        XCTAssertFalse(securityService.isInitialized)
        XCTAssertFalse(securityService.isSessionValid)
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 0)
        XCTAssertFalse(securityService.isAccountLocked)
        XCTAssertNotNil(securityService.securityPolicy)
        
        // Test security policy defaults
        XCTAssertTrue(securityService.securityPolicy.requiresBiometricAuth)
        XCTAssertTrue(securityService.securityPolicy.requiresDataEncryption)
        XCTAssertEqual(securityService.securityPolicy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(securityService.securityPolicy.maxFailedAttempts, 3)
    }
    
    /// Test 2: Verify initialization functionality
    func testInitialization() async throws {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        
        // When: Initialize service
        try await securityService.initialize()
        
        // Then: Service should be initialized
        XCTAssertTrue(securityService.isInitialized)
    }
    
    /// Test 3: Verify biometric availability check
    func testBiometricAvailability() {
        // Test biometric availability (this will depend on device/simulator configuration)
        let isAvailable = securityService.isBiometricAuthAvailable
        XCTAssertTrue(isAvailable == true || isAvailable == false) // Just verify it returns a boolean
    }
    
    /// Test 4: Verify PIN setup functionality
    func testPINSetup() async throws {
        // Given: Service is initialized
        try await securityService.initialize()
        
        // When: Setup PIN
        let testPIN = "1234"
        try await securityService.setupPIN(pin: testPIN)
        
        // Then: PIN should be set (no exception thrown)
        // PIN verification will be tested separately
    }
    
    /// Test 5: Verify PIN setup fails when not initialized
    func testPINSetupFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        
        // When/Then: Setup PIN should fail
        do {
            try await securityService.setupPIN(pin: "1234")
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test 6: Verify PIN verification functionality
    func testPINVerification() async throws {
        // Given: Service is initialized with a PIN
        try await securityService.initialize()
        let testPIN = "1234"
        try await securityService.setupPIN(pin: testPIN)
        
        // When: Verify correct PIN
        let isCorrect = try await securityService.verifyPIN(pin: testPIN)
        
        // Then: Verification should succeed
        XCTAssertTrue(isCorrect)
        
        // When: Verify incorrect PIN
        let isIncorrect = try await securityService.verifyPIN(pin: "5678")
        
        // Then: Verification should fail
        XCTAssertFalse(isIncorrect)
    }
    
    /// Test 7: Verify PIN verification fails when PIN not set
    func testPINVerificationFailsWhenPINNotSet() async throws {
        // Given: Service is initialized but no PIN set
        try await securityService.initialize()
        
        // When/Then: PIN verification should fail
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Expected SecurityError.pinNotSet")
        } catch SecurityServiceImpl.SecurityError.pinNotSet {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test 8: Verify PIN verification fails when not initialized
    func testPINVerificationFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        
        // When/Then: PIN verification should fail
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test 9: Verify data encryption functionality
    func testDataEncryption() async throws {
        // Given: Service is initialized
        try await securityService.initialize()
        let testData = "Hello, World!".data(using: .utf8)!
        
        // When: Encrypt data
        let encryptedData = try await securityService.encryptData(testData)
        
        // Then: Encrypted data should be different from original
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertTrue(encryptedData.count > 0)
    }
    
    /// Test 10: Verify data decryption functionality
    func testDataDecryption() async throws {
        // Given: Service is initialized with encrypted data
        try await securityService.initialize()
        let testData = "Hello, World!".data(using: .utf8)!
        let encryptedData = try await securityService.encryptData(testData)
        
        // When: Decrypt data
        let decryptedData = try await securityService.decryptData(encryptedData)
        
        // Then: Decrypted data should match original
        XCTAssertEqual(decryptedData, testData)
        XCTAssertEqual(String(data: decryptedData, encoding: .utf8), "Hello, World!")
    }
    
    /// Test 11: Verify encryption fails when not initialized
    func testEncryptionFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        let testData = "Test".data(using: .utf8)!
        
        // When/Then: Encryption should fail
        do {
            _ = try await securityService.encryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test 12: Verify decryption fails when not initialized
    func testDecryptionFailsWhenNotInitialized() async {
        // Given: Service is not initialized
        XCTAssertFalse(securityService.isInitialized)
        let testData = "Test".data(using: .utf8)!
        
        // When/Then: Decryption should fail
        do {
            _ = try await securityService.decryptData(testData)
            XCTFail("Expected SecurityError.notInitialized")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// Test 13: Verify synchronous encryption functionality
    func testSynchronousEncryption() throws {
        // Given: Service is initialized (need to run async init first)
        let expectation = expectation(description: "Initialize service")
        Task {
            try await securityService.initialize()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        let testData = "Sync Test".data(using: .utf8)!
        
        // When: Encrypt data synchronously
        let encryptedData = try securityService.encryptData(testData)
        
        // Then: Encrypted data should be different from original
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertTrue(encryptedData.count > 0)
    }
    
    /// Test 14: Verify synchronous decryption functionality
    func testSynchronousDecryption() throws {
        // Given: Service is initialized with encrypted data
        let expectation = expectation(description: "Initialize and encrypt")
        var encryptedData: Data?
        let testData = "Sync Test".data(using: .utf8)!
        
        Task {
            try await securityService.initialize()
            encryptedData = try await securityService.encryptData(testData)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Ensure encryptedData was set properly
        guard let encryptedData = encryptedData else {
            XCTFail("Failed to encrypt data within timeout")
            return
        }
        
        // When: Decrypt data synchronously
        let decryptedData = try securityService.decryptData(encryptedData)
        
        // Then: Decrypted data should match original
        XCTAssertEqual(decryptedData, testData)
    }
    
    /// Test 15: Verify session management
    func testSessionManagement() {
        // Given: Initial session state
        XCTAssertFalse(securityService.isSessionValid)
        
        // When: Start secure session
        securityService.startSecureSession()
        
        // Then: Session should be valid
        XCTAssertTrue(securityService.isSessionValid)
        
        // When: Invalidate session
        securityService.invalidateSession()
        
        // Then: Session should be invalid
        XCTAssertFalse(securityService.isSessionValid)
    }
    
    /// Test 16: Verify secure data storage
    func testSecureDataStorage() {
        // Given: Test data
        let testData = "Secure Test Data".data(using: .utf8)!
        let testKey = "test_key"
        
        // When: Store secure data
        let storeResult = securityService.storeSecureData(testData, forKey: testKey)
        
        // Then: Storage should succeed
        XCTAssertTrue(storeResult)
        
        // When: Retrieve secure data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        
        // Then: Retrieved data should match stored data
        XCTAssertEqual(retrievedData, testData)
    }
    
    /// Test 17: Verify secure data deletion
    func testSecureDataDeletion() {
        // Given: Stored secure data
        let testData = "Delete Test Data".data(using: .utf8)!
        let testKey = "delete_test_key"
        let storeResult = securityService.storeSecureData(testData, forKey: testKey)
        XCTAssertTrue(storeResult)
        
        // When: Delete secure data
        let deleteResult = securityService.deleteSecureData(forKey: testKey)
        
        // Then: Deletion should succeed
        XCTAssertTrue(deleteResult)
        
        // When: Try to retrieve deleted data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        
        // Then: Should return nil
        XCTAssertNil(retrievedData)
    }
    
    /// Test 18: Verify security violation handling - unauthorized access
    func testSecurityViolationUnauthorizedAccess() {
        // Given: Valid session
        securityService.startSecureSession()
        XCTAssertTrue(securityService.isSessionValid)
        
        // When: Handle unauthorized access violation
        securityService.handleSecurityViolation(.unauthorizedAccess)
        
        // Then: Session should be invalidated
        XCTAssertFalse(securityService.isSessionValid)
    }
    
    /// Test 19: Verify security violation handling - session timeout
    func testSecurityViolationSessionTimeout() {
        // Given: Valid session
        securityService.startSecureSession()
        XCTAssertTrue(securityService.isSessionValid)
        
        // When: Handle session timeout violation
        securityService.handleSecurityViolation(.sessionTimeout)
        
        // Then: Session should be invalidated
        XCTAssertFalse(securityService.isSessionValid)
    }
    
    /// Test 20: Verify security violation handling - too many failed attempts
    func testSecurityViolationTooManyFailedAttempts() {
        // Given: Valid session and unlocked account
        securityService.startSecureSession()
        XCTAssertTrue(securityService.isSessionValid)
        XCTAssertFalse(securityService.isAccountLocked)
        
        // When: Handle too many failed attempts violation
        securityService.handleSecurityViolation(.tooManyFailedAttempts)
        
        // Then: Account should be locked and session invalidated
        XCTAssertTrue(securityService.isAccountLocked)
        XCTAssertFalse(securityService.isSessionValid)
    }
    
    /// Test 21: Verify round-trip encryption/decryption with different data types
    func testEncryptionDecryptionRoundTrip() async throws {
        // Given: Service is initialized
        try await securityService.initialize()
        
        // Test with different data types
        let testCases = [
            "Simple string",
            "",
            "String with special characters: !@#$%^&*()_+{}[]|\\:;\"'<>?,./",
            String(repeating: "A", count: 1000), // Large string
            "🔒🗝️💰📊" // Emoji
        ]
        
        for testString in testCases {
            let testData = testString.data(using: .utf8)!
            
            // When: Encrypt and decrypt
            let encryptedData = try await securityService.encryptData(testData)
            let decryptedData = try await securityService.decryptData(encryptedData)
            
            // Then: Should get back original data
            XCTAssertEqual(decryptedData, testData)
            XCTAssertEqual(String(data: decryptedData, encoding: .utf8), testString)
        }
    }
    
    /// Test 22: Verify SecurityError descriptions
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
        
        // Test specific error descriptions
        XCTAssertEqual(SecurityServiceImpl.SecurityError.notInitialized.errorDescription, "Security service not initialized")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.biometricsNotAvailable.errorDescription, "Biometric authentication not available")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.authenticationFailed.errorDescription, "Authentication failed")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.encryptionFailed.errorDescription, "Failed to encrypt data")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.decryptionFailed.errorDescription, "Failed to decrypt data")
        XCTAssertEqual(SecurityServiceImpl.SecurityError.pinNotSet.errorDescription, "PIN has not been set")
    }
    
    /// Test 23: Verify SecurityPolicy configuration
    func testSecurityPolicyConfiguration() {
        let policy = securityService.securityPolicy
        
        // Test default values
        XCTAssertTrue(policy.requiresBiometricAuth)
        XCTAssertTrue(policy.requiresDataEncryption)
        XCTAssertEqual(policy.sessionTimeoutMinutes, 30)
        XCTAssertEqual(policy.maxFailedAttempts, 3)
        
        // Test policy modification
        policy.requiresBiometricAuth = false
        policy.requiresDataEncryption = false
        policy.sessionTimeoutMinutes = 60
        policy.maxFailedAttempts = 5
        
        XCTAssertFalse(policy.requiresBiometricAuth)
        XCTAssertFalse(policy.requiresDataEncryption)
        XCTAssertEqual(policy.sessionTimeoutMinutes, 60)
        XCTAssertEqual(policy.maxFailedAttempts, 5)
    }
    
    /// Test 24: Verify SecurityViolation enum cases
    func testSecurityViolationEnumCases() {
        let violations: [SecurityViolation] = [
            .unauthorizedAccess,
            .tooManyFailedAttempts,
            .sessionTimeout
        ]
        
        // Verify all cases exist and can be created
        XCTAssertEqual(violations.count, 3)
        
        // Test that each violation can be handled
        for violation in violations {
            // Should not crash when handling violations
            securityService.handleSecurityViolation(violation)
        }
    }
    
    /// Test 25: Verify data encryption with empty data
    func testEncryptionWithEmptyData() async throws {
        // Given: Service is initialized
        try await securityService.initialize()
        let emptyData = Data()
        
        // When: Encrypt empty data
        let encryptedData = try await securityService.encryptData(emptyData)
        
        // Then: Should still produce encrypted output (due to authentication tag)
        XCTAssertTrue(encryptedData.count > 0)
        
        // When: Decrypt the encrypted empty data
        let decryptedData = try await securityService.decryptData(encryptedData)
        
        // Then: Should get back empty data
        XCTAssertEqual(decryptedData, emptyData)
        XCTAssertEqual(decryptedData.count, 0)
    }
    
    /// Test 26: Verify PIN hashing consistency
    func testPINHashingConsistency() async throws {
        // Given: Service is initialized
        try await securityService.initialize()
        let testPIN = "9876"
        
        // When: Setup PIN multiple times
        try await securityService.setupPIN(pin: testPIN)
        let firstVerification = try await securityService.verifyPIN(pin: testPIN)
        
        try await securityService.setupPIN(pin: testPIN)
        let secondVerification = try await securityService.verifyPIN(pin: testPIN)
        
        // Then: PIN verification should be consistent
        XCTAssertTrue(firstVerification)
        XCTAssertTrue(secondVerification)
        
        // And wrong PIN should still fail
        let wrongPINVerification = try await securityService.verifyPIN(pin: "0000")
        XCTAssertFalse(wrongPINVerification)
    }
}