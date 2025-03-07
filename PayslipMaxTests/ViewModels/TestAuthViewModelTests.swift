import XCTest
@testable import Payslip_Max

@MainActor
class TestAuthViewModelTests: XCTestCase {
    var mockSecurity: MockSecurityService!
    var sut: TestAuthViewModel!
    
    override func setUpWithError() throws {
        mockSecurity = MockSecurityService()
        sut = TestAuthViewModel(securityService: mockSecurity)
    }
    
    override func tearDownWithError() throws {
        mockSecurity = nil
        sut = nil
    }
    
    func testInit() {
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated initially")
        XCTAssertNil(sut.error, "Should not have an error initially")
    }
    
    func testAuthenticate_Success() async throws {
        // Given
        mockSecurity.shouldFail = false
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertTrue(sut.isAuthenticated, "Should be authenticated after successful authentication")
        XCTAssertNil(sut.error, "Should not have an error after successful authentication")
        XCTAssertEqual(mockSecurity.authenticateCount, 1, "Should call authenticate once")
    }
    
    func testAuthenticate_Failure() async throws {
        // Given
        mockSecurity.shouldFail = true
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated, "Should not be authenticated after failed authentication")
        XCTAssertNotNil(sut.error, "Should have an error after failed authentication")
        XCTAssertEqual(mockSecurity.authenticateCount, 1, "Should call authenticate once")
    }
} 