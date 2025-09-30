import XCTest
@testable import PayslipMax

/// Test suite for PayslipsViewModel initialization and initial state validation
/// Following MVVM architecture and SOLID principles for focused testing
@MainActor
final class PayslipsViewModelInitializationTests: XCTestCase {

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

    func testInitialState() {
        // Test initial state properties
        XCTAssertFalse(payslipsViewModel.isLoading)
        XCTAssertNil(payslipsViewModel.error)
        XCTAssertEqual(payslipsViewModel.searchText, "")
        XCTAssertEqual(payslipsViewModel.sortOrder, .dateDescending)
        XCTAssertTrue(payslipsViewModel.payslips.isEmpty)
        XCTAssertNil(payslipsViewModel.selectedPayslip)
        XCTAssertFalse(payslipsViewModel.showShareSheet)
        XCTAssertEqual(payslipsViewModel.shareText, "")
        XCTAssertTrue(payslipsViewModel.groupedPayslips.isEmpty)
        XCTAssertTrue(payslipsViewModel.sortedSectionKeys.isEmpty)
    }

    func testHasActiveFiltersInitially() {
        // Test that no filters are active initially
        XCTAssertFalse(payslipsViewModel.hasActiveFilters)
    }

    func testHasActiveFiltersWithSearchText() {
        // Test active filters when search text is set
        payslipsViewModel.searchText = "test"
        XCTAssertTrue(payslipsViewModel.hasActiveFilters)

        // Test clearing search text removes active filters
        payslipsViewModel.searchText = ""
        XCTAssertFalse(payslipsViewModel.hasActiveFilters)
    }
}
