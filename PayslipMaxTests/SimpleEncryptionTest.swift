import XCTest
import Foundation
@testable import PayslipMax

final class SimpleEncryptionTest: XCTestCase {

    private var encryptionService: EncryptionService!

    override func setUp() {
        super.setUp()
        encryptionService = EncryptionService()
    }

    override func tearDown() {
        encryptionService = nil
        super.tearDown()
    }

    /// Test 1: Basic encryption and decryption
    func testBasicEncryptionDecryption() throws {
        let testData = "Hello, World!".data(using: .utf8)!

        let encryptedData = try encryptionService.encrypt(testData)
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertFalse(encryptedData.isEmpty)

        let decryptedData = try encryptionService.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, testData)
    }

    /// Test 2: Empty data encryption
    func testEmptyDataEncryption() throws {
        let emptyData = Data()

        let encryptedData = try encryptionService.encrypt(emptyData)
        XCTAssertFalse(encryptedData.isEmpty)

        let decryptedData = try encryptionService.decrypt(encryptedData)
        XCTAssertEqual(decryptedData, emptyData)
    }

    /// Test 3: Large data encryption
    func testLargeDataEncryption() throws {
        let largeString = String(repeating: "Test", count: 1000)
        let largeData = largeString.data(using: .utf8)!

        let encryptedData = try encryptionService.encrypt(largeData)
        let decryptedData = try encryptionService.decrypt(encryptedData)

        XCTAssertEqual(decryptedData, largeData)
    }
}
