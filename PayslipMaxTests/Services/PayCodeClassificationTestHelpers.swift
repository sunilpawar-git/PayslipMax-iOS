import XCTest
@testable import PayslipMax

/// Helper methods for PayCodeClassificationEngine tests
extension XCTestCase {

    /// Asserts that a classification result has the expected section and minimum confidence
    func assertClassificationResult(
        _ result: PayCodeClassificationResult,
        expectedSection: PayslipSection,
        minConfidence: Double = 0.7,
        code: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(result.section, expectedSection,
                      "Code \(code) should be classified as \(expectedSection)",
                      file: file, line: line)
        XCTAssertGreaterThan(result.confidence, minConfidence,
                            "Code \(code) should have confidence > \(minConfidence)",
                            file: file, line: line)
    }

    /// Asserts that a component is correctly identified as dual-section or not
    func assertDualSectionDetection(
        _ engine: PayCodeClassificationEngine,
        code: String,
        expectedIsDual: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let isDual = engine.isDualSectionComponent(code)
        if expectedIsDual {
            XCTAssertTrue(isDual, "Code \(code) should be detected as dual-section",
                         file: file, line: line)
        } else {
            XCTAssertFalse(isDual, "Code \(code) should not be dual-section",
                          file: file, line: line)
        }
    }

    /// Performs intelligent classification and asserts the result
    func performAndAssertClassification(
        _ engine: PayCodeClassificationEngine,
        component: String,
        value: Double,
        context: String,
        expectedSection: PayslipSection,
        expectedIsDual: Bool? = nil,
        minConfidence: Double = 0.7,
        file: StaticString = #file,
        line: UInt = #line
    ) -> PayCodeClassificationResult {
        let result = engine.classifyComponentIntelligently(
            component: component,
            value: value,
            context: context
        )

        assertClassificationResult(result,
                                  expectedSection: expectedSection,
                                  minConfidence: minConfidence,
                                  code: component,
                                  file: file, line: line)

        if let expectedIsDual = expectedIsDual {
            XCTAssertEqual(result.isDualSection, expectedIsDual,
                          "Code \(component) dual-section status should be \(expectedIsDual)",
                          file: file, line: line)
        }

        return result
    }

    /// Creates a standard context string for testing
    func createContext(for code: String, value: Double) -> String {
        return "\(code) \(value)"
    }

    /// Performs bulk classification testing for multiple codes
    func performBulkClassification(
        _ engine: PayCodeClassificationEngine,
        codes: [String],
        expectedSection: PayslipSection,
        value: Double = 10000,
        minConfidence: Double = 0.7,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for code in codes {
            let context = createContext(for: code, value: value)
            _ = performAndAssertClassification(
                engine,
                component: code,
                value: value,
                context: context,
                expectedSection: expectedSection,
                minConfidence: minConfidence,
                file: file, line: line
            )
        }
    }
}
