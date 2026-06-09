import CoreGraphics
import Foundation

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
}
