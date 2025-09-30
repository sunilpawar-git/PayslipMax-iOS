//
//  PayslipDataCompatibilityTests.swift
//  PayslipMaxTests
//
//  Tests for backward compatibility with legacy key formats
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import XCTest
@testable import PayslipMax

final class PayslipDataCompatibilityTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    // MARK: - Backward Compatibility Tests

    func testBackwardCompatibilityWithLegacyKeys() {
        // Test that legacy single keys still work alongside dual-section keys
        let mockPayslip = PayslipDataTestHelpers.createMockPayslipWithMixedKeys()
        let payslipData = PayslipData(from: mockPayslip)

        // Verify legacy keys are handled
        XCTAssertEqual(payslipData.basicPay, 50000.0, "Legacy BPAY should work")
        XCTAssertEqual(payslipData.militaryServicePay, 15500.0, "Legacy MSP should work")

        // Verify dual-section keys are handled
        XCTAssertTrue(payslipData.allEarnings.keys.contains("DA_EARNINGS") || payslipData.dearnessPay > 0,
                      "DA dual-section should work alongside legacy")

        // Verify no data loss
        let totalInput = mockPayslip.credits
        let totalProcessed = payslipData.totalCredits
        XCTAssertEqual(totalInput, totalProcessed, "No data should be lost in mixed key processing")
    }
}
