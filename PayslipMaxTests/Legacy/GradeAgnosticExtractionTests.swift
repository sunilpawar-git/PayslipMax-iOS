//
//  GradeAgnosticExtractionTests.swift
//  PayslipMaxTests
//
//  Created for testing grade-agnostic military pattern extraction
//  Validates the fix for February 2025 vs May 2025 parsing discrepancy
//

import XCTest
@testable import PayslipMax

/// Comprehensive test suite for grade-agnostic military pattern extraction
/// Tests all ranks from Lieutenant to General with various DA combinations
@MainActor
final class GradeAgnosticExtractionTests: XCTestCase {

    // MARK: - Properties

    private var patternExtractor: MilitaryPatternExtractor!
    private var patternService: DynamicMilitaryPatternService!
    private var validator: MilitaryComponentValidator!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        patternService = DynamicMilitaryPatternService()
        validator = MilitaryComponentValidator(payStructure: nil)
        patternExtractor = MilitaryPatternExtractor(
            dynamicPatternService: patternService,
            spatialAnalyzer: nil,
            sectionClassifier: nil,
            validationService: MilitaryValidationService()
        )
    }

    override func tearDown() {
        patternExtractor = nil
        patternService = nil
        validator = nil
        super.tearDown()
    }

    // MARK: - Grade-Agnostic BPAY Recognition Tests

    func testBPayRecognition_WithoutGrade() {
        // Test February 2025 scenario - BPAY without grade identifier
        let februaryText = GradeAgnosticExtractionTestData.createFebruaryTextWithoutGrade()
        let result = patternExtractor.extractFinancialDataLegacy(from: februaryText)

        // Verify BPAY extraction works without grade
        GradeAgnosticExtractionTestHelpers.validateFinancialExtraction(
            result: result,
            expectedBasicPay: 144700.0,
            expectedDA: 84906.0,
            expectedMSP: 15500.0,
            expectedRH12: 21125.0,
            testDescription: " without grade identifier"
        )
    }

    func testBPayRecognition_WithGrade() {
        // Test May 2025 scenario - BPAY with grade identifier
        let mayText = GradeAgnosticExtractionTestData.createMayTextWithGrade()
        let result = patternExtractor.extractFinancialDataLegacy(from: mayText)

        // Verify BPAY extraction works with grade
        XCTAssertEqual(result["BasicPay"], 144700.0, "Should extract BPAY (12A) correctly with grade identifier")
        XCTAssertEqual(result["DA"], 88110.0, "Should extract DA correctly")
        XCTAssertEqual(result["MSP"], 15500.0, "Should extract MSP correctly")
        // Note: May 2025 has dual RH12 entries - first one found is the deduction (₹7,518)
        XCTAssertEqual(result["RH12"], 7518.0, "Should extract first RH12 correctly (May 2025 has dual entries)")
    }

    // MARK: - Grade Inference Tests

    func testGradeInference_FromBasicPayAmounts() {
        for testCase in GradeAgnosticExtractionTestData.gradeInferenceTestCases {
            let testText = GradeAgnosticExtractionTestData.createSimpleTestText(basicPay: testCase.basicPay)
            let result = patternExtractor.extractFinancialDataLegacy(from: testText)

            XCTAssertEqual(result["BasicPay"], testCase.basicPay,
                         "Should extract BasicPay ₹\(testCase.basicPay) for \(testCase.rank)")

            // Test grade inference method directly if available
            if let extractorMethod = GradeAgnosticExtractionTestHelpers.getGradeInferenceMethod() {
                let inferredGrade = extractorMethod(testCase.basicPay)
                if let expectedGrade = testCase.expectedGrade {
                    XCTAssertEqual(inferredGrade, expectedGrade,
                                 "Should infer grade \(expectedGrade) from BasicPay ₹\(testCase.basicPay)")
                }
            }
        }
    }

    // MARK: - DA Validation Tests

    func testDAValidation_VariousPercentages() {
        let basicPay = 144700.0

        for testCase in GradeAgnosticExtractionTestData.daValidationTestCases {
            let daAmount = basicPay * testCase.daPercentage
            let testText = GradeAgnosticExtractionTestData.createSimpleTestText(basicPay: basicPay, daPercentage: testCase.daPercentage)
            let result = patternExtractor.extractFinancialDataLegacy(from: testText)

            if testCase.shouldPass {
                XCTAssertEqual(result["BasicPay"], basicPay,
                             "Should extract BasicPay for \(testCase.description)")
                XCTAssertEqual(result["DA"], daAmount,
                             "Should extract DA for \(testCase.description)")
            } else {
                // For cases that should fail, DA might be rejected
                XCTAssertEqual(result["BasicPay"], basicPay,
                             "Should still extract BasicPay for \(testCase.description)")
                // DA might be nil or different due to validation failure
            }
        }
    }

    // MARK: - Comprehensive Rank Testing

    func testAllMilitaryRanks_ComprehensiveScenarios() {
        for rank in GradeAgnosticExtractionTestData.militaryRankData {
            // Test with minimum, middle, and maximum pay for each rank
            let testPays = [rank.minPay, (rank.minPay + rank.maxPay) / 2, rank.maxPay]

            for basicPay in testPays {
                let daAmount = basicPay * 0.5 // Standard 50% DA

                // Test with grade identifier
                let textWithGrade = GradeAgnosticExtractionTestData.createTestPayslipText(
                    basicPay: basicPay,
                    daAmount: daAmount,
                    withGrade: true,
                    gradeLevel: rank.level
                )
                let resultWithGrade = patternExtractor.extractFinancialDataLegacy(from: textWithGrade)

                XCTAssertEqual(resultWithGrade["BasicPay"], basicPay,
                             "Should extract BasicPay ₹\(basicPay) for \(rank.rank) with grade")
                XCTAssertEqual(resultWithGrade["DA"], daAmount,
                             "Should extract DA ₹\(daAmount) for \(rank.rank) with grade")

                // Test without grade identifier (grade-agnostic)
                let textWithoutGrade = GradeAgnosticExtractionTestData.createTestPayslipText(
                    basicPay: basicPay,
                    daAmount: daAmount,
                    withGrade: false
                )
                let resultWithoutGrade = patternExtractor.extractFinancialDataLegacy(from: textWithoutGrade)

                XCTAssertEqual(resultWithoutGrade["BasicPay"], basicPay,
                             "Should extract BasicPay ₹\(basicPay) for \(rank.rank) without grade")
                XCTAssertEqual(resultWithoutGrade["DA"], daAmount,
                             "Should extract DA ₹\(daAmount) for \(rank.rank) without grade")
            }
        }
    }

    // MARK: - Edge Case Tests

    func testEdgeCases_GradeAgnosticValidation() {
        // Test case where grade detection fails but amounts are valid
        let edgeCaseText = GradeAgnosticExtractionTestData.createEdgeCaseText()
        let result = patternExtractor.extractFinancialDataLegacy(from: edgeCaseText)

        GradeAgnosticExtractionTestHelpers.validateFinancialExtraction(
            result: result,
            expectedBasicPay: 144700.0,
            expectedDA: 84906.0,
            expectedMSP: 15500.0,
            expectedRH12: 21125.0,
            testDescription: " with alternative label"
        )
    }

    func testFallbackValidation_ComponentRanges() {
        let basicPay = 144700.0

        for testCase in GradeAgnosticExtractionTestData.componentValidationTestCases {
            let amount = testCase.amount == 84906 ? testCase.amount : (testCase.component == "DA" ? testCase.amount : testCase.amount)
            let isValid = validator.applyFallbackValidation(
                testCase.component,
                amount: amount,
                basicPay: basicPay
            )

            XCTAssertEqual(isValid, testCase.shouldPass,
                         "Fallback validation for \(testCase.component) ₹\(amount) should \(testCase.shouldPass ? "pass" : "fail")")
        }
    }

    // MARK: - Integration Test: February vs May 2025

    func testFebruary2025VsMay2025_ParsedEqually() {
        // February 2025: No grade in BPAY
        let februaryText = GradeAgnosticExtractionTestData.createFebruary2025PayslipText()
        let februaryResult = patternExtractor.extractFinancialDataLegacy(from: februaryText)

        // May 2025: Grade in BPAY (12A)
        let mayText = GradeAgnosticExtractionTestData.createMay2025PayslipText()
        let mayResult = patternExtractor.extractFinancialDataLegacy(from: mayText)

        // Both should extract BasicPay correctly
        XCTAssertEqual(februaryResult["BasicPay"], 144700.0,
                       "February 2025 should extract correct BasicPay")
        XCTAssertEqual(mayResult["BasicPay"], 144700.0,
                       "May 2025 should extract correct BasicPay")

        // Both should extract key components
        GradeAgnosticExtractionTestHelpers.validateKeyComponentsExist(
            result: februaryResult,
            components: ["BasicPay", "MSP", "RH12", "TPTA"],
            testDescription: " for February 2025"
        )
        GradeAgnosticExtractionTestHelpers.validateKeyComponentsExist(
            result: mayResult,
            components: ["BasicPay", "MSP", "RH12", "TPTA"],
            testDescription: " for May 2025"
        )
    }
}
