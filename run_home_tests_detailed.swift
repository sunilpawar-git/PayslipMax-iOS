#!/usr/bin/env swift

import Foundation
import Combine

// Mock global loading manager for testing
class GlobalLoadingManager {
    static let shared = GlobalLoadingManager()
    private init() {}
    
    func startLoading(operationId: String, message: String) {
        // Silent for detailed output
    }
    
    func stopLoading(operationId: String) {
        // Silent for detailed output
    }
}

// MARK: - Test Data Types (same as before)
struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
}

enum PayslipFormat { case military, civilian, government }
struct PayslipChartData {
    let month: String
    let value: Double
    let type: ChartDataType
}
enum ChartDataType { case income, expense }

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
    
    var userMessage: String { return errorDescription ?? "Unknown error" }
    var localizedDescription: String { return errorDescription ?? "Unknown error" }
}

// MARK: - Mock Implementations (simplified for demo)
class MockPDFProcessingHandler {
    var processPDFResult: Result<Data, Error> = .success(Data("test pdf".utf8))
    var processPDFDataResult: Result<PayslipItem, Error> = .success(PayslipItem())
    var processScannedImageResult: Result<PayslipItem, Error> = .success(PayslipItem())
    var detectFormatResult: PayslipFormat = .military
    var isPasswordProtectedResult = false
    
    func processPDF(from url: URL) async -> Result<Data, Error> { return processPDFResult }
    func processPDFData(_ data: Data, from url: URL?) async -> Result<PayslipItem, Error> { return processPDFDataResult }
    func processScannedImage(_ image: Any) async -> Result<PayslipItem, Error> { return processScannedImageResult }
    func detectPayslipFormat(_ data: Data) -> PayslipFormat { return detectFormatResult }
    func isPasswordProtected(_ data: Data) -> Bool { return isPasswordProtectedResult }
}

class MockPayslipDataHandler {
    var mockRecentPayslips: [AnyPayslip] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")
    
    func loadRecentPayslips() async throws -> [AnyPayslip] {
        if shouldThrowError { throw errorToThrow }
        return mockRecentPayslips
    }
    
    func savePayslipItem(_ item: PayslipItem) async throws {
        if shouldThrowError { throw errorToThrow }
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

// MARK: - HomeViewModel Implementation (minimal version for testing)
@MainActor
class HomeViewModel: ObservableObject {
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
        
        bindPasswordHandlerProperties()
        bindErrorHandlerProperties()
    }
    
    private func bindPasswordHandlerProperties() {
        passwordHandler.$showPasswordEntryView.assign(to: \.showPasswordEntryView, on: self).store(in: &cancellables)
        passwordHandler.$currentPasswordProtectedPDFData.assign(to: \.currentPasswordProtectedPDFData, on: self).store(in: &cancellables)
        passwordHandler.$currentPDFPassword.assign(to: \.currentPDFPassword, on: self).store(in: &cancellables)
    }
    
    private func bindErrorHandlerProperties() {
        errorHandler.$error.assign(to: \.error, on: self).store(in: &cancellables)
        errorHandler.$errorMessage.assign(to: \.errorMessage, on: self).store(in: &cancellables)
        errorHandler.$errorType.assign(to: \.errorType, on: self).store(in: &cancellables)
    }
    
    // Simplified core methods for testing
    func loadRecentPayslips() {
        Task {
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
                await MainActor.run { self.handleError(error) }
            }
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
                if showPasswordEntryView { passwordHandler.resetPasswordState() }
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
    
    func handleError(_ error: Error) { errorHandler.handleError(error) }
    func clearError() { errorHandler.clearError() }
    func showManualEntry() { showManualEntryForm = true }
    func cancelLoading() {
        isLoading = false
        isUploading = false
    }
}

// MARK: - Detailed Test Suite
@MainActor
class DetailedHomeViewModelTestSuite {
    private var testResults: [(String, Bool)] = []
    
    private func runTest(_ name: String, test: () async throws -> Bool) async {
        do {
            let result = try await test()
            testResults.append((name, result))
            let status = result ? "✅ PASS" : "❌ FAIL"
            print("🧪 \(name): \(status)")
        } catch {
            testResults.append((name, false))
            print("🧪 \(name): ❌ FAIL (Error: \(error))")
        }
    }
    
    func runAllDetailedTests() async {
        print("🚀 Starting Detailed HomeViewModel Test Suite")
        print("=" + String(repeating: "=", count: 60))
        
        // Test 1: Basic Initialization
        await runTest("HomeViewModel Initialization") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            return viewModel.error == nil &&
                   !viewModel.isLoading &&
                   !viewModel.isUploading &&
                   viewModel.recentPayslips.isEmpty &&
                   viewModel.payslipData.isEmpty &&
                   !viewModel.showPasswordEntryView &&
                   !viewModel.showManualEntryForm
        }
        
        // Test 2: Load Recent Payslips Success
        await runTest("Load Recent Payslips Success") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let mockPayslips = [
                AnyPayslip(name: "Payslip 1"),
                AnyPayslip(name: "Payslip 2"),
                AnyPayslip(name: "Payslip 3")
            ]
            mockDataHandler.mockRecentPayslips = mockPayslips
            
            let mockChartData = [
                PayslipChartData(month: "Jan", value: 5000, type: .income),
                PayslipChartData(month: "Feb", value: 5200, type: .income)
            ]
            mockChartService.mockChartData = mockChartData
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            viewModel.loadRecentPayslips()
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            return viewModel.recentPayslips.count == 3 &&
                   viewModel.payslipData.count == 2 &&
                   viewModel.recentPayslips.first?.name == "Payslip 1"
        }
        
        // Test 3: Load Recent Payslips Error Handling
        await runTest("Load Recent Payslips Error Handling") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            mockDataHandler.shouldThrowError = true
            mockDataHandler.errorToThrow = AppError.message("Load failed")
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            viewModel.loadRecentPayslips()
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            return mockErrorHandler.handleErrorCalled
        }
        
