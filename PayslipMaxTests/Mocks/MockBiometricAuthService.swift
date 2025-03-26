import Foundation
import LocalAuthentication
@testable import Payslip_Max

class MockBiometricAuthService: BiometricAuthService {
    // Control mock behavior
    var mockBiometricType: BiometricType = .none
    var mockAuthenticationSuccess = true
    var mockAuthenticationError: String? = nil
    
    // Tracking for verification
    var getBiometricTypeCalled = false
    var authenticateCalled = false
    
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
} 