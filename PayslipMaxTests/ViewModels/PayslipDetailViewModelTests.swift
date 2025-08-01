import XCTest
@testable import PayslipMax

@MainActor
final class PayslipDetailViewModelTests: BaseTestCase {
    
    var sut: PayslipDetailViewModel!
    var mockSecurityService: CoreMockSecurityService!
    var testPayslip: PayslipItem!
    var testContainer: TestDIContainer!
    var asyncTasks: Set<Task<Void, Never>>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize async task tracking
        asyncTasks = Set<Task<Void, Never>>()
        
        // Create mock services
        mockSecurityService = CoreMockSecurityService()
        
        // Set up the DI container with mock services
        testContainer = TestDIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        // Create a test payslip with known values
        testPayslip = PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000,
            debits: 2300, // 1000 + 500 + 800 to match expected net of 2700
            dsop: 500,
            tax: 800,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Create the view model with the test payslip and all required services from test container
        sut = PayslipDetailViewModel(
            payslip: testPayslip,
            securityService: testContainer.securityService,
            dataService: testContainer.dataService,
            pdfService: MockPayslipPDFService(),
            formatterService: MockPayslipFormatterService(),
            shareService: MockPayslipShareService()
        )
        
        // Wait for any async initialization to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        // Cancel all async tasks before cleanup to prevent race conditions
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()
        
        sut = nil
        mockSecurityService = nil
        testPayslip = nil
        testContainer = nil
        asyncTasks = nil
        // DO NOT call TestDIContainer.resetToDefault() to avoid async race conditions
        try await super.tearDown()
    }
    
    func testInitialization() {
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.payslipData.netRemittance, 2700.0) // 5000 - (1000 + 500 + 800)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.payslipData.name, "Test User")
    }
    
    func testLoadAdditionalData() async {
        // When
        await sut.loadAdditionalData()
        
        // Then
        XCTAssertEqual(sut.payslipData.name, "Test User")
        XCTAssertEqual(sut.payslipData.month, "January")
        XCTAssertEqual(sut.payslipData.year, 2025)
        XCTAssertEqual(sut.payslipData.totalCredits, 5000)
        XCTAssertEqual(sut.payslipData.netRemittance, 2700.0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFormatCurrency() {
        // When
        let formatted = sut.formatCurrency(1234.56)
        
        // Then
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("1,235") || formatted.contains("1235"), "Expected rounded value of 1234.56 to be 1235")
    }
    
    func testGetShareText() async {
        // Given
        await sut.loadAdditionalData()
        
        // When
        let shareText = sut.getShareText()
        
        // Then
        XCTAssertTrue(shareText.contains("Test User"))
        XCTAssertTrue(shareText.contains("January"))
        XCTAssertTrue(shareText.contains("2025"))
        XCTAssertTrue(shareText.contains("Net Amount"))
    }
    
    func testCalculateNetAmount() {
        // Given
        let expectedNet = testPayslip.credits - testPayslip.debits  // Net remittance = credits - debits
        
        // Then
        XCTAssertEqual(sut.payslipData.netRemittance, expectedNet)
        XCTAssertEqual(sut.payslipData.netRemittance, 2700.0)
    }
    
    func testLoadingState() async {
        // Check initial state
        XCTAssertFalse(sut.isLoading)
        
        // Create a controlled async operation and track it
        let loadingTask = Task<Void, Never> {
            await sut.loadAdditionalData()
        }
        asyncTasks.insert(loadingTask)
        
        // Wait for the operation to complete
        await loadingTask.value
        
        // Check final state - loading should be false after completion
        XCTAssertFalse(sut.isLoading)
        
        // Remove completed task from tracking
        asyncTasks.remove(loadingTask)
    }
} 