import XCTest
@testable import PayslipMax

/// Security service isolation tests
/// Tests that multiple service instances operate independently
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityIsolationTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 14: Verify service isolation between instances
    func testServiceIsolation() async throws {
        // Given: Two service instances
        let service1 = SecurityServiceImpl()
        let service2 = SecurityServiceImpl()

        // When: Initialize both
        try await service1.initialize()
        try await service2.initialize()

        // Then: They should operate independently
        let data1 = createTestData("Service 1 data")
        let data2 = createTestData("Service 2 data")

        let encrypted1 = try await service1.encryptData(data1)
        let encrypted2 = try await service2.encryptData(data2)

        // Cross-service decryption should fail (different keys)
        do {
            _ = try await service1.decryptData(encrypted2)
            XCTFail("Cross-service decryption should fail")
        } catch {
            // Expected to fail
        }

        do {
            _ = try await service2.decryptData(encrypted1)
            XCTFail("Cross-service decryption should fail")
        } catch {
            // Expected to fail
        }

        // Same-service decryption should work
        let decrypted1 = try await service1.decryptData(encrypted1)
        let decrypted2 = try await service2.decryptData(encrypted2)

        XCTAssertEqual(decrypted1, data1)
        XCTAssertEqual(decrypted2, data2)
    }
}
