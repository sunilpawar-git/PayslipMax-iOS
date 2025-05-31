import XCTest
@testable import PayslipMax

class PayslipsViewModelTests: XCTestCase {
    var viewModel: PayslipsViewModel!
    var mockDataService: MockDataService!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        viewModel = PayslipsViewModel(dataService: mockDataService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockDataService = nil
        super.tearDown()
    }
    
    func testChronologicalSortingDescending() {
        // Create test payslips with different dates
        let payslips = [
            createTestPayslip(month: "September", year: 2024),
            createTestPayslip(month: "January", year: 2025),
            createTestPayslip(month: "March", year: 2024),
            createTestPayslip(month: "November", year: 2024),
            createTestPayslip(month: "February", year: 2025)
        ]
        
        // Set up mock data service to return these payslips
        mockDataService.mockPayslips = payslips
        viewModel.payslips = payslips
        
        // Ensure sort order is date descending (newest first)
        viewModel.sortOrder = .dateDescending
        
        // Get filtered payslips (which applies sorting)
        let sortedPayslips = viewModel.filteredPayslips
        
        // Verify the order is correct: Feb 2025, Jan 2025, Nov 2024, Sep 2024, Mar 2024
        XCTAssertEqual(sortedPayslips.count, 5)
        XCTAssertEqual(sortedPayslips[0].month, "February")
        XCTAssertEqual(sortedPayslips[0].year, 2025)
        XCTAssertEqual(sortedPayslips[1].month, "January")
        XCTAssertEqual(sortedPayslips[1].year, 2025)
        XCTAssertEqual(sortedPayslips[2].month, "November")
        XCTAssertEqual(sortedPayslips[2].year, 2024)
        XCTAssertEqual(sortedPayslips[3].month, "September")
        XCTAssertEqual(sortedPayslips[3].year, 2024)
        XCTAssertEqual(sortedPayslips[4].month, "March")
        XCTAssertEqual(sortedPayslips[4].year, 2024)
    }
    
    private func createTestPayslip(month: String, year: Int) -> PayslipItem {
        return PayslipItem(
            id: UUID(),
            month: month,
            year: year,
            name: "Test User",
            credits: 100000.0,
            debits: 20000.0,
            netAmount: 80000.0,
            source: "Test",
            timestamp: Date()
        )
    }
} 