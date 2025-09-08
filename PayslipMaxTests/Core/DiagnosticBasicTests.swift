import XCTest
import SwiftData
@testable import PayslipMax

/// Basic diagnostic tests for core functionality
@MainActor
final class DiagnosticBasicTests: BaseTestCase {

    private var testContainer: TestDIContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = TestDIContainer.forTesting()
    }

    override func tearDownWithError() throws {
        testContainer = nil
        try super.tearDownWithError()
    }

    func testBasicFunctionality() {
        // Basic math test
        XCTAssertEqual(2 + 2, 4, "Basic math should work")

        // Async test
        let expectation = expectation(description: "Async operation")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPayslipItemWithMocks() {
        // Create a test payslip using realistic defense data
        let payslip = TestDataGenerator.samplePayslipItem()

        // Verify properties with realistic defense payslip values
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2024)

        // Defense payslip calculations:
        // Basic Pay: 56100.0, MSP: 15500.0, DA: 5610.0 → Credits: 77210.0
        XCTAssertEqual(payslip.credits, 77210.0)

        // DSOP: 1200.0, AGIF: 150.0, Income Tax: 2800.0 → Debits: 4150.0
        XCTAssertEqual(payslip.debits, 4150.0)

        XCTAssertEqual(payslip.dsop, 1200.0)
        XCTAssertEqual(payslip.tax, 2800.0)
        XCTAssertEqual(payslip.name, "Capt. Rajesh Kumar")
        XCTAssertEqual(payslip.accountNumber, "IC-12345")

        // PAN number is generated for Army service → starts with "ARMY"
        XCTAssertTrue(payslip.panNumber.hasPrefix("ARMY"))

        // Calculate net remittance (credits - debits, since debits already includes dsop & tax)
        let expectedNet = payslip.credits - payslip.debits
        XCTAssertEqual(expectedNet, 73060.0)
    }
}
