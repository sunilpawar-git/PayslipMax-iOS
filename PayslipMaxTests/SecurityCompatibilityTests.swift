import XCTest
@testable import PayslipMax

/// Security service cross-platform compatibility tests
/// Tests compatibility across different platforms and data types
/// Follows SOLID principles with single responsibility focus
@MainActor
final class SecurityCompatibilityTests: SecurityTestBaseSetup {

    // MARK: - Test Cases

    /// Test 10: Verify cross-platform compatibility
    func testCrossPlatformCompatibility() async throws {
        // Given: Service is initialized
        try await initializeSecurityService()

        // Test data that might behave differently across platforms
        let testStrings = [
            "ASCII: Hello World",
            "Unicode: 你好世界 🌍",
            "Control chars: \n\t\r",
            "Numbers: 1234567890",
            "Symbols: !@#$%^&*()_+-=[]{}|;:,.<>?",
            "Empty: ",
            "Very long: " + String(repeating: "x", count: 10000)
        ]

        for testString in testStrings {
            let testData = testString.data(using: .utf8)!

            // When: Encrypt and decrypt
            let encrypted = try await securityService.encryptData(testData)
            let decrypted = try await securityService.decryptData(encrypted)

            // Then: Should get back original data
            XCTAssertEqual(decrypted, testData)
            XCTAssertEqual(String(data: decrypted, encoding: .utf8), testString)
        }
    }
}
