import XCTest
@testable import PayslipStandaloneTests

@MainActor
final class PDFViewModelTests: XCTestCase {
    var mockPDFService: MockPDFService!
    var viewModel: PDFViewModel!
    
    override func setUp() async throws {
        mockPDFService = MockPDFService()
        viewModel = PDFViewModel(pdfService: mockPDFService)
    }
    
    override func tearDown() async throws {
        mockPDFService = nil
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing initially")
        XCTAssertNil(viewModel.extractedPayslip, "ViewModel should not have an extracted payslip initially")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error initially")
    }
    
    func testProcessPDF_Success() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        
        // When
        await viewModel.processPDF(at: testURL)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing after completion")
        XCTAssertNotNil(viewModel.extractedPayslip, "ViewModel should have an extracted payslip after successful processing")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful processing")
        XCTAssertEqual(mockPDFService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockPDFService.processCount, 1, "process() should be called once")
        XCTAssertEqual(mockPDFService.extractCount, 1, "extract() should be called once")
    }
    
    func testProcessPDF_Failure_InitializationFails() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFService.shouldFail = true
        
        // When
        await viewModel.processPDF(at: testURL)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing after completion")
        XCTAssertNil(viewModel.extractedPayslip, "ViewModel should not have an extracted payslip after failed processing")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed processing")
        XCTAssertEqual(mockPDFService.initializeCount, 1, "initialize() should be called once")
        XCTAssertEqual(mockPDFService.processCount, 0, "process() should not be called if initialization fails")
        XCTAssertEqual(mockPDFService.extractCount, 0, "extract() should not be called if initialization fails")
        
        if let error = viewModel.error as? MockError {
            XCTAssertEqual(error, MockError.initializationFailed, "Error should be initializationFailed")
        } else {
            XCTFail("Error should be a MockError")
        }
    }
    
    func testProcessPDF_ServiceAlreadyInitialized() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFService.isInitialized = true
        
        // When
        await viewModel.processPDF(at: testURL)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing after completion")
        XCTAssertNotNil(viewModel.extractedPayslip, "ViewModel should have an extracted payslip after successful processing")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after successful processing")
        XCTAssertEqual(mockPDFService.initializeCount, 0, "initialize() should not be called if service is already initialized")
        XCTAssertEqual(mockPDFService.processCount, 1, "process() should be called once")
        XCTAssertEqual(mockPDFService.extractCount, 1, "extract() should be called once")
    }
    
    func testReset() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        await viewModel.processPDF(at: testURL)
        XCTAssertNotNil(viewModel.extractedPayslip, "ViewModel should have an extracted payslip after successful processing")
        
        // When
        viewModel.reset()
        
        // Then
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing after reset")
        XCTAssertNil(viewModel.extractedPayslip, "ViewModel should not have an extracted payslip after reset")
        XCTAssertNil(viewModel.error, "ViewModel should not have an error after reset")
    }
    
    func testProcessPDF_ProcessingFails() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFService.isInitialized = true // Skip initialization
        
        // Configure the mock to fail during processing
        let processFailMock = MockPDFService()
        processFailMock.isInitialized = true
        processFailMock.shouldFail = true
        viewModel = PDFViewModel(pdfService: processFailMock)
        
        // When
        await viewModel.processPDF(at: testURL)
        
        // Then
        XCTAssertFalse(viewModel.isProcessing, "ViewModel should not be processing after completion")
        XCTAssertNil(viewModel.extractedPayslip, "ViewModel should not have an extracted payslip after failed processing")
        XCTAssertNotNil(viewModel.error, "ViewModel should have an error after failed processing")
        XCTAssertEqual(processFailMock.processCount, 1, "process() should be called once")
        XCTAssertEqual(processFailMock.extractCount, 0, "extract() should not be called if processing fails")
        
        if let error = viewModel.error as? MockError {
            XCTAssertEqual(error, MockError.processingFailed, "Error should be processingFailed")
        } else {
            XCTFail("Error should be a MockError")
        }
    }
} 