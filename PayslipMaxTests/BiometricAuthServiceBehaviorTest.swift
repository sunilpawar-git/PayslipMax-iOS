import XCTest
import LocalAuthentication
@testable import PayslipMax

@MainActor
final class BiometricAuthServiceBehaviorTest: XCTestCase {

    private var biometricAuthService: BiometricAuthService!

    override func setUp() {
        super.setUp()
        biometricAuthService = BiometricAuthService()
    }

    override func tearDown() {
        biometricAuthService = nil
        super.tearDown()
    }

    func testMultipleServiceInstances() {
        let service1 = BiometricAuthService()
        let service2 = BiometricAuthService()

        XCTAssertFalse(service1 === service2)

        let type1 = service1.getBiometricType()
        let type2 = service2.getBiometricType()

        XCTAssertEqual(type1, type2)
    }

    func testConcurrentAuthentication() {
        let expectation1 = expectation(description: "First authentication")
        let expectation2 = expectation(description: "Second authentication")

        var completion1Called = false
        var completion2Called = false

        biometricAuthService.authenticate { success, errorMessage in
            completion1Called = true
            expectation1.fulfill()
        }

        biometricAuthService.authenticate { success, errorMessage in
            completion2Called = true
            expectation2.fulfill()
        }

        waitForExpectations(timeout: 10.0)
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
    }

    func testBiometricTypeConsistency() {
        let type1 = biometricAuthService.getBiometricType()
        let type2 = biometricAuthService.getBiometricType()
        let type3 = biometricAuthService.getBiometricType()

        XCTAssertEqual(type1, type2)
        XCTAssertEqual(type2, type3)
        XCTAssertEqual(type1, type3)
    }

    func testServiceWhenBiometricsUnavailable() {
        let biometricType = biometricAuthService.getBiometricType()

        if biometricType == .none {
            let expectation = expectation(description: "Authentication when unavailable")

            biometricAuthService.authenticate { success, errorMessage in
                XCTAssertFalse(success)
                XCTAssertNotNil(errorMessage)
                expectation.fulfill()
            }

            waitForExpectations(timeout: 5.0)
        } else {
            XCTAssertTrue(biometricType == .touchID || biometricType == .faceID)
        }
    }

    func testAuthenticationTimeout() {
        let expectation = expectation(description: "Authentication timeout")

        biometricAuthService.authenticate { success, errorMessage in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    func testServiceMemoryManagement() {
        weak var weakService: BiometricAuthService?

        autoreleasepool {
            let service = BiometricAuthService()
            weakService = service
            XCTAssertNotNil(weakService)

            _ = service.getBiometricType()
        }

        XCTAssertNil(weakService)
    }

    func testAuthenticationCallbackParameters() {
        let expectation = expectation(description: "Authentication callback parameters")

        biometricAuthService.authenticate { success, errorMessage in
            XCTAssertNotNil(success)

            if let errorMessage = errorMessage {
                XCTAssertFalse(errorMessage.isEmpty)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}
