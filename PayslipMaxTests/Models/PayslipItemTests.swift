import XCTest
@testable import Payslip_Max

@MainActor
final class PayslipItemTests: XCTestCase {
    
    var sut: PayslipItem!
    var mockSecurityService: MockSecurityService!
    var mockEncryptionService: MockEncryptionService!
    var testContainer: TestDIContainer!
    
    override func setUp() {
        super.setUp()
        
        // Create a mock encryption service
        mockEncryptionService = MockEncryptionService()
        
        // Configure the encryption service factory to return our mock
        _ = PayslipItem.setEncryptionServiceFactory { [self] in
            return mockEncryptionService as EncryptionServiceProtocolInternal
        }
        
        // Create a test instance with known values
        sut = PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
        
        // Add test earnings and deductions
        sut.earnings = [
            "Basic Pay": 3000.0,
            "DA": 1500.0,
            "MSP": 500.0
        ]
        
        sut.deductions = [
            "DSOP": 500.0,
            "ITAX": 800.0,
            "AGIF": 200.0
        ]
    }
    
    override func tearDown() {
        PayslipItem.resetEncryptionServiceFactory()
        super.tearDown()
    }
    
    func testSimpleCalculation() {
        // This test doesn't rely on any external services
        let a = 10
        let b = 20
        XCTAssertEqual(a + b, 30, "Basic addition should work")
    }
    
