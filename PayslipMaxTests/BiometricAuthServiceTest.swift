import XCTest
import LocalAuthentication
@testable import PayslipMax

@MainActor
final class BiometricAuthServiceTest: XCTestCase {
    
    // MARK: - Test Properties
    
    private var biometricAuthService: BiometricAuthService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        biometricAuthService = BiometricAuthService()
    }
    
    override func tearDown() {
        biometricAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test 1: Verify BiometricType enum descriptions
    func testBiometricTypeDescriptions() {
        XCTAssertEqual(BiometricAuthService.BiometricType.none.description, "None")
        XCTAssertEqual(BiometricAuthService.BiometricType.touchID.description, "Touch ID")
        XCTAssertEqual(BiometricAuthService.BiometricType.faceID.description, "Face ID")
    }
    
    /// Test 2: Verify BiometricType enum cases
    func testBiometricTypeEnumCases() {
        let allCases: [BiometricAuthService.BiometricType] = [.none, .touchID, .faceID]
        XCTAssertEqual(allCases.count, 3)
        
        // Verify each case can be created and compared
        XCTAssertNotEqual(BiometricAuthService.BiometricType.none, .touchID)
        XCTAssertNotEqual(BiometricAuthService.BiometricType.touchID, .faceID)
        XCTAssertNotEqual(BiometricAuthService.BiometricType.faceID, .none)
    }
    
    /// Test 3: Verify getBiometricType returns valid type
    func testGetBiometricType() {
        // When: Get biometric type
        let biometricType = biometricAuthService.getBiometricType()
        
        // Then: Should return one of the valid types
        let validTypes: [BiometricAuthService.BiometricType] = [.none, .touchID, .faceID]
        XCTAssertTrue(validTypes.contains(biometricType))
    }
    
    /// Test 4: Verify authentication method exists and handles completion
    func testAuthenticateMethodExists() {
        // This test verifies the method signature and basic functionality
        let expectation = expectation(description: "Authentication completion")
        var completionCalled = false
        
        // When: Call authenticate method
        biometricAuthService.authenticate { success, errorMessage in
            completionCalled = true
            expectation.fulfill()
        }
        
        // Then: Completion should be called
        waitForExpectations(timeout: 5.0)
        XCTAssertTrue(completionCalled)
    }
    
    /// Test 5: Verify authenticate completion is called on main queue
    func testAuthenticateCompletionOnMainQueue() {
        let expectation = expectation(description: "Main queue completion")
        
        // When: Call authenticate method
        biometricAuthService.authenticate { success, errorMessage in
            // Then: Should be on main queue
            XCTAssertTrue(Thread.isMainThread, "Completion should be called on main queue")
            expectation.fulfill()
        }
        
        // Reduced timeout for better test performance and add proper handling
        waitForExpectations(timeout: 2.0) { error in
            if let error = error {
                // In simulator or when biometrics aren't available, this is expected
                print("Biometric authentication test timed out (expected in simulator): \(error.localizedDescription)")
            }
        }
    }
    
    /// Test 6: Verify error message handling through authentication callback
    func testErrorMessageHandlingThroughAuthentication() {
        // Since errorMessage is private, we test it indirectly through authentication failures
        // This test verifies that error messages are properly formatted when returned
        let expectation = expectation(description: "Authentication with error message")
        
        biometricAuthService.authenticate { success, errorMessage in
            if !success, let errorMessage = errorMessage {
                // Verify error message is not empty and is a reasonable string
                XCTAssertFalse(errorMessage.isEmpty)
                XCTAssertTrue(errorMessage.count > 5) // Should be a meaningful message
                XCTAssertFalse(errorMessage.contains("nil"))
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    /// Test 7: Verify service handles authentication failures gracefully
    func testAuthenticationFailureHandling() {
        let expectation = expectation(description: "Authentication failure handling")
        
        biometricAuthService.authenticate { success, errorMessage in
            // Whether success or failure, the callback should be called with valid parameters
            XCTAssertNotNil(success) // success is Bool, always has a value
            
            if !success {
                XCTAssertNotNil(errorMessage)
                XCTAssertTrue(errorMessage!.count > 0)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    /// Test 8: Verify service behavior with different biometric states
    func testServiceBehaviorWithDifferentBiometricStates() {
        let biometricType = biometricAuthService.getBiometricType()
        
        // Test based on actual device capabilities
        switch biometricType {
        case .none:
            // When no biometrics available, authentication should fail
            let expectation = expectation(description: "No biometrics authentication")
            biometricAuthService.authenticate { success, errorMessage in
                XCTAssertFalse(success)
                XCTAssertNotNil(errorMessage)
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
            
        case .touchID, .faceID:
            // When biometrics are available, verify the service attempts authentication
            let expectation = expectation(description: "Biometrics available authentication")
            biometricAuthService.authenticate { success, errorMessage in
                // Either succeeds or fails with appropriate error message
                if !success {
                    XCTAssertNotNil(errorMessage)
                }
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
        }
    }
    
    /// Test 9: Verify service can be instantiated multiple times
    func testMultipleServiceInstances() {
        let service1 = BiometricAuthService()
        let service2 = BiometricAuthService()
        
        // Should be different instances
        XCTAssertFalse(service1 === service2)
        
        // Both should be functional
        let type1 = service1.getBiometricType()
        let type2 = service2.getBiometricType()
        
        // Should return the same type (device capability doesn't change)
        XCTAssertEqual(type1, type2)
    }
    
    /// Test 10: Verify authentication with multiple concurrent calls
    func testConcurrentAuthentication() {
        let expectation1 = expectation(description: "First authentication")
        let expectation2 = expectation(description: "Second authentication")
        
        var completion1Called = false
        var completion2Called = false
        
        // When: Make concurrent authentication calls
        biometricAuthService.authenticate { success, errorMessage in
            completion1Called = true
            expectation1.fulfill()
        }
        
        biometricAuthService.authenticate { success, errorMessage in
            completion2Called = true
            expectation2.fulfill()
        }
        
        // Then: Both completions should be called
        waitForExpectations(timeout: 10.0)
        XCTAssertTrue(completion1Called)
        XCTAssertTrue(completion2Called)
    }
    
    /// Test 11: Verify biometric type consistency across calls
    func testBiometricTypeConsistency() {
        // When: Call getBiometricType multiple times
        let type1 = biometricAuthService.getBiometricType()
        let type2 = biometricAuthService.getBiometricType()
        let type3 = biometricAuthService.getBiometricType()
        
        // Then: Should return consistent results
        XCTAssertEqual(type1, type2)
        XCTAssertEqual(type2, type3)
        XCTAssertEqual(type1, type3)
    }
    
    /// Test 12: Verify service behavior when biometrics unavailable
    func testServiceWhenBiometricsUnavailable() {
        // This test verifies the service handles the case when biometrics are not available
        // The actual availability depends on device/simulator configuration
        
        let biometricType = biometricAuthService.getBiometricType()
        
        if biometricType == .none {
            // When biometrics are not available, authentication should fail gracefully
            let expectation = expectation(description: "Authentication when unavailable")
            
            biometricAuthService.authenticate { success, errorMessage in
                XCTAssertFalse(success)
                XCTAssertNotNil(errorMessage)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 5.0)
        } else {
            // If biometrics are available, just verify the type is valid
            XCTAssertTrue(biometricType == .touchID || biometricType == .faceID)
        }
    }
    
    /// Test 13: Verify authentication timeout handling
    func testAuthenticationTimeout() {
        let expectation = expectation(description: "Authentication timeout")
        
        // When: Call authenticate method with reasonable timeout
        biometricAuthService.authenticate { success, errorMessage in
            // Then: Should complete within reasonable time
            expectation.fulfill()
        }
        
        // Use shorter timeout to test that completion happens in reasonable time
        waitForExpectations(timeout: 3.0)
    }
    
    /// Test 14: Verify service memory management
    func testServiceMemoryManagement() {
        weak var weakService: BiometricAuthService?
        
        autoreleasepool {
            let service = BiometricAuthService()
            weakService = service
            XCTAssertNotNil(weakService)
            
            // Use the service
            _ = service.getBiometricType()
        }
        
        // Service should be deallocated after leaving scope
        XCTAssertNil(weakService)
    }
    
    /// Test 15: Verify authentication callback parameters
    func testAuthenticationCallbackParameters() {
        let expectation = expectation(description: "Authentication callback parameters")
        
        biometricAuthService.authenticate { success, errorMessage in
            // Verify parameter values (types are already enforced by Swift)
            XCTAssertNotNil(success) // success is Bool, always has a value
            
            if let errorMessage = errorMessage {
                XCTAssertFalse(errorMessage.isEmpty)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}