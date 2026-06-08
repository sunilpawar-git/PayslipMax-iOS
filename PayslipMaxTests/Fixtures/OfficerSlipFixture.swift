import XCTest
@testable import PayslipMax

/// A labeled PCDA(O) officer payslip fixture: the (PII-sanitized) page-1 text
/// extracted from a real slip, paired with its co-verified ground-truth oracle.
///
/// Identity PII (name / account number / PAN) is redacted in `rawText`; **all**
/// financial line items and totals are preserved verbatim so the oracle exercises
/// the real offline officer parse (`UniversalPayslipProcessor`).
///
/// Phase A0 (regression harness). See `you-re-a-senior-ios-majestic-gem.md`.
struct OfficerSlipFixture {
    /// Human-readable identifier, e.g. "2023-08 (old PCDA-O layout)".
    let label: String
    /// PII-sanitized page-1 text as extracted from the source PDF.
    let rawText: String
    /// Canonical credit line items → amount (documentation + amount oracle).
    let expectedEarnings: [String: Double]
    /// Canonical debit line items → amount.
    let expectedDeductions: [String: Double]
    /// Gross pay anchor (== sum of `expectedEarnings`).
    let expectedGrossPay: Double
    /// Total deductions (== sum of `expectedDeductions`); the *true* deductions,
    /// not the balanced-sheet "Total Debit" figure printed on old-format slips.
    let expectedTotalDeductions: Double
    /// Net remittance (== gross − deductions).
    let expectedNetRemittance: Double

    var expectedEarningsAmounts: [Double] { expectedEarnings.values.sorted() }
    var expectedDeductionAmounts: [Double] { expectedDeductions.values.sorted() }
}

/// Drives a fixture through the offline officer parse and asserts the acceptance bar:
/// every credit/debit line item extracted **and** gross/deductions/net reconcile.
enum OfficerParsingHarness {
    /// Tolerance for totals reconciliation (whole rupees).
    static let tolerance: Double = 1.0

    /// Runs the pure-offline officer parse (no OCR, no LLM, no network).
    static func parse(_ fixture: OfficerSlipFixture) async throws -> PayslipItem {
        let processor = UniversalPayslipProcessor()
        return try await processor.processPayslip(from: fixture.rawText)
    }

    /// Async convenience: parse then assert the full acceptance bar
    /// (totals **and** every line item).
    static func assertFullyParsed(
        _ fixture: OfficerSlipFixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let item = try await parse(fixture)
        assertTotals(item, against: fixture, file: file, line: line)
        assertLineItems(item, against: fixture, file: file, line: line)
    }

    /// Totals/anchors reconciliation — gross, deductions, net.
    ///
    /// Anchors (`Total Credit`/`Gross Pay`, `Total Debit`/`Total Deductions`,
    /// `REMITTANCE`/`Net Remittance`) are extracted reliably for the new layout, so
    /// this is the **regression guard** that must stay green. For the old layout the
    /// printed "Total Debit" folds in remittance, so `debits` does not yet equal the
    /// true deductions — that gap is part of the Track-A work.
    ///
    /// Kept synchronous so it composes with `XCTExpectFailure` (whose closure is not
    /// async) for the documented red baselines.
    static func assertTotals(
        _ item: PayslipItem,
        against fixture: OfficerSlipFixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            item.credits, fixture.expectedGrossPay, accuracy: tolerance,
            "\(fixture.label): gross pay anchor mismatch", file: file, line: line
        )
        XCTAssertEqual(
            item.debits, fixture.expectedTotalDeductions, accuracy: tolerance,
            "\(fixture.label): total deductions anchor mismatch", file: file, line: line
        )
        XCTAssertEqual(
            item.credits - item.debits, fixture.expectedNetRemittance, accuracy: tolerance,
            "\(fixture.label): gross − deductions does not equal net remittance", file: file, line: line
        )
    }

    /// Every credit/debit **line item** extracted and summing to the totals.
    ///
    /// This is the harder bar the offline regex path does **not** clear today (for
    /// either layout): values are mis-associated (`BPAY (12A)` → `12`) and spurious
    /// duplicate components are emitted. Documented red until the Track-A fixes land.
    static func assertLineItems(
        _ item: PayslipItem,
        against fixture: OfficerSlipFixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            item.earnings.values.sorted(), fixture.expectedEarningsAmounts,
            "\(fixture.label): credit line items mismatch (expected \(fixture.expectedEarnings))",
            file: file, line: line
        )
        XCTAssertEqual(
            item.deductions.values.sorted(), fixture.expectedDeductionAmounts,
            "\(fixture.label): debit line items mismatch (expected \(fixture.expectedDeductions))",
            file: file, line: line
        )

        let earningsTotal = item.earnings.values.reduce(0, +)
        let deductionsTotal = item.deductions.values.reduce(0, +)
        XCTAssertEqual(
            earningsTotal, fixture.expectedGrossPay, accuracy: tolerance,
            "\(fixture.label): earnings line items do not reconcile to gross pay", file: file, line: line
        )
        XCTAssertEqual(
            deductionsTotal, fixture.expectedTotalDeductions, accuracy: tolerance,
            "\(fixture.label): deduction line items do not reconcile to total deductions", file: file, line: line
        )
    }
}
