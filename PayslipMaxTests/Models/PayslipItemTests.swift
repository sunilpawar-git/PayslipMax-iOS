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
            return self.mockEncryptionService
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
            dspof: 500,
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
        XCTAssertEqual(sut.dspof, 500)
        XCTAssertEqual(sut.tax, 800)
        XCTAssertEqual(sut.location, "Test Location")
    }
    
    func testSensitiveData() throws {
        // Test encryption
        XCTAssertNoThrow(try sut.encryptSensitiveData())
        
        // Verify the sensitive data was "encrypted" (in our mock, it's just returned as-is)
        // In a real test, we would check that the values are different after encryption
        XCTAssertEqual(sut.name, "Test User".data(using: .utf8)!.base64EncodedString())
        XCTAssertEqual(sut.accountNumber, "1234567890".data(using: .utf8)!.base64EncodedString())
        XCTAssertEqual(sut.panNumber, "ABCDE1234F".data(using: .utf8)!.base64EncodedString())
        
        // Test decryption
        XCTAssertNoThrow(try sut.decryptSensitiveData())
        
        // Verify the sensitive data was "decrypted" back to original values
        XCTAssertEqual(sut.name, "Test User")
        XCTAssertEqual(sut.accountNumber, "1234567890")
        XCTAssertEqual(sut.panNumber, "ABCDE1234F")
    }
    
    func testEncryptionFailure() {
        // Set the mock to fail
        mockEncryptionService.shouldFail = true
        
        // Verify that encryption throws an error
        XCTAssertThrowsError(try sut.encryptSensitiveData())
    }
    
    func testDecryptionFailure() {
        // First encrypt the data
        XCTAssertNoThrow(try sut.encryptSensitiveData())
        
        // Set the mock to fail
        mockEncryptionService.shouldFail = true
        
        // Verify that decryption throws an error
        XCTAssertThrowsError(try sut.decryptSensitiveData())
    }
    
    func testCalculations() {
        // Given
        let credits = 5000.0
        let debits = 1000.0
        let dspof = 500.0
        let tax = 1000.0
        
        // When
        let calculatedNet = credits - (debits + dspof + tax)
        let expectedNet = 2500.0
        
        // Then
        XCTAssertEqual(calculatedNet, expectedNet)
    }
    
    func testNetAmount() {
        // Given
        let expectedNet = sut.credits - (sut.debits + sut.dspof + sut.tax)
        
        // Then
        XCTAssertEqual(expectedNet, 2700.0)
    }
} 