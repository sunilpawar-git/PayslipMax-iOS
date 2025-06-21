import Foundation

// MARK: - Re-exported Mock Services
// This file now serves as a coordinator for all domain-specific mock services

// Import and re-export the domain-specific mock services
@_exported import MockSecurityServices
@_exported import MockPayslipServices  
@_exported import MockPDFServices
@_exported import MockTestCoordinator

// MARK: - Convenience Extensions for Testing

/// Main mock services facade for easy testing setup
class MockServicesFacade {
    static let shared = MockServicesFacade()
    
    let coordinator = MockTestCoordinator.shared
    
    private init() {}
    
    /// Reset all services to default state
    func resetAll() {
        coordinator.resetAllServices()
    }
    
    /// Configure all services for a specific test scenario
    func configure(for scenario: TestScenario) {
        coordinator.configureForTestScenario(scenario)
    }
}

// MARK: - Legacy Compatibility
// Maintain backward compatibility with existing test code

/// Legacy access to security service
var mockSecurityService: MockSecurityService {
    MockTestCoordinator.shared.securityService
}

/// Legacy access to data service
var mockDataService: MockDataService {
    MockTestCoordinator.shared.dataService
}

/// Legacy access to PDF service
var mockPDFService: MockPDFService {
    MockTestCoordinator.shared.pdfService
}

/// Legacy access to extractor service
var mockExtractorService: MockPDFExtractor {
    MockTestCoordinator.shared.extractorService
} 