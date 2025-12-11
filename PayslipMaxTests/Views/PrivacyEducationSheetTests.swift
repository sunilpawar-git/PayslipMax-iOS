import XCTest
@testable import PayslipMax

/// Tests for PrivacyEducationSheet and UserDefaults extension
final class PrivacyEducationSheetTests: XCTestCase {

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "hasSeenPrivacyEducation")
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "hasSeenPrivacyEducation")
        super.tearDown()
    }

    // MARK: - UserDefaults Extension Tests

    func testHasSeenPrivacyEducation_DefaultValue_ReturnsFalse() {
        // Given: Fresh UserDefaults (no value set)
        // When: Accessing hasSeenPrivacyEducation
        let result = UserDefaults.hasSeenPrivacyEducation

        // Then: Should return false (Bool default)
        XCTAssertFalse(result, "Default value should be false for new users")
    }

    func testHasSeenPrivacyEducation_AfterSetting_ReturnsTrue() {
        // Given: UserDefaults is set
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Accessing hasSeenPrivacyEducation
        let result = UserDefaults.hasSeenPrivacyEducation

        // Then: Should return true
        XCTAssertTrue(result, "Should return true after being set")
    }

    func testHasSeenPrivacyEducation_PersistsAcrossAccess() {
        // Given: Value is set to true
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Accessing multiple times
        let firstAccess = UserDefaults.hasSeenPrivacyEducation
        let secondAccess = UserDefaults.hasSeenPrivacyEducation

        // Then: Should remain consistent
        XCTAssertTrue(firstAccess)
        XCTAssertTrue(secondAccess)
        XCTAssertEqual(firstAccess, secondAccess, "Value should persist across multiple accesses")
    }

    func testHasSeenPrivacyEducation_KeyConsistency() {
        // Given: Value set through standard UserDefaults
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Accessing through extension
        let extensionValue = UserDefaults.hasSeenPrivacyEducation

        // Then: Should match direct access
        let directValue = UserDefaults.standard.bool(forKey: "hasSeenPrivacyEducation")
        XCTAssertEqual(extensionValue, directValue, "Extension should use same key")
    }

    // MARK: - Privacy Education Flow Tests

    func testFirstTimeUser_FlagNotSet() {
        // Given: Fresh UserDefaults
        // When: Checking first-time status
        let isFirstTime = !UserDefaults.hasSeenPrivacyEducation

        // Then: Should be first-time user
        XCTAssertTrue(isFirstTime, "New user should be first-time")
    }

    func testReturningUser_FlagSet() {
        // Given: Flag is set (user has seen education)
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Checking first-time status
        let isFirstTime = !UserDefaults.hasSeenPrivacyEducation

        // Then: Should not be first-time user
        XCTAssertFalse(isFirstTime, "Returning user should not be first-time")
    }

    func testMarkAsShown_SetsFlag() {
        // Given: Fresh state
        XCTAssertFalse(UserDefaults.hasSeenPrivacyEducation, "Should start false")

        // When: Marking as shown (simulating button tap)
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // Then: Flag should be set
        XCTAssertTrue(UserDefaults.hasSeenPrivacyEducation, "Should be true after marking")
    }

    // MARK: - Edge Cases

    func testMultipleMarkAsShown_RemainsTrue() {
        // Given: Flag already set
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // When: Setting again (user sees sheet multiple times somehow)
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")

        // Then: Should remain true
        XCTAssertTrue(UserDefaults.hasSeenPrivacyEducation)
    }

    func testClearFlag_ResetsToFalse() {
        // Given: Flag is set
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")
        XCTAssertTrue(UserDefaults.hasSeenPrivacyEducation)

        // When: Clearing (e.g., app reset)
        UserDefaults.standard.removeObject(forKey: "hasSeenPrivacyEducation")

        // Then: Should return to false
        XCTAssertFalse(UserDefaults.hasSeenPrivacyEducation)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess_ThreadSafe() {
        let expectation = XCTestExpectation(description: "Concurrent access completes")
        expectation.expectedFulfillmentCount = 10

        // When: Multiple threads access simultaneously
        for i in 0..<10 {
            DispatchQueue.global().async {
                UserDefaults.standard.set(i % 2 == 0, forKey: "hasSeenPrivacyEducation")
                _ = UserDefaults.hasSeenPrivacyEducation
                expectation.fulfill()
            }
        }

        // Then: Should not crash
        wait(for: [expectation], timeout: 2.0)
    }
}
