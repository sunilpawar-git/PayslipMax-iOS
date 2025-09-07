import XCTest
@testable import PayslipMax

/// Security service data storage tests
/// Tests secure data storage, retrieval, and deletion operations
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityDataStorageTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 1: Verify secure data storage
    func testSecureDataStorage() {
        // Given: Test data
        let testData = createTestData("Secure Test Data")
        let testKey = "test_key"

        // When: Store secure data
        let storeResult = securityService.storeSecureData(testData, forKey: testKey)

        // Then: Storage should succeed
        XCTAssertTrue(storeResult)

        // When: Retrieve secure data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)

        // Then: Retrieved data should match stored data
        XCTAssertEqual(retrievedData, testData)
    }

    /// Test 2: Verify secure data deletion
    func testSecureDataDeletion() {
        // Given: Stored secure data
        let testData = createTestData("Delete Test Data")
        let testKey = "delete_test_key"
        let storeResult = securityService.storeSecureData(testData, forKey: testKey)
        XCTAssertTrue(storeResult)

        // When: Delete secure data
        let deleteResult = securityService.deleteSecureData(forKey: testKey)

        // Then: Deletion should succeed
        XCTAssertTrue(deleteResult)

        // When: Try to retrieve deleted data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)

        // Then: Should return nil
        XCTAssertNil(retrievedData)
    }

    /// Test 3: Verify retrieval of non-existent data
    func testRetrieveNonExistentData() {
        // Given: No data stored for key
        let nonExistentKey = "non_existent_key"

        // When: Try to retrieve data
        let retrievedData = securityService.retrieveSecureData(forKey: nonExistentKey)

        // Then: Should return nil
        XCTAssertNil(retrievedData)
    }

    /// Test 4: Verify deletion of non-existent data
    func testDeleteNonExistentData() {
        // Given: No data stored for key
        let nonExistentKey = "non_existent_key_to_delete"

        // When: Try to delete data
        let deleteResult = securityService.deleteSecureData(forKey: nonExistentKey)

        // Then: Deletion should succeed (idempotent operation)
        XCTAssertTrue(deleteResult)
    }

    /// Test 5: Verify overwriting existing data
    func testOverwriteExistingData() {
        // Given: Initial data stored
        let initialData = createTestData("Initial Data")
        let testKey = "overwrite_key"
        let storeResult1 = securityService.storeSecureData(initialData, forKey: testKey)
        XCTAssertTrue(storeResult1)

        // When: Store different data with same key
        let newData = createTestData("New Data")
        let storeResult2 = securityService.storeSecureData(newData, forKey: testKey)
        XCTAssertTrue(storeResult2)

        // Then: Retrieved data should be the new data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        XCTAssertEqual(retrievedData, newData)
        XCTAssertNotEqual(retrievedData, initialData)
    }

    /// Test 6: Verify data storage with empty data
    func testStoreEmptyData() {
        // Given: Empty data
        let emptyData = Data()
        let testKey = "empty_data_key"

        // When: Store empty data
        let storeResult = securityService.storeSecureData(emptyData, forKey: testKey)

        // Then: Storage should succeed
        XCTAssertTrue(storeResult)

        // When: Retrieve empty data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)

        // Then: Should get back empty data
        XCTAssertEqual(retrievedData, emptyData)
        XCTAssertEqual(retrievedData?.count, 0)
    }

    /// Test 7: Verify data storage with large data
    func testStoreLargeData() {
        // Given: Large data (1MB)
        let largeData = Data(repeating: 0x42, count: 1024 * 1024)
        let testKey = "large_data_key"

        // When: Store large data
        let storeResult = securityService.storeSecureData(largeData, forKey: testKey)

        // Then: Storage should succeed
        XCTAssertTrue(storeResult)

        // When: Retrieve large data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)

        // Then: Should get back large data
        XCTAssertEqual(retrievedData, largeData)
        XCTAssertEqual(retrievedData?.count, largeData.count)
    }

    /// Test 8: Verify multiple key storage
    func testMultipleKeyStorage() {
        // Given: Multiple data items
        let data1 = createTestData("Data 1")
        let data2 = createTestData("Data 2")
        let data3 = createTestData("Data 3")

        let key1 = "key1"
        let key2 = "key2"
        let key3 = "key3"

        // When: Store all data
        let storeResult1 = securityService.storeSecureData(data1, forKey: key1)
        let storeResult2 = securityService.storeSecureData(data2, forKey: key2)
        let storeResult3 = securityService.storeSecureData(data3, forKey: key3)

        // Then: All storage operations should succeed
        XCTAssertTrue(storeResult1)
        XCTAssertTrue(storeResult2)
        XCTAssertTrue(storeResult3)

        // And: All data should be retrievable
        XCTAssertEqual(securityService.retrieveSecureData(forKey: key1), data1)
        XCTAssertEqual(securityService.retrieveSecureData(forKey: key2), data2)
        XCTAssertEqual(securityService.retrieveSecureData(forKey: key3), data3)
    }

    /// Test 9: Verify data isolation between keys
    func testDataIsolationBetweenKeys() {
        // Given: Data stored for different keys
        let data1 = createTestData("Data One")
        let data2 = createTestData("Data Two")
        let key1 = "isolation_key_1"
        let key2 = "isolation_key_2"

        _ = securityService.storeSecureData(data1, forKey: key1)
        _ = securityService.storeSecureData(data2, forKey: key2)

        // When: Retrieve data for each key
        let retrieved1 = securityService.retrieveSecureData(forKey: key1)
        let retrieved2 = securityService.retrieveSecureData(forKey: key2)

        // Then: Each key should return its own data
        XCTAssertEqual(retrieved1, data1)
        XCTAssertEqual(retrieved2, data2)
        XCTAssertNotEqual(retrieved1, retrieved2)
    }

    /// Test 10: Verify selective deletion
    func testSelectiveDeletion() {
        // Given: Multiple keys with data
        let data1 = createTestData("Keep This")
        let data2 = createTestData("Delete This")
        let data3 = createTestData("Keep This Too")

        let key1 = "keep_1"
        let key2 = "delete_me"
        let key3 = "keep_2"

        _ = securityService.storeSecureData(data1, forKey: key1)
        _ = securityService.storeSecureData(data2, forKey: key2)
        _ = securityService.storeSecureData(data3, forKey: key3)

        // When: Delete middle key
        let deleteResult = securityService.deleteSecureData(forKey: key2)
        XCTAssertTrue(deleteResult)

        // Then: Only middle data should be deleted
        XCTAssertEqual(securityService.retrieveSecureData(forKey: key1), data1)
        XCTAssertNil(securityService.retrieveSecureData(forKey: key2))
        XCTAssertEqual(securityService.retrieveSecureData(forKey: key3), data3)
    }

    /// Test 11: Verify data persistence across service instances
    func testDataPersistenceAcrossInstances() {
        // Given: Data stored in first instance
        let testData = createTestData("Persistent Data")
        let testKey = "persistent_key"
        let storeResult = securityService.storeSecureData(testData, forKey: testKey)
        XCTAssertTrue(storeResult)

        // When: Create new service instance
        securityService = SecurityServiceImpl()

        // Then: Data should not be available (since it's stored in UserDefaults with specific prefixes)
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        XCTAssertNil(retrievedData)
    }

    /// Test 12: Verify storage with special characters in keys
    func testStorageWithSpecialKeyCharacters() {
        // Given: Data with special characters in key
        let testData = createTestData("Special Key Data")
        let specialKeys = [
            "key-with-dashes",
            "key_with_underscores",
            "key.with.dots",
            "key/with/slashes",
            "key with spaces"
        ]

        // When/Then: Store and retrieve data with special keys
        for key in specialKeys {
            let storeResult = securityService.storeSecureData(testData, forKey: key)
            XCTAssertTrue(storeResult, "Failed to store data for key: \(key)")

            let retrievedData = securityService.retrieveSecureData(forKey: key)
            XCTAssertEqual(retrievedData, testData, "Failed to retrieve data for key: \(key)")
        }
    }

    /// Test 13: Verify binary data storage and retrieval
    func testBinaryDataStorage() {
        // Given: Binary data
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD, 0x80, 0x7F])
        let testKey = "binary_data_key"

        // When: Store binary data
        let storeResult = securityService.storeSecureData(binaryData, forKey: testKey)
        XCTAssertTrue(storeResult)

        // Then: Retrieve binary data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        XCTAssertEqual(retrievedData, binaryData)
        XCTAssertEqual(retrievedData?.count, binaryData.count)
    }

    /// Test 14: Verify storage and retrieval with Unicode data
    func testUnicodeDataStorage() {
        // Given: Unicode data
        let unicodeData = "🔐📱💾🚀".data(using: .utf8)!
        let testKey = "unicode_data_key"

        // When: Store Unicode data
        let storeResult = securityService.storeSecureData(unicodeData, forKey: testKey)
        XCTAssertTrue(storeResult)

        // Then: Retrieve Unicode data
        let retrievedData = securityService.retrieveSecureData(forKey: testKey)
        XCTAssertEqual(retrievedData, unicodeData)
        XCTAssertEqual(String(data: retrievedData!, encoding: .utf8), "🔐📱💾🚀")
    }
}
