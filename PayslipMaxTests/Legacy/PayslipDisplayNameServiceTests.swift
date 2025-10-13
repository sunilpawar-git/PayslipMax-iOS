import XCTest
@testable import PayslipMax

/// Test suite for PayslipDisplayNameService functionality
///
/// Verifies that internal parsing keys are correctly converted to user-friendly display names
/// while preserving the robust parsing infrastructure.
final class PayslipDisplayNameServiceTests: XCTestCase {

    private var displayNameService: PayslipDisplayNameServiceProtocol!

    override func setUp() {
        super.setUp()
        displayNameService = PayslipDisplayNameService()
    }

    override func tearDown() {
        displayNameService = nil
        super.tearDown()
    }

    // MARK: - RH12 Display Name Tests (Main Issue)

    func testRH12EarningsDisplayName() {
        // Given: Internal RH12_EARNINGS key
        let internalKey = "RH12_EARNINGS"

        // When: Getting display name
        let displayName = displayNameService.getDisplayName(for: internalKey)

        // Then: Should show clean "RH12" name
        XCTAssertEqual(displayName, "RH12", "RH12_EARNINGS should display as clean 'RH12'")
    }

    func testRH12DeductionsDisplayName() {
        // Given: Internal RH12_DEDUCTIONS key
        let internalKey = "RH12_DEDUCTIONS"

        // When: Getting display name
        let displayName = displayNameService.getDisplayName(for: internalKey)

        // Then: Should show clean "RH12" name
        XCTAssertEqual(displayName, "RH12", "RH12_DEDUCTIONS should display as clean 'RH12'")
    }

    func testAllRHCodesDisplayNames() {
        // Given: All RH codes with suffixes
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]

        for rhCode in rhCodes {
            // When: Getting display names for earnings and deductions
            let earningsDisplayName = displayNameService.getDisplayName(for: "\(rhCode)_EARNINGS")
            let deductionsDisplayName = displayNameService.getDisplayName(for: "\(rhCode)_DEDUCTIONS")

            // Then: Should show clean RH code without suffixes
            XCTAssertEqual(earningsDisplayName, rhCode, "\(rhCode)_EARNINGS should display as '\(rhCode)'")
            XCTAssertEqual(deductionsDisplayName, rhCode, "\(rhCode)_DEDUCTIONS should display as '\(rhCode)'")
        }
    }

    // MARK: - Standard Component Display Tests

    func testStandardPayComponentNames() {
        // Given: Standard pay component mappings
        let testCases: [(internal: String, expected: String)] = [
            ("BPAY", "Basic Pay"),
            ("Basic Pay", "Basic Pay"),
            ("DA", "Dearness Allowance"),
            ("MSP", "Military Service Pay"),
            ("TPTA", "Transport Allowance"),
            ("DSOP", "DSOP"),
            ("AGIF", "AGIF"),
            ("ITAX", "Income Tax")
        ]

        for testCase in testCases {
            // When: Getting display name
            let displayName = displayNameService.getDisplayName(for: testCase.internal)

            // Then: Should match expected display name
            XCTAssertEqual(displayName, testCase.expected,
                          "Internal key '\(testCase.internal)' should display as '\(testCase.expected)'")
        }
    }

    // MARK: - Display Earnings/Deductions Tests

    func testGetDisplayEarnings() {
        // Given: Earnings with internal keys including RH12_EARNINGS
        let earnings: [String: Double] = [
            "BPAY": 144700,
            "DA": 88110,
            "MSP": 15500,
            "RH12_EARNINGS": 21125,
            "TPTA": 3600
        ]

        // When: Getting display earnings
        let displayEarnings = displayNameService.getDisplayEarnings(from: earnings)

        // Then: Should have clean display names sorted alphabetically
        XCTAssertEqual(displayEarnings.count, 5, "Should have 5 earnings items")

        // Find RH12 entry
        let rh12Entry = displayEarnings.first { $0.displayName == "RH12" }
        XCTAssertNotNil(rh12Entry, "Should have RH12 entry")
        XCTAssertEqual(rh12Entry?.value, 21125, "RH12 value should be preserved")

        // Verify all display names are clean (no underscores or technical suffixes)
        for item in displayEarnings {
            XCTAssertFalse(item.displayName.contains("_"), "Display name '\(item.displayName)' should not contain underscores")
            XCTAssertFalse(item.displayName.contains("EARNINGS"), "Display name '\(item.displayName)' should not contain 'EARNINGS'")
        }
    }

    func testGetDisplayDeductions() {
        // Given: Deductions with internal keys including RH12_DEDUCTIONS
        let deductions: [String: Double] = [
            "DSOP": 40000,
            "AGIF": 12500,
            "ITAX": 47624,
            "RH12_DEDUCTIONS": 7518,
            "EHCESS": 1905
        ]

        // When: Getting display deductions
        let displayDeductions = displayNameService.getDisplayDeductions(from: deductions)

        // Then: Should have clean display names
        XCTAssertEqual(displayDeductions.count, 5, "Should have 5 deductions items")

        // Find RH12 entry
        let rh12Entry = displayDeductions.first { $0.displayName == "RH12" }
        XCTAssertNotNil(rh12Entry, "Should have RH12 entry")
        XCTAssertEqual(rh12Entry?.value, 7518, "RH12 deduction value should be preserved")
    }

    // MARK: - Edge Cases and Fallback Tests

    func testUnknownKeyCleanup() {
        // Given: Unknown internal key with technical suffixes
        let unknownKey = "UNKNOWN_COMPONENT_EARNINGS"

        // When: Getting display name
        let displayName = displayNameService.getDisplayName(for: unknownKey)

        // Then: Should clean up the key
        XCTAssertEqual(displayName, "Unknown Component", "Should clean up unknown keys")
    }

    func testGenericSuffixHandling() {
        // Given: Generic component with _EARNINGS suffix
        let genericKey = "SOME_ALLOWANCE_EARNINGS"

        // When: Getting display name
        let displayName = displayNameService.getDisplayName(for: genericKey)

        // Then: Should remove suffix and clean up
        XCTAssertEqual(displayName, "Some Allowance", "Should handle generic _EARNINGS suffix")
    }

    func testEmptyAndZeroValueFiltering() {
        // Given: Earnings with zero and negative values
        let earnings: [String: Double] = [
            "BPAY": 144700,
            "ZERO_VALUE": 0,
            "NEGATIVE_VALUE": -100,
            "RH12_EARNINGS": 21125
        ]

        // When: Getting display earnings
        let displayEarnings = displayNameService.getDisplayEarnings(from: earnings)

        // Then: Should filter out zero and negative values
        XCTAssertEqual(displayEarnings.count, 2, "Should only include positive values")

        let displayNames = displayEarnings.map { $0.displayName }
        XCTAssertTrue(displayNames.contains("Basic Pay"), "Should include Basic Pay")
        XCTAssertTrue(displayNames.contains("RH12"), "Should include RH12")
        XCTAssertFalse(displayNames.contains("Zero Value"), "Should not include zero values")
        XCTAssertFalse(displayNames.contains("Negative Value"), "Should not include negative values")
    }
}
