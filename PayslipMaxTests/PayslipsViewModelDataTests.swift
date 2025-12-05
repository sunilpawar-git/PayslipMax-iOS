import XCTest
@testable import PayslipMax

/// Test suite for PayslipsViewModel data operations
/// Following MVVM architecture and SOLID principles for data flow testing
@MainActor
final class PayslipsViewModelDataTests: XCTestCase {

    var mockDataService: PayslipsViewModelMockDataService!
    var mockRepository: MockSendablePayslipRepository!
    var payslipsViewModel: PayslipsViewModel!

    override func setUp() {
        super.setUp()
        mockDataService = PayslipsViewModelMockDataService()
        mockRepository = MockSendablePayslipRepository()

        // Create cache manager with mock repository
        let mockDataHandler = PayslipDataHandler(repository: mockRepository, dataService: mockDataService)
        let mockCacheManager = PayslipCacheManager(dataHandler: mockDataHandler)

        payslipsViewModel = PayslipsViewModel(repository: mockRepository, cacheManager: mockCacheManager)
    }

    override func tearDown() {
        payslipsViewModel = nil
        mockRepository = nil
        mockDataService = nil
        super.tearDown()
    }

    func testLoadPayslips() async {
        // Create test payslips with comprehensive data as PayslipDTOs
        let testPayslips = [
            PayslipDTO(
                month: "January",
                year: 2024,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Employee 1",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipDTO(
                month: "February",
                year: 2024,
                credits: 5200.0,
                debits: 1100.0,
                dsop: 320.0,
                tax: 850.0,
                name: "Employee 2",
                accountNumber: "XXXX5678",
                panNumber: "ABCDE5678G"
            )
        ]

        // Set up mock repository with test data
        mockRepository.payslips = testPayslips

        // Execute load payslips operation
        await payslipsViewModel.loadPayslips()

        // Verify successful loading
        XCTAssertEqual(payslipsViewModel.payslips.count, 2)
        XCTAssertNil(payslipsViewModel.error)
        XCTAssertFalse(payslipsViewModel.isLoading)
    }

    func testLoadPayslipsWithError() async {
        // Set up mock repository to simulate failure
        mockRepository.shouldThrowError = true

        // Execute load payslips operation that should fail
        await payslipsViewModel.loadPayslips()

        // Verify error handling and state
        XCTAssertNotNil(payslipsViewModel.error)
        XCTAssertTrue(payslipsViewModel.payslips.isEmpty)
        XCTAssertFalse(payslipsViewModel.isLoading)
    }

    func testGroupedPayslips() async {
        // Create test payslips from different months for grouping as PayslipDTOs
        let testPayslips = [
            PayslipDTO(
                month: "January",
                year: 2024,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Employee 1",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipDTO(
                month: "January",
                year: 2024,
                credits: 5200.0,
                debits: 1100.0,
                dsop: 320.0,
                tax: 850.0,
                name: "Employee 2",
                accountNumber: "XXXX5678",
                panNumber: "ABCDE5678G"
            ),
            PayslipDTO(
                month: "February",
                year: 2024,
                credits: 5100.0,
                debits: 1050.0,
                dsop: 310.0,
                tax: 825.0,
                name: "Employee 3",
                accountNumber: "XXXX9012",
                panNumber: "ABCDE9012H"
            )
        ]

        // Set up mock repository
        mockRepository.payslips = testPayslips
        await payslipsViewModel.loadPayslips()

        // Test grouped payslips functionality
        let grouped = payslipsViewModel.groupedPayslips
        XCTAssertEqual(grouped.keys.count, 2) // Two different months
        XCTAssertEqual(grouped["January 2024"]?.count, 2)
        XCTAssertEqual(grouped["February 2024"]?.count, 1)

        // Test sorted section keys for UI display
        let sectionKeys = payslipsViewModel.sortedSectionKeys
        XCTAssertTrue(sectionKeys.contains("January 2024"))
        XCTAssertTrue(sectionKeys.contains("February 2024"))
    }
}
