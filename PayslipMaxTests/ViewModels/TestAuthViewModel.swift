import Foundation
import Combine

// A simplified MockSecurityService for testing
class MockSecurityService {
    var isInitialized: Bool = true
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    
    // Track method calls for verification in tests
    var authenticateCount = 0
    
    func authenticate() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
}

// Simple error enum for testing
enum MockError: Error {
    case authenticationFailed
}

// A test-specific version of AuthViewModel that doesn't depend on the main app
class TestAuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    
    // MARK: - Properties
    private let securityService: MockSecurityService
    
    // MARK: - Initialization
    init(securityService: MockSecurityService) {
        self.securityService = securityService
    }
    
    // MARK: - Authentication
    func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            isAuthenticated = try await securityService.authenticate()
            error = nil
        } catch {
            isAuthenticated = false
            self.error = error
        }
    }
    
    // MARK: - Reset
    func reset() {
        isAuthenticated = false
        error = nil
    }
} 