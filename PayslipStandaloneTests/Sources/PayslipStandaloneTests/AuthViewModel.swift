import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let securityService: SecurityServiceProtocol
    
    init(securityService: SecurityServiceProtocol) {
        self.securityService = securityService
    }
    
    func authenticate() async {
        do {
            // Ensure the service is initialized
            if !securityService.isInitialized {
                try await securityService.initialize()
            }
            
            // Attempt authentication
            isAuthenticated = try await securityService.authenticate()
            error = nil
        } catch {
            isAuthenticated = false
            self.error = error
        }
    }
    
    func reset() {
        isAuthenticated = false
        error = nil
    }
} 