    func testInitialization() {
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.month, "January")
        XCTAssertEqual(sut.year, 2024)
        XCTAssertEqual(sut.credits, 5000.0)
        XCTAssertEqual(sut.debits, 1000.0)
        XCTAssertEqual(sut.dsop, 500.0)
        XCTAssertEqual(sut.tax, 800.0)
    }
    
    func testEncryptionAndDecryption() throws {
        // Given
        let originalName = "Test User"
        let originalAccountNumber = "1234567890"
        let originalPanNumber = "ABCDE1234F"
        
        // When - Test encryption
        try sut.encryptSensitiveData()
        
        // Then - Verify encryption flags are set
        XCTAssertTrue(sut.isNameEncrypted)
        XCTAssertTrue(sut.isAccountNumberEncrypted)
        XCTAssertTrue(sut.isPanNumberEncrypted)
        
        // Verify values are encrypted
        XCTAssertNotEqual(sut.name, originalName)
        XCTAssertNotEqual(sut.accountNumber, originalAccountNumber)
        XCTAssertNotEqual(sut.panNumber, originalPanNumber)
        
        // When - Test decryption
        try sut.decryptSensitiveData()
        
        // Then - Verify encryption flags are cleared
        XCTAssertFalse(sut.isNameEncrypted)
        XCTAssertFalse(sut.isAccountNumberEncrypted)
        XCTAssertFalse(sut.isPanNumberEncrypted)
        
        // Verify values are decrypted back to original
        XCTAssertEqual(sut.name, originalName)
        XCTAssertEqual(sut.accountNumber, originalAccountNumber)
        XCTAssertEqual(sut.panNumber, originalPanNumber)
        
        // Verify mock service was used
        XCTAssertEqual(mockEncryptionService.encryptionCount, 3, "Encryption should be called 3 times")
        XCTAssertEqual(mockEncryptionService.decryptionCount, 3, "Decryption should be called 3 times")
    }
    
    func testEncryptionFailure() throws {
        // Given
        mockEncryptionService.shouldFailEncryption = true
        
        // Then
        XCTAssertThrowsError(try sut.encryptSensitiveData()) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
        }
    }
    
    func testDecryptionFailure() throws {
        // Given
        try sut.encryptSensitiveData()
        mockEncryptionService.shouldFailDecryption = true
        
        // Then
        XCTAssertThrowsError(try sut.decryptSensitiveData()) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
        }
    }
    
    func testCustomEncryptionService() throws {
        // Given
        let customMockService = MockEncryptionService()
        PayslipItem.setEncryptionServiceFactory {
            return customMockService as EncryptionServiceProtocolInternal
        }
        
        // When
        try sut.encryptSensitiveData()
        
        // Then
        XCTAssertEqual(customMockService.encryptionCount, 3, "Encryption should be called 3 times")
    }
    
    func testResetEncryptionServiceFactory() {
        // Given
        PayslipItem.setEncryptionServiceFactory {
            return self.mockEncryptionService! as EncryptionServiceProtocolInternal
        }
        
        // When
        PayslipItem.resetEncryptionServiceFactory()
        
        // Then
        let newService = PayslipItem.getEncryptionServiceFactory()()
        XCTAssertNotNil(newService, "Factory should return a non-nil service")
        XCTAssertFalse(newService === mockEncryptionService, "Factory should return a new instance")
    }
    
    func testCalculations() {
        // Given
        let credits = 5000.0
        let debits = 1000.0
        let dsop = 500.0
        let tax = 800.0
        
        // When
        let calculatedNet = credits - (debits + dsop + tax)
        let expectedNet = sut.credits - (sut.debits + sut.dsop + sut.tax)
        
        // Then
        XCTAssertEqual(calculatedNet, expectedNet)
    }
    
    func testNetAmount() {
        // Given
        let expectedNet = sut.credits - (sut.debits + sut.dsop + sut.tax)
        
        // Then
        XCTAssertEqual(expectedNet, 2700.0)
    }
    
    func testEncryptionServiceFactory() {
        // Given
        let customMockService = MockEncryptionService()
        customMockService.shouldFailEncryption = true
        customMockService.shouldFailDecryption = true
        
        // When
        PayslipItem.setEncryptionServiceFactory { 
            return customMockService as EncryptionServiceProtocolInternal
        }
        
        // Then
        let factory = PayslipItem.getEncryptionServiceFactory()
        XCTAssertNotNil(factory)
        
        let service = factory()
        XCTAssertTrue(service === customMockService)
    }
    
    func testLegacyEncryptionFallback() throws {
        // Create a failing mock service for the handler
        let failingMockService = MockEncryptionService()
        failingMockService.shouldFailEncryption = true
        failingMockService.shouldFailDecryption = true
        
        // Set up the factory to use our failing mock for the handler
        let originalFactory = PayslipSensitiveDataHandler.Factory.setSensitiveDataEncryptionServiceFactory {
            return failingMockService as EncryptionServiceProtocolInternal
        }
        
        // Create a new payslip item
        let newPayslip = PayslipItem(
            month: "March",
            year: 2025,
            credits: 7000,
            debits: 1400,
            dsop: 700,
            tax: 1000,
            name: "Third User",
            accountNumber: "1122334455",
            panNumber: "PQRST5678H"
        )
        
        // Set up a working mock service for the legacy methods
        let workingMockService = MockEncryptionService()
        PayslipItem.setEncryptionServiceFactory {
            return workingMockService as EncryptionServiceProtocolInternal
        }
        
        // Test encryption (should use working mock service)
        try newPayslip.encryptSensitiveData()
        
        // Verify the sensitive data was encrypted
        XCTAssertNotEqual(newPayslip.name, "Third User")
        XCTAssertNotEqual(newPayslip.accountNumber, "1122334455")
        XCTAssertNotEqual(newPayslip.panNumber, "PQRST5678H")
        
        // Test decryption (should use working mock service)
        try newPayslip.decryptSensitiveData()
        
        // Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(newPayslip.name, "Third User")
        XCTAssertEqual(newPayslip.accountNumber, "1122334455")
        XCTAssertEqual(newPayslip.panNumber, "PQRST5678H")
        
        // Verify that the working mock service was used
        XCTAssertGreaterThan(workingMockService.encryptionCount, 0, "Working mock service should have been used for encryption")
        XCTAssertGreaterThan(workingMockService.decryptionCount, 0, "Working mock service should have been used for decryption")
        
        // Reset the factories to default
        PayslipSensitiveDataHandler.Factory.resetSensitiveDataEncryptionServiceFactory()
        PayslipItem.resetEncryptionServiceFactory()
    }
    
    func testPayslipItem() {
        // ... existing code ...
    }
} 