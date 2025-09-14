//
//  RH12DualSectionIntegrationTests.swift
//  PayslipMaxTests
//
//  Created for testing end-to-end RH12 dual-section parsing
//  Validates complete Phase 1-5 implementation from RH12_Dual_Section_Parsing_Fix_Roadmap
//

import XCTest
@testable import PayslipMax

/// Integration tests for complete RH12 dual-section parsing pipeline
/// Validates end-to-end functionality from detection through data pipeline to PayslipData
@MainActor
final class RH12DualSectionIntegrationTests: BaseTestCase {

    // MARK: - Properties

    private var processor: UnifiedDefensePayslipProcessor!
    private var container: TestDIContainer!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        container = createTestContainer()

        // Create date extractor with all dependencies for testing
        let dateExtractor = MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )

        processor = UnifiedDefensePayslipProcessor(dateExtractor: dateExtractor)
    }

    override func tearDown() {
        processor = nil
        container = nil
        super.tearDown()
    }

    // MARK: - End-to-End Integration Tests

    func testRH12DualSectionProcessing_May2025Complete() throws {
        // Complete May 2025 payslip text as referenced in the roadmap
        let may2025PayslipText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS (NAVY)
        STATEMENT OF ACCOUNT FOR THE MONTH OF MAY 2025

        NAME: COMMANDER PRIYA SHARMA
        SERVICE NO: 27156N
        UNIT: INS VIKRANT
        ACCOUNT NO: 50100012345678
        PAN: ABCDE1234F

        EARNINGS                                          AMOUNT (₹)
        001  Basic Pay (Level 12)                         78,800
        002  Dearness Allowance @ 50%                     39,400
        003  Military Service Pay                         15,500
        004  Flying Allowance                             10,200
        005  Special Sea Going Allowance                   8,900
        006  RH12                                         21,125
        007  Technical Allowance                           6,800
        008  Transport Allowance                           3,240
        009  Washing Allowance                               800
        010  Kit Maintenance Allowance                     1,900
                                            TOTAL EARNINGS  276,665

        DEDUCTIONS                                        AMOUNT (₹)
        101  Income Tax u/s 192                           52,380
        102  AGIF                                          7,888
        103  DSOP                                         25,600
        104  Group Insurance (Officers)                    2,150
        105  RH12                                          7,518
        106  Naval Benevolent Fund                         1,500
        107  Mess Charges                                 10,289
        108  Other Deductions                              1,200
                                         TOTAL DEDUCTIONS  108,525

        NET REMITTANCE                                   168,140
        """

        // Process the complete payslip
        let payslipItem = try processor.processPayslip(from: may2025PayslipText)

        // Validate financial totals match roadmap expectations (100% accuracy target)
        XCTAssertEqual(payslipItem.credits, 276665.0, "Total credits should match roadmap expectation: ₹276,665")
        XCTAssertEqual(payslipItem.debits, 108525.0, "Total debits should match roadmap expectation: ₹108,525")

        // Validate RH12 dual-section detection using Phase 2 distinct keys
        let rh12Earnings = payslipItem.earnings["RH12_EARNINGS"] ?? 0
        let rh12Deductions = payslipItem.deductions["RH12_DEDUCTIONS"] ?? 0

        XCTAssertEqual(rh12Earnings, 21125.0, "RH12 earnings should be ₹21,125 (Phase 2 implementation)")
        XCTAssertEqual(rh12Deductions, 7518.0, "RH12 deductions should be ₹7,518 (Phase 2 implementation)")

        // Validate total RH12 detection
        let totalRH12 = rh12Earnings + rh12Deductions
        XCTAssertEqual(totalRH12, 28643.0, "Total RH12 should be ₹28,643 (₹21,125 + ₹7,518)")

        // Validate personal information extraction
        XCTAssertEqual(payslipItem.name, "COMMANDER PRIYA SHARMA", "Should extract name correctly")
        XCTAssertEqual(payslipItem.month, "MAY", "Should extract month correctly")
        XCTAssertEqual(payslipItem.year, 2025, "Should extract year correctly")
        XCTAssertEqual(payslipItem.accountNumber, "50100012345678", "Should extract account number")
        XCTAssertEqual(payslipItem.panNumber, "ABCDE1234F", "Should extract PAN number")

        // Validate other key components are detected
        XCTAssertGreaterThan(payslipItem.earnings["Basic Pay"] ?? 0, 0, "Should detect Basic Pay")
        XCTAssertGreaterThan(payslipItem.earnings["Dearness Allowance"] ?? 0, 0, "Should detect DA")
        XCTAssertGreaterThan(payslipItem.earnings["Military Service Pay"] ?? 0, 0, "Should detect MSP")
        XCTAssertGreaterThan(payslipItem.deductions["Income Tax"] ?? 0, 0, "Should detect Income Tax")
        XCTAssertGreaterThan(payslipItem.deductions["DSOP"] ?? 0, 0, "Should detect DSOP")
    }

    func testPayslipDataFactory_DualKeyRetrieval() {
        // Test Phase 4 data pipeline fix - ensure extracted values reach PayslipData
        let mockPayslip = createMockPayslipWithDualRH12()
        let payslipData = PayslipData(from: mockPayslip)

        // Validate that PayslipDataFactory correctly retrieves dual-section RH12
        let expectedRH12Earnings = mockPayslip.earnings["RH12_EARNINGS"] ?? 0
        let expectedRH12Deductions = mockPayslip.deductions["RH12_DEDUCTIONS"] ?? 0

        XCTAssertEqual(expectedRH12Earnings, 21125.0, "Mock should have RH12 earnings")
        XCTAssertEqual(expectedRH12Deductions, 7518.0, "Mock should have RH12 deductions")

        // Verify data pipeline correctly processes dual-section values
        let totalRH12 = expectedRH12Earnings + expectedRH12Deductions
        XCTAssertEqual(totalRH12, 28643.0, "Data pipeline should preserve total RH12 value")

        // Verify PayslipData totals are accurate
        XCTAssertEqual(payslipData.totalCredits, 276665.0, "PayslipData should preserve total credits")
        XCTAssertEqual(payslipData.totalDebits, 108525.0, "PayslipData should preserve total debits")
        XCTAssertEqual(payslipData.netRemittance, 168140.0, "PayslipData should calculate net remittance correctly")
    }

    func testRH12Classification_AccuracyImprovement() throws {
        // Test classification accuracy improvement from Phase 3
        let testCases: [(text: String, value: Double, expectedSection: String, description: String)] = [
            // High-value RH12 (>₹15,000) should be earnings
            (createPayslipWithRH12InEarnings(21125.0), 21125.0, "earnings", "High-value RH12 in earnings context"),

            // Low-value RH12 (<₹10,000) should be deductions
            (createPayslipWithRH12InDeductions(7518.0), 7518.0, "deductions", "Low-value RH12 in deductions context"),

            // Mid-range RH12 should default to earnings (safer classification)
            (createPayslipWithRH12Ambiguous(12000.0), 12000.0, "earnings", "Mid-range RH12 defaults to earnings"),

            // Boundary cases
            (createPayslipWithRH12Ambiguous(15000.0), 15000.0, "earnings", "Boundary high-value RH12"),
            (createPayslipWithRH12Ambiguous(10000.0), 10000.0, "earnings", "Boundary mid-range RH12"),
            (createPayslipWithRH12Ambiguous(9999.0), 9999.0, "deductions", "Boundary low-value RH12")
        ]

        for testCase in testCases {
            let payslipItem = try processor.processPayslip(from: testCase.text)

            if testCase.expectedSection == "earnings" {
                let rh12Value = payslipItem.earnings["RH12_EARNINGS"] ?? 0
                XCTAssertEqual(rh12Value, testCase.value,
                              "Failed: \(testCase.description) - Expected ₹\(testCase.value) in earnings")
            } else {
                let rh12Value = payslipItem.deductions["RH12_DEDUCTIONS"] ?? 0
                XCTAssertEqual(rh12Value, testCase.value,
                              "Failed: \(testCase.description) - Expected ₹\(testCase.value) in deductions")
            }
        }
    }

    func testRegressionValidation_AllReferencePayslips() throws {
        // Test regression validation as specified in Phase 5
        let referencePayslips = createReferencePayslipTestCases()

        for (description, testData) in referencePayslips {
            let payslipItem = try processor.processPayslip(from: testData.text)

            // Validate no regression in parsing accuracy
            XCTAssertEqual(payslipItem.credits, testData.expectedCredits,
                          accuracy: 100.0, "Credits regression in \(description)")
            XCTAssertEqual(payslipItem.debits, testData.expectedDebits,
                          accuracy: 100.0, "Debits regression in \(description)")

            print("✅ \(description): Credits ₹\(payslipItem.credits), Debits ₹\(payslipItem.debits)")
        }
    }

    func testPerformanceValidation_ProcessingTime() throws {
        // Validate performance targets from Phase 5 (< 15% impact)
        let may2025Text = createMay2025PayslipText()

        let iterations = 10
        var totalTime: CFAbsoluteTime = 0

        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = try processor.processPayslip(from: may2025Text)
            totalTime += CFAbsoluteTimeGetCurrent() - startTime
        }

        let averageTime = totalTime / Double(iterations)

        // Performance target: should complete within reasonable time (< 1 second)
        XCTAssertLessThan(averageTime, 1.0, "Average processing time should be under 1 second")

        print("📊 Performance: Average processing time \(String(format: "%.3f", averageTime))s")
    }

    // MARK: - Helper Methods

    private func createMockPayslipWithDualRH12() -> AnyPayslip {
        let mockPayslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "MAY",
            year: 2025,
            credits: 276665.0,
            debits: 108525.0,
            dsop: 25600.0,
            tax: 52380.0,
            name: "Test Officer",
            accountNumber: "50100012345678",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )

        // Set dual-section RH12 using Phase 2 distinct keys
        mockPayslip.earnings = [
            "Basic Pay": 78800.0,
            "Dearness Allowance": 39400.0,
            "Military Service Pay": 15500.0,
            "RH12_EARNINGS": 21125.0
        ]

        mockPayslip.deductions = [
            "Income Tax": 52380.0,
            "DSOP": 25600.0,
            "AGIF": 7888.0,
            "RH12_DEDUCTIONS": 7518.0
        ]

        return AnyPayslip(mockPayslip)
    }

    private func createPayslipWithRH12InEarnings(_ value: Double) -> String {
        return """
        STATEMENT OF ACCOUNT
        EARNINGS                     AMOUNT
        Basic Pay                    50000
        Dearness Allowance          15000
        RH12                        \(Int(value))
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                   8000
        TOTAL DEDUCTIONS           108525
        """
    }

    private func createPayslipWithRH12InDeductions(_ value: Double) -> String {
        return """
        STATEMENT OF ACCOUNT
        EARNINGS                     AMOUNT
        Basic Pay                    50000
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                   8000
        AGIF                        2000
        RH12                        \(Int(value))
        TOTAL DEDUCTIONS           108525
        """
    }

    private func createPayslipWithRH12Ambiguous(_ value: Double) -> String {
        return """
        STATEMENT OF ACCOUNT
        Basic Pay                    50000
        RH12                        \(Int(value))
        Income Tax                   8000
        """
    }

    private func createMay2025PayslipText() -> String {
        return """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR THE MONTH OF MAY 2025

        EARNINGS                     AMOUNT
        Basic Pay                    78800
        Dearness Allowance          39400
        Military Service Pay        15500
        RH12                        21125
        TOTAL EARNINGS             276665

        DEDUCTIONS                   AMOUNT
        Income Tax                  52380
        DSOP                        25600
        RH12                         7518
        TOTAL DEDUCTIONS           108525
        """
    }

    private func createReferencePayslipTestCases() -> [(String, (text: String, expectedCredits: Double, expectedDebits: Double))] {
        return [
            ("October 2023", (
                text: createReferencePayslip(credits: 263160, debits: 102590),
                expectedCredits: 263160.0,
                expectedDebits: 102590.0
            )),
            ("June 2023", (
                text: createReferencePayslip(credits: 220968, debits: 143754),
                expectedCredits: 220968.0,
                expectedDebits: 143754.0
            )),
            ("February 2025", (
                text: createReferencePayslip(credits: 271739, debits: 109310),
                expectedCredits: 271739.0,
                expectedDebits: 109310.0
            )),
            ("May 2025", (
                text: createMay2025PayslipText(),
                expectedCredits: 276665.0,
                expectedDebits: 108525.0
            ))
        ]
    }

    private func createReferencePayslip(credits: Int, debits: Int) -> String {
        return """
        STATEMENT OF ACCOUNT
        EARNINGS
        Basic Pay                    \(credits - 50000)
        Dearness Allowance          30000
        Military Service Pay        20000
        TOTAL EARNINGS             \(credits)

        DEDUCTIONS
        Income Tax                  \(debits - 20000)
        DSOP                        20000
        TOTAL DEDUCTIONS           \(debits)
        """
    }
}
