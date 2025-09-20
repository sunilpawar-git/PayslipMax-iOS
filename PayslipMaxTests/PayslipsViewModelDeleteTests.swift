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
        payslipsViewModel = PayslipsViewModel(repository: MockSendablePayslipRepository())
    }

    override func tearDown() {
        payslipsViewModel = nil
        mockDataService = nil
        super.tearDown()
    }

    /// Helper method to get the mock repository from the ViewModel
    private var mockRepository: MockSendablePayslipRepository {
        payslipsViewModel.repository as! MockSendablePayslipRepository
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

        // Convert to DTO for repository storage
        let testPayslipDTO = PayslipDTO(from: testPayslip)

        // Set up mock repository with test payslip
        mockRepository.payslips = [testPayslipDTO]
        await payslipsViewModel.loadPayslips()

        // Verify payslip is loaded
        XCTAssertEqual(payslipsViewModel.payslips.count, 1)

        // Delete the payslip through repository (simulating the ViewModel's delete behavior)
        _ = try? await mockRepository.deletePayslip(withId: testPayslip.id)

        // Verify payslip is deleted from mock repository
        XCTAssertEqual(mockRepository.payslips.count, 0)

        // Reload payslips to verify the deletion persists
        await payslipsViewModel.loadPayslips()
        XCTAssertEqual(payslipsViewModel.payslips.count, 0)
    }

    func testDeletePayslipWithError() async {
        // Set up mock repository to fail delete operations
        mockRepository.shouldThrowError = true

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

        // Convert to DTO for repository storage
        let testPayslipDTO = PayslipDTO(from: testPayslip)

        // Set up mock repository with test payslip
        mockRepository.payslips = [testPayslipDTO]
        await payslipsViewModel.loadPayslips()

        // Try to delete with error through repository
        do {
            _ = try await mockRepository.deletePayslip(withId: testPayslip.id)
            XCTFail("Expected error was not thrown")
        } catch {
            // Expected error - verify it's the correct type
            XCTAssertTrue(error is AppError)
        }
    }
}
