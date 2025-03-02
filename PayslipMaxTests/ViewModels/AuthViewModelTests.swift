import XCTest
@testable import Payslip_Max

final class AuthViewModelTests: XCTestCase {
    
    var authViewModel: AuthViewModel!
    var mockAuthService: MockAuthServiceImpl!
    
    override func setUpWithError() throws {
        super.setUp()
        ServiceLocator.reset()
        
        mockAuthService = MockAuthServiceImpl()
        ServiceLocator.register(type: AuthServiceProtocol.self, service: mockAuthService!)
        
        authViewModel = AuthViewModel()
    }
    
    override func tearDown() {
        authViewModel = nil
        mockAuthService = nil
        ServiceLocator.reset()
        super.tearDown()
    }
    
    func testLogin() async {
        // Set up the expected result
        mockAuthService.shouldSucceed = true
        
        // Perform the login
        await authViewModel.login(username: "test@example.com", password: "password")
        
        // Verify the login was called and the state is updated
        XCTAssertTrue(mockAuthService.loginCalled, "Login method should be called")
        XCTAssertTrue(authViewModel.isAuthenticated, "User should be authenticated after successful login")
    }
    
    func testLoginFailure() async {
        // Set up the expected result
        mockAuthService.shouldSucceed = false
        
        // Perform the login
        await authViewModel.login(username: "test@example.com", password: "wrong")
        
        // Verify the login was called and the state is updated
        XCTAssertTrue(mockAuthService.loginCalled, "Login method should be called")
        XCTAssertFalse(authViewModel.isAuthenticated, "User should not be authenticated after failed login")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be set after failed login")
    }
    
    func testLogout() async {
        // Set up initial authenticated state
        mockAuthService.shouldSucceed = true
        await authViewModel.login(username: "test@example.com", password: "password")
        
        // Perform logout
        await authViewModel.logout()
        
        // Verify the logout was called and the state is updated
        XCTAssertTrue(mockAuthService.logoutCalled, "Logout method should be called")
        XCTAssertFalse(authViewModel.isAuthenticated, "User should not be authenticated after logout")
    }
}

// MARK: - Mock Auth Service Implementation
class MockAuthServiceImpl: AuthServiceProtocol {
    var loginCalled = false
    var logoutCalled = false
    var shouldSucceed = true
    var isLoggedIn = false
    
    func login(username: String, password: String) async throws -> Bool {
        loginCalled = true
        
        if shouldSucceed {
            isLoggedIn = true
            return true
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
    }
    
    func logout() async -> Bool {
        logoutCalled = true
        isLoggedIn = false
        return true
    }
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    @Inject private var authService: AuthServiceProtocol
    
    func login(username: String, password: String) async {
        do {
            isAuthenticated = try await authService.login(username: username, password: password)
            errorMessage = nil
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }
    
    func logout() async {
        let _ = await authService.logout()
        isAuthenticated = false
    }
}