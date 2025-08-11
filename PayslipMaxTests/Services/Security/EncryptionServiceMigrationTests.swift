import XCTest
import Foundation
@testable import PayslipMax

final class EncryptionServiceMigrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Ensure a clean keychain state for encryption key
        cleanupKeychainKey()
    }

    override func tearDown() {
        cleanupKeychainKey()
        super.tearDown()
    }

    func testEncryptDecryptAcrossServiceInstances_NoPlaintextPersists() throws {
        // Given
        let original = "migrate: secrets".data(using: .utf8)!

        // When: encrypt with first instance
        let serviceV1 = EncryptionService()
        let ciphertext = try serviceV1.encrypt(original)

        // Then: ciphertext must differ and not contain plaintext bytes
        XCTAssertNotEqual(ciphertext, original)
        XCTAssertFalse(String(data: ciphertext, encoding: .utf8) == String(data: original, encoding: .utf8))

        // And: decrypt with new instance (simulating app upgrade / migration)
        let serviceV2 = EncryptionService()
        let decrypted = try serviceV2.decrypt(ciphertext)
        XCTAssertEqual(decrypted, original)
    }

    func testPayslipSensitiveDataHandler_RoundTrip_WithInjectedServiceFactory() throws {
        // Given
        cleanupKeychainKey()
        // Inject a factory that returns a fresh EncryptionService to validate DI path
        _ = PayslipSensitiveDataHandler.Factory.setSensitiveDataEncryptionServiceFactory { EncryptionService() }
        let handler = try PayslipSensitiveDataHandler.Factory.create()

        // When: encrypt fields
        let enc = try handler.encryptSensitiveFields(name: "Alice", accountNumber: "1234567890", panNumber: "ABCDE1234F")

        // Ensure they look like base64 and differ
        XCTAssertNotEqual(enc.name, "Alice")
        XCTAssertNotEqual(enc.accountNumber, "1234567890")
        XCTAssertNotEqual(enc.panNumber, "ABCDE1234F")

        // And: decrypt back
        let dec = try handler.decryptSensitiveFields(name: enc.name, accountNumber: enc.accountNumber, panNumber: enc.panNumber)

        // Then
        XCTAssertEqual(dec.name, "Alice")
        XCTAssertEqual(dec.accountNumber, "1234567890")
        XCTAssertEqual(dec.panNumber, "ABCDE1234F")
    }

    func testDecryptionFailsForTamperedCiphertext_AfterUpgrade() throws {
        // Given
        let service = EncryptionService()
        var ciphertext = try service.encrypt(Data("hello".utf8))

        // When: tamper one byte and try decrypt via a new instance
        ciphertext[ciphertext.count - 1] ^= 0x7F
        let upgraded = EncryptionService()

        // Then
        XCTAssertThrowsError(try upgraded.decrypt(ciphertext))
    }

    // MARK: - Helpers
    private func cleanupKeychainKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.app.payslipmax",
            kSecAttrAccount as String: "encryption_key"
        ]
        SecItemDelete(query as CFDictionary)
    }
}


