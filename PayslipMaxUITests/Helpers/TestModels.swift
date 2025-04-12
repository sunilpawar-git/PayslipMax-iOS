import Foundation
import XCTest

// MARK: - Protocols

/// Protocol for payslip items
protocol PayslipItemProtocol: Identifiable {
    var id: UUID { get set }
    var month: String { get set }
    var year: Int { get set }
    var credits: Double { get set }
    var debits: Double { get set }
    var dsop: Double { get set }
    var tax: Double { get set }
    var name: String { get set }
    var accountNumber: String { get set }
    var panNumber: String { get set }
    var timestamp: Date { get set }
    var earnings: [String: Double] { get set }
    var deductions: [String: Double] { get set }
    
    func encryptSensitiveData() throws
    func decryptSensitiveData() throws
}

/// Protocol for payslip items
protocol PayslipProtocol: PayslipItemProtocol {
    var id: UUID { get set }
    var month: String { get set }
    var year: Int { get set }
    var credits: Double { get set }
    var debits: Double { get set }
    var dsop: Double { get set }
    var tax: Double { get set }
    var name: String { get set }
    var accountNumber: String { get set }
    var panNumber: String { get set }
    var timestamp: Date { get set }
    var earnings: [String: Double] { get set }
    var deductions: [String: Double] { get set }
    
    func encryptSensitiveData() throws
    func decryptSensitiveData() throws
}

// MARK: - Test Models

/// Test-specific implementation of PayslipItem for use in UI tests
class TestPayslipItem: PayslipItemProtocol {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    
    // Private flags for sensitive data encryption status
    private var isNameEncrypted: Bool = false
    private var isAccountNumberEncrypted: Bool = false
    private var isPanNumberEncrypted: Bool = false
    
    init(
        id: UUID = UUID(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        name: String,
        accountNumber: String,
        panNumber: String,
        timestamp: Date = Date(),
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:]
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
        self.earnings = earnings
        self.deductions = deductions
    }
    
    // Helper to create a sample test payslip item
    static func sample() -> TestPayslipItem {
        let testItem = TestPayslipItem(
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Add sample earnings and deductions
        testItem.earnings = [
            "Basic Pay": 3000.0,
            "DA": 1500.0,
            "MSP": 500.0
        ]
        
        testItem.deductions = [
            "DSOP": 500.0,
            "ITAX": 800.0,
            "AGIF": 200.0
        ]
        
        return testItem
    }
    
    // Implementation of PayslipItemProtocol methods
    func encryptSensitiveData() throws {
        if !isNameEncrypted {
            name = "ENCRYPTED_" + name
            isNameEncrypted = true
        }
        
        if !isAccountNumberEncrypted {
            accountNumber = "ENCRYPTED_" + accountNumber
            isAccountNumberEncrypted = true
        }
        
        if !isPanNumberEncrypted {
            panNumber = "ENCRYPTED_" + panNumber
            isPanNumberEncrypted = true
        }
    }
    
    func decryptSensitiveData() throws {
        if isNameEncrypted {
            name = name.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isNameEncrypted = false
        }
        
        if isAccountNumberEncrypted {
            accountNumber = accountNumber.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isAccountNumberEncrypted = false
        }
        
        if isPanNumberEncrypted {
            panNumber = panNumber.replacingOccurrences(of: "ENCRYPTED_", with: "")
            isPanNumberEncrypted = false
        }
    }
}

// MARK: - Mock View Models

/// Mock Auth View Model
class MockAuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage = ""
    
    private let securityService: MockSecurityService
    
    init(securityService: MockSecurityService) {
        self.securityService = securityService
    }
    
    func authenticate() {
        isAuthenticated = securityService.authenticate()
    }
    
    func logout() {
        securityService.logout()
        isAuthenticated = false
    }
}

/// Mock Home View Model
class MockHomeViewModel: ObservableObject {
    @Published var payslips: [TestPayslipItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let dataService: MockDataService
    private let pdfService: MockPDFService
    
    init(dataService: MockDataService, pdfService: MockPDFService) {
        self.dataService = dataService
        self.pdfService = pdfService
        loadPayslips()
    }
    
    func loadPayslips() {
        isLoading = true
        payslips = dataService.payslips.compactMap { $0 as? TestPayslipItem }
        isLoading = false
    }
}

/// Mock Payslips View Model
class MockPayslipsViewModel: ObservableObject {
    @Published var payslips: [TestPayslipItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        loadPayslips()
    }
    
    func loadPayslips() {
        isLoading = true
        payslips = dataService.payslips.compactMap { $0 as? TestPayslipItem }
        isLoading = false
    }
}

/// Mock Insights View Model
class MockInsightsViewModel: ObservableObject {
    @Published var payslips: [TestPayslipItem] = []
    @Published var isLoading = false
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService) {
        self.dataService = dataService
        loadPayslips()
    }
    
    func loadPayslips() {
        isLoading = true
        payslips = dataService.payslips.compactMap { $0 as? TestPayslipItem }
        isLoading = false
    }
}

/// Mock Security View Model
class MockSecurityViewModel: ObservableObject {
    @Published var isBiometricEnabled = true
    @Published var hasPIN = true
    
    private let securityService: MockSecurityService
    
    init(securityService: MockSecurityService) {
        self.securityService = securityService
    }
}

/// Mock Settings View Model
class MockSettingsViewModel: ObservableObject {
    @Published var darkModeEnabled = false
    @Published var notificationsEnabled = true
    
    func toggleDarkMode() {
        darkModeEnabled.toggle()
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
    }
}

/// Mock Payslip Detail View Model
class MockPayslipDetailViewModel: ObservableObject {
    @Published var payslip: TestPayslipItem
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let dataService: MockDataService
    
    init(payslip: TestPayslipItem, dataService: MockDataService) {
        self.payslip = payslip
        self.dataService = dataService
    }
    
    func loadPayslip() {
        // No-op in the mock
    }
    
    func deletePayslip() {
        isLoading = true
        do {
            try dataService.delete(payslip)
            isLoading = false
        } catch {
            errorMessage = "Failed to delete payslip: \(error.localizedDescription)"
            isLoading = false
        }
    }
} 