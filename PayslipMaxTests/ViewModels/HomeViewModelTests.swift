import XCTest
import SwiftUI
import Combine
import PDFKit
@testable import PayslipMax

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var sut: HomeViewModel!
    var mockPDFHandler: MockPDFProcessingHandler!
    var mockDataHandler: MockPayslipDataHandler!
    var mockChartService: MockChartDataPreparationService!
    var mockPasswordHandler: MockPasswordProtectedPDFHandler!
    var mockErrorHandler: MockErrorHandler!
    var mockNavigationCoordinator: MockHomeNavigationCoordinator!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock dependencies
        mockPDFHandler = MockPDFProcessingHandler()
        mockDataHandler = MockPayslipDataHandler()
        mockChartService = MockChartDataPreparationService()
        mockPasswordHandler = MockPasswordProtectedPDFHandler()
        mockErrorHandler = MockErrorHandler()
        mockNavigationCoordinator = MockHomeNavigationCoordinator()
        
        // Initialize view model with mocks
        sut = HomeViewModel(
            pdfHandler: mockPDFHandler,
            dataHandler: mockDataHandler,
            chartService: mockChartService,
            passwordHandler: mockPasswordHandler,
            errorHandler: mockErrorHandler,
            navigationCoordinator: mockNavigationCoordinator
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockPDFHandler = nil
        mockDataHandler = nil
        mockChartService = nil
        mockPasswordHandler = nil
        mockErrorHandler = nil
        mockNavigationCoordinator = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When - ViewModel is initialized in setUp
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.recentPayslips.isEmpty)
        XCTAssertTrue(sut.payslipData.isEmpty)
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertFalse(sut.showManualEntryForm)
    }
    
    // MARK: - PDF Processing Tests
    
    func testProcessPDFFromURL_Success() async {
        // Given
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let expectedPayslip = createMockPayslipItem()
        mockPDFHandler.mockProcessResult = .success(expectedPayslip)
        
        // When
        await sut.processPDF(from: testURL)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processFromURLCalled)
        XCTAssertEqual(mockPDFHandler.lastProcessedURL, testURL)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testProcessPDFFromURL_Failure() async {
        // Given
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let expectedError = AppError.pdfExtractionFailed("Test error")
        mockPDFHandler.mockProcessResult = .failure(expectedError)
        
        // When
        await sut.processPDF(from: testURL)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processFromURLCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
    }
    
    func testProcessPDFFromData_Success() async {
        // Given
        let testData = Data("test pdf content".utf8)
        let expectedPayslip = createMockPayslipItem()
        mockPDFHandler.mockProcessResult = .success(expectedPayslip)
        
        // When
        await sut.processPDF(from: testData, filename: "test.pdf")
        
        // Then
        XCTAssertTrue(mockPDFHandler.processFromDataCalled)
        XCTAssertEqual(mockPDFHandler.lastProcessedData, testData)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testProcessPDFFromData_PasswordProtected() async {
        // Given
        let testData = Data("password protected pdf".utf8)
        let passwordError = AppError.passwordRequired
        mockPDFHandler.mockProcessResult = .failure(passwordError)
        mockPasswordHandler.shouldShowPasswordEntry = true
        
        // When
        await sut.processPDF(from: testData, filename: "test.pdf")
        
        // Then
        XCTAssertTrue(mockPDFHandler.processFromDataCalled)
        XCTAssertTrue(sut.showPasswordEntryView)
        XCTAssertNotNil(sut.currentPasswordProtectedPDFData)
    }
    
    // MARK: - Data Loading Tests
    
    func testRefreshData_Success() async {
        // Given
        let mockPayslips = [createMockPayslipItem(), createMockPayslipItem()]
        let mockChartData = [createMockChartData()]
        mockDataHandler.mockPayslips = mockPayslips
        mockChartService.mockChartData = mockChartData
        
        // When
        await sut.refreshData()
        
        // Then
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
        XCTAssertTrue(mockChartService.prepareChartDataCalled)
        XCTAssertEqual(sut.recentPayslips.count, mockPayslips.count)
        XCTAssertEqual(sut.payslipData.count, mockChartData.count)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testRefreshData_Failure() async {
        // Given
        let expectedError = AppError.dataLoadFailed("Test error")
        mockDataHandler.mockError = expectedError
        
        // When
        await sut.refreshData()
        
        // Then
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Password Handling Tests
    
    func testSubmitPassword_Success() async {
        // Given
        let password = "testPassword123"
        let testData = Data("test pdf data".utf8)
        let expectedPayslip = createMockPayslipItem()
        
        sut.currentPasswordProtectedPDFData = testData
        sut.currentPDFPassword = password
        mockPasswordHandler.mockUnlockResult = .success(expectedPayslip)
        
        // When
        await sut.submitPassword()
        
        // Then
        XCTAssertTrue(mockPasswordHandler.unlockAndProcessCalled)
        XCTAssertEqual(mockPasswordHandler.lastPassword, password)
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertNil(sut.currentPasswordProtectedPDFData)
        XCTAssertNil(sut.currentPDFPassword)
    }
    
    func testSubmitPassword_InvalidPassword() async {
        // Given
        let password = "wrongPassword"
        let testData = Data("test pdf data".utf8)
        let expectedError = AppError.invalidPassword
        
        sut.currentPasswordProtectedPDFData = testData
        sut.currentPDFPassword = password
        mockPasswordHandler.mockUnlockResult = .failure(expectedError)
        
        // When
        await sut.submitPassword()
        
        // Then
        XCTAssertTrue(mockPasswordHandler.unlockAndProcessCalled)
        XCTAssertTrue(sut.showPasswordEntryView) // Should remain visible
        XCTAssertNotNil(sut.error)
    }
    
    func testCancelPasswordEntry() {
        // Given
        sut.showPasswordEntryView = true
        sut.currentPasswordProtectedPDFData = Data()
        sut.currentPDFPassword = "test"
        
        // When
        sut.cancelPasswordEntry()
        
        // Then
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertNil(sut.currentPasswordProtectedPDFData)
        XCTAssertNil(sut.currentPDFPassword)
    }
    
    // MARK: - Manual Entry Tests
    
    func testShowManualEntry() {
        // Given
        XCTAssertFalse(sut.showManualEntryForm)
        
        // When
        sut.showManualEntry()
        
        // Then
        XCTAssertTrue(sut.showManualEntryForm)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        sut.error = AppError.unknown("Test error")
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertTrue(mockErrorHandler.clearErrorCalled)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStatesduringPDFProcessing() async {
        // Given
        let testURL = URL(fileURLWithPath: "/tmp/test.pdf")
        mockPDFHandler.shouldDelay = true // Mock will introduce delay
        
        // When
        let processingTask = Task {
            await sut.processPDF(from: testURL)
        }
        
        // Then - Check loading state during processing
        XCTAssertTrue(sut.isLoading)
        
        // Wait for completion
        await processingTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Notification Handling Tests
    
    func testPayslipDeletedNotification() async {
        // Given
        let initialPayslips = [createMockPayslipItem(), createMockPayslipItem()]
        sut.recentPayslips = initialPayslips.map { AnyPayslip($0) }
        
        let payslipToDelete = initialPayslips[0]
        
        // When
        NotificationCenter.default.post(
            name: .payslipDeleted,
            object: nil,
            userInfo: ["payslipId": payslipToDelete.id]
        )
        
        // Wait for notification processing
        await Task.yield()
        
        // Then
        XCTAssertTrue(mockDataHandler.refreshCalled)
    }
    
    func testPayslipUpdatedNotification() async {
        // Given
        let initialPayslips = [createMockPayslipItem()]
        sut.recentPayslips = initialPayslips.map { AnyPayslip($0) }
        
        // When
        NotificationCenter.default.post(name: .payslipUpdated, object: nil)
        
        // Wait for notification processing
        await Task.yield()
        
        // Then
        XCTAssertTrue(mockDataHandler.refreshCalled)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPayslipItem() -> PayslipItem {
        return PayslipItem(
            name: "Test User",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 10000.0,
            dsop: 5000.0,
            tax: 3000.0,
            netRemittance: 40000.0,
            earnings: ["BPAY": 30000.0, "DA": 20000.0],
            deductions: ["DSOP": 5000.0, "ITAX": 3000.0]
        )
    }
    
    private func createMockChartData() -> PayslipChartData {
        return PayslipChartData(
            month: "January",
            year: 2024,
            totalEarnings: 50000.0,
            totalDeductions: 10000.0,
            netAmount: 40000.0
        )
    }
} 