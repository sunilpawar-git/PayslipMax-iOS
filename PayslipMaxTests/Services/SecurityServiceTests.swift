import XCTest
import LocalAuthentication
@testable import PayslipMax

final class SecurityServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var securityService: SecurityService!
    var mockBiometricService: MockBiometricAuthService!
    var mockEncryptionService: MockEncryptionService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockBiometricService = MockBiometricAuthService()
        mockEncryptionService = MockEncryptionService()
        
        // Initialize security service with mocks
        securityService = SecurityService(
            biometricService: mockBiometricService,
            encryptionService: mockEncryptionService
        )
    }
    
    override func tearDown() async throws {
        securityService = nil
        mockBiometricService = nil
        mockEncryptionService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // When
        try await securityService.initialize()
        
        // Then
        XCTAssertTrue(securityService.isInitialized)
        XCTAssertTrue(mockBiometricService.initializeCalled)
        XCTAssertTrue(mockEncryptionService.initializeCalled)
    }
    
    func testInitialization_BiometricServiceFailure() async {
        // Given
        mockBiometricService.shouldFailInitialization = true
        
        // When & Then
        do {
            try await securityService.initialize()
            XCTFail("Expected initialization to fail")
        } catch {
            XCTAssertFalse(securityService.isInitialized)
            XCTAssertTrue(error is SecurityError)
        }
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testBiometricAuthAvailable_WhenAvailable() {
        // Given
        mockBiometricService.isBiometricAvailable = true
        
        // When
        let isAvailable = securityService.isBiometricAuthAvailable
        
        // Then
        XCTAssertTrue(isAvailable)
        XCTAssertTrue(mockBiometricService.checkAvailabilityCalled)
    }
    
    func testBiometricAuthAvailable_WhenNotAvailable() {
        // Given
        mockBiometricService.isBiometricAvailable = false
        
        // When
        let isAvailable = securityService.isBiometricAuthAvailable
        
        // Then
        XCTAssertFalse(isAvailable)
    }
    
    func testAuthenticateWithBiometrics_Success() async throws {
        // Given
        mockBiometricService.authenticationResult = .success(())
        let reason = "Test authentication"
        
        // When
        try await securityService.authenticateWithBiometrics(reason: reason)
        
        // Then
        XCTAssertTrue(mockBiometricService.authenticateCalled)
        XCTAssertEqual(mockBiometricService.lastAuthenticationReason, reason)
    }
    
    func testAuthenticateWithBiometrics_UserCancel() async {
        // Given
        mockBiometricService.authenticationResult = .failure(LAError(.userCancel))
        
        // When & Then
        do {
            try await securityService.authenticateWithBiometrics(reason: "Test")
            XCTFail("Expected authentication to fail")
        } catch let error as LAError {
            XCTAssertEqual(error.code, .userCancel)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testAuthenticateWithBiometrics_BiometricNotAvailable() async {
        // Given
        mockBiometricService.authenticationResult = .failure(LAError(.biometryNotAvailable))
        
        // When & Then
        do {
            try await securityService.authenticateWithBiometrics(reason: "Test")
            XCTFail("Expected authentication to fail")
        } catch let error as LAError {
            XCTAssertEqual(error.code, .biometryNotAvailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testAuthenticateWithBiometrics_AuthenticationFailed() async {
        // Given
        mockBiometricService.authenticationResult = .failure(LAError(.authenticationFailed))
        
        // When & Then
        do {
            try await securityService.authenticateWithBiometrics(reason: "Test")
            XCTFail("Expected authentication to fail")
        } catch let error as LAError {
            XCTAssertEqual(error.code, .authenticationFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Data Encryption Tests
    
    func testEncryptData_Success() throws {
        // Given
        let testData = "Sensitive payslip data".data(using: .utf8)!
        let expectedEncryptedData = "encrypted_data".data(using: .utf8)!
        mockEncryptionService.encryptResult = .success(expectedEncryptedData)
        
        // When
        let encryptedData = try securityService.encryptData(testData)
        
        // Then
        XCTAssertEqual(encryptedData, expectedEncryptedData)
        XCTAssertTrue(mockEncryptionService.encryptCalled)
        XCTAssertEqual(mockEncryptionService.lastDataToEncrypt, testData)
    }
    
    func testEncryptData_Failure() {
        // Given
        let testData = "Test data".data(using: .utf8)!
        mockEncryptionService.encryptResult = .failure(SecurityError.encryptionFailed)
        
        // When & Then
        do {
            _ = try securityService.encryptData(testData)
            XCTFail("Expected encryption to fail")
        } catch {
            XCTAssertTrue(error is SecurityError)
            XCTAssertTrue(mockEncryptionService.encryptCalled)
        }
    }
    
    func testDecryptData_Success() throws {
        // Given
        let encryptedData = "encrypted_data".data(using: .utf8)!
        let expectedDecryptedData = "Sensitive payslip data".data(using: .utf8)!
        mockEncryptionService.decryptResult = .success(expectedDecryptedData)
        
        // When
        let decryptedData = try securityService.decryptData(encryptedData)
        
        // Then
        XCTAssertEqual(decryptedData, expectedDecryptedData)
        XCTAssertTrue(mockEncryptionService.decryptCalled)
        XCTAssertEqual(mockEncryptionService.lastDataToDecrypt, encryptedData)
    }
    
    func testDecryptData_Failure() {
        // Given
        let encryptedData = "invalid_data".data(using: .utf8)!
        mockEncryptionService.decryptResult = .failure(SecurityError.decryptionFailed)
        
        // When & Then
        do {
            _ = try securityService.decryptData(encryptedData)
            XCTFail("Expected decryption to fail")
        } catch {
            XCTAssertTrue(error is SecurityError)
            XCTAssertTrue(mockEncryptionService.decryptCalled)
        }
    }
    
    // MARK: - Encryption Round-Trip Tests
    
    func testEncryptDecryptRoundTrip() throws {
        // Given
        let originalData = "Sensitive payslip information".data(using: .utf8)!
        let encryptedData = "encrypted_sensitive_data".data(using: .utf8)!
        
        mockEncryptionService.encryptResult = .success(encryptedData)
        mockEncryptionService.decryptResult = .success(originalData)
        
        // When
        let encrypted = try securityService.encryptData(originalData)
        let decrypted = try securityService.decryptData(encrypted)
        
        // Then
        XCTAssertEqual(encrypted, encryptedData)
        XCTAssertEqual(decrypted, originalData)
        XCTAssertTrue(mockEncryptionService.encryptCalled)
        XCTAssertTrue(mockEncryptionService.decryptCalled)
    }
    
    // MARK: - Security Policy Tests
    
    func testSecurityPolicyCompliance() {
        // Given
        let policy = securityService.securityPolicy
        
        // Then
        XCTAssertTrue(policy.requiresBiometricAuth)
        XCTAssertTrue(policy.requiresDataEncryption)
        XCTAssertGreaterThan(policy.sessionTimeoutMinutes, 0)
        XCTAssertGreaterThan(policy.maxFailedAttempts, 0)
    }
    
    func testSessionTimeout() async throws {
        // Given
        try await securityService.initialize()
        securityService.startSecureSession()
        
        // When
        let isSessionValid = securityService.isSessionValid
        
        // Then
        XCTAssertTrue(isSessionValid)
        
        // Simulate session timeout
        securityService.invalidateSession()
        XCTAssertFalse(securityService.isSessionValid)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleSecurityViolation() {
        // Given
        let violation = SecurityViolation.unauthorizedAccess
        
        // When
        securityService.handleSecurityViolation(violation)
        
        // Then
        XCTAssertFalse(securityService.isSessionValid)
        // Additional checks for logging, alerts, etc.
    }
    
    func testFailedAuthenticationAttempts() async {
        // Given
        mockBiometricService.authenticationResult = .failure(LAError(.authenticationFailed))
        
        // When
        for _ in 1...5 {
            do {
                try await securityService.authenticateWithBiometrics(reason: "Test")
            } catch {
                // Expected to fail
            }
        }
        
        // Then
        XCTAssertEqual(securityService.failedAuthenticationAttempts, 5)
        XCTAssertTrue(securityService.isAccountLocked)
    }
    
    // MARK: - Keychain Integration Tests
    
    func testStoreSecureData() {
        // Given
        let key = "test_key"
        let data = "secure_data".data(using: .utf8)!
        
        // When
        let success = securityService.storeSecureData(data, forKey: key)
        
        // Then
        XCTAssertTrue(success)
    }
    
    func testRetrieveSecureData() {
        // Given
        let key = "test_key"
        let originalData = "secure_data".data(using: .utf8)!
        
        // Store data first
        XCTAssertTrue(securityService.storeSecureData(originalData, forKey: key))
        
        // When
        let retrievedData = securityService.retrieveSecureData(forKey: key)
        
        // Then
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData, originalData)
    }
    
    func testDeleteSecureData() {
        // Given
        let key = "test_key"
        let data = "secure_data".data(using: .utf8)!
        
        // Store data first
        XCTAssertTrue(securityService.storeSecureData(data, forKey: key))
        XCTAssertNotNil(securityService.retrieveSecureData(forKey: key))
        
        // When
        let success = securityService.deleteSecureData(forKey: key)
        
        // Then
        XCTAssertTrue(success)
        XCTAssertNil(securityService.retrieveSecureData(forKey: key))
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() {
        // Given
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        mockEncryptionService.encryptResult = .success(largeData)
        
        // When & Then
        measure {
            do {
                _ = try securityService.encryptData(largeData)
            } catch {
                XCTFail("Encryption should not fail: \(error)")
            }
        }
    }
    
    func testDecryptionPerformance() {
        // Given
        let largeEncryptedData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        let originalData = Data(repeating: 0x41, count: 1024 * 1024)
        mockEncryptionService.decryptResult = .success(originalData)
        
        // When & Then
        measure {
            do {
                _ = try securityService.decryptData(largeEncryptedData)
            } catch {
                XCTFail("Decryption should not fail: \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEncryptEmptyData() throws {
        // Given
        let emptyData = Data()
        mockEncryptionService.encryptResult = .success(emptyData)
        
        // When
        let result = try securityService.encryptData(emptyData)
        
        // Then
        XCTAssertEqual(result, emptyData)
        XCTAssertTrue(mockEncryptionService.encryptCalled)
    }
    
    func testDecryptEmptyData() throws {
        // Given
        let emptyData = Data()
        mockEncryptionService.decryptResult = .success(emptyData)
        
        // When
        let result = try securityService.decryptData(emptyData)
        
        // Then
        XCTAssertEqual(result, emptyData)
        XCTAssertTrue(mockEncryptionService.decryptCalled)
    }
    
    func testConcurrentEncryptionRequests() async throws {
        // Given
        let testData = "Test data".data(using: .utf8)!
        let encryptedData = "Encrypted".data(using: .utf8)!
        mockEncryptionService.encryptResult = .success(encryptedData)
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { [weak self] in
                    do {
                        _ = try self?.securityService.encryptData(testData)
                    } catch {
                        XCTFail("Concurrent encryption failed: \(error)")
                    }
                }
            }
        }
        
        // Then
        XCTAssertEqual(mockEncryptionService.encryptCallCount, 10)
    }
    
    // MARK: - Integration Tests
    
    func testFullSecurityWorkflow() async throws {
        // Given
        try await securityService.initialize()
        let sensitiveData = "Very sensitive payslip data".data(using: .utf8)!
        
        mockBiometricService.authenticationResult = .success(())
        mockEncryptionService.encryptResult = .success(Data("encrypted".utf8))
        mockEncryptionService.decryptResult = .success(sensitiveData)
        
        // When - Full workflow
        // 1. Authenticate user
        try await securityService.authenticateWithBiometrics(reason: "Access payslip data")
        
        // 2. Start secure session
        securityService.startSecureSession()
        XCTAssertTrue(securityService.isSessionValid)
        
        // 3. Encrypt sensitive data
        let encryptedData = try securityService.encryptData(sensitiveData)
        
        // 4. Store encrypted data
        XCTAssertTrue(securityService.storeSecureData(encryptedData, forKey: "payslip_data"))
        
        // 5. Retrieve and decrypt data
        let retrievedData = securityService.retrieveSecureData(forKey: "payslip_data")!
        let decryptedData = try securityService.decryptData(retrievedData)
        
        // Then
        XCTAssertEqual(decryptedData, sensitiveData)
        XCTAssertTrue(mockBiometricService.authenticateCalled)
        XCTAssertTrue(mockEncryptionService.encryptCalled)
        XCTAssertTrue(mockEncryptionService.decryptCalled)
    }
} 