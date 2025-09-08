import XCTest
@testable import PayslipMax

/// Security service operation idempotency tests
/// Tests that repeated operations produce consistent results
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityIdempotencyTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 12: Verify operation idempotency
    func testOperationIdempotency() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        let testData = createTestData("Idempotency test")
        let key = "idempotent_key"

        // When: Perform same operation multiple times
        for _ in 0..<5 {
            // Store same data multiple times
            let storeResult = securityService.storeSecureData(testData, forKey: key)
            XCTAssertTrue(storeResult)

            // Retrieve should always return same data
            let retrieved = securityService.retrieveSecureData(forKey: key)
            XCTAssertEqual(retrieved, testData)
        }

        // When: Delete multiple times
        for _ in 0..<3 {
            let deleteResult = securityService.deleteSecureData(forKey: key)
            XCTAssertTrue(deleteResult) // Should succeed even if already deleted
        }

        // Then: Data should be gone
        let finalRetrieved = securityService.retrieveSecureData(forKey: key)
        XCTAssertNil(finalRetrieved)
    }
}
