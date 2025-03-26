import XCTest
@testable import Payslip_Max

@MainActor
final class EncryptionServiceAdapterTests: XCTestCase {
    
    var sut: EncryptionServiceAdapter!
    var mockService: MockEncryptionService!
    
    override func setUp() {
        super.setUp()
        mockService = MockEncryptionService()
        sut = EncryptionServiceAdapter(encryptionService: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    func testEncrypt() throws {
        // Given
        let testData = "Test Data".data(using: .utf8)!
        
        // When
        let encrypted = try sut.encrypt(testData)
        
        // Then
        XCTAssertNotEqual(encrypted, testData)
        XCTAssertEqual(mockService.encryptionCount, 1)
        XCTAssertEqual(mockService.lastEncryptedData, testData)
    }
    
    func testDecrypt() throws {
        // Given
        let testData = "Test Data".data(using: .utf8)!
        let encrypted = try sut.encrypt(testData)
        
        // When
        let decrypted = try sut.decrypt(encrypted)
        
        // Then
        XCTAssertEqual(decrypted, testData)
        XCTAssertEqual(mockService.decryptionCount, 1)
        XCTAssertEqual(mockService.lastDecryptedData, encrypted)
    }
    
    func testEncryptFailure() {
        // Given
        let testData = "Test Data".data(using: .utf8)!
        mockService.shouldFailEncryption = true
        
        // Then
        XCTAssertThrowsError(try sut.encrypt(testData)) { error in
            XCTAssertTrue(error is MockEncryptionError)
        }
    }
    
    func testDecryptFailure() throws {
        // Given
        let testData = "Test Data".data(using: .utf8)!
        let encrypted = try sut.encrypt(testData)
        mockService.shouldFailDecryption = true
        
        // Then
        XCTAssertThrowsError(try sut.decrypt(encrypted)) { error in
            XCTAssertTrue(error is MockEncryptionError)
        }
    }
    
    func testProtocolConformance() {
        // Given
        let adapter = EncryptionServiceAdapter(encryptionService: mockService)
        
        // Then
        XCTAssertTrue(adapter is SensitiveDataEncryptionService)
        XCTAssertTrue(adapter is EncryptionServiceProtocolInternal)
    }
} 