import XCTest
import CryptoKit
@testable import PayslipMax

@MainActor
class PINAuthenticationTests: XCTestCase {

    var sut: SecurityServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = SecurityServiceImpl()
    }

    override func tearDownWithError() throws {
        sut = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "app_pin")
        try super.tearDownWithError()
    }

    // MARK: - PIN Setup Tests

    func testSetupPIN_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        XCTAssertFalse(sut.isInitialized)

        // When/Then
        do {
            try await sut.setupPIN(pin: "1234")
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityError.notInitialized {
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
        } catch SecurityError.notInitialized {
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
        } catch SecurityError.pinNotSet {
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
}
