import CoreGraphics
import Foundation

/// Old (7th-CPC, 2016–Oct-2023) PCDA(O) positional fixtures, geometry from the plan's
/// "2023 old (y=225)" row (credit label 20 / amount 120, debit label 157 / amount 276,
/// narrative column at x ≥ 311). `oldFolded` totals template: printed `Total Debit ≈
/// Total Credit`, so the true deductions are `Total Credit − REMITTANCE`.
///
/// `aug2023` additionally bakes a "DETAILS OF TRANSACTIONS" header and a stray narrative
/// amount (`1436@330`) so the narrative-cutoff drop is exercised.
enum OfficerPositionalFixturesOldFormat {
    private static let layout = ColumnLayout(
        creditLabelX: 20, creditAmountX: 120, debitLabelX: 157, debitAmountX: 276
    )

    static let aug2023 = PositionalFixture(
        label: "2023-08 columnar (old PCDA-O layout)",
        elements: [
            [ColumnarFixture.el("DETAILS OF TRANSACTIONS", x: 311, y: 430)],
            layout.row(y: 400, credit: ("Basic Pay", "136400"), debit: ("DSOPF Subn", "40000")),
            [ColumnarFixture.el("1436", x: 330, y: 400)],
            layout.row(y: 370, credit: ("DA", "63798"), debit: ("AGIF", "10000")),
            layout.row(y: 340, credit: ("MSP", "15500"), debit: ("Incm Tax", "40560")),
            layout.row(y: 310, credit: ("Tpt Allc", "5112"), debit: ("Educ Cess", "1620")),
            layout.row(y: 280, debit: ("R/o Etkt", "4308")),
            layout.row(y: 250, debit: ("L Fee", "878")),
            layout.row(y: 220, debit: ("Fur", "392")),
            layout.row(y: 190, credit: ("Total Credit", "220810"), debit: ("Total Debit", "220810")),
            [ColumnarFixture.el("REMITTANCE", x: 20, y: 160), ColumnarFixture.el("123052", x: 120, y: 160)]
        ].flatMap { $0 },
        expectedEarnings: [
            "Basic Pay": 136400, "DA": 63798, "MSP": 15500, "Tpt Allc": 5112
        ],
        expectedDeductions: [
            "DSOPF Subn": 40000, "AGIF": 10000, "Incm Tax": 40560, "Educ Cess": 1620,
            "R/o Etkt": 4308, "L Fee": 878, "Fur": 392
        ],
        expectedGrossPay: 220810,
        expectedTotalDeductions: 97758,
        expectedNetRemittance: 123052
    )

    static let aug2022 = PositionalFixture(
        label: "2022-08 columnar (old PCDA-O layout)",
        elements: [
            layout.row(y: 400, credit: ("Basic Pay", "132400"), debit: ("DSOPF Subn", "7944")),
            layout.row(y: 370, credit: ("DA", "50286"), debit: ("AGIF", "10000")),
            layout.row(y: 340, credit: ("MSP", "15500"), debit: ("Incm Tax", "40970")),
            layout.row(y: 310, credit: ("Tpt Allc", "4824"), debit: ("Educ Cess", "2030")),
            layout.row(y: 280, debit: ("L Fee", "748")),
            layout.row(y: 250, debit: ("Fur", "326")),
            layout.row(y: 220, debit: ("Water", "840")),
            layout.row(y: 190, debit: ("Elec", "13095")),
            layout.row(y: 160, credit: ("Total Credit", "203010"), debit: ("Total Debit", "203010")),
            [ColumnarFixture.el("REMITTANCE", x: 20, y: 130), ColumnarFixture.el("127057", x: 120, y: 130)]
        ].flatMap { $0 },
        expectedEarnings: [
            "Basic Pay": 132400, "DA": 50286, "MSP": 15500, "Tpt Allc": 4824
        ],
        expectedDeductions: [
            "DSOPF Subn": 7944, "AGIF": 10000, "Incm Tax": 40970, "Educ Cess": 2030,
            "L Fee": 748, "Fur": 326, "Water": 840, "Elec": 13095
        ],
        expectedGrossPay: 203010,
        expectedTotalDeductions: 75953,
        expectedNetRemittance: 127057
    )
}
