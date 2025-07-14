import Foundation
import UIKit
import PDFKit
import Combine
@testable import PayslipMax

// MARK: - Mock PDF Processing Handler

class MockPDFProcessingHandler: PDFProcessingHandler {
    var processPDFCalled = false
    var processPDFDataCalled = false
    var processScannedImageCalled = false
    var detectPayslipFormatCalled = false
    var isPasswordProtectedCalled = false
    
    var mockProcessPDFResult: Result<Data, Error> = .success(Data())
    var mockProcessPDFDataResult: Result<PayslipItem, Error> = .success(TestDataGenerator.samplePayslipItem())
    var mockProcessScannedImageResult: Result<PayslipItem, Error> = .success(TestDataGenerator.samplePayslipItem())
    var mockDetectFormatResult: PayslipFormat = .military
    var mockIsPasswordProtectedResult = false
    
    func processPDF(from url: URL) async -> Result<Data, Error> {
        processPDFCalled = true
        return mockProcessPDFResult
    }
    
    func processPDFData(_ data: Data, from url: URL?) async -> Result<PayslipItem, Error> {
        processPDFDataCalled = true
        return mockProcessPDFDataResult
    }
    
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, Error> {
        processScannedImageCalled = true
        return mockProcessScannedImageResult
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCalled = true
        return mockDetectFormatResult
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCalled = true
        return mockIsPasswordProtectedResult
    }
    
    func reset() {
        processPDFCalled = false
        processPDFDataCalled = false
        processScannedImageCalled = false
        detectPayslipFormatCalled = false
        isPasswordProtectedCalled = false
        mockProcessPDFResult = .success(Data())
        mockProcessPDFDataResult = .success(TestDataGenerator.samplePayslipItem())
        mockProcessScannedImageResult = .success(TestDataGenerator.samplePayslipItem())
        mockDetectFormatResult = .military
        mockIsPasswordProtectedResult = false
    }
}

// MARK: - Mock Payslip Data Handler

class MockPayslipDataHandler: PayslipDataHandler {
    var loadRecentPayslipsCalled = false
    var savePayslipItemCalled = false
    var createPayslipFromManualEntryCalled = false
    
    var mockRecentPayslips: [AnyPayslip] = []
    var mockCreatedPayslipItem: PayslipItem = TestDataGenerator.samplePayslipItem()
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")
    
    func loadRecentPayslips() async throws -> [AnyPayslip] {
        loadRecentPayslipsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockRecentPayslips
    }
    
    func savePayslipItem(_ item: PayslipItem) async throws {
        savePayslipItemCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    func createPayslipFromManualEntry(_ data: PayslipManualEntryData) -> PayslipItem {
        createPayslipFromManualEntryCalled = true
        return mockCreatedPayslipItem
    }
    
    func reset() {
        loadRecentPayslipsCalled = false
        savePayslipItemCalled = false
        createPayslipFromManualEntryCalled = false
        mockRecentPayslips = []
        mockCreatedPayslipItem = TestDataGenerator.samplePayslipItem()
        shouldThrowError = false
        errorToThrow = AppError.message("Test error")
    }
}

// MARK: - Mock Chart Data Preparation Service

class MockChartDataPreparationService: ChartDataPreparationService {
    var prepareChartDataCalled = false
    var mockChartData: [PayslipChartData] = []
    
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        prepareChartDataCalled = true
        return mockChartData
    }
    
    func reset() {
        prepareChartDataCalled = false
        mockChartData = []
    }
}

// MARK: - Mock Password Protected PDF Handler

class MockPasswordProtectedPDFHandler: PasswordProtectedPDFHandler, ObservableObject {
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
    
    func reset() {
        showPasswordEntryCalled = false
        resetPasswordStateCalled = false
        resetPasswordState()
    }
}

// MARK: - Mock Error Handler

class MockErrorHandler: ErrorHandler, ObservableObject {
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
    
    func reset() {
        handleErrorCalled = false
        handlePDFErrorCalled = false
        clearErrorCalled = false
        clearError()
    }
}

// MARK: - Mock Home Navigation Coordinator

class MockHomeNavigationCoordinator: HomeNavigationCoordinator, ObservableObject {
    var currentPDFURL: URL?
    var navigateToPayslipDetailCalled = false
    var setPDFDocumentCalled = false
    
    var mockPDFDocument: PDFDocument?
    var mockURL: URL?
    
    func navigateToPayslipDetail(for payslip: PayslipItem) {
        navigateToPayslipDetailCalled = true
    }
    
