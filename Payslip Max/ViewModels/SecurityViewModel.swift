import SwiftUI
import LocalAuthentication
import CryptoKit

// Import our security services
import Security

@MainActor
final class SecurityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
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
    
    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        self.error = error
    }
}

// MARK: - Supporting Types
extension SecurityViewModel {
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
} 