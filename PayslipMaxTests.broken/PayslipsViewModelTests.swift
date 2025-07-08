import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class PayslipsViewModelTests: XCTestCase {
    var sut: PayslipsViewModel!
    var mockDataService: MockDataService!
    var modelContext: ModelContext!
    var testPayslips: [PayslipItem] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test payslips
        testPayslips = [
            PayslipItem(
                id: UUID(),
                month: "March",
                year: 2023,
                credits: 6000.0,
                debits: 1300.0,
                dsop: 240.0,
                tax: 600.0,
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
                dsop: 220.0,
                tax: 550.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 200.0,
                tax: 500.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        ]
        
        // Create a model container for testing
        let schema = Schema([PayslipItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(container)
        
        // Insert test data into mock service
        mockDataService = MockDataService()
        for payslip in testPayslips {
            try? await mockDataService.save(payslip)
        }
        
        sut = PayslipsViewModel(dataService: mockDataService)
    }
    
    override func tearDown() {
        sut = nil
        mockDataService = nil
        modelContext = nil
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
    
    func testDeletePayslip() async throws {
        // Given
        let payslipToDelete = testPayslips[0]
        
        // When
        sut.deletePayslip(payslipToDelete, from: modelContext)
        try modelContext.save()
        
        // Then
        XCTAssertNil(sut.error, "No errors should occur during deletion")
    }
    
    func testDeletePayslipsAtIndices() async throws {
        // Given
        let indices = IndexSet([0])
        
        // When
        sut.deletePayslips(at: indices, from: testPayslips, context: modelContext)
        try modelContext.save()
        
        // Then
        XCTAssertNil(sut.error, "No errors should occur during deletion")
    }
}
