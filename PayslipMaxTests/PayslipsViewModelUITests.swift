import XCTest
@testable import PayslipMax

/// Test suite for PayslipsViewModel UI-related functionality
/// Following MVVM architecture and SOLID principles for user interaction testing
@MainActor
final class PayslipsViewModelUITests: XCTestCase {

    var mockDataService: PayslipsViewModelMockDataService!
    var payslipsViewModel: PayslipsViewModel!

    override func setUp() {
        super.setUp()
        mockDataService = PayslipsViewModelMockDataService()
        payslipsViewModel = PayslipsViewModel(repository: MockSendablePayslipRepository())
    }

    override func tearDown() {
        payslipsViewModel = nil
        mockDataService = nil
        super.tearDown()
    }

    func testSelectedPayslipAndShare() {
        // Create a test payslip for UI interaction testing
        let testPayslip = PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: "Employee 1",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )

        // Test payslip selection functionality
        payslipsViewModel.selectedPayslip = testPayslip
        XCTAssertNotNil(payslipsViewModel.selectedPayslip)
        XCTAssertEqual(payslipsViewModel.selectedPayslip?.name, "Employee 1")

        // Test share functionality - share text setting
        payslipsViewModel.shareText = "Test share text"
        payslipsViewModel.showShareSheet = true
        XCTAssertTrue(payslipsViewModel.showShareSheet)
        XCTAssertEqual(payslipsViewModel.shareText, "Test share text")

        // Test share sheet dismissal
        payslipsViewModel.showShareSheet = false
        XCTAssertFalse(payslipsViewModel.showShareSheet)
    }

    func testShareSheetStateManagement() {
        // Test initial share sheet state
        XCTAssertFalse(payslipsViewModel.showShareSheet)
        XCTAssertEqual(payslipsViewModel.shareText, "")

        // Test enabling share sheet with content
        payslipsViewModel.shareText = "Payslip summary for January 2024"
        payslipsViewModel.showShareSheet = true

        XCTAssertTrue(payslipsViewModel.showShareSheet)
        XCTAssertEqual(payslipsViewModel.shareText, "Payslip summary for January 2024")

        // Test clearing share content
        payslipsViewModel.shareText = ""
        payslipsViewModel.showShareSheet = false

        XCTAssertFalse(payslipsViewModel.showShareSheet)
        XCTAssertEqual(payslipsViewModel.shareText, "")
    }
}
