import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Plan Phase 3 — reconciliation gate + builder.**
///
/// The gate is the hard acceptance bar: a result is accepted only when earnings sum to
/// gross, deductions sum to the true deductions, and gross − deductions equals net (±1).
/// The builder turns an accepted result into a `PayslipItem` whose `credits/debits` and
/// line-item maps reconcile, stamped `parsing.path == "columnar"`.
@MainActor
final class OfficerColumnarReconciliationTests: XCTestCase {
    private let gate = OfficerColumnarReconciliationGate()
    private let builder = OfficerColumnarPayslipBuilder()

    // MARK: - Gate acceptance

    func test_gate_acceptsReconcilingResult() {
        XCTAssertTrue(gate.accept(Self.reconcilingResult()))
    }

    /// Earnings that don't sum to gross (a dropped/mis-paired line item) are rejected.
    func test_gate_rejectsEarningsMismatch() {
        let result = OfficerColumnarResult(
            earnings: ["BPAY": 100000, "DA": 50000],   // sums to 150000, not 275015
            deductions: ["DSOP": 102029],
            grossPay: 275015,
            totalDeductions: 102029,
            netRemittance: 172986,
            template: .newDirect
        )
        XCTAssertFalse(gate.accept(result))
    }

    /// Deductions that don't sum to the true deductions are rejected.
    func test_gate_rejectsDeductionsMismatch() {
        let result = OfficerColumnarResult(
            earnings: ["BPAY": 275015],
            deductions: ["DSOP": 40000],               // sums to 40000, not 102029
            grossPay: 275015,
            totalDeductions: 102029,
            netRemittance: 172986,
            template: .newDirect
        )
        XCTAssertFalse(gate.accept(result))
    }

    /// A net that doesn't equal gross − deductions is rejected even when both sides sum.
    func test_gate_rejectsNetMismatch() {
        let result = OfficerColumnarResult(
            earnings: ["BPAY": 275015],
            deductions: ["DSOP": 102029],
            grossPay: 275015,
            totalDeductions: 102029,
            netRemittance: 999999,                     // != 172986
            template: .newDirect
        )
        XCTAssertFalse(gate.accept(result))
    }

    // MARK: - Builder

    func test_builder_producesReconcilingPayslipItem() {
        let item = builder.build(Self.reconcilingResult())

        XCTAssertEqual(item.credits, 275015, accuracy: 1)
        XCTAssertEqual(item.debits, 102029, accuracy: 1)
        XCTAssertEqual(item.credits - item.debits, 172986, accuracy: 1)

        XCTAssertEqual(item.earnings.values.reduce(0, +), item.credits, accuracy: 1)
        XCTAssertEqual(item.deductions.values.reduce(0, +), item.debits, accuracy: 1)
        XCTAssertEqual(item.earnings, Self.reconcilingResult().earnings)
        XCTAssertEqual(item.deductions, Self.reconcilingResult().deductions)
    }

    /// `dsop`/`tax` are pulled from the verbatim deduction labels.
    func test_builder_pullsDsopAndTaxByLabel() {
        let item = builder.build(Self.reconcilingResult())
        XCTAssertEqual(item.dsop, 40000, accuracy: 1)
        XCTAssertEqual(item.tax, 47624, accuracy: 1)
    }

    func test_builder_stampsColumnarPath() {
        let item = builder.build(Self.reconcilingResult())
        XCTAssertEqual(item.metadata["parsing.path"], "columnar")
        XCTAssertEqual(item.metadata["parsing.template"], "newDirect")
    }

    func test_builder_stampsOldFoldedTemplate() {
        let result = OfficerColumnarResult(
            earnings: ["Basic Pay": 220810],
            deductions: ["DSOP": 97758],
            grossPay: 220810,
            totalDeductions: 97758,
            netRemittance: 123052,
            template: .oldFolded
        )
        XCTAssertEqual(builder.build(result).metadata["parsing.template"], "oldFolded")
    }

    /// Without first-page text the builder still yields a valid item with safe defaults.
    func test_builder_defaultsIdentityWithoutText() {
        let item = builder.build(Self.reconcilingResult())
        XCTAssertEqual(item.name, "Defense Personnel")
        XCTAssertEqual(item.accountNumber, "")
        XCTAssertEqual(item.panNumber, "")
    }

    // MARK: - Fixtures

    private static func reconcilingResult() -> OfficerColumnarResult {
        OfficerColumnarResult(
            earnings: [
                "BPAY (12A)": 144700, "DA": 88110, "MSP": 15500,
                "RH12": 21125, "TPTA": 3600, "TPTADA": 1980
            ],
            deductions: ["DSOP": 40000, "AGIF": 12500, "ITAX": 47624, "EHCESS": 1905],
            grossPay: 275015,
            totalDeductions: 102029,
            netRemittance: 172986,
            template: .newDirect
        )
    }
}
