import XCTest
@testable import PayslipMax

/// Tests specifically for dual-section detection and classification
final class PayCodeClassificationDualSectionTests: XCTestCase {

    var classificationEngine: PayCodeClassificationEngine!

    override func setUp() {
        super.setUp()
        classificationEngine = PayCodeClassificationEngine()
    }

    override func tearDown() {
        classificationEngine = nil
        super.tearDown()
    }

    // MARK: - Dual Section Detection Tests

    func testDualSectionDetection() {
        // When: Check dual-section detection for allowances
        for code in PayCodeClassificationTestData.dualSectionCodes {
            assertDualSectionDetection(classificationEngine, code: code, expectedIsDual: true)
        }

        // MSP is now guaranteed earnings (not dual-section)
        assertDualSectionDetection(classificationEngine, code: "MSP", expectedIsDual: false)
    }

    func testNonDualSectionDetection() {
        // When: Check components that are guaranteed single-section
        for code in PayCodeClassificationTestData.nonDualSectionCodes {
            assertDualSectionDetection(classificationEngine, code: code, expectedIsDual: false)
        }

        // Universal dual-section components (allowances that can be recovered)
        assertDualSectionDetection(classificationEngine, code: "SICHA", expectedIsDual: true)
        assertDualSectionDetection(classificationEngine, code: "HRA", expectedIsDual: true)
    }

    func testRH12DualSectionClassification() {
        // When: Classify RH12 with different contexts
        let rh12Earnings = performAndAssertClassification(
            classificationEngine,
            component: "RH12",
            value: 21125,
            context: "Earnings section: RH12 21125.00",
            expectedSection: .earnings,
            expectedIsDual: true
        )

        let rh12Deductions = performAndAssertClassification(
            classificationEngine,
            component: "RH12",
            value: 7518,
            context: "Deductions section: RH12 7518.00",
            expectedSection: .deductions, // RH12 with low value in deductions context should be deductions
            expectedIsDual: true
        )

        // Both results should have reasonable confidence
        XCTAssertGreaterThan(rh12Earnings.confidence, 0.7)
        XCTAssertGreaterThan(rh12Deductions.confidence, 0.7)
    }

    func testSpecialForcesDualSectionBehavior() {
        // Special forces allowances are universal dual-section (can be recovered)
        for code in PayCodeClassificationTestData.specialForcesCodes {
            let result = classificationEngine.classifyComponentIntelligently(
                component: code,
                value: 25000,
                context: "\(code) 25000.00"
            )

            XCTAssertEqual(result.section, .earnings)
            XCTAssertTrue(result.isDualSection,
                         "Special forces code \(code) should be dual-section")
            XCTAssertGreaterThan(result.confidence, 0.8)
        }
    }
}
