import Foundation
import LocalAuthentication

/// Service for handling biometric authentication (Face ID/Touch ID)
class BiometricAuthService {
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        
        var description: String {
            switch self {
            case .none:
                return "None"
            case .touchID:
                return "Touch ID"
            case .faceID:
                return "Face ID"
            }
        }
    }
    
    /// Determines the type of biometric authentication available on the device
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            default:
                return .none
            }
        } else {
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
        }
    }
    
    /// Attempts to authenticate the user using available biometrics
    /// - Parameter completion: Callback with result (success/failure) and optional error message
    func authenticate(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access your payslips"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        let message = self.errorMessage(from: error)
                        completion(false, message)
                    }
                }
            }
        } else {
            let message = self.errorMessage(from: error)
            completion(false, message)
        }
    }
    
    /// Converts LocalAuthentication errors to user-friendly messages
    /// - Parameter error: The error from LocalAuthentication
    /// - Returns: A user-friendly error message
    private func errorMessage(from error: Error?) -> String {
        guard let error = error as? LAError else {
            return "Authentication failed"
        }
        
        switch error.code {
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancel:
            return "Authentication cancelled"
        case .userFallback:
            return "Password authentication requested"
        case .biometryNotAvailable:
            return "Biometric authentication not available"
        case .biometryNotEnrolled:
            return "Biometric authentication not set up"
        case .biometryLockout:
            return "Biometric authentication is locked out. Please use your device passcode."
        default:
            return "Authentication error: \(error.localizedDescription)"
        }
    }
} 