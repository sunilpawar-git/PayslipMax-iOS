import XCTest
@testable import PayslipMax

/// Tests for on-device LLM integration: result conversion, availability gating, and month parsing.
final class HybridProcessorOnDeviceTests: XCTestCase {

    private var mockOnDevice: MockOnDeviceLLMService!

    override func setUp() {
        super.setUp()
        mockOnDevice = MockOnDeviceLLMService()
    }

    override func tearDown() {
        mockOnDevice = nil
        super.tearDown()
    }

    // MARK: - Result Conversion

    func test_onDeviceResult_convertsCreditsAndDebits() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        XCTAssertEqual(item.credits, result.grossPay)
        XCTAssertEqual(item.debits, result.totalDeductions)
    }

    func test_onDeviceResult_netIsDerived() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        let expectedNet = result.grossPay - result.totalDeductions
        XCTAssertEqual(item.credits - item.debits, expectedNet)
    }

    func test_onDeviceResult_populatesEarnings() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        XCTAssertEqual(item.earnings["BPAY"], 56900)
        XCTAssertEqual(item.earnings["DA"], 34140)
        XCTAssertEqual(item.earnings["MSP"], 15500)
    }

    func test_onDeviceResult_populatesDeductions() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        XCTAssertEqual(item.deductions["DSOP"], 15000)
        XCTAssertEqual(item.deductions["ITAX"], 12000)
        XCTAssertEqual(item.deductions["AGIF"], 7500)
    }

    func test_onDeviceResult_extractsDSOPAndTax() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        XCTAssertEqual(item.dsop, 15000)
        XCTAssertEqual(item.tax, 12000)
    }

    func test_onDeviceResult_setsYear() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)
        XCTAssertEqual(item.year, 2025)
    }

    func test_onDeviceResult_setsMonthDisplayName() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)
        XCTAssertEqual(item.month, "January")
    }

    func test_onDeviceResult_piiFieldsEmpty() {
        let result = MockOnDeviceLLMService.makeDefaultResult()
        let item = PayslipItem.from(onDeviceResult: result)

        XCTAssertTrue(item.name.isEmpty)
        XCTAssertTrue(item.accountNumber.isEmpty)
        XCTAssertTrue(item.panNumber.isEmpty)
    }

    // MARK: - Availability Gating

    func test_unavailableService_returnsNil() async {
        mockOnDevice.mockIsAvailable = false
        let result = await mockOnDevice.parsePayslip(text: "test")
        XCTAssertNil(result)
    }

    func test_availableService_withResult_returnsResult() async {
        mockOnDevice.mockResult = MockOnDeviceLLMService.makeDefaultResult()
        let result = await mockOnDevice.parsePayslip(text: "test")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.grossPay, 106540)
    }

    // MARK: - Month Parsing

    func test_monthParsing_fullNames() {
        XCTAssertEqual(OnDeviceLLMResultConverter.parseMonth("JANUARY"), 1)
        XCTAssertEqual(OnDeviceLLMResultConverter.parseMonth("DECEMBER"), 12)
        XCTAssertEqual(OnDeviceLLMResultConverter.parseMonth("June"), 6)
    }

    func test_monthParsing_abbreviated() {
        XCTAssertEqual(OnDeviceLLMResultConverter.parseMonth("JAN"), 1)
        XCTAssertEqual(OnDeviceLLMResultConverter.parseMonth("Aug"), 8)
    }

    func test_monthParsing_nilForInvalid() {
        XCTAssertNil(OnDeviceLLMResultConverter.parseMonth(nil))
        XCTAssertNil(OnDeviceLLMResultConverter.parseMonth("INVALID"))
        XCTAssertNil(OnDeviceLLMResultConverter.parseMonth(""))
    }

    func test_monthDisplayName_validNumbers() {
        XCTAssertEqual(OnDeviceLLMResultConverter.monthDisplayName(for: 1), "January")
        XCTAssertEqual(OnDeviceLLMResultConverter.monthDisplayName(for: 12), "December")
    }

    func test_monthDisplayName_invalidReturnsUnknown() {
        XCTAssertEqual(OnDeviceLLMResultConverter.monthDisplayName(for: 0), "Unknown")
        XCTAssertEqual(OnDeviceLLMResultConverter.monthDisplayName(for: 13), "Unknown")
    }
}
