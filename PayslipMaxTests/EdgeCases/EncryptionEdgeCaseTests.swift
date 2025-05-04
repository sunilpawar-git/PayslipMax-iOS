import XCTest
@testable import PayslipMax
import PayslipMaxTestMocks

@MainActor
final class EncryptionEdgeCaseTests: XCTestCase {
    
    // System under test
    var sut: PayslipSensitiveDataHandler!
    var mockEncryptionService: MockEncryptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockEncryptionService = MockEncryptionService()
        
        // Create the sensitive data handler
        sut = PayslipSensitiveDataHandler(encryptionService: mockEncryptionService)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockEncryptionService = nil
        try await super.tearDown()
    }
    
    // MARK: - Edge Case Tests
    
    /// Tests encryption/decryption of empty strings
    func testEncryptDecryptEmptyString() throws {
        // Given
        let emptyString = ""
        let fieldName = "testField"
        
        // When
        let encrypted = try sut.encryptString(emptyString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, emptyString, "Encrypted empty string should not be empty")
        XCTAssertEqual(decrypted, emptyString, "Decrypted string should match original empty string")
    }
    
    /// Tests encryption/decryption of very large strings
    func testEncryptDecryptVeryLargeString() throws {
        // Given
        let largeString = String(repeating: "A", count: 1_000_000) // 1 million characters
        let fieldName = "largeField"
        
        // When
        let encrypted = try sut.encryptString(largeString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, largeString, "Encrypted large string should be different")
        XCTAssertEqual(decrypted, largeString, "Decrypted string should match original large string")
    }
    
    /// Tests encryption/decryption of strings with special characters
    func testEncryptDecryptSpecialCharacters() throws {
        // Given
        let specialString = "!@#$%^&*()_+{}|:\"<>?~`-=[]\\;',./—–ß∫ç√∂ƒ©˙∆˚¬…æœ«πøˆ¨¥†®´∑œåß∂ƒ©"
        let fieldName = "specialCharsField"
        
        // When
        let encrypted = try sut.encryptString(specialString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, specialString, "Encrypted special string should be different")
        XCTAssertEqual(decrypted, specialString, "Decrypted string should match original special string")
    }
    
    /// Tests encryption/decryption of strings with emojis and non-ASCII characters
    func testEncryptDecryptEmojisAndUnicode() throws {
        // Given
        let unicodeString = "Hello 😀👍🏼🌍 World! こんにちは 你好 안녕하세요 Привет"
        let fieldName = "unicodeField"
        
        // When
        let encrypted = try sut.encryptString(unicodeString, fieldName: fieldName)
        let decrypted = try sut.decryptString(encrypted, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, unicodeString, "Encrypted unicode string should be different")
        XCTAssertEqual(decrypted, unicodeString, "Decrypted string should match original unicode string")
    }
    
    /// Tests behavior when the encrypted string is not a valid base64 string
    func testDecryptInvalidBase64String() {
        // Given
        let invalidBase64 = "This is not valid base64!@#$"
        let fieldName = "invalidField"
        
        // Then
        XCTAssertThrowsError(try sut.decryptString(invalidBase64, fieldName: fieldName)) { error in
            if let sensitiveDataError = error as? SensitiveDataError {
                // Check by comparing the case instead of direct equality
                switch sensitiveDataError {
                case .invalidBase64Data(let field):
                    XCTAssertEqual(field, fieldName)
                default:
                    XCTFail("Expected SensitiveDataError.invalidBase64Data but got \(sensitiveDataError)")
                }
            } else {
                XCTFail("Expected SensitiveDataError.invalidBase64Data but got \(type(of: error))")
            }
        }
    }
    
    /// Tests encryption with invalid UTF-8 data
    func testEncryptInvalidUTF8Data() throws {
        // Given
        // Create a Data object that can't be represented as a UTF-8 string
        let invalidUTF8Data = Data([0xFF, 0xFE, 0xFD]) // Invalid UTF-8 sequence
        let invalidString = String(decoding: invalidUTF8Data, as: UTF8.self)
        let fieldName = "invalidUTF8Field"
        
        // Store original behavior
        let originalShouldFail = mockEncryptionService.shouldFailEncryption
        
        // Configure the mock to pass through data
        mockEncryptionService.shouldFailEncryption = false
        
        // When
        let encrypted = try sut.encryptString(invalidString, fieldName: fieldName)
        
        // Then
        XCTAssertNotEqual(encrypted, invalidString, "Encrypted invalid UTF-8 string should be different")
        
        // Reset the mock for tearDown
        mockEncryptionService.shouldFailEncryption = originalShouldFail
    }
    
    /// Tests handling of repeated encryption operations
    func testRepeatedEncryptionOperations() throws {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        
        // When - Encrypt multiple times
        for _ in 1...100 {
            _ = try sut.encryptString(testString, fieldName: fieldName)
        }
        
        // Then
        XCTAssertEqual(mockEncryptionService.encryptionCount, 100, "Should handle 100 encryption operations")
    }
    
    /// Tests concurrent encryption operations
    func testConcurrentEncryptionOperations() async {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        
        // When - Encrypt concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...10 {
                group.addTask {
                    do {
                        // The sut.encryptString method is async, so we need await
                        _ = try await self.sut.encryptString(testString, fieldName: fieldName)
                    } catch {
                        XCTFail("Concurrent encryption failed: \(error)")
                    }
                }
            }
        }
        
        // Then
        XCTAssertEqual(mockEncryptionService.encryptionCount, 10, "Should handle 10 concurrent encryption operations")
    }
    
    /// Tests behavior when encryption service throws custom error
    func testEncryptionServiceCustomError() {
        // Given
        let testString = "Test String"
        let fieldName = "testField"
        
        // Configure mock to throw an error
        mockEncryptionService.shouldFailEncryption = true
        
        // Then
        XCTAssertThrowsError(try sut.encryptString(testString, fieldName: fieldName)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError, "Should propagate encryption errors")
        }
        
        // Reset for other tests
        mockEncryptionService.shouldFailEncryption = false
    }
} 