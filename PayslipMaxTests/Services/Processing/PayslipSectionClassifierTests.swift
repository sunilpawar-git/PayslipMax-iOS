import XCTest
@testable import PayslipMax

final class PayslipSectionClassifierTests: XCTestCase {

    private var sut: PayslipSectionClassifier!

    override func setUp() {
        super.setUp()
        sut = PayslipSectionClassifier()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - RH12 Classification

    func test_classifyRH12_highValue_returnsEarnings() {
        let section = sut.classifyRH12Section(
            key: "RH12",
            value: 21125,
            text: "EARNINGS RH12 21125 DEDUCTIONS"
        )
        XCTAssertEqual(section, .earnings)
    }

    func test_classifyRH12_lowValueWithDeductionsContext_returnsDeductions() {
        let section = sut.classifyRH12Section(
            key: "RH12",
            value: 7518,
            text: "EARNINGS BASIC PAY 56100 DEDUCTIONS RH12 7518"
        )
        XCTAssertEqual(section, .deductions)
    }

    func test_classifyRH12_midRangeValueWithoutHeaders_defaultsToEarnings() {
        let section = sut.classifyRH12Section(
            key: "RH12",
            value: 12000,
            text: "RH12 12000"
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - Dual Section Component Classification

    func test_classifyDualSection_RHComponent_delegatesToRH12() {
        let section = sut.classifyDualSectionComponent(
            componentKey: "RH12",
            value: 21125,
            text: "EARNINGS RH12 21125"
        )
        XCTAssertEqual(section, .earnings)
    }

    func test_classifyDualSection_obviousDeduction_returnsDeductions() {
        let section = sut.classifyDualSectionComponent(
            componentKey: "DEDUCTION FUND",
            value: 5000,
            text: "DEDUCTION FUND 5000"
        )
        XCTAssertEqual(section, .deductions)
    }

    func test_classifyDualSection_recoveryInName_returnsDeductions() {
        let section = sut.classifyDualSectionComponent(
            componentKey: "HRA RECOVERY",
            value: 3000,
            text: "HRA RECOVERY 3000"
        )
        XCTAssertEqual(section, .deductions)
    }

    func test_classifyDualSection_insuranceInName_returnsDeductions() {
        let section = sut.classifyDualSectionComponent(
            componentKey: "GROUP INSURANCE",
            value: 1000,
            text: "GROUP INSURANCE 1000"
        )
        XCTAssertEqual(section, .deductions)
    }

    func test_classifyDualSection_highValueUnknown_returnsEarnings() {
        let section = sut.classifyDualSectionComponent(
            componentKey: "SPECIAL",
            value: 20000,
            text: "SPECIAL 20000"
        )
        XCTAssertEqual(section, .earnings)
    }

    // MARK: - Spatial Context Analysis

    func test_classifyDualSection_withEarningsHeader_returnsEarnings() {
        let text = "EARNINGS BASIC PAY 56100 DA 5000 SPECIAL 8000"
        let section = sut.classifyDualSectionComponent(
            componentKey: "SPECIAL",
            value: 8000,
            text: text
        )
        XCTAssertEqual(section, .earnings)
    }
}
