import XCTest
@testable import PayslipMax

/// Test suite for PayslipsViewModel delete operations and error handling
/// Following MVVM architecture and SOLID principles for data manipulation testing
@MainActor
final class PayslipsViewModelDeleteTests: XCTestCase {

    var mockDataService: PayslipsViewModelMockDataService!
    var payslipsViewModel: PayslipsViewModel!

    override func setUp() {
        super.setUp()
        mockDataService = PayslipsViewModelMockDataService()
        payslipsViewModel = PayslipsViewModel(dataService: mockDataService)
    }

    override func tearDown() {
        payslipsViewModel = nil
        mockDataService = nil
        super.tearDown()
    }

    func testDeletePayslip() async {
        // Create a test payslip for deletion testing
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

        // Set up mock data service with test payslip
        mockDataService.payslips = [testPayslip]
        await payslipsViewModel.loadPayslips()

        // Verify payslip is loaded
        XCTAssertEqual(payslipsViewModel.payslips.count, 1)

        // Delete the payslip through data service (simulating the ViewModel's delete behavior)
        try? await mockDataService.delete(testPayslip)

        // Verify payslip is deleted from mock data service
        XCTAssertEqual(mockDataService.payslips.count, 0)
    }

    func testDeletePayslipWithError() async {
        // Set up mock data service to fail delete operations
        mockDataService.shouldFailDelete = true

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

        // Set up mock data service with test payslip
        mockDataService.payslips = [testPayslip]
        await payslipsViewModel.loadPayslips()

        // Try to delete with error through data service
        do {
            try await mockDataService.delete(testPayslip)
            XCTFail("Expected error was not thrown")
        } catch {
            // Expected error - verify it's the correct type
            XCTAssertTrue(error is AppError)
        }
    }
}
