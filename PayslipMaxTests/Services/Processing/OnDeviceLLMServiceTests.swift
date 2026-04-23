import XCTest
@testable import PayslipMax

/// Tests for OnDeviceLLMServiceProtocol contract and mock behavior
final class OnDeviceLLMServiceTests: XCTestCase {

    private var sut: MockOnDeviceLLMService!

    override func setUp() {
        super.setUp()
        sut = MockOnDeviceLLMService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Availability

    func test_isAvailable_defaultsToTrue() {
        XCTAssertTrue(sut.isAvailable)
    }

    func test_isAvailable_canBeDisabled() {
        sut.mockIsAvailable = false
        XCTAssertFalse(sut.isAvailable)
    }

    // MARK: - Parse Contract

    func test_parsePayslip_returnsNilWhenNoResultConfigured() async {
        let result = await sut.parsePayslip(text: "sample text")
        XCTAssertNil(result)
    }

    func test_parsePayslip_returnsConfiguredResult() async {
        sut.mockResult = MockOnDeviceLLMService.makeDefaultResult()
        let result = await sut.parsePayslip(text: "sample text")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.grossPay, 106540)
        XCTAssertEqual(result?.totalDeductions, 34500)
        XCTAssertEqual(result?.netRemittance, 72040)
    }

    func test_parsePayslip_tracksParsedText() async {
        _ = await sut.parsePayslip(text: "test input")
        XCTAssertEqual(sut.lastParsedText, "test input")
    }

    func test_parsePayslip_incrementsCallCount() async {
        _ = await sut.parsePayslip(text: "first")
        _ = await sut.parsePayslip(text: "second")
        XCTAssertEqual(sut.parseCallCount, 2)
    }

    // MARK: - Result Model

    func test_onDeviceLLMResult_containsEarnings() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        XCTAssertEqual(result.earnings["BPAY"], 56900)
        XCTAssertEqual(result.earnings["DA"], 34140)
        XCTAssertEqual(result.earnings["MSP"], 15500)
    }

    func test_onDeviceLLMResult_containsDeductions() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        XCTAssertEqual(result.deductions["DSOP"], 15000)
        XCTAssertEqual(result.deductions["AGIF"], 7500)
        XCTAssertEqual(result.deductions["ITAX"], 12000)
    }

    func test_onDeviceLLMResult_containsDateInfo() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        XCTAssertEqual(result.month, "JANUARY")
        XCTAssertEqual(result.year, 2025)
    }

    func test_onDeviceLLMResult_totalsReconcile() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        XCTAssertEqual(result.netRemittance, result.grossPay - result.totalDeductions)
    }
}
