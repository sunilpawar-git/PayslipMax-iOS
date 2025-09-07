import XCTest
@testable import PayslipMax

@MainActor
class SecurityErrorTests: XCTestCase {

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
}