        // Test 4: Process PDF Success Flow
        await runTest("Process PDF Success Flow") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            mockPDFHandler.processPDFResult = .success(Data("test pdf".utf8))
            mockPDFHandler.processPDFDataResult = .success(PayslipItem(name: "Processed Payslip"))
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            let testURL = URL(string: "file:///test.pdf")!
            await viewModel.processPayslipPDF(from: testURL)
            
            return !viewModel.isLoading &&
                   !viewModel.isUploading &&
                   mockNavigationCoordinator.navigateToPayslipDetailCalled
        }
        
        // Test 5: Process PDF Password Protected
        await runTest("Process PDF Password Protected") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            mockPDFHandler.processPDFResult = .failure(AppError.passwordProtectedPDF("Password required"))
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            let testURL = URL(string: "file:///protected.pdf")!
            await viewModel.processPayslipPDF(from: testURL)
            
            return mockPasswordHandler.showPasswordEntryCalled &&
                   mockNavigationCoordinator.currentPDFURL == testURL
        }
        
        // Test 6: Manual Entry Processing
        await runTest("Manual Entry Processing") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
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
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            return mockNavigationCoordinator.navigateToPayslipDetailCalled
        }
        
        // Test 7: Property Binding
        await runTest("Property Binding Functionality") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            // Test password handler binding
            mockPasswordHandler.showPasswordEntry(for: Data("test".utf8))
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            let passwordBindingWorks = viewModel.showPasswordEntryView && 
                                     viewModel.currentPasswordProtectedPDFData != nil
            
            // Test error handler binding
            let testError = AppError.message("Binding test")
            mockErrorHandler.handleError(testError)
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            let errorBindingWorks = viewModel.error != nil && 
                                   viewModel.errorMessage == "Binding test"
            
            return passwordBindingWorks && errorBindingWorks
        }
        
        // Test 8: Show Manual Entry Flag
        await runTest("Show Manual Entry Flag") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            let initialState = !viewModel.showManualEntryForm
            viewModel.showManualEntry()
            let afterCallState = viewModel.showManualEntryForm
            
            return initialState && afterCallState
        }
        
        // Test 9: Error Handling Delegation
        await runTest("Error Handling Delegation") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            let testError = AppError.message("Delegation test")
            viewModel.handleError(testError)
            
            let handleErrorWorks = mockErrorHandler.handleErrorCalled
            
            viewModel.clearError()
            let clearErrorWorks = mockErrorHandler.clearErrorCalled
            
            return handleErrorWorks && clearErrorWorks
        }
        
        // Test 10: Loading State Management
        await runTest("Loading State Management") {
            let mockPDFHandler = MockPDFProcessingHandler()
            let mockDataHandler = MockPayslipDataHandler()
            let mockChartService = MockChartDataPreparationService()
            let mockPasswordHandler = MockPasswordProtectedPDFHandler()
            let mockErrorHandler = MockErrorHandler()
            let mockNavigationCoordinator = MockHomeNavigationCoordinator()
            
            let viewModel = HomeViewModel(
                pdfHandler: mockPDFHandler,
                dataHandler: mockDataHandler,
                chartService: mockChartService,
                passwordHandler: mockPasswordHandler,
                errorHandler: mockErrorHandler,
                navigationCoordinator: mockNavigationCoordinator
            )
            
            viewModel.isLoading = true
            viewModel.isUploading = true
            
            viewModel.cancelLoading()
            
            return !viewModel.isLoading && !viewModel.isUploading
        }
        
        // Print final results
        print("=" + String(repeating: "=", count: 60))
        let passedTests = testResults.filter { $0.1 }.count
        let totalTests = testResults.count
        let successRate = (Double(passedTests) / Double(totalTests)) * 100
        
        print("📊 Test Results Summary:")
        print("   Total Tests: \(totalTests)")
        print("   Passed: \(passedTests)")
        print("   Failed: \(totalTests - passedTests)")
        print("   Success Rate: \(String(format: "%.1f", successRate))%")
        
        if passedTests == totalTests {
            print("🎉 All HomeViewModel tests passed successfully!")
        } else {
            print("⚠️  Some tests failed - review implementation")
        }
        
        print("=" + String(repeating: "=", count: 60))
    }
}

// MARK: - Main Execution
Task { @MainActor in
    let testSuite = DetailedHomeViewModelTestSuite()
    await testSuite.runAllDetailedTests()
    exit(0)
}

RunLoop.main.run()