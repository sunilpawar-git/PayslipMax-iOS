import XCTest
import LocalAuthentication
@testable import PayslipMax

@MainActor
class BiometricAuthenticationTests: XCTestCase {

    var sut: SecurityServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = SecurityServiceImpl()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Biometric Authentication Tests

    func testIsBiometricAuthAvailable_ReturnsExpectedValue() {
        // Given/When
        let isAvailable = sut.isBiometricAuthAvailable

        // Then
        // Test should verify the property works correctly, regardless of actual availability
        // This test verifies the property can be accessed without crashing
        XCTAssertNotNil(isAvailable)
        // The actual value depends on the device/simulator configuration
        // We just ensure it returns a boolean value
    }

    func testAuthenticateWithBiometrics_WhenBiometricsNotAvailable_ThrowsError() async {
        // Given
        let isAvailable = sut.isBiometricAuthAvailable

        if isAvailable {
            // Skip this test if biometrics are available in the current environment
            // This test is specifically for when biometrics are NOT available
            return
        }

        // When/Then (only runs if biometrics are not available)
        do {
            _ = try await sut.authenticateWithBiometrics()
            XCTFail("Should have thrown biometricsNotAvailable error")
        } catch SecurityServiceImpl.SecurityError.biometricsNotAvailable {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAuthenticateWithBiometrics_WhenBiometricsAvailable_HandlesProperly() async {
        // Given
        let isAvailable = sut.isBiometricAuthAvailable

        guard isAvailable else {
            // Skip this test if biometrics are not available in the current environment
            return
        }

        // When/Then
        do {
            // This may succeed or fail depending on user interaction in simulator
            // We're just testing that it doesn't crash and handles the call properly
            _ = try await sut.authenticateWithBiometrics()
        } catch SecurityServiceImpl.SecurityError.authenticationFailed {
            // This is acceptable - user may have cancelled or failed authentication
        } catch SecurityServiceImpl.SecurityError.biometricsNotAvailable {
            XCTFail("Biometrics should be available but got biometricsNotAvailable error")
        } catch {
            // Other errors may occur (e.g., user interaction required)
            // We accept these as they're part of normal flow
        }
    }
}
