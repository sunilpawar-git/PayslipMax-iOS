import XCTest
import Foundation
@testable import Payslip_Max

class EncryptionServiceAdapterTests: XCTestCase {
    var adapter: EncryptionServiceAdapter!
    var mockEncryptionService: MockEncryptionService!
    
    override func setUp() {
        super.setUp()
        mockEncryptionService = MockEncryptionService()
        adapter = EncryptionServiceAdapter(encryptionService: mockEncryptionService)
    }
    
    override func tearDown() {
        adapter = nil
        mockEncryptionService = nil
        super.tearDown()
    }
    
    func testEncrypt() throws {
        let testData = "test123".data(using: .utf8)!
        let encrypted = try adapter.encrypt(testData)
        XCTAssertNotEqual(encrypted, testData)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 1)
    }
    
    func testDecrypt() throws {
        let testData = "test123".data(using: .utf8)!
        let encrypted = try adapter.encrypt(testData)
        let decrypted = try adapter.decrypt(encrypted)
        XCTAssertEqual(decrypted, testData)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 1)
    }
    
    func testEncryptFailure() {
        mockEncryptionService.shouldFailEncryption = true
        
        XCTAssertThrowsError(try adapter.encrypt("test".data(using: .utf8)!)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .encryptionFailed)
        }
    }
    
    func testDecryptFailure() {
        mockEncryptionService.shouldFailDecryption = true
        
        XCTAssertThrowsError(try adapter.decrypt("test".data(using: .utf8)!)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .decryptionFailed)
        }
    }
    
    func testKeyManagementFailure() {
        mockEncryptionService.shouldFailKeyManagement = true
        
        XCTAssertThrowsError(try adapter.encrypt("test".data(using: .utf8)!)) { error in
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .keyNotFound)
        }
    }
    
    func testProtocolConformance() {
        XCTAssertTrue(adapter is SensitiveDataEncryptionService)
        XCTAssertTrue(adapter is EncryptionServiceProtocolInternal)
    }
} 