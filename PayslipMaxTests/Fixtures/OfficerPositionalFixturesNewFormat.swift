import CoreGraphics
import Foundation
@testable import PayslipMax

/// New (Nov-2023+) bilingual PCDA(O) positional fixtures, geometry from the plan's
/// "2025 new (y=264)" row (credit label 94 / amount 237, debit label 300 / amount 452).
/// `newDirect` totals template: the printed `Total Deductions` is already the true
/// deductions. Includes the `BPAY (12A)` label so suffix-rejection is exercised.
enum OfficerPositionalFixturesNewFormat {
    private static let layout = ColumnLayout(
        creditLabelX: 94, creditAmountX: 237, debitLabelX: 300, debitAmountX: 452
    )

    static let aug2025 = PositionalFixture(
        label: "2025-08 columnar (new bilingual PCDA-O layout)",
        elements: [
            layout.row(y: 400, credit: ("BPAY (12A)", "144700"), debit: ("DSOP", "40000")),
            layout.row(y: 370, credit: ("DA", "88110"), debit: ("AGIF", "12500")),
            layout.row(y: 340, credit: ("MSP", "15500"), debit: ("ITAX", "47624")),
            layout.row(y: 310, credit: ("RH12", "21125"), debit: ("EHCESS", "1905")),
            layout.row(y: 280, credit: ("TPTA", "3600")),
            layout.row(y: 250, credit: ("TPTADA", "1980")),
            layout.row(y: 210, credit: ("Gross Pay", "275015"), debit: ("Total Deductions", "102029"))
        ].flatMap { $0 },
        expectedEarnings: [
            "BPAY (12A)": 144700, "DA": 88110, "MSP": 15500,
            "RH12": 21125, "TPTA": 3600, "TPTADA": 1980
        ],
        expectedDeductions: [
            "DSOP": 40000, "AGIF": 12500, "ITAX": 47624, "EHCESS": 1905
        ],
        expectedGrossPay: 275015,
        expectedTotalDeductions: 102029,
        expectedNetRemittance: 172986
    )

    static let dec2024 = PositionalFixture(
        label: "2024-12 columnar (new bilingual PCDA-O layout)",
        elements: dec2024Elements,
        expectedEarnings: [
            "BPAY": 140000, "DA": 75000, "MSP": 15500,
            "RH12": 20000, "TPTA": 3600, "TPTADA": 1800
        ],
        expectedDeductions: [
            "DSOP": 39000, "AGIF": 12000, "ITAX": 44000, "EHCESS": 1760
        ],
        expectedGrossPay: 255900,
        expectedTotalDeductions: 96760,
        expectedNetRemittance: 159140
    )

    /// Split out so the type-checker doesn't choke on a long `+` chain.
    private static var dec2024Elements: [PositionalElement] {
        var elements: [PositionalElement] = layout.stack([
            .init(credit: ("BPAY", "140000"), debit: ("DSOP", "39000")),
            .init(credit: ("DA", "75000"), debit: ("AGIF", "12000")),
            .init(credit: ("MSP", "15500"), debit: ("ITAX", "44000")),
            .init(credit: ("RH12", "20000"), debit: ("EHCESS", "1760")),
            .init(credit: ("TPTA", "3600")),
            .init(credit: ("TPTADA", "1800"))
        ])
        elements += layout.row(y: 232, credit: ("Gross Pay", "255900"), debit: ("Total Deductions", "96760"))
        return elements
    }
}
