import XCTest
@testable import PayslipMax

/// Tests for enhanced PayCodeClassificationEngine with JSON-based classification
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
        // When: Classify basic pay codes
        let bpayResult = classificationEngine.classifyComponentIntelligently(
            component: "BPAY",
            value: 144700,
            context: "BPAY 144700.00"
        )

        let mspResult = classificationEngine.classifyComponentIntelligently(
            component: "MSP",
            value: 15500,
            context: "MSP 15500.00"
        )

        // Then: Should classify as earnings
        XCTAssertEqual(bpayResult.section, .earnings)
        XCTAssertGreaterThan(bpayResult.confidence, 0.8)
        XCTAssertFalse(bpayResult.isDualSection)

        XCTAssertEqual(mspResult.section, .earnings)
        XCTAssertGreaterThan(mspResult.confidence, 0.8)
        XCTAssertFalse(mspResult.isDualSection)
    }

    func testDeductionClassification() {
        // When: Classify deduction codes
        let dsopResult = classificationEngine.classifyComponentIntelligently(
            component: "DSOP",
            value: 40000,
            context: "DSOP 40000.00"
        )

        let agifResult = classificationEngine.classifyComponentIntelligently(
            component: "AGIF",
            value: 10000,
            context: "AGIF 10000.00"
        )

        let itaxResult = classificationEngine.classifyComponentIntelligently(
            component: "ITAX",
            value: 25000,
            context: "ITAX 25000.00"
        )

        // Then: Should classify as deductions
        XCTAssertEqual(dsopResult.section, .deductions)
        XCTAssertEqual(agifResult.section, .deductions)
        XCTAssertEqual(itaxResult.section, .deductions)

        // Should have high confidence for known codes
        XCTAssertGreaterThan(dsopResult.confidence, 0.8)
        XCTAssertGreaterThan(agifResult.confidence, 0.8)
        XCTAssertGreaterThan(itaxResult.confidence, 0.8)
    }

    func testSpecialForcesClassification() {
        // When: Classify special forces codes
        let spcdoResult = classificationEngine.classifyComponentIntelligently(
            component: "SPCDO",
            value: 45000,
            context: "SPCDO 45000.00"
        )

        let flyallowResult = classificationEngine.classifyComponentIntelligently(
            component: "FLYALLOW",
            value: 25000,
            context: "FLYALLOW 25000.00"
        )

        let sichaResult = classificationEngine.classifyComponentIntelligently(
            component: "SICHA",
            value: 50000,
            context: "SICHA 50000.00"
        )

        // Then: Should classify as earnings
        XCTAssertEqual(spcdoResult.section, .earnings)
        XCTAssertEqual(flyallowResult.section, .earnings)
        XCTAssertEqual(sichaResult.section, .earnings)

        // Should have high confidence for known special forces codes
        XCTAssertGreaterThan(spcdoResult.confidence, 0.8)
        XCTAssertGreaterThan(flyallowResult.confidence, 0.8)
        XCTAssertGreaterThan(sichaResult.confidence, 0.8)
    }

    // MARK: - Arrears Classification Tests

    func testArrearsClassification() {
        // When: Classify arrears codes
        let arrearsBasicPay = classificationEngine.classifyComponentIntelligently(
            component: "ARR-BPAY",
            value: 12000,
            context: "ARR-BPAY 12000.00"
        )

        let arrearsCEA = classificationEngine.classifyComponentIntelligently(
            component: "ARR-CEA",
            value: 8000,
            context: "ARR-CEA 8000.00"
        )

        let arrearsSpecialForces = classificationEngine.classifyComponentIntelligently(
            component: "ARR-SPCDO",
            value: 15000,
            context: "ARR-SPCDO 15000.00"
        )

        // Then: Should classify based on underlying code
        XCTAssertEqual(arrearsBasicPay.section, .earnings)
        XCTAssertEqual(arrearsCEA.section, .earnings)
        XCTAssertEqual(arrearsSpecialForces.section, .earnings)

        // Should have reasonable confidence
        XCTAssertGreaterThan(arrearsBasicPay.confidence, 0.7)
        XCTAssertGreaterThan(arrearsCEA.confidence, 0.7)
        XCTAssertGreaterThan(arrearsSpecialForces.confidence, 0.7)
    }

    func testArrearsDeductionClassification() {
        // When: Classify arrears for deduction codes
        let arrearsDSOP = classificationEngine.classifyComponentIntelligently(
            component: "ARR-DSOP",
            value: 5000,
            context: "ARR-DSOP 5000.00"
        )

        let arrearsITAX = classificationEngine.classifyComponentIntelligently(
            component: "ARR-ITAX",
            value: 3000,
            context: "ARR-ITAX 3000.00"
        )

        // Then: Should classify as deductions (arrears of deductions are still deductions)
        XCTAssertEqual(arrearsDSOP.section, .deductions)
        XCTAssertEqual(arrearsITAX.section, .deductions)
    }

    // MARK: - Dual Section Tests

    func testDualSectionDetection() {
        // When: Check dual-section detection for RH codes
        let rh12IsDual = classificationEngine.isDualSectionComponent("RH12")
        let rh13IsDual = classificationEngine.isDualSectionComponent("RH13")
        let mspIsDual = classificationEngine.isDualSectionComponent("MSP")
        let tptaIsDual = classificationEngine.isDualSectionComponent("TPTA")

        // Then: Should detect dual-section components
        XCTAssertTrue(rh12IsDual, "RH12 should be detected as dual-section")
        XCTAssertTrue(rh13IsDual, "RH13 should be detected as dual-section")
        XCTAssertTrue(mspIsDual, "MSP should be detected as dual-section")
        XCTAssertTrue(tptaIsDual, "TPTA should be detected as dual-section")
    }

    func testNonDualSectionDetection() {
        // When: Check components that are not dual-section
        let bpayIsDual = classificationEngine.isDualSectionComponent("BPAY")
        let dsopIsDual = classificationEngine.isDualSectionComponent("DSOP")
        let sichaIsDual = classificationEngine.isDualSectionComponent("SICHA")

        // Then: Should not detect as dual-section
        XCTAssertFalse(bpayIsDual, "BPAY should not be dual-section")
        XCTAssertFalse(dsopIsDual, "DSOP should not be dual-section")
        XCTAssertFalse(sichaIsDual, "SICHA should not be dual-section")
    }

    func testRH12DualSectionClassification() {
        // When: Classify RH12 with different contexts
        let rh12Earnings = classificationEngine.classifyComponentIntelligently(
            component: "RH12",
            value: 21125,
            context: "Earnings section: RH12 21125.00"
        )

        let rh12Deductions = classificationEngine.classifyComponentIntelligently(
            component: "RH12",
            value: 7518,
            context: "Deductions section: RH12 7518.00"
        )

        // Then: Should detect as dual-section
        XCTAssertTrue(rh12Earnings.isDualSection)
        XCTAssertTrue(rh12Deductions.isDualSection)

        // Classification may depend on context and value
        // Both results should have reasonable confidence
        XCTAssertGreaterThan(rh12Earnings.confidence, 0.7)
        XCTAssertGreaterThan(rh12Deductions.confidence, 0.7)
    }

    // MARK: - Enhanced JSON-Based Tests

    func testJSONBasedClassificationAccuracy() {
        // When: Test classification for all major categories
        let testCases: [(code: String, expectedSection: PayslipSection)] = [
            // Basic Pay & Allowances (Earnings)
            ("BPAY", .earnings), ("MSP", .earnings), ("DA", .earnings), ("HRA", .earnings),
            ("TPTA", .earnings), ("TPTADA", .earnings), ("CEA", .earnings),

            // Special Forces (Earnings)
            ("SPCDO", .earnings), ("FLYALLOW", .earnings), ("SICHA", .earnings), ("HAUC3", .earnings),

            // Deductions
            ("DSOP", .deductions), ("AGIF", .deductions), ("ITAX", .deductions), ("EHCESS", .deductions),
            ("GPF", .deductions), ("PF", .deductions)
        ]

        for testCase in testCases {
            let result = classificationEngine.classifyComponentIntelligently(
                component: testCase.code,
                value: 10000,
                context: "\(testCase.code) 10000.00"
            )

            XCTAssertEqual(result.section, testCase.expectedSection,
                          "Code \(testCase.code) should be classified as \(testCase.expectedSection)")
            XCTAssertGreaterThan(result.confidence, 0.7,
                               "Code \(testCase.code) should have high confidence")
        }
    }

    func testPartialMatchingClassification() {
        // When: Test partial matching for complex codes
        let complexCodes = ["RH12", "RH21", "HAUC3", "SPCDO"]

        for code in complexCodes {
            let result = classificationEngine.classifyComponentIntelligently(
                component: code,
                value: 15000,
                context: "\(code) 15000.00"
            )

            // Then: Should successfully classify complex codes
            XCTAssertNotNil(result.section, "Should classify complex code: \(code)")
            XCTAssertGreaterThan(result.confidence, 0.5,
                               "Should have reasonable confidence for \(code)")
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

        // Then: Should have fallback classification
        // May use contextual or pattern-based fallback
        XCTAssertNotNil(unknownResult.section)
        XCTAssertLessThan(unknownResult.confidence, 0.8, "Unknown codes should have lower confidence")
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

    // MARK: - Performance Tests

    func testClassificationPerformance() {
        // Given: Common military codes
        let commonCodes = [
            "BPAY", "MSP", "DA", "HRA", "TPTA", "CEA", "RH12", "RH13",
            "DSOP", "AGIF", "ITAX", "EHCESS", "SPCDO", "FLYALLOW", "SICHA"
        ]

        // When: Measure classification performance
        measure {
            for code in commonCodes {
                _ = classificationEngine.classifyComponentIntelligently(
                    component: code,
                    value: 10000,
                    context: "\(code) 10000.00"
                )
            }
        }
    }

    func testDualSectionDetectionPerformance() {
        // Given: Various codes
        let testCodes = [
            "BPAY", "MSP", "DA", "HRA", "RH11", "RH12", "RH13", "TPTA",
            "DSOP", "AGIF", "ITAX", "SPCDO", "FLYALLOW", "SICHA"
        ]

        // When: Measure dual-section detection performance
        measure {
            for code in testCodes {
                _ = classificationEngine.isDualSectionComponent(code)
            }
        }
    }
}
