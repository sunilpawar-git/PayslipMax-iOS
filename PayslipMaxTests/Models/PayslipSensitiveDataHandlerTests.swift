import XCTest
@testable import Payslip_Max

@MainActor
final class PayslipSensitiveDataHandlerTests: XCTestCase {
    
    var sut: PayslipSensitiveDataHandler!
    var mockEncryptionService: MockEncryptionService!
    
    override func setUp() {
        super.setUp()
        mockEncryptionService = MockEncryptionService()
        sut = PayslipSensitiveDataHandler(encryptionService: mockEncryptionService)
    }
    
    override func tearDown() {
        sut = nil
        mockEncryptionService = nil
        super.tearDown()
    }
    
    func testEncryptString() throws {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        
        // When
        let encrypted = try sut.encryptString(testString, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, testString)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 1)
    }
    
    func testDecryptString() throws {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        let encrypted = try sut.encryptString(testString, fieldName: fieldName)
        
        // When
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertEqual(decrypted, testString)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 1)
    }
    
    func testEncryptStringFailure() {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        mockEncryptionService.shouldFailEncryption = true
        
        // Then
        XCTAssertThrowsError(try sut.encryptString(testString, fieldName: fieldName)) { error in
            // Check if error is of the expected type and value
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .encryptionFailed)
            } else {
                XCTFail("Expected EncryptionService.EncryptionError but got \(type(of: error))")
            }
        }
    }
    
    func testDecryptStringFailure() throws {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        let encrypted = try sut.encryptString(testString, fieldName: fieldName)
        mockEncryptionService.shouldFailDecryption = true
        
        // Then
        XCTAssertThrowsError(try sut.decryptString(encrypted, fieldName: fieldName)) { error in
            // Check if error is of the expected type and value
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .decryptionFailed)
            } else {
                XCTFail("Expected EncryptionService.EncryptionError but got \(type(of: error))")
            }
        }
    }
    
    func testKeyManagementFailure() {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        mockEncryptionService.shouldFailKeyManagement = true
        
        // Then
        XCTAssertThrowsError(try sut.encryptString(testString, fieldName: fieldName)) { error in
            // Check if error is of the expected type and value
            if let encryptionError = error as? EncryptionService.EncryptionError {
                XCTAssertEqual(encryptionError, .keyNotFound)
            } else {
                XCTFail("Expected EncryptionService.EncryptionError but got \(type(of: error))")
            }
        }
    }
    
    func testEncryptSensitiveFields() throws {
        // Given
        let name = "John Doe"
        let accountNumber = "1234567890"
        let panNumber = "ABCDE1234F"
        
        // When
        let result = try sut.encryptSensitiveFields(name: name, accountNumber: accountNumber, panNumber: panNumber)
        
        // Then
        XCTAssertNotEqual(result.name, name)
        XCTAssertNotEqual(result.accountNumber, accountNumber)
        XCTAssertNotEqual(result.panNumber, panNumber)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 3)
    }
    
    func testDecryptSensitiveFields() throws {
        // Given
        let name = "John Doe"
        let accountNumber = "1234567890"
        let panNumber = "ABCDE1234F"
        let encrypted = try sut.encryptSensitiveFields(name: name, accountNumber: accountNumber, panNumber: panNumber)
        
        // When
        let result = try sut.decryptSensitiveFields(name: encrypted.name, accountNumber: encrypted.accountNumber, panNumber: encrypted.panNumber)
        
        // Then
        XCTAssertEqual(result.name, name)
        XCTAssertEqual(result.accountNumber, accountNumber)
        XCTAssertEqual(result.panNumber, panNumber)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 3)
    }
    
    func testFactoryCreation() throws {
        // Given
        let factory = PayslipSensitiveDataHandler.Factory.self
        
        // When
        let handler = try factory.create()
        
        // Then
        XCTAssertNotNil(handler)
    }
    
    func testFactoryCustomService() throws {
        // Given
        let factory = PayslipSensitiveDataHandler.Factory.self
        let customService = MockEncryptionService()
        
        // When
        _ = factory.setSensitiveDataEncryptionServiceFactory { customService as EncryptionServiceProtocolInternal }
        let handler = try factory.create()
        
        // Then
        XCTAssertNotNil(handler)
        
        // Test that the custom service is used
        let _ = try handler.encryptString("test", fieldName: "test")
        XCTAssertEqual(customService.encryptionCount, 1)
    }
    
    func testFactoryReset() async throws {
        // Given
        let factory = PayslipSensitiveDataHandler.Factory.self
        let customService = MockEncryptionService()
        
        // When
        _ = factory.setSensitiveDataEncryptionServiceFactory { customService as EncryptionServiceProtocolInternal }
        factory.resetSensitiveDataEncryptionServiceFactory()
        
        // Wait for the reset to take effect
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let handler = try factory.create()
        
        // Then
        XCTAssertNotNil(handler)
        
        // Test that the default service is used
        let _ = try handler.encryptString("test", fieldName: "test")
        XCTAssertEqual(customService.encryptionCount, 0)
    }
    
    func testEmptyStringHandling() throws {
        // Given
        let emptyString = ""
        let fieldName = "testField"
        
        // When
        let encrypted = try sut.encryptString(emptyString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertEqual(decrypted, emptyString)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 1)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 1)
    }
    
    func testSpecialCharacterHandling() throws {
        // Given
        let specialString = "!@#$%^&*()_+"
        let fieldName = "testField"
        
        // When
        let encrypted = try sut.encryptString(specialString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertEqual(decrypted, specialString)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 1)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 1)
    }
} 