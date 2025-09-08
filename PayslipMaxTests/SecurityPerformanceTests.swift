import XCTest
@testable import PayslipMax

/// Security service performance and memory pressure tests
/// Tests memory handling, large data processing, and stress testing
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityPerformanceTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 8: Verify memory pressure handling
    func testMemoryPressureHandling() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Process large amounts of data
        var encryptedResults: [Data] = []
        let largeData = Data(repeating: 0x41, count: 100 * 1024) // 100KB per item

        for i in 0..<10 {
            let data = createTestData("Large data \(i)") + largeData
            let encrypted = try await securityService.encryptData(data)
            encryptedResults.append(encrypted)
        }

        // Then: All operations should succeed and be decryptable
        for (index, encrypted) in encryptedResults.enumerated() {
            let expectedData = createTestData("Large data \(index)") + largeData
            let decrypted = try await securityService.decryptData(encrypted)
            XCTAssertEqual(decrypted, expectedData)
        }
    }

    /// Test 13: Verify service behavior under stress
    func testServiceUnderStress() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // When: Perform many rapid operations
        let operationCount = 100
        var results: [Data] = []

        for i in 0..<operationCount {
            let data = createTestData("Stress test \(i)")
            let encrypted = try await securityService.encryptData(data)
            results.append(encrypted)
        }

        // Then: All results should be valid and decryptable
        for (index, encrypted) in results.enumerated() {
            let expected = createTestData("Stress test \(index)")
            let decrypted = try await securityService.decryptData(encrypted)
            XCTAssertEqual(decrypted, expected)
        }
    }
}
