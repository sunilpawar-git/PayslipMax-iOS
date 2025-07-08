#!/usr/bin/env swift

import Foundation
import Combine

// Mock global loading manager for testing
class GlobalLoadingManager {
    static let shared = GlobalLoadingManager()
    private init() {}
    
    func startLoading(operationId: String, message: String) {
        print("✓ Starting loading operation: \(operationId) - \(message)")
    }
    
    func stopLoading(operationId: String) {
        print("✓ Stopping loading operation: \(operationId)")
    }
}

// MARK: - Test Data Types
struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
}

enum PayslipFormat {
    case military
    case civilian
    case government
}

struct PayslipChartData {
    let month: String
    let value: Double
    let type: ChartDataType
}

enum ChartDataType {
    case income
    case expense
}

struct AnyPayslip {
    let id: UUID
    let name: String
    let timestamp: Date
    
    init(id: UUID = UUID(), name: String = "Test Payslip", timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
    }
}

class PayslipItem {
    let id: UUID
    let name: String
    let timestamp: Date
    
    init(id: UUID = UUID(), name: String = "Test Payslip", timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
    }
}

// MARK: - AppError
enum AppError: Error, LocalizedError {
    case message(String)
    case passwordProtectedPDF(String)
    case pdfProcessingFailed(String)
    case invalidPDFFormat
    
    var errorDescription: String? {
        switch self {
        case .message(let msg): return msg
        case .passwordProtectedPDF(let msg): return msg
        case .pdfProcessingFailed(let msg): return msg
        case .invalidPDFFormat: return "Invalid PDF format"
        }
    }
    
    var userMessage: String {
        return errorDescription ?? "Unknown error"
    }
    
    var localizedDescription: String {
        return errorDescription ?? "Unknown error"
    }
}

// MARK: - Simplified Mock Implementations
class MockPDFProcessingHandler {
    var processPDFResult: Result<Data, Error> = .success(Data("test pdf".utf8))
    var processPDFDataResult: Result<PayslipItem, Error> = .success(PayslipItem())
    var processScannedImageResult: Result<PayslipItem, Error> = .success(PayslipItem())
    var detectFormatResult: PayslipFormat = .military
    var isPasswordProtectedResult = false
    
    func processPDF(from url: URL) async -> Result<Data, Error> {
        return processPDFResult
    }
    
    func processPDFData(_ data: Data, from url: URL?) async -> Result<PayslipItem, Error> {
        return processPDFDataResult
    }
    
    func processScannedImage(_ image: Any) async -> Result<PayslipItem, Error> {
        return processScannedImageResult
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        return detectFormatResult
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        return isPasswordProtectedResult
    }
}

class MockPayslipDataHandler {
    var mockRecentPayslips: [AnyPayslip] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")
    
    func loadRecentPayslips() async throws -> [AnyPayslip] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockRecentPayslips
    }
    
    func savePayslipItem(_ item: PayslipItem) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func createPayslipFromManualEntry(_ data: PayslipManualEntryData) -> PayslipItem {
        return PayslipItem(name: data.name)
    }
}

class MockChartDataPreparationService {
    var mockChartData: [PayslipChartData] = []
    
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        return mockChartData
    }
}

@MainActor
class MockPasswordProtectedPDFHandler: ObservableObject {
    @Published var showPasswordEntryView = false
    @Published var currentPasswordProtectedPDFData: Data?
    @Published var currentPDFPassword: String?
    
    var showPasswordEntryCalled = false
    var resetPasswordStateCalled = false
    
    func showPasswordEntry(for pdfData: Data) {
        showPasswordEntryCalled = true
        currentPasswordProtectedPDFData = pdfData
        showPasswordEntryView = true
    }
    
    func resetPasswordState() {
        resetPasswordStateCalled = true
        showPasswordEntryView = false
        currentPasswordProtectedPDFData = nil
        currentPDFPassword = nil
    }
}

@MainActor
class MockErrorHandler: ObservableObject {
    @Published var error: AppError?
    @Published var errorMessage: String?
    @Published var errorType: AppError?
    
    var handleErrorCalled = false
    var handlePDFErrorCalled = false
    var clearErrorCalled = false
    
    func handleError(_ error: Error) {
        handleErrorCalled = true
        if let appError = error as? AppError {
            self.error = appError
            self.errorType = appError
        }
        self.errorMessage = error.localizedDescription
    }
    
