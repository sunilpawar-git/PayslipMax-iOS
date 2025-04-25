import Foundation
@testable import Payslip_Max

class MockBiometricAuthService: BiometricAuthServiceProtocol {
    var authenticateCallCount = 0
    var shouldSucceed = true
    
    func authenticate() async -> Bool {
        authenticateCallCount += 1
        return shouldSucceed
    }
    
    func reset() {
        authenticateCallCount = 0
        shouldSucceed = true
    }
} 