import XCTest
import SwiftUI
@testable import PayslipMax

final class ChangeArrowIndicatorTests: XCTestCase {

    func testIncreasedEarningShowsUpArrowGreen() {
        let config = ChangeArrowIndicator(direction: .increased, isEarning: true).debugConfig()
        XCTAssertEqual(config.icon, "arrow.up")
        XCTAssertEqual(config.accessibility, "Amount increased")
        XCTAssertEqual(config.color, FintechColors.successGreen)
    }

    func testDecreasedEarningShowsDownArrowRed() {
        let config = ChangeArrowIndicator(direction: .decreased, isEarning: true).debugConfig()
        XCTAssertEqual(config.icon, "arrow.down")
        XCTAssertEqual(config.accessibility, "Amount decreased")
        XCTAssertEqual(config.color, FintechColors.dangerRed)
    }

    func testNewEarningUsesLeftArrowGrey() {
        let config = ChangeArrowIndicator(direction: .new, isEarning: true).debugConfig()
        XCTAssertEqual(config.icon, "arrow.left")
        XCTAssertEqual(config.accessibility, "New earning")
        XCTAssertEqual(config.color, FintechColors.textSecondary)
    }

    func testNewDeductionUsesRightArrowGrey() {
        let config = ChangeArrowIndicator(direction: .new, isEarning: false).debugConfig()
        XCTAssertEqual(config.icon, "arrow.right")
        XCTAssertEqual(config.accessibility, "New deduction")
        XCTAssertEqual(config.color, FintechColors.textSecondary)
    }

    func testUnchangedUsesMinusTertiary() {
        let config = ChangeArrowIndicator(direction: .unchanged, isEarning: true).debugConfig()
        XCTAssertEqual(config.icon, "minus")
        XCTAssertEqual(config.accessibility, "Amount unchanged")
        XCTAssertEqual(config.color, FintechColors.textTertiary)
    }
}

