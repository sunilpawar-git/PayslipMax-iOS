//
//  GradeAgnosticExtractionTestData.swift
//  PayslipMaxTests
//
//  Test data constants and payslip text creation for GradeAgnosticExtractionTests
//

import Foundation

/// Test data constants for grade-agnostic extraction tests
struct GradeAgnosticExtractionTestData {

    /// Military rank data with pay scales
    static let militaryRankData: [(level: String, rank: String, minPay: Double, maxPay: Double)] = [
        ("10", "Lieutenant", 56100, 177500),
        ("10B", "Captain", 61300, 193900),
        ("11", "Major", 69400, 207200),
        ("12A", "Lieutenant Colonel", 121200, 212400),
        ("13", "Colonel", 130600, 215900),
        ("13A", "Brigadier", 139600, 217600),
        ("14", "Major General", 144200, 218200),
        ("HAG", "Lieutenant General", 182200, 224100),
        ("APEX", "General", 250000, 250000)
    ]

    /// Grade inference test cases
    static let gradeInferenceTestCases: [(basicPay: Double, expectedGrade: String?, rank: String)] = [
        (56100, "10", "Lieutenant"),
        (61300, "10B", "Captain"),
        (69400, "11", "Major"),
        (144700, "12A", "Lieutenant Colonel"),
        (130600, "13", "Colonel"),
        (139600, "13A", "Brigadier"),
        (144200, "14", "Major General"),
        (182200, "HAG", "Lieutenant General"),
        (250000, "APEX", "General")
    ]

    /// DA validation test cases
    static let daValidationTestCases: [(daPercentage: Double, shouldPass: Bool, description: String)] = [
        (0.30, false, "30% - Below fallback range"),
        (0.35, true, "35% - At fallback minimum"),
        (0.40, true, "40% - Standard minimum"),
        (0.50, true, "50% - Standard rate"),
        (0.58, true, "58% - February 2025 actual"),
        (0.60, true, "60% - High but valid"),
        (0.65, true, "65% - Standard maximum"),
        (0.70, true, "70% - At fallback maximum"),
        (0.75, false, "75% - Above fallback range")
    ]

    /// Component validation test cases
    static let componentValidationTestCases: [(component: String, amount: Double, shouldPass: Bool)] = [
        ("DA", 84906, true),     // February 2025 DA (58.7%)
        ("DA", 50795, true),     // Minimum fallback range (35%)
        ("DA", 101190, true),    // Maximum fallback range (70%)
        ("DA", 43410, false),    // Below range (30%)
        ("RH12", 21125, true),   // Valid RH12 amount
        ("RH12", 35000, false),  // Above RH12 range
        ("MSP", 15500, true),    // Valid MSP amount
        ("MSP", 20000, false),   // Above MSP range
        ("TPTA", 3600, true),    // Valid TPTA amount
        ("TPTADA", 1908, true)   // Valid TPTADA amount
    ]

    /// February 2025 payslip text for testing
    static func createFebruary2025PayslipText() -> String {
        return """
        Principal Controller of Defence Accounts (Officers), Pune
        02/2025 कि लेखा विवरणी / STATEMENT OF ACCOUNT FOR 02/2025

        Name: Sunil Suresh Pawar         A/C No - 16/110/206718K

        आय/EARNINGS (₹)    कटौती/DEDUCTIONS (₹)    लेन देन का विवरण/DETAILS OF TRANSACTIONS

        विवरण        राशि    विवरण        राशि
        Description  Amount  Description  Amount

        BPAY        144700  DSOP        40000
        DA          84906   AGIF        10000
        MSP         15500   ITAX        57028
        RH12        21125   EHCESS      2282
        TPTA        3600
        TPTADA      1908

        कुल आय      271739  कुल कटौती    109310
        Gross Pay           Total Deductions

        Net Remittance : Rs.1,62,429 (One Lakh Sixty Two Thousand Four Hundred Twenty Nine only)
        """
    }

    /// May 2025 payslip text for testing
    static func createMay2025PayslipText() -> String {
        return """
        Principal Controller of Defence Accounts (Officers), Pune
        05/2025 कि लेखा विवरणी / STATEMENT OF ACCOUNT FOR 05/2025

        Name: Sunil Suresh Pawar         A/C No - 16/110/206718K
        Next Increment Date:01/01/2026

        आय/EARNINGS (₹)                कटौती/DEDUCTIONS (₹)

        विवरण        राशि              विवरण        राशि
        Description  Amount            Description  Amount

        BPAY (12A)  144700            RH12         7518
        DA          88110             DSOP         40000
        MSP         15500             AGIF         12500
        RH12        21125             ITAX         46641
        TPTA        3600              EHCESS       1866
        TPTADA      1980
        ARR-RSHNA   1650

        कुल आय      276665            कुल कटौती     108525
        Gross Pay                     Total Deductions

        Net Remittance : Rs.1,68,140 (One Lakh Sixty Eight Thousand One Hundred Forty only)
        """
    }

    /// Test payslip text without grade identifier
    static func createFebruaryTextWithoutGrade() -> String {
        return """
        Principal Controller of Defence Accounts (Officers), Pune
        02/2025 STATEMENT OF ACCOUNT FOR 02/2025

        आय/EARNINGS (₹)                    कटौती/DEDUCTIONS (₹)
        Description     Amount             Description     Amount
        BPAY           144700             DSOP           40000
        DA             84906              AGIF           10000
        MSP            15500              ITAX           57028
        RH12           21125              EHCESS         2282
        TPTA           3600
        TPTADA         1908

        कुल आय         271739            कुल कटौती       109310
        Gross Pay                        Total Deductions
        """
    }

    /// Test payslip text with grade identifier
    static func createMayTextWithGrade() -> String {
        return """
        Principal Controller of Defence Accounts (Officers), Pune
        05/2025 STATEMENT OF ACCOUNT FOR 05/2025

        आय/EARNINGS (₹)                    कटौती/DEDUCTIONS (₹)
        Description     Amount             Description     Amount
        BPAY (12A)     144700             RH12           7518
        DA             88110              DSOP           40000
        MSP            15500              AGIF           12500
        RH12           21125              ITAX           46641
        TPTA           3600               EHCESS         1866
        TPTADA         1980
        ARR-RSHNA      1650

        कुल आय         276665            कुल कटौती       108525
        Gross Pay                        Total Deductions
        """
    }

    /// Edge case payslip text for testing alternative labels
    static func createEdgeCaseText() -> String {
        return """
        BASIC PAY   144700    // Different label variant
        DA          84906     // February 2025 DA amount (58.7% of BasicPay)
        MSP         15500
        RH12        21125
        """
    }

    /// Creates test payslip text with specified parameters
    static func createTestPayslipText(basicPay: Double, daAmount: Double, withGrade: Bool = false, gradeLevel: String? = nil) -> String {
        let gradeText = withGrade && gradeLevel != nil ? " (\(gradeLevel!))" : ""
        return """
        BPAY\(gradeText)     \(Int(basicPay))
        DA       \(Int(daAmount))
        MSP      15500
        RH12     21125
        TPTA     3600
        DSOP     40000
        AGIF     10000
        """
    }

    /// Creates simple test text with basic components
    static func createSimpleTestText(basicPay: Double, daPercentage: Double = 0.5) -> String {
        let daAmount = basicPay * daPercentage
        return """
        BPAY    \(Int(basicPay))
        DA      \(Int(daAmount))
        MSP     15500
        """
    }
}
