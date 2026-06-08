import Foundation

/// New (Nov-2023+) bilingual PCDA(O) officer layout fixtures.
///
/// These extract as clean label-then-value digital text and use the modern
/// pay-code vocabulary (BPAY, DA, MSP, DSOP, AGIF, ITAX, EHCESS, …) already in
/// the catalogue — so they parse fully offline today and serve as the
/// **regression guard** that must stay green through every later phase.
enum OfficerFixturesNewFormat {
    /// 08/2025 — PCDA(O) "print" layout, all financials consolidated on page 1.
    static let aug2025 = OfficerSlipFixture(
        label: "2025-08 (new bilingual PCDA-O layout)",
        rawText: """
        08/2025  kI laoKa ivavarNaI  / STATEMENT OF ACCOUNT FOR 08/2025
        naama/Name:
        Test Officer
        laoKa saM#yaa /A/C No:
        XX/XXX/XXXXXXX
        sqaayaI Kata saM#yaa/PAN No:
        AB*****00X
        Aaya / EARNINGS (`)
        kTaOtI / DEDUCTIONS (`)
        ivavarNa
        Description
        raiSa
        Amount
        ivavarNa
        Description
        raiSa
        Amount
        BPAY (12A)
        144700
        DA
        88110
        MSP
        15500
        RH12
        21125
        TPTA
        3600
        TPTADA
        1980
        DSOP
        40000
        AGIF
        12500
        ITAX
        47624
        EHCESS
        1905
        kula Aaya
        Gross Pay
        275015
        kula kTaOtI
        Total Deductions
        102029
        AgalaI vaotna vaR/iw kI tarIK  / Next Increment Date:01/01/2026
        inavala p`oiYat Qana/Net Remittance : Rs.1,72,986 (One Lakh Seventy Two Thousand Nine
        Hundred Eighty Six  only)
        Page 1 of
        7
        """,
        expectedEarnings: [
            "BPAY": 144700, "DA": 88110, "MSP": 15500,
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
