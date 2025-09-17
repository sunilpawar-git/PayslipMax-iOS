import XCTest
import CryptoKit
@testable import PayslipMax

@MainActor
class EncryptionTests: XCTestCase {

    var sut: SecurityServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = SecurityServiceImpl()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Encryption Tests

    func testEncryptData_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        let testData = Data("test data".utf8)
        XCTAssertFalse(sut.isInitialized)

        // When/Then
        do {
            _ = try await sut.encryptData(testData)
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEncryptData_WhenInitialized_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let testData = Data("test data".utf8)

        // When
        let encryptedData = try await sut.encryptData(testData)

        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertNotEqual(encryptedData, testData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }

    func testEncryptData_WithEmptyData_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let emptyData = Data()

        // When
        let encryptedData = try await sut.encryptData(emptyData)

        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }

    func testEncryptData_WithLargeData_ReturnsEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let largeData = Data(repeating: 0xFF, count: 100_000)

        // When
        let encryptedData = try await sut.encryptData(largeData)

        // Then
        XCTAssertNotNil(encryptedData)
        XCTAssertNotEqual(encryptedData, largeData)
        XCTAssertGreaterThan(encryptedData.count, 0)
    }

    // MARK: - Decryption Tests

    func testDecryptData_WhenNotInitialized_ThrowsNotInitializedError() async {
        // Given
        let testData = Data("test data".utf8)
        XCTAssertFalse(sut.isInitialized)

        // When/Then
        do {
            _ = try await sut.decryptData(testData)
            XCTFail("Should have thrown notInitialized error")
        } catch SecurityError.notInitialized {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDecryptData_WithValidEncryptedData_ReturnsOriginalData() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)
        let encryptedData = try await sut.encryptData(originalData)

        // When
        let decryptedData = try await sut.decryptData(encryptedData)

        // Then
        XCTAssertEqual(decryptedData, originalData)
    }

    func testDecryptData_WithInvalidData_ThrowsError() async {
        // Given
        do {
            try await sut.initialize()
        } catch {
            XCTFail("Initialization failed: \(error)")
            return
        }
        let invalidData = Data("invalid encrypted data".utf8)

        // When/Then
        do {
            _ = try await sut.decryptData(invalidData)
            XCTFail("Should have thrown decryption error")
        } catch {
            // Success - should throw error for invalid data
        }
    }

    func testDecryptData_WithTamperedData_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)
        var encryptedData = try await sut.encryptData(originalData)

        // Tamper with the data
        encryptedData[0] = encryptedData[0] ^ 0xFF

        // When/Then
        do {
            _ = try await sut.decryptData(encryptedData)
            XCTFail("Should have thrown decryption error for tampered data")
        } catch {
            // Success - should throw error for tampered data
        }
    }

    // MARK: - Encrypt/Decrypt Round Trip Tests

    func testEncryptDecryptRoundTrip_PreservesOriginalData() async throws {
        // Given
        try await sut.initialize()
        let testCases = [
            Data("simple text".utf8),
            Data(),
            Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]),
            Data(repeating: 0xAA, count: 1000),
            Data("emoji test 🔒🔑💾".utf8)
        ]

        // When/Then
        for originalData in testCases {
            let encryptedData = try await sut.encryptData(originalData)
            let decryptedData = try await sut.decryptData(encryptedData)

            XCTAssertEqual(decryptedData, originalData, "Round trip failed for data: \(originalData)")
        }
    }

    func testEncryptDecryptRoundTrip_ProducesDifferentEncryptedData() async throws {
        // Given
        try await sut.initialize()
        let originalData = Data("test data".utf8)

        // When
        let encrypted1 = try await sut.encryptData(originalData)
        let encrypted2 = try await sut.encryptData(originalData)

        // Then
        XCTAssertNotEqual(encrypted1, encrypted2, "Encrypting same data twice should produce different ciphertext")

        // But both should decrypt to the same original data
        let decrypted1 = try await sut.decryptData(encrypted1)
        let decrypted2 = try await sut.decryptData(encrypted2)

        XCTAssertEqual(decrypted1, originalData)
        XCTAssertEqual(decrypted2, originalData)
    }

    // MARK: - Performance Tests

    func testEncryptionPerformance() async throws {
        // Given
        try await sut.initialize()
        let testData = Data(repeating: 0xFF, count: 1_000)

        // When: Test encryption performance with simplified approach
        var results: [Data] = []
        measure {
            // Run synchronous encryption multiple times
            for _ in 0..<10 {
                do {
                    let encrypted = try sut.encryptData(testData) // Use sync version for performance testing
                    results.append(encrypted)
                } catch {
                    XCTFail("Encryption failed: \(error)")
                    break
                }
            }
        }

        // Verify encryption succeeded
        XCTAssertFalse(results.isEmpty, "Should have encrypted data")
        XCTAssertGreaterThan(results.count, 0, "Should have multiple encryption results")
    }

    func testDecryptionPerformance() async throws {
        // Given
        try await sut.initialize()
        let testData = Data(repeating: 0xFF, count: 1_000)

        // Use sync encryption for performance testing
        let encryptedData = try await sut.encryptData(testData)

        // When: Test decryption performance with measure block
        var results: [Data] = []
        measure {
            do {
                // Use the synchronous version explicitly to avoid method resolution issues
                let decrypted = try sut!.decryptDataSync(encryptedData)
                results.append(decrypted)
            } catch {
                print("Test: Decryption failed: \(error)")
                XCTFail("Decryption failed: \(error)")
            }
        }

        // Verify decryption succeeded
        XCTAssertFalse(results.isEmpty, "Should have decrypted data")
        guard let firstResult = results.first else {
            XCTFail("No decrypted results")
            return
        }

        XCTAssertEqual(firstResult.count, testData.count, "Decrypted data size should match original")
        XCTAssertEqual(firstResult, testData, "Decrypted data should match original")
    }
}
