import XCTest
@testable import PayslipMax

@MainActor
class TestAuthViewModelTests: XCTestCase {
    // Properties
    var mockSecurity: MockSecurityService!
    var sut: TestAuthViewModel!
    
    // Setup
    override func setUp() async throws {
        try await super.setUp()
        mockSecurity = MockSecurityService()
        sut = TestAuthViewModel(securityService: mockSecurity)
    }
    
    // Teardown
    override func tearDown() {
        mockSecurity = nil
        sut = nil
        super.tearDown()
    }
    
    // Test initial state
    func testInit() {
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.error)
    }
    
    // Test successful authentication
    func testAuthenticate_Success() async {
        // Given
        mockSecurity.shouldAuthenticateSuccessfully = true
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.error)
        XCTAssertEqual(mockSecurity.authenticateCount, 1)
    }
    
    // Test failed authentication
    func testAuthenticate_Failure() async {
        // Given
        mockSecurity.shouldFail = true
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(mockSecurity.authenticateCount, 1)
    }
} 