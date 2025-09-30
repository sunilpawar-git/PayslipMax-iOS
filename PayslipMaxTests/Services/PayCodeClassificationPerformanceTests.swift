import XCTest
@testable import PayslipMax

/// Performance tests for PayCodeClassificationEngine
final class PayCodeClassificationPerformanceTests: XCTestCase {

    var classificationEngine: PayCodeClassificationEngine!

    override func setUp() {
        super.setUp()
        classificationEngine = PayCodeClassificationEngine()
    }

    override func tearDown() {
        classificationEngine = nil
        super.tearDown()
    }

    func testClassificationPerformance() {
        // Given: Common military codes
        let commonCodes = PayCodeClassificationTestData.commonMilitaryCodes

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
        let testCodes = PayCodeClassificationTestData.allTestCodes

        // When: Measure dual-section detection performance
        measure {
            for code in testCodes {
                _ = classificationEngine.isDualSectionComponent(code)
            }
        }
    }

    func testBulkClassificationPerformance() {
        // Given: Large set of test codes
        let bulkCodes = PayCodeClassificationTestData.jsonBasedTestCases.map { $0.code }

        // When: Measure bulk classification performance
        measure {
            for code in bulkCodes {
                _ = classificationEngine.classifyComponentIntelligently(
                    component: code,
                    value: 15000,
                    context: "Performance test: \(code) 15000.00"
                )
            }
        }
    }
}
