@testable import PayslipMax
import XCTest

@MainActor
final class AuthViewModelPINTests: BaseTestCase {
    var mockSecurityService: AuthMockSecurityService?
    var authViewModel: AuthViewModel?
    var asyncTasks: Set<Task<Void, Never>> = []

    override func setUp() {
        super.setUp()
        let mock = AuthMockSecurityService()
        mockSecurityService = mock
        authViewModel = AuthViewModel(securityService: mock)
    }

    override func tearDown() {
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()
        authViewModel = nil
        mockSecurityService = nil
        super.tearDown()
    }

    func testValidPINValidation() async throws {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        vm.pinCode = "1234"
        let result = try await vm.validatePIN()
        XCTAssertTrue(result)
    }

    func testInvalidPINLength() async {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        vm.pinCode = "123"
        do {
            _ = try await vm.validatePIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        vm.pinCode = "12345"
        do {
            _ = try await vm.validatePIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPINSetup() async throws {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        vm.pinCode = "5678"
        try await vm.setupPIN()
        XCTAssert(true, "PIN setup completed successfully")
    }

    func testPINSetupWithInvalidLength() async {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        vm.pinCode = "56"
        do {
            try await vm.setupPIN()
            XCTFail("Should have thrown invalidPINLength error")
        } catch AuthViewModel.AuthError.invalidPINLength {
            XCTAssert(true, "Expected invalidPINLength error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLogout() async {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        await vm.authenticate()
        vm.pinCode = "1234"
        vm.logout()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertEqual(vm.pinCode, "")
    }

    func testAuthErrorDescriptions() {
        XCTAssertEqual(AuthViewModel.AuthError.invalidPINLength.errorDescription, "PIN must be 4 digits")
        XCTAssertEqual(AuthViewModel.AuthError.invalidPIN.errorDescription, "Invalid PIN")
        let bioError = AuthViewModel.AuthError.biometricsNotAvailable
        XCTAssertEqual(bioError.errorDescription, "Biometric authentication is not available")
    }

    func testPINCodePropertyUpdates() {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        vm.pinCode = "9876"
        XCTAssertEqual(vm.pinCode, "9876")
        vm.pinCode = ""
        XCTAssertEqual(vm.pinCode, "")
    }

    func testErrorPropertyUpdates() {
        guard let vm = authViewModel else {
            XCTFail("authViewModel not set up")
            return
        }
        let testError = AuthViewModel.AuthError.invalidPIN
        vm.error = testError
        XCTAssertNotNil(vm.error)
        XCTAssertEqual(vm.error as? AuthViewModel.AuthError, testError)
        vm.error = nil
        XCTAssertNil(vm.error)
    }
}
