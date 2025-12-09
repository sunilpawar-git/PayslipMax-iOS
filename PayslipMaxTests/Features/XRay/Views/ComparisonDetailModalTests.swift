import XCTest
import SwiftUI
@testable import PayslipMax

final class ComparisonDetailModalTests: XCTestCase {

    func testNewEarningShowsNewMessaging() {
        let comparison = ItemComparison(
            itemName: "Bonus",
            currentAmount: 15000,
            previousAmount: nil,
            absoluteChange: 15000,
            percentageChange: nil,
            needsAttention: false
        )

        let summary = ComparisonDetailModal(itemComparison: comparison, isEarning: true).debugSummary()
        XCTAssertEqual(summary.direction, .new)
        XCTAssertEqual(summary.icon, "plus.circle.fill")
        XCTAssertEqual(summary.directionText, "New Earning")
        XCTAssertTrue(summary.explanation.contains("first time"))
    }

    func testEarningDecreaseNeedsAttentionShowsDecreasedMessaging() {
        let comparison = ItemComparison(
            itemName: "Basic Pay",
            currentAmount: 45000,
            previousAmount: 50000,
            absoluteChange: -5000,
            percentageChange: -10.0,
            needsAttention: true
        )

        let summary = ComparisonDetailModal(itemComparison: comparison, isEarning: true).debugSummary()
        XCTAssertEqual(summary.direction, .decreased)
        XCTAssertEqual(summary.icon, "arrow.down")
        XCTAssertEqual(summary.directionText, "Earning Decreased")
        XCTAssertTrue(summary.explanation.contains("decreased"))
    }

    func testDeductionIncreaseNeedsAttentionShowsDeductionMessaging() {
        let comparison = ItemComparison(
            itemName: "Tax",
            currentAmount: 12000,
            previousAmount: 10000,
            absoluteChange: 2000,
            percentageChange: 20.0,
            needsAttention: true
        )

        let summary = ComparisonDetailModal(itemComparison: comparison, isEarning: false).debugSummary()
        XCTAssertEqual(summary.direction, .increased)
        XCTAssertEqual(summary.icon, "arrow.up")
        XCTAssertEqual(summary.directionText, "Deduction Increased")
        XCTAssertTrue(summary.explanation.contains("increased"))
    }

    func testNoChangeShowsNoChangeMessaging() {
        let comparison = ItemComparison(
            itemName: "HRA",
            currentAmount: 30000,
            previousAmount: 30000,
            absoluteChange: 0,
            percentageChange: 0,
            needsAttention: false
        )

        let summary = ComparisonDetailModal(itemComparison: comparison, isEarning: true).debugSummary()
        XCTAssertEqual(summary.direction, .unchanged)
        XCTAssertEqual(summary.icon, "arrow.down") // default branch uses arrow.down when no increase
        XCTAssertEqual(summary.directionText, "No Change")
        XCTAssertTrue(summary.explanation.contains("improved"))
    }
}

