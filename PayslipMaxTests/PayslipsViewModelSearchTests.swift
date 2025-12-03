import XCTest
@testable import PayslipMax

/// Test suite for PayslipsViewModel search, filtering, and sorting functionality
/// Following MVVM architecture and SOLID principles for UI interaction testing
@MainActor
final class PayslipsViewModelSearchTests: XCTestCase {

    var mockRepository: MockSendablePayslipRepository!
    var payslipsViewModel: PayslipsViewModel!

    override func setUp() {
        super.setUp()
        mockRepository = MockSendablePayslipRepository()
        let mockDataService = PayslipsViewModelMockDataService()

        // Create cache manager with mock repository
        let mockDataHandler = PayslipDataHandler(repository: mockRepository, dataService: mockDataService)
        let mockCacheManager = PayslipCacheManager(dataHandler: mockDataHandler)

        payslipsViewModel = PayslipsViewModel(repository: mockRepository, cacheManager: mockCacheManager)
    }

    override func tearDown() {
        payslipsViewModel = nil
        mockRepository = nil
        super.tearDown()
    }

    func testSearchFiltering() async {
        // Create test payslips with diverse data for comprehensive filtering tests
        let testPayslips = [
            PayslipItem(
                month: "January",
                year: 2024,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipItem(
                month: "February",
                year: 2024,
                credits: 5200.0,
                debits: 1100.0,
                dsop: 320.0,
                tax: 850.0,
                name: "Jane Smith",
                accountNumber: "XXXX5678",
                panNumber: "ABCDE5678G"
            )
        ]

        // Set up mock repository with test data
        mockRepository.payslips = testPayslips.map { PayslipDTO(from: $0) }
        await payslipsViewModel.loadPayslips()

        // Test search by name
        payslipsViewModel.searchText = "John"
        let filteredByName = payslipsViewModel.filteredPayslips
        XCTAssertEqual(filteredByName.count, 1)
        XCTAssertEqual(filteredByName.first?.name, "John Doe")

        // Test search by month
        payslipsViewModel.searchText = "February"
        let filteredByMonth = payslipsViewModel.filteredPayslips
        XCTAssertEqual(filteredByMonth.count, 1)
        XCTAssertEqual(filteredByMonth.first?.month, "February")

        // Test search by year
        payslipsViewModel.searchText = "2024"
        let filteredByYear = payslipsViewModel.filteredPayslips
        XCTAssertEqual(filteredByYear.count, 2)

        // Test clear search returns all payslips
        payslipsViewModel.searchText = ""
        let allPayslips = payslipsViewModel.filteredPayslips
        XCTAssertEqual(allPayslips.count, 2)
    }

    func testFilteredPayslipsEmptyResults() async {
        // Create test payslips for empty search results testing
        let testPayslips = [
            PayslipItem(
                month: "January",
                year: 2024,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        ]

        // Set up mock repository with test data
        mockRepository.payslips = testPayslips.map { PayslipDTO(from: $0) }
        await payslipsViewModel.loadPayslips()

        // Search for something that doesn't exist
        payslipsViewModel.searchText = "NonExistent"
        let filtered = payslipsViewModel.filteredPayslips
        XCTAssertEqual(filtered.count, 0)
    }

    func testSortingOrders() async {
        // Create test payslips with different values for comprehensive sorting tests
        let testPayslips = [
            PayslipItem(
                month: "January",
                year: 2024,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Alice",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipItem(
                month: "February",
                year: 2024,
                credits: 6000.0,
                debits: 1200.0,
                dsop: 350.0,
                tax: 900.0,
                name: "Bob",
                accountNumber: "XXXX5678",
                panNumber: "ABCDE5678G"
            ),
            PayslipItem(
                month: "March",
                year: 2024,
                credits: 4500.0,
                debits: 800.0,
                dsop: 250.0,
                tax: 700.0,
                name: "Charlie",
                accountNumber: "XXXX9012",
                panNumber: "ABCDE9012H"
            )
        ]

        // Set up mock repository with test data
        mockRepository.payslips = testPayslips.map { PayslipDTO(from: $0) }
        await payslipsViewModel.loadPayslips()

        // Test amount descending sort
        payslipsViewModel.sortOrder = .amountDescending
        let sortedByAmountDesc = payslipsViewModel.filteredPayslips
        XCTAssertEqual(sortedByAmountDesc.first?.credits, 6000.0)
        XCTAssertEqual(sortedByAmountDesc.last?.credits, 4500.0)

        // Test amount ascending sort
        payslipsViewModel.sortOrder = .amountAscending
        let sortedByAmountAsc = payslipsViewModel.filteredPayslips
        XCTAssertEqual(sortedByAmountAsc.first?.credits, 4500.0)
        XCTAssertEqual(sortedByAmountAsc.last?.credits, 6000.0)

        // Test name ascending sort
        payslipsViewModel.sortOrder = .nameAscending
        let sortedByNameAsc = payslipsViewModel.filteredPayslips
        XCTAssertEqual(sortedByNameAsc.first?.name, "Alice")
        XCTAssertEqual(sortedByNameAsc.last?.name, "Charlie")

        // Test name descending sort
        payslipsViewModel.sortOrder = .nameDescending
        let sortedByNameDesc = payslipsViewModel.filteredPayslips
        XCTAssertEqual(sortedByNameDesc.first?.name, "Charlie")
        XCTAssertEqual(sortedByNameDesc.last?.name, "Alice")
    }
}
