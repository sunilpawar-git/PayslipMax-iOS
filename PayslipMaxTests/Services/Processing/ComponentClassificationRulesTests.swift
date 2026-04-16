import XCTest
@testable import PayslipMax

final class ComponentClassificationRulesTests: XCTestCase {

    private var sut: ComponentClassificationRules!

    override func setUp() {
        super.setUp()
        sut = ComponentClassificationRules()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - HRA Classification

    func test_classifyHRA_highValue_returnsEarnings() {
        let section = sut.getComponentSpecificClassification(
            "HRA", value: 10000, text: "EARNINGS HRA 10000",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertEqual(section, .earnings)
    }

    func test_classifyHRA_lowValueInDeductionContext_returnsDeductions() {
        let section = sut.getComponentSpecificClassification(
            "HRA", value: 3000, text: "DEDUCTIONS HRA 3000",
            spatialAnalyzer: { _, _, _ in .deductions }
        )
        XCTAssertEqual(section, .deductions)
    }

    // MARK: - CEA Classification

    func test_classifyCEA_highValue_returnsEarnings() {
        let section = sut.getComponentSpecificClassification(
            "CEA", value: 5000, text: "EARNINGS CEA 5000",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - SICHA Classification

    func test_classifySICHA_highValue_returnsEarnings() {
        let section = sut.getComponentSpecificClassification(
            "SICHA", value: 15000, text: "SICHA 15000",
            spatialAnalyzer: { _, _, _ in .deductions }
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - DA Classification

    func test_classifyDA_spatialEarnings_returnsEarnings() {
        let section = sut.getComponentSpecificClassification(
            "DA", value: 5000, text: "DA 5000",
            spatialAnalyzer: { _, _, _ in .earnings }
        )
        XCTAssertEqual(section, .earnings)
    }

    func test_classifyDA_spatialUnknown_defaultsToEarnings() {
        let section = sut.getComponentSpecificClassification(
            "DA", value: 5000, text: "DA 5000",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - TPTA Classification

    func test_classifyTPTA_highValue_returnsEarnings() {
        let section = sut.getComponentSpecificClassification(
            "TPTA", value: 3600, text: "TPTA 3600",
            spatialAnalyzer: { _, _, _ in .deductions }
        )
        XCTAssertEqual(section, .earnings)
    }

    func test_classifyTPTA_withRecoveryIndicator_returnsDeductions() {
        let section = sut.getComponentSpecificClassification(
            "TPTA", value: 2000, text: "TPTA RECOVERY 2000",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertEqual(section, .deductions)
    }

    // MARK: - TPTADA Classification

    func test_classifyTPTADA_withoutTPTA_matchesTPTADAFirst() {
        let section = sut.getComponentSpecificClassification(
            "TPTADA", value: 1980, text: "TPTADA 1980",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - Unknown Component

    func test_unknownComponent_returnsNil() {
        let section = sut.getComponentSpecificClassification(
            "RANDOM", value: 5000, text: "RANDOM 5000",
            spatialAnalyzer: { _, _, _ in .unknown }
        )
        XCTAssertNil(section)
    }

    // MARK: - Helper Methods

    func test_isCommonRecoveryPattern_withKnownPattern_returnsTrue() {
        XCTAssertTrue(sut.isCommonRecoveryPattern("HRA"))
        XCTAssertTrue(sut.isCommonRecoveryPattern("CEA"))
        XCTAssertTrue(sut.isCommonRecoveryPattern("LTC"))
    }

    func test_isCommonRecoveryPattern_withUnknownPattern_returnsFalse() {
        XCTAssertFalse(sut.isCommonRecoveryPattern("BASIC"))
        XCTAssertFalse(sut.isCommonRecoveryPattern("RANDOM"))
    }

    func test_getClassificationConfidence_withSpecificRules_returnsHighConfidence() {
        let confidence = sut.getClassificationConfidence(for: "HRA", value: 15000)
        XCTAssertEqual(confidence, 0.90, accuracy: 0.01)
    }

    func test_getClassificationConfidence_withLowValue_returns085() {
        let confidence = sut.getClassificationConfidence(for: "HRA", value: 500)
        XCTAssertEqual(confidence, 0.85, accuracy: 0.01)
    }

    func test_getClassificationConfidence_withNoSpecificRules_returns070() {
        let confidence = sut.getClassificationConfidence(for: "UNKNOWN", value: 5000)
        XCTAssertEqual(confidence, 0.70, accuracy: 0.01)
    }
}
