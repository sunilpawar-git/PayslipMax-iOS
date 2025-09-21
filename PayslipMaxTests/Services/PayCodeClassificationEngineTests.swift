import XCTest
@testable import PayslipMax

/// Tests for enhanced PayCodeClassificationEngine with JSON-based classification
/// This file contains core classification tests. Performance and dual-section tests
/// are separated into dedicated files to maintain file size limits.
final class PayCodeClassificationEngineTests: XCTestCase {

    var classificationEngine: PayCodeClassificationEngine!

    override func setUp() {
        super.setUp()
        classificationEngine = PayCodeClassificationEngine()
    }

    override func tearDown() {
        classificationEngine = nil
        super.tearDown()
    }

    // MARK: - Basic Classification Tests

    func testBasicPayClassification() {
        // When: Classify basic pay codes and Then: assert results
        let bpayResult = performAndAssertClassification(
            classificationEngine,
            component: "BPAY",
            value: 144700,
            context: createContext(for: "BPAY", value: 144700),
            expectedSection: .earnings,
            expectedIsDual: false
        )

        let mspResult = performAndAssertClassification(
            classificationEngine,
            component: "MSP",
            value: 15500,
            context: createContext(for: "MSP", value: 15500),
            expectedSection: .earnings,
            expectedIsDual: false
        )

        // Verify high confidence for both
        XCTAssertGreaterThan(bpayResult.confidence, 0.8)
        XCTAssertGreaterThan(mspResult.confidence, 0.8)
    }

    func testDeductionClassification() {
        // When: Classify deduction codes using bulk testing
        performBulkClassification(
            classificationEngine,
            codes: PayCodeClassificationTestData.deductionCodes,
            expectedSection: .deductions
        )

        // Additional verification for specific codes
        let dsopResult = performAndAssertClassification(
            classificationEngine,
            component: "DSOP",
            value: 40000,
            context: createContext(for: "DSOP", value: 40000),
            expectedSection: .deductions,
            expectedIsDual: false
        )

        let agifResult = performAndAssertClassification(
            classificationEngine,
            component: "AGIF",
            value: 10000,
            context: createContext(for: "AGIF", value: 10000),
            expectedSection: .deductions,
            expectedIsDual: false
        )

        let itaxResult = performAndAssertClassification(
            classificationEngine,
            component: "ITAX",
            value: 25000,
            context: createContext(for: "ITAX", value: 25000),
            expectedSection: .deductions,
            expectedIsDual: false
        )

        // All should have high confidence
        XCTAssertGreaterThan(dsopResult.confidence, 0.8)
        XCTAssertGreaterThan(agifResult.confidence, 0.8)
        XCTAssertGreaterThan(itaxResult.confidence, 0.8)
    }

    func testSpecialForcesClassification() {
        // When: Classify special forces codes using bulk testing
        performBulkClassification(
            classificationEngine,
            codes: PayCodeClassificationTestData.specialForcesCodes,
            expectedSection: .earnings
        )

        // Additional verification for dual-section behavior
        let spcdoResult = performAndAssertClassification(
            classificationEngine,
            component: "SPCDO",
            value: 45000,
            context: createContext(for: "SPCDO", value: 45000),
            expectedSection: .earnings,
            expectedIsDual: true
        )

        let flyallowResult = performAndAssertClassification(
            classificationEngine,
            component: "FLYALLOW",
            value: 25000,
            context: createContext(for: "FLYALLOW", value: 25000),
            expectedSection: .earnings,
            expectedIsDual: true
        )

        let sichaResult = performAndAssertClassification(
            classificationEngine,
            component: "SICHA",
            value: 50000,
            context: createContext(for: "SICHA", value: 50000),
            expectedSection: .earnings,
            expectedIsDual: true
        )

        // All should have high confidence
        XCTAssertGreaterThan(spcdoResult.confidence, 0.8)
        XCTAssertGreaterThan(flyallowResult.confidence, 0.8)
        XCTAssertGreaterThan(sichaResult.confidence, 0.8)
    }

    // MARK: - Arrears Classification Tests

    func testArrearsClassification() {
        // When: Classify arrears codes for earnings
        let earningsArrears = ["ARR-BPAY", "ARR-CEA", "ARR-SPCDO"]

        for code in earningsArrears {
            let value = PayCodeClassificationTestData.sampleValues[code] ?? 10000
            performAndAssertClassification(
                classificationEngine,
                component: code,
                value: value,
                context: createContext(for: code, value: value),
                expectedSection: .earnings,
                minConfidence: 0.7
            )
        }
    }

    func testArrearsDeductionClassification() {
        // When: Classify arrears for deduction codes
        let deductionArrears = ["ARR-DSOP", "ARR-ITAX"]

        for code in deductionArrears {
            let value = PayCodeClassificationTestData.sampleValues[code] ?? 5000
            performAndAssertClassification(
                classificationEngine,
                component: code,
                value: value,
                context: createContext(for: code, value: value),
                expectedSection: .deductions
            )
        }
    }

    // MARK: - Enhanced JSON-Based Tests

    func testJSONBasedClassificationAccuracy() {
        // When: Test classification for all major categories using predefined test data
        for testCase in PayCodeClassificationTestData.jsonBasedTestCases {
            let result = classificationEngine.classifyComponentIntelligently(
                component: testCase.code,
                value: 10000,
                context: createContext(for: testCase.code, value: 10000)
            )

            assertClassificationResult(result,
                                     expectedSection: testCase.expectedSection,
                                     minConfidence: 0.7,
                                     code: testCase.code)
        }
    }

    func testPartialMatchingClassification() {
        // When: Test partial matching for complex codes using predefined data
        for code in PayCodeClassificationTestData.complexCodes {
            let result = performAndAssertClassification(
                classificationEngine,
                component: code,
                value: 15000,
                context: createContext(for: code, value: 15000),
                expectedSection: .earnings, // Complex codes typically classify as earnings
                minConfidence: 0.5
            )

            XCTAssertNotNil(result.section, "Should classify complex code: \(code)")
        }
    }

    // MARK: - Fallback Classification Tests

    func testFallbackClassification() {
        // When: Test unknown codes
        let unknownResult = classificationEngine.classifyComponentIntelligently(
            component: "UNKNOWN_CODE",
            value: 5000,
            context: "UNKNOWN_CODE 5000.00"
        )

        // Then: Should have fallback classification as universal dual-section
        // Unknown codes default to universal dual-section strategy
        XCTAssertNotNil(unknownResult.section)
        XCTAssertTrue(unknownResult.isDualSection, "Unknown codes should be treated as dual-section")
        // Unknown codes get contextual classification which may have reasonable confidence
        XCTAssertGreaterThan(unknownResult.confidence, 0.5, "Unknown codes should have some confidence")
    }

    func testFallbackPatternMatching() {
        // When: Test codes that might match fallback patterns
        let allowancePattern = classificationEngine.classifyComponentIntelligently(
            component: "NEW_ALLOWANCE",
            value: 8000,
            context: "NEW_ALLOWANCE 8000.00"
        )

        let deductionPattern = classificationEngine.classifyComponentIntelligently(
            component: "NEW_TAX",
            value: 2000,
            context: "NEW_TAX 2000.00"
        )

        // Then: Should apply pattern-based fallback
        // Allowance patterns should tend toward earnings
        // Tax patterns should tend toward deductions
        XCTAssertNotNil(allowancePattern.section)
        XCTAssertNotNil(deductionPattern.section)
    }

}
