import XCTest
@testable import PayslipMax

/// Test for AuthViewModel authentication flows
@MainActor
final class AuthViewModelTest: XCTestCase {
    
    var mockSecurityService: AuthMockSecurityService!
    var authViewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        mockSecurityService = AuthMockSecurityService()
        authViewModel = AuthViewModel(securityService: mockSecurityService)
    }
    
    override func tearDown() {
        authViewModel = nil
        mockSecurityService = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Test initial authentication state
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isLoading)
        XCTAssertNil(authViewModel.error)
        XCTAssertEqual(authViewModel.pinCode, "")
        XCTAssertFalse(authViewModel.isBiometricAuthEnabled)
    }
    
    func testBiometricAvailability() {
        // Test biometric availability detection
        mockSecurityService.isBiometricAuthAvailable = true
        XCTAssertTrue(authViewModel.isBiometricAvailable)
        
        mockSecurityService.isBiometricAuthAvailable = false
        XCTAssertFalse(authViewModel.isBiometricAvailable)
    }
    
    func testSuccessfulBiometricAuthentication() async {
        // Test successful biometric authentication
        mockSecurityService.isBiometricAuthAvailable = true
        
        await authViewModel.authenticate()
        
        XCTAssertTrue(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isLoading)
        XCTAssertNil(authViewModel.error)
    }
    
    func testFailedBiometricAuthentication() async {
        // Test failed biometric authentication
        mockSecurityService.shouldFailAuthentication = true
        
        await authViewModel.authenticate()
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertFalse(authViewModel.isLoading)
        XCTAssertNotNil(authViewModel.error)
    }
    
    func testLoadingStateDuringAuthentication() async {
        // Test loading state management
        mockSecurityService.authenticationDelay = 0.1
        
        let task = Task {
            await authViewModel.authenticate()
        }
        
        // Check loading state is set during authentication
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        XCTAssertTrue(authViewModel.isLoading)
        
        await task.value
        XCTAssertFalse(authViewModel.isLoading)
    }
    
    func testValidPINValidation() async throws {
        // Test valid PIN validation
        authViewModel.pinCode = "1234"
        
        let result = try await authViewModel.validatePIN()
        XCTAssertTrue(result)
    }
    
    func testInvalidPINLength() async {
        // Test invalid PIN length validation
        authViewModel.pinCode = "123" // Too short
        
        do {
            let _ = try await authViewModel.validatePIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test PIN too long
        authViewModel.pinCode = "12345"
        
        do {
            let _ = try await authViewModel.validatePIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPINSetup() async throws {
        // Test PIN setup with valid PIN
        authViewModel.pinCode = "5678"
        
        try await authViewModel.setupPIN()
        // If no error is thrown, setup succeeded
        XCTAssert(true, "PIN setup completed successfully")
    }
    
    func testPINSetupWithInvalidLength() async {
        // Test PIN setup with invalid length
        authViewModel.pinCode = "56" // Too short
        
        do {
            try await authViewModel.setupPIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLogout() async {
        // Test logout functionality - first authenticate
        await authViewModel.authenticate()
        authViewModel.pinCode = "1234"
        
        authViewModel.logout()
        
        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertEqual(authViewModel.pinCode, "")
    }
    
    func testAuthErrorDescriptions() {
        // Test error descriptions
        let invalidPINLengthError = AuthViewModel.AuthError.invalidPINLength
        XCTAssertEqual(invalidPINLengthError.errorDescription, "PIN must be 4 digits")
        
        let invalidPINError = AuthViewModel.AuthError.invalidPIN
        XCTAssertEqual(invalidPINError.errorDescription, "Invalid PIN")
        
        let biometricsNotAvailableError = AuthViewModel.AuthError.biometricsNotAvailable
        XCTAssertEqual(biometricsNotAvailableError.errorDescription, "Biometric authentication is not available")
    }
    
    func testPINCodePropertyUpdates() {
        // Test PIN code property updates
        authViewModel.pinCode = "9876"
        XCTAssertEqual(authViewModel.pinCode, "9876")
        
        authViewModel.pinCode = ""
        XCTAssertEqual(authViewModel.pinCode, "")
    }
    
    func testErrorPropertyUpdates() {
        // Test error property updates
        let testError = AuthViewModel.AuthError.invalidPIN
        authViewModel.error = testError
        
        XCTAssertNotNil(authViewModel.error)
        XCTAssertEqual(authViewModel.error as? AuthViewModel.AuthError, testError)
        
        authViewModel.error = nil
        XCTAssertNil(authViewModel.error)
    }
}

// Enhanced mock security service for AuthViewModel testing
@MainActor
class AuthMockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = true
    var isBiometricAuthAvailable: Bool = true
    var isSessionValid: Bool = true
    var failedAuthenticationAttempts: Int = 0
    var isAccountLocked: Bool = false
    var securityPolicy: SecurityPolicy = SecurityPolicy()
    
    // Test control properties
    var shouldFailAuthentication = false
    var authenticationDelay: TimeInterval = 0
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        if authenticationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(authenticationDelay * 1_000_000_000))
        }
        
        if shouldFailAuthentication {
            throw AuthViewModel.AuthError.biometricsNotAvailable
        }
        return true
    }
    
    func authenticateWithBiometrics(reason: String) async throws {
        if shouldFailAuthentication {
            throw AuthViewModel.AuthError.biometricsNotAvailable
        }
    }
    
    func setupPIN(pin: String) async throws {
        // Mock implementation - just validate length
        guard pin.count == 4 else {
            throw AuthViewModel.AuthError.invalidPINLength
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        guard pin.count == 4 else {
            throw AuthViewModel.AuthError.invalidPINLength
        }
        return true
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        return data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        return data
    }
    
    func encryptData(_ data: Data) throws -> Data {
        return data
    }
    
    func decryptData(_ data: Data) throws -> Data {
        return data
    }
    
    func startSecureSession() {
        // Mock implementation
    }
    
    func invalidateSession() {
        // Mock implementation
    }
    
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        return true
    }
    
    func retrieveSecureData(forKey key: String) -> Data? {
        return nil
    }
    
    func deleteSecureData(forKey key: String) -> Bool {
        return true
    }
    
    func handleSecurityViolation(_ violation: SecurityViolation) {
        // Mock implementation
    }
    
    func reset() {
        isInitialized = false
        failedAuthenticationAttempts = 0
        isAccountLocked = false
        isSessionValid = true
        shouldFailAuthentication = false
        authenticationDelay = 0
    }
}