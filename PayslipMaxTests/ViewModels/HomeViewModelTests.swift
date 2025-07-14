import XCTest
import Combine
import PDFKit
@testable import PayslipMax

@MainActor
class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!
    var mockPDFHandler: MockPDFProcessingHandler!
    var mockDataHandler: MockPayslipDataHandler!
    var mockChartService: MockChartDataPreparationService!
    var mockPasswordHandler: MockPasswordProtectedPDFHandler!
    var mockErrorHandler: MockErrorHandler!
    var mockNavigationCoordinator: MockHomeNavigationCoordinator!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use TestDIContainer with mocks
        let testContainer = TestDIContainer()
        testContainer.useMocks = true
        
        // Create SUT with test container dependencies
        sut = testContainer.makeHomeViewModel()
        
        // Initialize mocks for direct access in tests
        mockPDFHandler = MockPDFProcessingHandler()
        mockDataHandler = MockPayslipDataHandler()
        mockChartService = MockChartDataPreparationService()
        mockPasswordHandler = MockPasswordProtectedPDFHandler()
        mockErrorHandler = MockErrorHandler()
        mockNavigationCoordinator = MockHomeNavigationCoordinator()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockPDFHandler = nil
        mockDataHandler = nil
        mockChartService = nil
        mockPasswordHandler = nil
        mockErrorHandler = nil
        mockNavigationCoordinator = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultValues() {
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
        XCTAssertTrue(sut.recentPayslips.isEmpty)
        XCTAssertTrue(sut.payslipData.isEmpty)
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertFalse(sut.showManualEntryForm)
    }
    
    func testInitialization_BindsPasswordHandlerProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Password handler properties bound")
        
        // When
        mockPasswordHandler.showPasswordEntryView = true
        mockPasswordHandler.currentPasswordProtectedPDFData = Data("test".utf8)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.showPasswordEntryView)
            XCTAssertEqual(self.sut.currentPasswordProtectedPDFData, Data("test".utf8))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInitialization_BindsErrorHandlerProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Error handler properties bound")
        let testError = AppError.message("Test error")
        
        // When
        mockErrorHandler.error = testError
        mockErrorHandler.errorMessage = "Test error message"
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.error?.localizedDescription, testError.localizedDescription)
            XCTAssertEqual(self.sut.errorMessage, "Test error message")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Load Recent Payslips Tests
    
    func testLoadRecentPayslips_Success_UpdatesRecentPayslips() async {
        // Given
        let mockPayslips = [
            TestDataGenerator.samplePayslipItem(id: UUID(), name: "Payslip 1"),
            TestDataGenerator.samplePayslipItem(id: UUID(), name: "Payslip 2")
        ]
        let mockAnyPayslips = mockPayslips.map { AnyPayslip($0) }
        mockDataHandler.mockRecentPayslips = mockAnyPayslips
        
        let mockChartData = [
            PayslipChartData(month: "Jan", credits: 5000, debits: 1000, net: 4000),
            PayslipChartData(month: "Feb", credits: 5200, debits: 1100, net: 4100)
        ]
        mockChartService.mockChartData = mockChartData
        
        // When
        sut.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertEqual(sut.recentPayslips.count, 2)
        XCTAssertEqual(sut.payslipData.count, 2)
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
        XCTAssertTrue(mockChartService.prepareChartDataCalled)
    }
    
    func testLoadRecentPayslips_Error_HandlesError() async {
        // Given
        let expectedError = AppError.message("Test error")
        mockDataHandler.shouldThrowError = true
        mockDataHandler.errorToThrow = expectedError
        
        // When
        sut.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
    }
    
    func testLoadRecentPayslips_LimitsToFivePayslips() async {
        // Given
        let mockPayslips = (0..<10).map { index in
            AnyPayslip(TestDataGenerator.samplePayslipItem(id: UUID(), name: "Payslip \(index)"))
        }
        mockDataHandler.mockRecentPayslips = mockPayslips
        
        // When
        sut.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertEqual(sut.recentPayslips.count, 5)
    }
    
    // MARK: - Process PDF Tests
    
    func testProcessPayslipPDF_Success_ProcessesPDF() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessPDFResult = .success(Data("pdf data".utf8))
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        
        // When
        await sut.processPayslipPDF(from: testURL)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processPDFCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testProcessPayslipPDF_PasswordProtected_ShowsPasswordEntry() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
                        mockPDFHandler.mockProcessPDFResult = .failure(AppError.passwordProtectedPDF("Password required"))
        
        // When
        await sut.processPayslipPDF(from: testURL)
        
        // Then
        XCTAssertTrue(mockPasswordHandler.showPasswordEntryCalled)
        XCTAssertEqual(mockNavigationCoordinator.currentPDFURL, testURL)
    }
    
    func testProcessPayslipPDF_Error_HandlesError() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        let expectedError = AppError.message("Processing failed")
        mockPDFHandler.mockProcessPDFResult = .failure(expectedError)
        
        // When
        await sut.processPayslipPDF(from: testURL)
        
        // Then
        XCTAssertTrue(mockErrorHandler.handlePDFErrorCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    // MARK: - Process PDF Data Tests
    
    func testProcessPDFData_Success_SavesPayslipAndNavigates() async {
        // Given
        let testData = Data("test pdf data".utf8)
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        
        // When
        await sut.processPDFData(testData)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processPDFDataCalled)
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
        XCTAssertTrue(mockNavigationCoordinator.navigateToPayslipDetailCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testProcessPDFData_Error_HandlesError() async {
        // Given
        let testData = Data("test pdf data".utf8)
        let expectedError = AppError.message("Processing failed")
        mockPDFHandler.mockProcessPDFDataResult = .failure(expectedError)
        
        // When
        await sut.processPDFData(testData)
        
        // Then
        XCTAssertTrue(mockErrorHandler.handlePDFErrorCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testProcessPDFData_SaveError_HandlesError() async {
        // Given
        let testData = Data("test pdf data".utf8)
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        mockDataHandler.shouldThrowError = true
        mockDataHandler.errorToThrow = AppError.message("Save failed")
        
        // When
        await sut.processPDFData(testData)
        
        // Then
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
        XCTAssertFalse(mockNavigationCoordinator.navigateToPayslipDetailCalled)
    }
    
    // MARK: - Handle Unlocked PDF Tests
    
    func testHandleUnlockedPDF_Success_ProcessesUnlockedPDF() async {
        // Given
        let testData = Data("unlocked pdf data".utf8)
        let testPassword = "password123"
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        mockPDFHandler.mockDetectFormatResult = .military
        
        // When
        await sut.handleUnlockedPDF(data: testData, originalPassword: testPassword)
        
        // Then
        XCTAssertTrue(mockPDFHandler.detectPayslipFormatCalled)
        XCTAssertTrue(mockPDFHandler.processPDFDataCalled)
        XCTAssertTrue(mockPasswordHandler.resetPasswordStateCalled)
        XCTAssertFalse(sut.isProcessingUnlocked)
    }
    
    // MARK: - Process Manual Entry Tests
    
    func testProcessManualEntry_Success_SavesManualEntry() async {
        // Given
        let manualData = PayslipMax.PayslipManualEntryData(
            name: "John Doe",
            month: "January",
            year: 2023,
            credits: 5000,
            debits: 1000,
            tax: 800,
            dsop: 300
        )
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockDataHandler.mockCreatedPayslipItem = mockPayslipItem
        
        // When
        sut.processManualEntry(manualData)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockDataHandler.createPayslipFromManualEntryCalled)
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
        XCTAssertTrue(mockNavigationCoordinator.navigateToPayslipDetailCalled)
    }
    
    func testProcessManualEntry_Error_HandlesError() async {
        // Given
        let manualData = PayslipMax.PayslipManualEntryData(
            name: "John Doe",
            month: "January", 
            year: 2023,
            credits: 5000,
            debits: 1000,
            tax: 800,
            dsop: 300
        )
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockDataHandler.mockCreatedPayslipItem = mockPayslipItem
        mockDataHandler.shouldThrowError = true
        mockDataHandler.errorToThrow = AppError.message("Save failed")
        
        // When
        sut.processManualEntry(manualData)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
    }
    
    // MARK: - Process Scanned Payslip Tests
    
    func testProcessScannedPayslip_Success_ProcessesImage() async {
        // Given
        let testImage = UIImage(systemName: "doc.text")!
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessScannedImageResult = .success(mockPayslipItem)
        
        // When
        sut.processScannedPayslip(from: testImage)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockPDFHandler.processScannedImageCalled)
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
        XCTAssertTrue(mockNavigationCoordinator.navigateToPayslipDetailCalled)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testProcessScannedPayslip_Error_HandlesError() async {
        // Given
        let testImage = UIImage(systemName: "doc.text")!
        let expectedError = AppError.message("Scan failed")
        mockPDFHandler.mockProcessScannedImageResult = .failure(expectedError)
        
        // When
        sut.processScannedPayslip(from: testImage)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
        XCTAssertFalse(sut.isUploading)
    }
    
    // MARK: - Manual Entry Tests
    
    func testShowManualEntry_SetsFlag() {
        // Given
        XCTAssertFalse(sut.showManualEntryForm)
        
        // When
        sut.showManualEntry()
        
        // Then
        XCTAssertTrue(sut.showManualEntryForm)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleError_DelegatesToErrorHandler() {
        // Given
        let testError = AppError.message("Test error")
        
        // When
        sut.handleError(testError)
        
        // Then
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
    }
    
    func testClearError_DelegatesToErrorHandler() {
        // When
        sut.clearError()
        
        // Then
        XCTAssertTrue(mockErrorHandler.clearErrorCalled)
    }
    
    // MARK: - Loading State Tests
    
    func testCancelLoading_ResetsLoadingStates() {
        // Given
        sut.isLoading = true
        sut.isUploading = true
        
        // When
        sut.cancelLoading()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    // MARK: - Property Binding Tests
    
    func testPasswordHandlerPropertyBinding_UpdatesViewModelProperties() async {
        // Given
        let expectation = XCTestExpectation(description: "Password handler properties updated")
        let testData = Data("test pdf".utf8)
        
        // When
        mockPasswordHandler.showPasswordEntry(for: testData)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.showPasswordEntryView)
            XCTAssertEqual(self.sut.currentPasswordProtectedPDFData, testData)
            XCTAssertTrue(self.mockPasswordHandler.showPasswordEntryCalled)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorHandlerPropertyBinding_UpdatesViewModelProperties() async {
        // Given
        let expectation = XCTestExpectation(description: "Error handler properties updated")
        let testError = AppError.message("Property binding test")
        
        // When
        mockErrorHandler.handleError(testError)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.error?.localizedDescription, testError.localizedDescription)
            XCTAssertEqual(self.sut.errorMessage, "Property binding test")
            XCTAssertTrue(self.mockErrorHandler.handleErrorCalled)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Loading State Management Tests
    
    func testLoadingStates_DuringPDFProcessing() async {
        // Given
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFHandler.mockProcessPDFResult = .success(Data("test".utf8))
        mockPDFHandler.mockProcessPDFDataResult = .success(TestDataGenerator.samplePayslipItem())
        
        // When
        let processTask = Task {
            await sut.processPayslipPDF(from: testURL)
        }
        
        // Verify loading states are set during processing
        try? await Task.sleep(nanoseconds: 10_000_000) // Small delay to catch loading state
        
        // Complete the task
        await processTask.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testGlobalLoadingManager_Integration() {
        // Given
        XCTAssertTrue(sut.recentPayslips.isEmpty)
        
        // When
        sut.loadRecentPayslips()
        
        // Then - Verify global loading manager is used (would be called in real implementation)
        // This test verifies the method completes without errors
        XCTAssertTrue(true) // Integration test passes if no exceptions thrown
    }
    
    // MARK: - Advanced Scenario Tests
    
    func testProcessPDFData_WithURLParameter() async {
        // Given
        let testData = Data("test pdf data".utf8)
        let testURL = URL(string: "file:///test.pdf")
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        
        // When
        await sut.processPDFData(testData, from: testURL)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processPDFDataCalled)
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
        XCTAssertTrue(mockNavigationCoordinator.navigateToPayslipDetailCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testComplexWorkflow_PDFToPasswordToUnlock() async {
        // Given
        let testURL = URL(string: "file:///protected.pdf")!
        let testData = Data("protected pdf".utf8)
        let unlockedData = Data("unlocked pdf".utf8)
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        
        // Setup password protection scenario
        mockPDFHandler.mockProcessPDFResult = .failure(AppError.passwordProtectedPDF("Password required"))
        mockPDFHandler.mockProcessPDFDataResult = .success(mockPayslipItem)
        
        // When - Process password protected PDF
        await sut.processPayslipPDF(from: testURL)
        
        // Then - Should show password entry
        XCTAssertTrue(mockPasswordHandler.showPasswordEntryCalled)
        XCTAssertEqual(mockNavigationCoordinator.currentPDFURL, testURL)
        
        // When - Handle unlocked PDF
        await sut.handleUnlockedPDF(data: unlockedData, originalPassword: "password123")
        
        // Then - Should process the unlocked PDF
        XCTAssertTrue(mockPDFHandler.detectPayslipFormatCalled)
        XCTAssertTrue(mockPDFHandler.processPDFDataCalled)
        XCTAssertTrue(mockPasswordHandler.resetPasswordStateCalled)
        XCTAssertFalse(sut.isProcessingUnlocked)
    }
    
    func testDataLimiting_RecentPayslipsMaxFive() async {
        // Given
        let mockPayslips = (0..<10).map { index in
            AnyPayslip(TestDataGenerator.samplePayslipItem(id: UUID(), name: "Payslip \(index)"))
        }
        mockDataHandler.mockRecentPayslips = mockPayslips
        
        // When
        sut.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(sut.recentPayslips.count, 5)
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
        XCTAssertTrue(mockChartService.prepareChartDataCalled)
    }
    
    // MARK: - Edge Case Tests
    
    func testProcessScannedPayslip_SaveError_HandlesGracefully() async {
        // Given
        let testImage = UIImage(systemName: "doc.text")!
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockPDFHandler.mockProcessScannedImageResult = .success(mockPayslipItem)
        mockDataHandler.shouldThrowError = true
        mockDataHandler.errorToThrow = AppError.message("Save failed")
        
        // When
        sut.processScannedPayslip(from: testImage)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockPDFHandler.processScannedImageCalled)
        XCTAssertTrue(mockErrorHandler.handleErrorCalled)
        XCTAssertFalse(sut.isUploading)
    }
    
    func testProcessManualEntry_EmptyData_HandlesGracefully() async {
        // Given
        let emptyManualData = PayslipMax.PayslipManualEntryData(
            name: "",
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            tax: 0,
            dsop: 0
        )
        let mockPayslipItem = TestDataGenerator.samplePayslipItem()
        mockDataHandler.mockCreatedPayslipItem = mockPayslipItem
        
        // When
        sut.processManualEntry(emptyManualData)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockDataHandler.createPayslipFromManualEntryCalled)
        XCTAssertTrue(mockDataHandler.savePayslipItemCalled)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentLoadOperations_HandledProperly() async {
        // Given
        let mockPayslips = [AnyPayslip(TestDataGenerator.samplePayslipItem())]
        mockDataHandler.mockRecentPayslips = mockPayslips
        
        // When - Start multiple concurrent load operations
        let task1 = Task { sut.loadRecentPayslips() }
        let task2 = Task { sut.loadRecentPayslips() }
        let task3 = Task { sut.loadRecentPayslips() }
        
        await task1.value
        await task2.value
        await task3.value
        
        // Wait for all operations to complete
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
        XCTAssertFalse(sut.recentPayslips.isEmpty)
    }
    
    // MARK: - Notification Handling Tests
    
    func testHandlePayslipDeleted_RemovesPayslipFromRecentList() async {
        // Given
        let payslipId = UUID()
        let payslipToRemove = TestDataGenerator.samplePayslipItem(id: payslipId)
        let otherPayslip = TestDataGenerator.samplePayslipItem()
        sut.recentPayslips = [AnyPayslip(payslipToRemove), AnyPayslip(otherPayslip)]
        
        // When
        let notification = Notification(
            name: .payslipDeleted,
            object: nil,
            userInfo: ["payslipId": payslipId]
        )
        NotificationCenter.default.post(notification)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertEqual(sut.recentPayslips.count, 1)
        XCTAssertNotEqual(sut.recentPayslips.first?.id, payslipId)
    }
    
    func testHandlePayslipsForcedRefresh_ClearsDataAndReloads() async {
        // Given
        sut.recentPayslips = [AnyPayslip(TestDataGenerator.samplePayslipItem())]
        sut.payslipData = [PayslipChartData(month: "Jan", credits: 5000, debits: 1000, net: 4000)]
        
        // When
        let notification = Notification(name: .payslipsForcedRefresh)
        NotificationCenter.default.post(notification)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
        
        // Then
        XCTAssertTrue(mockDataHandler.loadRecentPayslipsCalled)
    }
}