    func setPDFDocument(_ document: PDFDocument, url: URL?) {
        setPDFDocumentCalled = true
        mockPDFDocument = document
        mockURL = url
    }
    
    func reset() {
        currentPDFURL = nil
        navigateToPayslipDetailCalled = false
        setPDFDocumentCalled = false
        mockPDFDocument = nil
        mockURL = nil
    }
}

// MARK: - Mock Data Types

// PayslipManualEntryData is imported from main app

// PayslipChartData is defined in PayslipMax/Views/Home/Components/ChartsView.swift



// MARK: - Protocol Definitions

protocol PDFProcessingHandler {
    func processPDF(from url: URL) async -> Result<Data, Error>
    func processPDFData(_ data: Data, from url: URL?) async -> Result<PayslipItem, Error>
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, Error>
    func detectPayslipFormat(_ data: Data) -> PayslipFormat
    func isPasswordProtected(_ data: Data) -> Bool
}

protocol PayslipDataHandler {
    func loadRecentPayslips() async throws -> [AnyPayslip]
    func savePayslipItem(_ item: PayslipItem) async throws
    func createPayslipFromManualEntry(_ data: PayslipManualEntryData) -> PayslipItem
}

protocol ChartDataPreparationService {
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData]
}

protocol PasswordProtectedPDFHandler {
    func showPasswordEntry(for pdfData: Data)
    func resetPasswordState()
}

protocol ErrorHandler {
    func handleError(_ error: Error)
    func handlePDFError(_ error: Error)
    func clearError()
}

protocol HomeNavigationCoordinator {
    var currentPDFURL: URL? { get set }
    func navigateToPayslipDetail(for payslip: PayslipItem)
    func setPDFDocument(_ document: PDFDocument, url: URL?)
}

// MARK: - AnyPayslip Wrapper

class AnyPayslip: PayslipProtocol {
    let id: UUID
    var timestamp: Date
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String
    var accountNumber: String
    var panNumber: String
    var earnings: [String: Double]
    var deductions: [String: Double]
    
    // PayslipEncryptionProtocol properties
    var isNameEncrypted: Bool = false
    var isAccountNumberEncrypted: Bool = false
    var isPanNumberEncrypted: Bool = false
    
    // PayslipMetadataProtocol properties
    var pdfData: Data? = nil
    var pdfURL: URL? = nil
    var isSample: Bool = false
    var source: String = "Test"
    var status: String = "Active"
    var notes: String? = nil
    
    init(_ payslipItem: PayslipItem) {
        self.id = payslipItem.id
        self.timestamp = payslipItem.timestamp
        self.month = payslipItem.month
        self.year = payslipItem.year
        self.credits = payslipItem.credits
        self.debits = payslipItem.debits
        self.dsop = payslipItem.dsop
        self.tax = payslipItem.tax
        self.name = payslipItem.name
        self.accountNumber = payslipItem.accountNumber
        self.panNumber = payslipItem.panNumber
        self.earnings = payslipItem.earnings
        self.deductions = payslipItem.deductions
        self.pdfData = payslipItem.pdfData
        self.pdfURL = payslipItem.pdfURL
        self.isSample = payslipItem.isSample
        self.source = payslipItem.source
        self.status = payslipItem.status
        self.notes = payslipItem.notes
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "Test User",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F",
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.earnings = earnings
        self.deductions = deductions
    }
    
    // MARK: - PayslipEncryptionProtocol Methods
    
    func encryptSensitiveData() async throws {
        // Mock implementation - just mark as encrypted
        isNameEncrypted = true
        isAccountNumberEncrypted = true
        isPanNumberEncrypted = true
    }
    
    func decryptSensitiveData() async throws {
        // Mock implementation - just mark as decrypted
        isNameEncrypted = false
        isAccountNumberEncrypted = false
        isPanNumberEncrypted = false
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let payslipDeleted = Notification.Name("payslipDeleted")
    static let payslipUpdated = Notification.Name("payslipUpdated")
    static let payslipsRefresh = Notification.Name("payslipsRefresh")
    static let payslipsForcedRefresh = Notification.Name("payslipsForcedRefresh")
}

// MARK: - Mock Global Loading Manager

class GlobalLoadingManager {
    static let shared = GlobalLoadingManager()
    private init() {}
    
    func startLoading(operationId: String, message: String) {
        // Mock implementation
    }
    
    func stopLoading(operationId: String) {
        // Mock implementation
    }
}