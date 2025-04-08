import Foundation
import XCTest

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
class AuthViewModelTests: XCTestCase {
    var mockSecurity: MockSecurityService!
    var viewModel: AuthViewModel!
    
    override func setUp() {
        super.setUp()
        mockSecurity = MockSecurityService()
        viewModel = AuthViewModel(securityService: mockSecurity)
    }
    
    override func tearDown() {
        mockSecurity = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.error)
    }
    
    func testAuthenticate_Success() async {
        // Given
        mockSecurity.shouldFail = false
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(mockSecurity.authenticateCount, 1)
    }
    
    func testAuthenticate_Failure() async {
        // Given
        mockSecurity.shouldFail = true
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(mockSecurity.authenticateCount, 1)
    }
} 