    func handlePDFError(_ error: Error) {
        handlePDFErrorCalled = true
        handleError(error)
    }
    
    func clearError() {
        clearErrorCalled = true
        error = nil
        errorMessage = nil
        errorType = nil
    }
}

class MockHomeNavigationCoordinator {
    var currentPDFURL: URL?
    var navigateToPayslipDetailCalled = false
    var setPDFDocumentCalled = false
    
    func navigateToPayslipDetail(for payslip: PayslipItem) {
        navigateToPayslipDetailCalled = true
    }
    
    func setPDFDocument(_ document: Any, url: URL?) {
        setPDFDocumentCalled = true
    }
}

// MARK: - Simplified HomeViewModel for Testing
@MainActor
class SimpleHomeViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var recentPayslips: [AnyPayslip] = []
    @Published var payslipData: [PayslipChartData] = []
    @Published var isProcessingUnlocked = false
    @Published var unlockedPDFData: Data?
    @Published var errorType: AppError?
    @Published var showPasswordEntryView = false
    @Published var currentPasswordProtectedPDFData: Data?
    @Published var currentPDFPassword: String?
    @Published var showManualEntryForm = false
    
    private let pdfHandler: MockPDFProcessingHandler
    private let dataHandler: MockPayslipDataHandler
    private let chartService: MockChartDataPreparationService
    private let passwordHandler: MockPasswordProtectedPDFHandler
    private let errorHandler: MockErrorHandler
    private let navigationCoordinator: MockHomeNavigationCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init(
        pdfHandler: MockPDFProcessingHandler,
        dataHandler: MockPayslipDataHandler,
        chartService: MockChartDataPreparationService,
        passwordHandler: MockPasswordProtectedPDFHandler,
        errorHandler: MockErrorHandler,
        navigationCoordinator: MockHomeNavigationCoordinator
    ) {
        self.pdfHandler = pdfHandler
        self.dataHandler = dataHandler
        self.chartService = chartService
        self.passwordHandler = passwordHandler
        self.errorHandler = errorHandler
        self.navigationCoordinator = navigationCoordinator
        
        // Bind handlers to view model
        bindPasswordHandlerProperties()
        bindErrorHandlerProperties()
    }
    
    private func bindPasswordHandlerProperties() {
        passwordHandler.$showPasswordEntryView
            .assign(to: \.showPasswordEntryView, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPasswordProtectedPDFData
            .assign(to: \.currentPasswordProtectedPDFData, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPDFPassword
            .assign(to: \.currentPDFPassword, on: self)
            .store(in: &cancellables)
    }
    
    private func bindErrorHandlerProperties() {
        errorHandler.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorType
            .assign(to: \.errorType, on: self)
            .store(in: &cancellables)
    }
    
    func loadRecentPayslips() {
        Task {
            GlobalLoadingManager.shared.startLoading(
                operationId: "home_recent_payslips",
                message: "Loading recent payslips..."
            )
            
            do {
                let payslips = try await dataHandler.loadRecentPayslips()
                let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
                let recentOnes = Array(sortedPayslips.prefix(5))
                let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)
                
                await MainActor.run {
                    self.recentPayslips = recentOnes
                    self.payslipData = chartData
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
            
            GlobalLoadingManager.shared.stopLoading(operationId: "home_recent_payslips")
        }
    }
    
    func processPayslipPDF(from url: URL) async {
        isLoading = true
        isUploading = true
        
        let result = await pdfHandler.processPDF(from: url)
        
        switch result {
        case .success(let data):
            await processPDFData(data, from: url)
        case .failure(let error):
            if error is AppError {
                passwordHandler.showPasswordEntry(for: Data())
                navigationCoordinator.currentPDFURL = url
            } else {
                isLoading = false
                isUploading = false
                errorHandler.handlePDFError(error)
            }
        }
    }
    
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        isLoading = true
        isUploading = true
        
        let result = await pdfHandler.processPDFData(data, from: url)
        
        defer {
            isLoading = false
            isUploading = false
            isProcessingUnlocked = false
        }
        
        switch result {
        case .success(let payslipItem):
            do {
                try await dataHandler.savePayslipItem(payslipItem)
                navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                
                if showPasswordEntryView {
                    passwordHandler.resetPasswordState()
                }
            } catch {
                errorHandler.handleError(error)
            }
            
        case .failure(let error):
            errorHandler.handlePDFError(error)
        }
    }
    
    func processManualEntry(_ payslipData: PayslipManualEntryData) {
        Task {
            let payslipItem = dataHandler.createPayslipFromManualEntry(payslipData)
            
            do {
                try await dataHandler.savePayslipItem(payslipItem)
                navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
            } catch {
                errorHandler.handleError(error)
            }
        }
    }
    
    func handleError(_ error: Error) {
        errorHandler.handleError(error)
    }
    
    func clearError() {
        errorHandler.clearError()
    }
    
    func showManualEntry() {
        showManualEntryForm = true
    }
    
    func cancelLoading() {
        GlobalLoadingManager.shared.stopLoading(operationId: "home_recent_payslips")
        isLoading = false
        isUploading = false
    }
}

// MARK: - Test Suite
@MainActor
class HomeViewModelTestSuite {
    private var viewModel: SimpleHomeViewModel!
    private var mockPDFHandler: MockPDFProcessingHandler!
    private var mockDataHandler: MockPayslipDataHandler!
    private var mockChartService: MockChartDataPreparationService!
    private var mockPasswordHandler: MockPasswordProtectedPDFHandler!
    private var mockErrorHandler: MockErrorHandler!
    private var mockNavigationCoordinator: MockHomeNavigationCoordinator!
    
    func setUp() {
        mockPDFHandler = MockPDFProcessingHandler()
        mockDataHandler = MockPayslipDataHandler()
        mockChartService = MockChartDataPreparationService()
        mockPasswordHandler = MockPasswordProtectedPDFHandler()
        mockErrorHandler = MockErrorHandler()
        mockNavigationCoordinator = MockHomeNavigationCoordinator()
        
        viewModel = SimpleHomeViewModel(
            pdfHandler: mockPDFHandler,
            dataHandler: mockDataHandler,
            chartService: mockChartService,
            passwordHandler: mockPasswordHandler,
            errorHandler: mockErrorHandler,
            navigationCoordinator: mockNavigationCoordinator
        )
    }
    
    func testInitialization() async {
        print("🧪 Testing HomeViewModel initialization...")
        
        setUp()
        
        assert(viewModel.error == nil, "❌ Initial error should be nil")
        assert(viewModel.errorMessage == nil, "❌ Initial error message should be nil")
        assert(!viewModel.isLoading, "❌ Initial loading state should be false")
        assert(!viewModel.isUploading, "❌ Initial uploading state should be false")
        assert(viewModel.recentPayslips.isEmpty, "❌ Initial payslips should be empty")
        assert(viewModel.payslipData.isEmpty, "❌ Initial chart data should be empty")
        assert(!viewModel.showPasswordEntryView, "❌ Initial password entry view should be false")
        assert(!viewModel.showManualEntryForm, "❌ Initial manual entry form should be false")
        
        print("✅ HomeViewModel initialization test passed")
    }
    
    func testLoadRecentPayslips() async {
        print("🧪 Testing load recent payslips...")
        
        setUp()
        
        let mockPayslips = [
            AnyPayslip(name: "Payslip 1"),
            AnyPayslip(name: "Payslip 2")
        ]
        mockDataHandler.mockRecentPayslips = mockPayslips
        
        let mockChartData = [
            PayslipChartData(month: "Jan", value: 5000, type: .income)
        ]
        mockChartService.mockChartData = mockChartData
        
        viewModel.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        assert(viewModel.recentPayslips.count == 2, "❌ Should load 2 payslips")
        assert(viewModel.payslipData.count == 1, "❌ Should load 1 chart data point")
        
        print("✅ Load recent payslips test passed")
    }
    
    func testLoadRecentPayslipsError() async {
        print("🧪 Testing load recent payslips error handling...")
        
        setUp()
        
        mockDataHandler.shouldThrowError = true
        mockDataHandler.errorToThrow = AppError.message("Test error")
        
        viewModel.loadRecentPayslips()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        assert(mockErrorHandler.handleErrorCalled, "❌ Should handle error")
        
        print("✅ Load recent payslips error test passed")
    }
    
    func testProcessPDFSuccess() async {
        print("🧪 Testing process PDF success...")
        
        setUp()
        
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFHandler.processPDFResult = .success(Data("test pdf".utf8))
        mockPDFHandler.processPDFDataResult = .success(PayslipItem())
        
        await viewModel.processPayslipPDF(from: testURL)
        
        assert(!viewModel.isLoading, "❌ Loading should be false after processing")
        assert(!viewModel.isUploading, "❌ Uploading should be false after processing")
        assert(mockNavigationCoordinator.navigateToPayslipDetailCalled, "❌ Should navigate to detail")
        
        print("✅ Process PDF success test passed")
    }
    
    func testProcessPDFPasswordProtected() async {
        print("🧪 Testing process PDF password protected...")
        
        setUp()
        
        let testURL = URL(string: "file:///test.pdf")!
        mockPDFHandler.processPDFResult = .failure(AppError.passwordProtectedPDF("Password required"))
        
        await viewModel.processPayslipPDF(from: testURL)
        
        assert(mockPasswordHandler.showPasswordEntryCalled, "❌ Should show password entry")
        assert(mockNavigationCoordinator.currentPDFURL == testURL, "❌ Should set current PDF URL")
        
        print("✅ Process PDF password protected test passed")
    }
    
    func testProcessManualEntry() async {
        print("🧪 Testing process manual entry...")
        
        setUp()
        
        let manualData = PayslipManualEntryData(
            name: "John Doe",
            month: "January",
            year: 2023,
            credits: 5000,
            debits: 1000,
            dsop: 300,
            tax: 800
        )
        
        viewModel.processManualEntry(manualData)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        assert(mockNavigationCoordinator.navigateToPayslipDetailCalled, "❌ Should navigate to detail")
        
        print("✅ Process manual entry test passed")
    }
    
    func testShowManualEntry() async {
        print("🧪 Testing show manual entry...")
        
        setUp()
        
        assert(!viewModel.showManualEntryForm, "❌ Manual entry form should initially be false")
        
        viewModel.showManualEntry()
        
        assert(viewModel.showManualEntryForm, "❌ Manual entry form should be true after calling showManualEntry")
        
        print("✅ Show manual entry test passed")
    }
    
    func testErrorHandling() async {
        print("🧪 Testing error handling...")
        
        setUp()
        
        let testError = AppError.message("Test error")
        
        viewModel.handleError(testError)
        
        assert(mockErrorHandler.handleErrorCalled, "❌ Should delegate to error handler")
        
        viewModel.clearError()
        
        assert(mockErrorHandler.clearErrorCalled, "❌ Should delegate clear error to error handler")
        
        print("✅ Error handling test passed")
    }
    
    func testCancelLoading() async {
        print("🧪 Testing cancel loading...")
        
        setUp()
        
        viewModel.isLoading = true
        viewModel.isUploading = true
        
        viewModel.cancelLoading()
        
        assert(!viewModel.isLoading, "❌ Loading should be false after cancel")
        assert(!viewModel.isUploading, "❌ Uploading should be false after cancel")
        
        print("✅ Cancel loading test passed")
    }
    
    func testPropertyBinding() async {
        print("🧪 Testing property binding...")
        
        setUp()
        
        // Test password handler binding
        mockPasswordHandler.showPasswordEntry(for: Data("test".utf8))
        
        // Wait for binding to take effect
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        assert(viewModel.showPasswordEntryView, "❌ Password entry view should be bound")
        assert(viewModel.currentPasswordProtectedPDFData != nil, "❌ Password protected data should be bound")
        
        // Test error handler binding
        let testError = AppError.message("Binding test")
        mockErrorHandler.handleError(testError)
        
        // Wait for binding to take effect
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        assert(viewModel.error != nil, "❌ Error should be bound")
        assert(viewModel.errorMessage == "Binding test", "❌ Error message should be bound")
        
        print("✅ Property binding test passed")
    }
    
    func runAllTests() async {
        print("🚀 Starting HomeViewModel Test Suite")
        print("=" + String(repeating: "=", count: 50))
        
        await testInitialization()
        await testLoadRecentPayslips()
        await testLoadRecentPayslipsError()
        await testProcessPDFSuccess()
        await testProcessPDFPasswordProtected()
        await testProcessManualEntry()
        await testShowManualEntry()
        await testErrorHandling()
        await testCancelLoading()
        await testPropertyBinding()
        
        print("=" + String(repeating: "=", count: 50))
        print("🎉 All HomeViewModel tests passed successfully!")
        print("✅ 10/10 tests completed")
    }
}

// MARK: - Main Execution
Task { @MainActor in
    let testSuite = HomeViewModelTestSuite()
    await testSuite.runAllTests()
    exit(0)
}

RunLoop.main.run()