import Foundation
import Combine
@testable import Payslip_Max

@MainActor
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