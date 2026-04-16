import XCTest
@testable import PayslipMax

/// Test for AuthViewModel authentication flows
@MainActor
final class AuthViewModelTest: BaseTestCase {

    var mockSecurityService: AuthMockSecurityService!
    var authViewModel: AuthViewModel!
    var asyncTasks: Set<Task<Void, Never>>!

    override func setUp() {
        super.setUp()

        // Initialize async task tracking
        asyncTasks = Set<Task<Void, Never>>()

        mockSecurityService = AuthMockSecurityService()
        authViewModel = AuthViewModel(securityService: mockSecurityService)
    }

    override func tearDown() {
        // Cancel all async tasks before cleanup to prevent race conditions
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()

        authViewModel = nil
        mockSecurityService = nil
        asyncTasks = nil
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

        // Check initial state
        XCTAssertFalse(authViewModel.isLoading)

        // Create a controlled async operation and track it
        let authTask = Task<Void, Never> {
            await authViewModel.authenticate()
        }
        asyncTasks.insert(authTask)

        // Give the task a moment to start and check loading state
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        XCTAssertTrue(authViewModel.isLoading)

        // Wait for the operation to complete
        await authTask.value

        // Check final state
        XCTAssertFalse(authViewModel.isLoading)

        // Remove completed task from tracking
        asyncTasks.remove(authTask)
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

    func decryptDataSync(_ data: Data) throws -> Data {
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
