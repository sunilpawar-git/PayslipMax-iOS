import XCTest
@testable import Payslip_Max

@MainActor
final class AuthViewModelTests: XCTestCase {
    private var sut: AuthViewModel!
    private var mockSecurity: MockSecurityService!
    
    override func setUpWithError() throws {
        mockSecurity = MockSecurityService()
        sut = AuthViewModel(securityService: mockSecurity)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockSecurity = nil
    }
    
    func testAuthenticate_Success() async throws {
        // Given
        XCTAssertFalse(sut.isAuthenticated)
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.error)
    }
    
    func testAuthenticate_Failure() async throws {
        // Given
        mockSecurity.shouldFail = true
        
        // When
        await sut.authenticate()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.error)
    }
} 