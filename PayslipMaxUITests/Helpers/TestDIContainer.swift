import Foundation
import XCTest
@testable import PayslipMax

// MARK: - UI Test Dependency Injection Container
class TestDIContainer {
    // Singleton instance for UI testing
    static let shared = TestDIContainer()
    
    // Mock services
    private(set) var securityService: MockSecurityService
    private(set) var dataService: MockDataService
    private(set) var pdfService: MockPDFService
    private(set) var pdfExtractor: MockPDFExtractor
    
    private init() {
        print("Initializing TestDIContainer for UI tests")
        
        // Create mock services
        securityService = MockSecurityService()
        dataService = MockDataService()
        pdfService = MockPDFService()
        pdfExtractor = MockPDFExtractor()
        
        // Setup test data if needed
        setupTestData()
    }
    
    // Setup initial test data
    private func setupTestData() {
        // Create sample payslips
        let samplePayslips = createSamplePayslips()
        dataService.payslips = samplePayslips
    }
    
    // Create sample payslips for testing
    func createSamplePayslips() -> [TestPayslipItem] {
        return [
            TestPayslipItem.sample(),
            TestPayslipItem(
                month: "February",
                year: 2025,
                credits: 5500.0,
                debits: 1200.0,
                dsop: 550.0,
                tax: 900.0,
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F"
            ),
            TestPayslipItem(
                month: "March",
                year: 2025,
                credits: 5200.0,
                debits: 1100.0,
                dsop: 520.0,
                tax: 850.0,
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F"
            )
        ]
    }
    
    // MARK: - Factory Methods
    
    // Create AuthViewModel for authentication
    func makeAuthViewModel() -> MockAuthViewModel {
        return MockAuthViewModel(securityService: securityService)
    }
    
    // Create HomeViewModel for the home screen
    func makeHomeViewModel() -> MockHomeViewModel {
        return MockHomeViewModel(dataService: dataService, pdfService: pdfService)
    }
    
    // Create PayslipsViewModel for payslip listing
    func makePayslipsViewModel() -> MockPayslipsViewModel {
        return MockPayslipsViewModel(dataService: dataService)
    }
    
    // Create InsightsCoordinator for insights and analytics
    @MainActor func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: dataService)
    }
    
    // Create SecurityViewModel for security settings
    func makeSecurityViewModel() -> MockSecurityViewModel {
        return MockSecurityViewModel(securityService: securityService)
    }
    
    // Create SettingsViewModel for app settings
    func makeSettingsViewModel() -> MockSettingsViewModel {
        return MockSettingsViewModel()
    }
    
    // Create PayslipDetailViewModel for detailed payslip view
    func makePayslipDetailViewModel(payslip: TestPayslipItem) -> MockPayslipDetailViewModel {
        return MockPayslipDetailViewModel(payslip: payslip, dataService: dataService)
    }
}

// ViewModels for UI tests - simplified versions
class AuthViewModel {
    let securityService: MockSecurityService?
    
    init(securityService: MockSecurityService?) {
        self.securityService = securityService
    }
}

class HomeViewModel {
    let dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
    }
}

class PayslipsViewModel {
    let dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
    }
}

class InsightsViewModel {
    let dataService: MockDataService?
    
    init(dataService: MockDataService?) {
        self.dataService = dataService
    }
}

class SecurityViewModel {
    init() {}
}

class SettingsViewModel {
    let securityService: MockSecurityService?
    let dataService: MockDataService?
    
    init(securityService: MockSecurityService?, dataService: MockDataService?, userDefaults: UserDefaults = .standard) {
        self.securityService = securityService
        self.dataService = dataService
    }
}

class PayslipDetailViewModel {
    let payslip: TestPayslipItem
    let securityService: MockSecurityService?
    let dataService: MockDataService?
    
    init(payslip: TestPayslipItem, securityService: MockSecurityService?, dataService: MockDataService?) {
        self.payslip = payslip
        self.securityService = securityService
        self.dataService = dataService
    }
} 