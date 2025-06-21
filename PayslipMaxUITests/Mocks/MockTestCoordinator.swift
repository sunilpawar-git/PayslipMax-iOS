import Foundation

/// Coordinator for managing all mock services in tests
class MockTestCoordinator {
    // MARK: - Service Dependencies
    let securityService: MockSecurityService
    let dataService: MockDataService
    let pdfService: MockPDFService
    let extractorService: MockPDFExtractor
    
    /// Initialization with default services
    init() {
        self.securityService = MockSecurityService()
        self.dataService = MockDataService()
        self.pdfService = MockPDFService()
        self.extractorService = MockPDFExtractor()
    }
    
    /// Reset all services to default state
    func resetAllServices() {
        securityService.reset()
        dataService.reset()
        pdfService.reset()
        extractorService.reset()
    }
    
    /// Configure services for specific test scenarios
    func configureForTestScenario(_ scenario: TestScenario) {
        switch scenario {
        case .successfulAuthentication:
            securityService.isValidBiometricAuth = true
            securityService.isAuthenticated = true
            
        case .failedAuthentication:
            securityService.isValidBiometricAuth = false
            securityService.isAuthenticated = false
            
        case .encryptionError:
            securityService.encryptionError = NSError(
                domain: "TestError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Mock encryption error"]
            )
            
        case .dataServiceError:
            dataService.fetchError = NSError(
                domain: "TestError",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Mock data service error"]
            )
            
        case .pdfProcessingError:
            pdfService.processPDFError = NSError(
                domain: "TestError",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "Mock PDF processing error"]
            )
            
        case .extractionError:
            extractorService.extractionError = NSError(
                domain: "TestError",
                code: 1004,
                userInfo: [NSLocalizedDescriptionKey: "Mock extraction error"]
            )
        }
    }
}

/// Test scenarios for mock configuration
enum TestScenario {
    case successfulAuthentication
    case failedAuthentication
    case encryptionError
    case dataServiceError
    case pdfProcessingError
    case extractionError
}

/// Shared test coordinator instance
extension MockTestCoordinator {
    static let shared = MockTestCoordinator()
} 