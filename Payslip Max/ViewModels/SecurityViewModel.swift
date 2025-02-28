import SwiftUI
import LocalAuthentication
import CryptoKit

// Import our security services
import Security

// MARK: - Supporting Types
enum SecurityError: LocalizedError {
    case notAuthenticated
    case encryptionFailed
    case decryptionFailed
    case biometricsFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Authentication required"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .biometricsFailed:
            return "Biometric authentication failed"
        }
    }
}

@MainActor
final class SecurityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    // For PIN functionality
    @Published var currentPin = ""
    @Published var newPin = ""
    @Published var confirmPin = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Properties
    private let context = LAContext()
    
    // MARK: - Public Methods
    func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            self.error = error
            isAuthenticated = false
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access payslip data"
            )
            isAuthenticated = success
        } catch {
            self.error = error
            isAuthenticated = false
        }
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        guard isAuthenticated else {
            throw SecurityError.notAuthenticated
        }
        
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let encrypted = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return encrypted
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        guard isAuthenticated else {
            throw SecurityError.notAuthenticated
        }
        
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    // PIN functionality
    func validateCurrentPin() -> Bool {
        // In a real implementation, this would validate against stored PIN
        return currentPin.count == 4
    }
    
    func validateNewPin() -> Bool {
        return newPin.count == 4 && newPin == confirmPin
    }
    
    func changePin() async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Validate inputs
        guard validateCurrentPin() else {
            errorMessage = "Current PIN is incorrect"
            isLoading = false
            return false
        }
        
        guard validateNewPin() else {
            errorMessage = "New PINs don't match or are invalid"
            isLoading = false
            return false
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real implementation, this would update the PIN in secure storage
        successMessage = "PIN changed successfully"
        isLoading = false
        return true
    }
    
    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        self.error = error
    }
} 