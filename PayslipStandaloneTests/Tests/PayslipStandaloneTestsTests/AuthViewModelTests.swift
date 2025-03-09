import XCTest
@testable import PayslipStandaloneTests

@MainActor
final class AuthViewModelTests: XCTestCase {
    var mockSecurityService: MockSecurityService!
    var viewModel: AuthViewModel!
    
    override func setUp() async throws {
        mockSecurityService = MockSecurityService()
        viewModel = AuthViewModel(securityService: mockSecurityService)
    }
    
    override func tearDown() async throws {
        mockSecurityService = nil
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isAuthenticated, "ViewModel should not be authenticated initially")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error initially")
    }
    
    func testAuthenticate_Success() async {
        // Given
        mockSecurityService.shouldAuthenticateSuccessfully = true
        mockSecurityService.shouldFail = false
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "ViewModel should be authenticated after successful authentication")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful authentication")
        XCTAssertEqual(mockSecurityService.authenticateCount, 1, "authenticate() should be called once")
        XCTAssertEqual(mockSecurityService.initializeCount, 1, "initialize() should be called once")
    }
    
    func testAuthenticate_Failure() async {
        // Given
        mockSecurityService.shouldFail = true
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "ViewModel should not be authenticated after failed authentication")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed authentication")
        XCTAssertEqual(mockSecurityService.initializeCount, 1, "initialize() should be called once")
    }
    
    func testAuthenticate_ServiceAlreadyInitialized() async {
        // Given
        mockSecurityService.isInitialized = true
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated, "ViewModel should be authenticated after successful authentication")
        XCTAssertEqual(mockSecurityService.initializeCount, 0, "initialize() should not be called if service is already initialized")
        XCTAssertEqual(mockSecurityService.authenticateCount, 1, "authenticate() should be called once")
    }
    
    func testReset() async {
        // Given
        mockSecurityService.shouldAuthenticateSuccessfully = true
        await viewModel.authenticate()
        XCTAssertTrue(viewModel.isAuthenticated, "ViewModel should be authenticated after successful authentication")
        
        // When
        viewModel.reset()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "ViewModel should not be authenticated after reset")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after reset")
    }
    
    func testAuthenticate_AuthenticationFailsWithError() async {
        // Given
        mockSecurityService.shouldFail = true
        
        // When
        await viewModel.authenticate()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "ViewModel should not be authenticated after failed authentication")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed authentication")
        
        if let error = viewModel.error as? MockError {
            XCTAssertEqual(error, MockError.initializationFailed, "Error should be initializationFailed")
        } else {
            XCTFail("Error should be a MockError")
        }
    }
} 