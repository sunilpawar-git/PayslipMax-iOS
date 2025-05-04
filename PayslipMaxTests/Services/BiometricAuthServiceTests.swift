import XCTest
import LocalAuthentication
@testable import PayslipMax

final class BiometricAuthServiceTests: XCTestCase {
    
    var sut: BiometricAuthService!
    var mockService: MockBiometricAuthService!
    
    override func setUp() {
        super.setUp()
        sut = BiometricAuthService()
        mockService = MockBiometricAuthService()
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Biometric Type Tests
    
    func testBiometricTypeDescription() {
        // Test descriptions for each biometric type
        XCTAssertEqual(BiometricAuthService.BiometricType.none.description, "None")
        XCTAssertEqual(BiometricAuthService.BiometricType.touchID.description, "Touch ID")
        XCTAssertEqual(BiometricAuthService.BiometricType.faceID.description, "Face ID")
    }
    
    func testGetBiometricType() {
        // This is a behavioral test rather than an exact result test
        // since the simulator/device capabilities vary
        let biometricType = sut.getBiometricType()
        
        // The result should be one of the valid enum cases
        switch biometricType {
        case .none, .touchID, .faceID:
            // Valid result
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Authentication Tests with Mock
    
    func testAuthenticateSuccess() {
        // Set up the mock
        mockService.mockAuthenticationSuccess = true
        mockService.mockAuthenticationError = nil
        
        // Create an expectation for the async call
        let expectation = XCTestExpectation(description: "Authentication succeeds")
        
        // Perform authentication
        mockService.authenticate { success, error in
            // Verify results
            XCTAssertTrue(success)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        
        // Verify the mock was called
        XCTAssertTrue(mockService.authenticateCalled)
        
        // Wait for the async call to complete
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAuthenticateFailure() {
        // Set up the mock
        mockService.mockAuthenticationSuccess = false
        mockService.mockAuthenticationError = "Authentication failed"
        
        // Create an expectation for the async call
        let expectation = XCTestExpectation(description: "Authentication fails")
        
        // Perform authentication
        mockService.authenticate { success, error in
            // Verify results
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            XCTAssertEqual(error, "Authentication failed")
            expectation.fulfill()
        }
        
        // Verify the mock was called
        XCTAssertTrue(mockService.authenticateCalled)
        
        // Wait for the async call to complete
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetBiometricTypeMock() {
        // Set up the mock
        mockService.mockBiometricType = .faceID
        
        // Call the method
        let result = mockService.getBiometricType()
        
        // Verify the results
        XCTAssertEqual(result, .faceID)
        XCTAssertTrue(mockService.getBiometricTypeCalled)
        
        // Try another type
        mockService.mockBiometricType = .touchID
        let result2 = mockService.getBiometricType()
        XCTAssertEqual(result2, .touchID)
    }
} 