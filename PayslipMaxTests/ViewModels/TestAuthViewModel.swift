import Foundation
import XCTest
@testable import Payslip_Max

// A test-specific version of the AuthViewModel that doesn't rely on the main app's DI system
@MainActor
class TestAuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    let securityService: MockSecurityService
    
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