import XCTest
@testable import PayslipStandaloneTests

@MainActor
final class PayslipsViewModelTests: XCTestCase {
    var mockDataService: MockDataService!
    var viewModel: PayslipsViewModel!
    
    override func setUp() async throws {
        mockDataService = MockDataService()
        viewModel = PayslipsViewModel(dataService: mockDataService)
    }
    
    override func tearDown() async throws {
        mockDataService = nil
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertTrue(viewModel.payslips.isEmpty, "Payslips should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading initially")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error initially")
    }
    
    func testLoadPayslips_Success() async {
        // Given
        let samplePayslip = StandalonePayslipItem.sample()
        try? await mockDataService.save(samplePayslip)
        
        // When
        await viewModel.loadPayslips()
        
        // Then
        XCTAssertFalse(viewModel.payslips.isEmpty, "Payslips should not be empty after loading")
        XCTAssertEqual(viewModel.payslips.count, 1, "There should be one payslip")
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful loading")
        XCTAssertEqual(mockDataService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockDataService.fetchCount, 1, "fetch() should be called once")
    }
    
    func testLoadPayslips_Failure() async {
        // Given
        mockDataService.shouldFail = true
        
        // When
        await viewModel.loadPayslips()
        
        // Then
        XCTAssertTrue(viewModel.payslips.isEmpty, "Payslips should be empty after failed loading")
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed loading")
        XCTAssertEqual(mockDataService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockDataService.fetchCount, 0, "fetch() should not be called if initialization fails")
    }
    
    func testAddPayslip_Success() async {
        // Given
        let samplePayslip = StandalonePayslipItem.sample()
        
        // When
        await viewModel.addPayslip(samplePayslip)
        
        // Then
        XCTAssertFalse(viewModel.payslips.isEmpty, "Payslips should not be empty after adding")
        XCTAssertEqual(viewModel.payslips.count, 1, "There should be one payslip")
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful adding")
        XCTAssertEqual(mockDataService.saveCount, 1, "save() should be called once")
        XCTAssertEqual(mockDataService.fetchCount, 1, "fetch() should be called once to reload payslips")
    }
    
    func testAddPayslip_Failure() async {
        // Given
        let samplePayslip = StandalonePayslipItem.sample()
        mockDataService.shouldFail = true
        
        // When
        await viewModel.addPayslip(samplePayslip)
        
        // Then
        XCTAssertTrue(viewModel.payslips.isEmpty, "Payslips should be empty after failed adding")
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed adding")
        XCTAssertEqual(mockDataService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockDataService.saveCount, 0, "save() should not be called if initialization fails")
    }
    
    func testDeletePayslip_Success() async {
        // Given
        let samplePayslip = StandalonePayslipItem.sample()
        try? await mockDataService.save(samplePayslip)
        await viewModel.loadPayslips()
        XCTAssertEqual(viewModel.payslips.count, 1, "There should be one payslip before deletion")
        
        // When
        await viewModel.deletePayslip(samplePayslip)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful deletion")
        XCTAssertEqual(mockDataService.deleteCount, 1, "delete() should be called once")
        XCTAssertEqual(mockDataService.fetchCount, 2, "fetch() should be called twice: once for initial load and once after deletion")
    }
    
    func testDeletePayslip_Failure() async {
        // Given
        let samplePayslip = StandalonePayslipItem.sample()
        try? await mockDataService.save(samplePayslip)
        await viewModel.loadPayslips()
        
        // Reset the mock's state to track new calls
        mockDataService = MockDataService()
        mockDataService.shouldFail = true
        viewModel = PayslipsViewModel(dataService: mockDataService)
        
        // When
        await viewModel.deletePayslip(samplePayslip)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after completion")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed deletion")
        XCTAssertEqual(mockDataService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockDataService.deleteCount, 0, "delete() should not be called if initialization fails")
    }
    
    func testServiceAlreadyInitialized() async {
        // Given
        mockDataService.isInitialized = true
        let samplePayslip = StandalonePayslipItem.sample()
        
        // When
        await viewModel.addPayslip(samplePayslip)
        
        // Then
        XCTAssertEqual(mockDataService.initializeCount, 0, "initialize() should not be called if service is already initialized")
        XCTAssertEqual(mockDataService.saveCount, 1, "save() should be called once")
    }
} 