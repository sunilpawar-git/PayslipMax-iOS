import XCTest
import Foundation
@testable import Payslip_Max

@MainActor
class EncryptionServiceAdapterTests: XCTestCase {
    var adapter: EncryptionServiceAdapter!
    var mockEncryptionService: MockEncryptionService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockEncryptionService = MockEncryptionService()
        adapter = EncryptionServiceAdapter(encryptionService: mockEncryptionService)
    }
    
    override func tearDown() async throws {
        adapter = nil
        mockEncryptionService = nil
        try await super.tearDown()
    }
    
    func testEncrypt() async throws {
        let testData = "test123".data(using: .utf8)!
        let encrypted = try adapter.encrypt(testData)
        XCTAssertNotEqual(encrypted, testData)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 1)
    }
    
    func testDecrypt() async throws {
        let testData = "test123".data(using: .utf8)!
        let encrypted = try adapter.encrypt(testData)
        let decrypted = try adapter.decrypt(encrypted)
        XCTAssertEqual(decrypted, testData)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 1)
    }
    
    func testEncryptFailure() async throws {
        mockEncryptionService.shouldFailEncryption = true
        
        do {
            _ = try adapter.encrypt("test".data(using: .utf8)!)
            XCTFail("Expected encryption to fail")
        } catch {
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .encryptionFailed)
        }
    }
    
    func testDecryptFailure() async throws {
        mockEncryptionService.shouldFailDecryption = true
        
        do {
            _ = try adapter.decrypt("test".data(using: .utf8)!)
            XCTFail("Expected decryption to fail")
        } catch {
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .decryptionFailed)
        }
    }
    
    func testKeyManagementFailure() async throws {
        mockEncryptionService.shouldFailKeyManagement = true
        
        do {
            _ = try adapter.encrypt("test".data(using: .utf8)!)
            XCTFail("Expected key management to fail")
        } catch {
            XCTAssertTrue(error is EncryptionService.EncryptionError)
            XCTAssertEqual(error as? EncryptionService.EncryptionError, .keyNotFound)
        }
    }
    
    func testProtocolConformance() async throws {
        XCTAssertTrue(adapter is SensitiveDataEncryptionService)
        XCTAssertTrue(adapter is EncryptionServiceProtocolInternal)
    }
} 