import XCTest
@testable import PayslipMax

/// Columnar extension of the A0 harness: runs the **position-aware** extractor over a
/// `PositionalFixture` and asserts the full acceptance bar (every line item extracted
/// **and** gross/deductions/net reconcile) — the bar the offline regex path never cleared.
extension OfficerParsingHarness {
    @MainActor
    static func parseColumnar(_ fixture: PositionalFixture) async -> OfficerColumnarResult? {
        await OfficerColumnarExtractor().extract(from: fixture.elements)
    }

    static func assertColumnarFullyParsed(
        _ result: OfficerColumnarResult?,
        against fixture: PositionalFixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let result else {
            XCTFail("\(fixture.label): columnar extractor returned nil", file: file, line: line)
            return
        }
        XCTAssertEqual(
            result.earnings.values.sorted(), fixture.expectedEarningsAmounts,
            "\(fixture.label): credit line items mismatch (expected \(fixture.expectedEarnings))",
            file: file, line: line
        )
        XCTAssertEqual(
            result.deductions.values.sorted(), fixture.expectedDeductionAmounts,
            "\(fixture.label): debit line items mismatch (expected \(fixture.expectedDeductions))",
            file: file, line: line
        )
        assertTotalsReconcile(result, against: fixture, file: file, line: line)
    }

    private static func assertTotalsReconcile(
        _ result: OfficerColumnarResult,
        against fixture: PositionalFixture,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(result.grossPay, fixture.expectedGrossPay, accuracy: tolerance,
                       "\(fixture.label): gross pay mismatch", file: file, line: line)
        XCTAssertEqual(result.totalDeductions, fixture.expectedTotalDeductions, accuracy: tolerance,
                       "\(fixture.label): true deductions mismatch", file: file, line: line)
        XCTAssertEqual(result.netRemittance, fixture.expectedNetRemittance, accuracy: tolerance,
                       "\(fixture.label): net remittance mismatch", file: file, line: line)
        XCTAssertEqual(result.earnings.values.reduce(0, +), fixture.expectedGrossPay, accuracy: tolerance,
                       "\(fixture.label): earnings do not reconcile to gross", file: file, line: line)
        XCTAssertEqual(result.deductions.values.reduce(0, +), fixture.expectedTotalDeductions, accuracy: tolerance,
                       "\(fixture.label): deductions do not reconcile to true deductions", file: file, line: line)
    }
}
