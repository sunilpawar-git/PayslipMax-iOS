import Foundation

/// Old (7th-CPC, 2016–Oct-2023) PCDA(O) officer layout fixtures.
///
/// These **also** extract as clean digital text — the only gap is *vocabulary*:
/// older spellings for the same components (`Basic Pay`, `DSOPF Subn`, `Incm Tax`,
/// `Tpt Allc`, `Educ Cess`, `L Fee`, `Fur`, `R/o Etkt`) are absent from the
/// catalogue/alias tables, so the line items fail to extract today.
///
/// Phase A0 expects these **red**; Phase A1 (vocabulary expansion) closes the gap.
/// Note the old-layout quirk: the printed "Total Debit" equals "Total Credit"
/// (it folds remittance into debits); the oracle below uses the *true* deductions.
enum OfficerFixturesOldFormat {
    /// 08/2023 — the canonical old-format oracle (matches the plan).
    static let aug2023 = OfficerSlipFixture(
        label: "2023-08 (old PCDA-O layout)",
        rawText: """
        Issued by PCDA(O), Min of Defence, Govt of INDIA.
        08/2023
        STATEMENT OF ACCOUNT FOR 08/2023
        CDA A/C NO
         : XX/XXX/XXXXXXX
        NAME  : TEST OFFICER
          /  CREDIT
          /  DEBIT
        /   DETAILS OF TRANSACTIONS
        DESCRIPTION
        AMOUNT
        DESCRIPTION
        AMOUNT
        Basic Pay
        136400
        DA
        63798
        MSP
        15500
        Tpt Allc
        5112
        DSOPF Subn
        40000
        AGIF
        10000
        Incm Tax
        40560
        Educ Cess
        1620
        R/o Etkt
        4308
        L Fee
        878
        Fur
        392
        Total Credit
        220810
        Total Debit
        220810
        REMITTANCE
        123052
        Page - 1 / 4
        """,
        expectedEarnings: [
            "Basic Pay": 136400, "DA": 63798, "MSP": 15500, "Transport Allowance": 5112
        ],
        expectedDeductions: [
            "DSOP": 40000, "AGIF": 10000, "Income Tax": 40560,
            "Education & Health Cess": 1620, "E-Ticketing Recovery": 4308,
            "Licence Fee": 878, "Furniture": 392
        ],
        expectedGrossPay: 220810,
        expectedTotalDeductions: 97758,
        expectedNetRemittance: 123052
    )

    /// 08/2022 — a second old-format year, including utility recoveries (Water, Elec).
    static let aug2022 = OfficerSlipFixture(
        label: "2022-08 (old PCDA-O layout)",
        rawText: """
        08/2022
        STATEMENT OF ACCOUNT FOR 08/2022
        CDA A/C NO
         : XX/XXX/XXXXXXX
        NAME  : TEST OFFICER
          /  CREDIT
          /  DEBIT
        /   DETAILS OF TRANSACTIONS
        DESCRIPTION
        AMOUNT
        DESCRIPTION
        AMOUNT
        Basic Pay
        132400
        DA
        50286
        MSP
        15500
        Tpt Allc
        4824
        DSOPF Subn
        7944
        AGIF
        10000
        Incm Tax
        40970
        Educ Cess
        2030
        L Fee
        748
        Fur
        326
        Water
        840
        Elec
        13095
        Total Credit
        203010
        Total Debit
        203010
        REMITTANCE
        127057
        Page - 1 / 3
        """,
        expectedEarnings: [
            "Basic Pay": 132400, "DA": 50286, "MSP": 15500, "Transport Allowance": 4824
        ],
        expectedDeductions: [
            "DSOP": 7944, "AGIF": 10000, "Income Tax": 40970,
            "Education & Health Cess": 2030, "Licence Fee": 748, "Furniture": 326,
            "Water": 840, "Electricity": 13095
        ],
        expectedGrossPay: 203010,
        expectedTotalDeductions: 75953,
        expectedNetRemittance: 127057
    )
}
