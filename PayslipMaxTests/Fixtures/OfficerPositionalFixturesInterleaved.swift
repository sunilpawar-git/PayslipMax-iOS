import CoreGraphics
import Foundation
@testable import PayslipMax

/// Nov-2023 "interleaved" bilingual PCDA(O) positional fixtures, geometry from the plan's
/// interleaved row (credit label 44 / amount 150, debit label 186 / amount 275, narrative
/// column at x ≥ 325). In real slips the *reading order* interleaves credit and debit
/// tokens, but the geometry stays cleanly column-separable — exactly what the position-aware
/// extractor exploits. `newDirect` totals template (printed `Total Deductions` is the truth).
///
/// `nov2023` bakes a "DETAILS OF TRANSACTIONS" header + a stray narrative amount so the
/// cutoff drop is exercised. `jan2024Etkt` carries `ETKT` as **both** a credit and a debit
/// (the plan's `ETKT 484@x44 vs 2129@x186` ambiguity), proving column geometry — not
/// vocabulary — disambiguates a repeated code.
enum OfficerPositionalFixturesInterleaved {
    private static let layout = ColumnLayout(
        creditLabelX: 44, creditAmountX: 150, debitLabelX: 186, debitAmountX: 275
    )

    static let nov2023 = PositionalFixture(
        label: "2023-11 columnar (Nov-2023 interleaved bilingual PCDA-O layout)",
        elements: nov2023Elements,
        expectedEarnings: [
            "BPAY": 142400, "DA": 78320, "MSP": 15500, "TPTA": 3600, "TPTADA": 1872
        ],
        expectedDeductions: [
            "DSOP": 38000, "AGIF": 11000, "ITAX": 35000, "EHCESS": 1400
        ],
        expectedGrossPay: 241692,
        expectedTotalDeductions: 85400,
        expectedNetRemittance: 156292
    )

    static let jan2024Etkt = PositionalFixture(
        label: "2024-01 columnar (interleaved, ETKT in both credit & debit columns)",
        elements: jan2024Elements,
        expectedEarnings: [
            "BPAY": 144700, "DA": 80000, "MSP": 15500, "ETKT": 484, "TPTA": 3600
        ],
        expectedDeductions: [
            "DSOP": 40000, "AGIF": 12000, "ITAX": 38000, "ETKT": 2129, "EHCESS": 1500
        ],
        expectedGrossPay: 244284,
        expectedTotalDeductions: 93629,
        expectedNetRemittance: 150655
    )

    // MARK: - Element builders (split out to keep the type-checker fast)

    private static var nov2023Elements: [PositionalElement] {
        var elements: [PositionalElement] = [ColumnarFixture.el("DETAILS OF TRANSACTIONS", x: 325, y: 430)]
        elements += layout.stack([
            .init(credit: ("BPAY", "142400"), debit: ("DSOP", "38000")),
            .init(credit: ("DA", "78320"), debit: ("AGIF", "11000")),
            .init(credit: ("MSP", "15500"), debit: ("ITAX", "35000")),
            .init(credit: ("TPTA", "3600"), debit: ("EHCESS", "1400")),
            .init(credit: ("TPTADA", "1872"))
        ])
        // Stray narrative amount on the top line — must be dropped (x ≥ cutoff 325).
        elements.append(ColumnarFixture.el("1500", x: 340, y: 400))
        elements += layout.row(y: 256, credit: ("Gross Pay", "241692"), debit: ("Total Deductions", "85400"))
        return elements
    }

    private static var jan2024Elements: [PositionalElement] {
        var elements: [PositionalElement] = layout.stack([
            .init(credit: ("BPAY", "144700"), debit: ("DSOP", "40000")),
            .init(credit: ("DA", "80000"), debit: ("AGIF", "12000")),
            .init(credit: ("MSP", "15500"), debit: ("ITAX", "38000")),
            .init(credit: ("ETKT", "484"), debit: ("ETKT", "2129")),
            .init(credit: ("TPTA", "3600"), debit: ("EHCESS", "1500"))
        ])
        elements += layout.row(y: 280, credit: ("Gross Pay", "244284"), debit: ("Total Deductions", "93629"))
        return elements
    }
}
