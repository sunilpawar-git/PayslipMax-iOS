// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// MARK: - Mock Error
enum MockError: Error {
    case authenticationFailed
}

// MARK: - Mock Security Service
class MockSecurityService {
    var isAuthenticated = false
    var shouldFail = false
    var authenticateCount = 0
    
    func authenticate() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return true
    }
}

// MARK: - Auth View Model
class AuthViewModel {
    var isAuthenticated = false
    var error: Error?
    
    private let securityService: MockSecurityService
    
    init(securityService: MockSecurityService) {
        self.securityService = securityService
    }
    
    func authenticate() async {
        do {
            isAuthenticated = try await securityService.authenticate()
            error = nil
        } catch {
            isAuthenticated = false
            self.error = error
        }
    }
}

// MARK: - Tests
func runTests() async {
    print("Running AuthViewModel tests...")
    
    // Test initial state
    let mockSecurity = MockSecurityService()
    let viewModel = AuthViewModel(securityService: mockSecurity)
    
    assert(!viewModel.isAuthenticated, "Should not be authenticated initially")
    assert(viewModel.error == nil, "Should not have an error initially")
    print("✅ Initial state test passed")
    
    // Test successful authentication
    await viewModel.authenticate()
    assert(viewModel.isAuthenticated, "Should be authenticated after successful authentication")
    assert(viewModel.error == nil, "Should not have an error after successful authentication")
    assert(mockSecurity.authenticateCount == 1, "Should call authenticate once")
    print("✅ Successful authentication test passed")
    
    // Test failed authentication
    let mockSecurityFail = MockSecurityService()
    mockSecurityFail.shouldFail = true
    let viewModelFail = AuthViewModel(securityService: mockSecurityFail)
    
    await viewModelFail.authenticate()
    assert(!viewModelFail.isAuthenticated, "Should not be authenticated after failed authentication")
    assert(viewModelFail.error != nil, "Should have an error after failed authentication")
    assert(mockSecurityFail.authenticateCount == 1, "Should call authenticate once")
    print("✅ Failed authentication test passed")
    
    print("All tests passed! 🎉")
}

// Run the tests
Task {
    await runTests()
}

// Keep the program running until tests complete
RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
