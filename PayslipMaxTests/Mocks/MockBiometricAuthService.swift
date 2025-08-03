import Foundation
import LocalAuthentication
@testable import PayslipMax

class MockBiometricAuthService: BiometricAuthService {
    // Control mock behavior
    var mockBiometricType: BiometricType = .none
    var mockAuthenticationSuccess = true
    var mockAuthenticationError: String? = nil
    var shouldFailInitialization = false
    var isBiometricAvailable = true
    
    // Tracking for verification
    var getBiometricTypeCalled = false
    var authenticateCalled = false
    var initializeCalled = false
    var checkAvailabilityCalled = false
    var lastAuthenticationReason: String?
    
    // Result simulation
    var authenticationResult: Result<Void, Error> = .success(())
    
    override func getBiometricType() -> BiometricType {
        getBiometricTypeCalled = true
        return mockBiometricType
    }
    
    override func authenticate(completion: @escaping (Bool, String?) -> Void) {
        authenticateCalled = true
        
        // Simulate async behavior of the real implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(self.mockAuthenticationSuccess, self.mockAuthenticationError)
        }
    }
    
    // Initialize method for tests
    func initialize() async throws {
        initializeCalled = true
        if shouldFailInitialization {
            throw MockError.initializationFailed
        }
    }
    
    // Check availability for tests
    func checkAvailability() -> Bool {
        checkAvailabilityCalled = true
        return isBiometricAvailable
    }
    
    // Async authentication method for tests
    func authenticateWithBiometrics(reason: String) async throws {
        authenticateCalled = true
        lastAuthenticationReason = reason
        
        switch authenticationResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
} 