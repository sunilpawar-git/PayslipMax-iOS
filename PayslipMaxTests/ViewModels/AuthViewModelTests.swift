import XCTest
@testable import Payslip_Max

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
} 