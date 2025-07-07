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
}

// MARK: - Mock Chart Data Preparation Service

class MockChartDataPreparationService: ChartDataPreparationService {
    var prepareChartDataCalled = false
    var mockChartData: [PayslipChartData] = []
    
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        prepareChartDataCalled = true
        return mockChartData
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
}

// MARK: - Mock Data Types

struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
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

struct AnyPayslip {
    let id: UUID
    let name: String
    let timestamp: Date
    
    init(_ payslipItem: PayslipItem) {
        self.id = payslipItem.id
        self.name = payslipItem.name ?? "Unknown"
        self.timestamp = payslipItem.timestamp ?? Date()
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