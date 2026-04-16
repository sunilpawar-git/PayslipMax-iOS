import XCTest
@testable import PayslipMax

@MainActor
final class AuthViewModelPINTests: BaseTestCase {

    var mockSecurityService: AuthMockSecurityService!
    var authViewModel: AuthViewModel!
    var asyncTasks: Set<Task<Void, Never>>!

    override func setUp() {
        super.setUp()
        asyncTasks = Set<Task<Void, Never>>()
        mockSecurityService = AuthMockSecurityService()
        authViewModel = AuthViewModel(securityService: mockSecurityService)
    }

    override func tearDown() {
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()
        authViewModel = nil
        mockSecurityService = nil
        asyncTasks = nil
        super.tearDown()
    }

    func testValidPINValidation() async throws {
        authViewModel.pinCode = "1234"

        let result = try await authViewModel.validatePIN()
        XCTAssertTrue(result)
    }

    func testInvalidPINLength() async {
        authViewModel.pinCode = "123" // Too short

        do {
            let _ = try await authViewModel.validatePIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

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
        authViewModel.pinCode = "5678"

        try await authViewModel.setupPIN()
        XCTAssert(true, "PIN setup completed successfully")
    }

    func testPINSetupWithInvalidLength() async {
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
        await authViewModel.authenticate()
        authViewModel.pinCode = "1234"

        authViewModel.logout()

        XCTAssertFalse(authViewModel.isAuthenticated)
        XCTAssertEqual(authViewModel.pinCode, "")
    }

    func testAuthErrorDescriptions() {
        let invalidPINLengthError = AuthViewModel.AuthError.invalidPINLength
        XCTAssertEqual(invalidPINLengthError.errorDescription, "PIN must be 4 digits")

        let invalidPINError = AuthViewModel.AuthError.invalidPIN
        XCTAssertEqual(invalidPINError.errorDescription, "Invalid PIN")

        let biometricsNotAvailableError = AuthViewModel.AuthError.biometricsNotAvailable
        XCTAssertEqual(biometricsNotAvailableError.errorDescription, "Biometric authentication is not available")
    }

    func testPINCodePropertyUpdates() {
        authViewModel.pinCode = "9876"
        XCTAssertEqual(authViewModel.pinCode, "9876")

        authViewModel.pinCode = ""
        XCTAssertEqual(authViewModel.pinCode, "")
    }

    func testErrorPropertyUpdates() {
        let testError = AuthViewModel.AuthError.invalidPIN
        authViewModel.error = testError

        XCTAssertNotNil(authViewModel.error)
        XCTAssertEqual(authViewModel.error as? AuthViewModel.AuthError, testError)

        authViewModel.error = nil
        XCTAssertNil(authViewModel.error)
    }
}
