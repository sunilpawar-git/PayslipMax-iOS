import XCTest
@testable import Payslip_Max

@MainActor
final class PayslipItemTests: XCTestCase {
    
    var sut: PayslipItem!
    var mockSecurityService: MockSecurityService!
    var mockEncryptionService: MockEncryptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockSecurityService = MockSecurityService()
        mockEncryptionService = MockEncryptionService()
        
        // Set up the factory to use our mock
        let result = PayslipItem.setEncryptionServiceFactory { [unowned self] in
            return self.mockEncryptionService!
        }
        print("Test setup: Encryption service factory configured with result: \(result)")
        
        // Set up the DI container with mock services
        let testContainer = DIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        // Create a test instance with known values
        sut = PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000,
            debits: 1000,
            dsop: 500,
            tax: 800,
            location: "Test Location",
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    override func tearDown() async throws {
        // Reset the factory to default implementation
        PayslipItem.resetEncryptionServiceFactory()
        
        sut = nil
        mockSecurityService = nil
        mockEncryptionService = nil
        DIContainer.resetToDefault()
        try await super.tearDown()
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
        XCTAssertEqual(sut.year, 2025)
        XCTAssertEqual(sut.credits, 5000)
        XCTAssertEqual(sut.debits, 1000)
        XCTAssertEqual(sut.dsop, 500)
        XCTAssertEqual(sut.tax, 800)
        XCTAssertEqual(sut.location, "Test Location")
    }
    
    func testSensitiveData() throws {
        // Reset the counts before testing
        mockEncryptionService.encryptionCount = 0
        mockEncryptionService.decryptionCount = 0
        
        // Test encryption
        XCTAssertNoThrow(try sut.encryptSensitiveData())
        
        // Verify the encryption count
        XCTAssertEqual(mockEncryptionService.encryptionCount, 3, "Encryption should be called 3 times (name, accountNumber, panNumber)")
        
        // Verify the sensitive data was "encrypted" (in our mock, it's just returned as-is)
        // In a real test, we would check that the values are different after encryption
        XCTAssertEqual(sut.name, "Test User".data(using: .utf8)!.base64EncodedString())
        XCTAssertEqual(sut.accountNumber, "1234567890".data(using: .utf8)!.base64EncodedString())
        XCTAssertEqual(sut.panNumber, "ABCDE1234F".data(using: .utf8)!.base64EncodedString())
        
        // Reset the counts before testing decryption
        mockEncryptionService.encryptionCount = 0
        mockEncryptionService.decryptionCount = 0
        
        // Test decryption
        XCTAssertNoThrow(try sut.decryptSensitiveData())
        
        // Verify the decryption count
        XCTAssertEqual(mockEncryptionService.decryptionCount, 3, "Decryption should be called 3 times (name, accountNumber, panNumber)")
        
        // Verify the sensitive data was "decrypted" back to original values
        XCTAssertEqual(sut.name, "Test User")
        XCTAssertEqual(sut.accountNumber, "1234567890")
        XCTAssertEqual(sut.panNumber, "ABCDE1234F")
    }
    
    func testEncryptionFailure() {
        // Set the mock to fail
        mockEncryptionService.shouldFail = true
        
        // Verify that encryption throws an error
        XCTAssertThrowsError(try sut.encryptSensitiveData()) { error in
            // Verify that the error is of the expected type
            XCTAssertTrue(error is MockSecurityError, "Error should be a MockSecurityError")
            if let mockError = error as? MockSecurityError {
                XCTAssertEqual(mockError, MockSecurityError.encryptionFailed, "Error should be encryptionFailed")
            }
        }
    }
    
    func testDecryptionFailure() {
        // First encrypt the data
        XCTAssertNoThrow(try sut.encryptSensitiveData())
        
        // Set the mock to fail
        mockEncryptionService.shouldFail = true
        
        // Verify that decryption throws an error
        XCTAssertThrowsError(try sut.decryptSensitiveData()) { error in
            // Verify that the error is of the expected type
            XCTAssertTrue(error is MockSecurityError, "Error should be a MockSecurityError")
            if let mockError = error as? MockSecurityError {
                XCTAssertEqual(mockError, MockSecurityError.decryptionFailed, "Error should be decryptionFailed")
            }
        }
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
        customMockService.shouldFail = true
        
        // When
        let result = PayslipItem.setEncryptionServiceFactory { 
            return customMockService
        }
        
        // Then
        XCTAssertNotNil(result, "Factory should return a non-nil result")
        
        // Create a new payslip item
        let newPayslip = PayslipItem(
            month: "February",
            year: 2025,
            credits: 6000,
            debits: 1200,
            dsop: 600,
            tax: 900,
            location: "Another Location",
            name: "Another User",
            accountNumber: "0987654321",
            panNumber: "ZYXWV9876G"
        )
        
        // Verify that encryption throws an error (because our custom mock is set to fail)
        XCTAssertThrowsError(try newPayslip.encryptSensitiveData()) { error in
            XCTAssertTrue(error is MockSecurityError, "Error should be a MockSecurityError")
        }
        
        // Reset the factory to default
        PayslipItem.resetEncryptionServiceFactory()
    }
    
    func testLegacyEncryptionFallback() throws {
        // Create a custom factory that will cause the handler creation to fail
        let originalFactory = PayslipSensitiveDataHandler.Factory.setEncryptionServiceFactory {
            // Return a non-SensitiveDataEncryptionService object to cause the cast to fail
            return "Not an encryption service"
        }
        
        // Create a new payslip item
        let newPayslip = PayslipItem(
            month: "March",
            year: 2025,
            credits: 7000,
            debits: 1400,
            dsop: 700,
            tax: 1000,
            location: "Third Location",
            name: "Third User",
            accountNumber: "1122334455",
            panNumber: "PQRST5678H"
        )
        
        // Set up the factory to use our mock for the legacy methods
        let factoryResult = PayslipItem.setEncryptionServiceFactory { [unowned self] in
            return self.mockEncryptionService!
        }
        XCTAssertNotNil(factoryResult, "Factory result should not be nil")
        
        // Test encryption (should fall back to legacy method)
        XCTAssertNoThrow(try newPayslip.encryptSensitiveData())
        
        // Verify the sensitive data was encrypted
        XCTAssertNotEqual(newPayslip.name, "Third User")
        XCTAssertNotEqual(newPayslip.accountNumber, "1122334455")
        XCTAssertNotEqual(newPayslip.panNumber, "PQRST5678H")
        
        // Test decryption (should fall back to legacy method)
        XCTAssertNoThrow(try newPayslip.decryptSensitiveData())
        
        // Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(newPayslip.name, "Third User")
        XCTAssertEqual(newPayslip.accountNumber, "1122334455")
        XCTAssertEqual(newPayslip.panNumber, "PQRST5678H")
        
        // Reset the factory to default
        PayslipSensitiveDataHandler.Factory.resetEncryptionServiceFactory()
        PayslipItem.resetEncryptionServiceFactory()
    }
} 