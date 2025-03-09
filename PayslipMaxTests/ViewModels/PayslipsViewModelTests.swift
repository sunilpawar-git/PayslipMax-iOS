import XCTest
import SwiftData
@testable import Payslip_Max

@MainActor
final class PayslipsViewModelTests: XCTestCase {
    var sut: PayslipsViewModel!
    var mockDataService: MockDataService!
    var mockModelContext: MockModelContext!
    var testPayslips: [PayslipItem] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test payslips
        testPayslips = [
            PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dspof: 200.0,
                tax: 500.0,
                location: "New York",
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipItem(
                id: UUID(),
                month: "February",
                year: 2023,
                credits: 5500.0,
                debits: 1200.0,
                dspof: 220.0,
                tax: 550.0,
                location: "Boston",
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        ]
        
        mockDataService = MockDataService()
        mockModelContext = MockModelContext()
        sut = PayslipsViewModel(dataService: mockDataService)
    }
    
    override func tearDown() {
        sut = nil
        mockDataService = nil
        mockModelContext = nil
        testPayslips = []
        super.tearDown()
    }
    
    func testFilterPayslips_WithSearchText() {
        // Given
        let searchText = "January"
        
        // When
        let filteredPayslips = sut.filterPayslips(testPayslips, searchText: searchText)
        
        // Then
        XCTAssertEqual(filteredPayslips.count, 1)
        XCTAssertEqual(filteredPayslips.first?.month, "January")
    }
    
    func testFilterPayslips_WithEmptySearchText() {
        // Given
        let searchText = ""
        
        // When
        let filteredPayslips = sut.filterPayslips(testPayslips, searchText: searchText)
        
        // Then
        XCTAssertEqual(filteredPayslips.count, testPayslips.count)
    }
    
    func testSortPayslips_DateAscending() {
        // Set sort order to date ascending
        sut.sortOrder = .dateAscending
        
        // Filter and sort payslips
        let sortedPayslips = sut.filterPayslips(testPayslips)
        
        // Verify payslips are sorted by date in ascending order
        XCTAssertEqual(sortedPayslips[0].month, "January")
        XCTAssertEqual(sortedPayslips[1].month, "February")
        XCTAssertEqual(sortedPayslips[2].month, "March")
    }
    
    func testSortPayslips_DateDescending() {
        // Set sort order to date descending
        sut.sortOrder = .dateDescending
        
        // Filter and sort payslips
        let sortedPayslips = sut.filterPayslips(testPayslips)
        
        // Verify payslips are sorted by date in descending order
        XCTAssertEqual(sortedPayslips[0].month, "March")
        XCTAssertEqual(sortedPayslips[1].month, "February")
        XCTAssertEqual(sortedPayslips[2].month, "January")
    }
    
    func testDeletePayslip() {
        // Given
        let payslipToDelete = testPayslips[0]
        
        // When
        sut.deletePayslip(payslipToDelete, from: mockModelContext!)
        
        // Then
        XCTAssertTrue(mockModelContext.deletedObjects.contains(where: { $0 as? PayslipItem === payslipToDelete }))
        XCTAssertTrue(mockModelContext.savedChanges)
    }
    
    func testDeletePayslipsAtIndices() {
        // Given
        let indices = IndexSet([0])
        
        // When
        sut.deletePayslips(at: indices, from: testPayslips, context: mockModelContext!)
        
        // Then
        XCTAssertTrue(mockModelContext.deletedObjects.contains(where: { $0 as? PayslipItem === testPayslips[0] }))
        XCTAssertTrue(mockModelContext.savedChanges)
    }
}
