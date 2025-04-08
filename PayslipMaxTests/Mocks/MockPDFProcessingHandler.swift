import Foundation
import PDFKit
import UIKit
@testable import Payslip_Max

/// A mock implementation of PDFProcessingHandler for testing purposes
@MainActor
class MockPDFProcessingHandler: PDFProcessingHandler {
    // Tracking properties
    private(set) var processPDFCallCount = 0
    private(set) var processPDFDataCallCount = 0
    private(set) var processScannedImageCallCount = 0
    private(set) var isPasswordProtectedCallCount = 0
    private(set) var detectPayslipFormatCallCount = 0
    
    // Result stubs
    var processPDFResult: Result<Data, Error> = .success(Data())
    var processPDFDataResult: Result<PayslipItem, Error> = .success(PayslipItem.sample())
    var processScannedImageResult: Result<PayslipItem, Error> = .success(PayslipItem.sample())
    var isPasswordProtectedResult: Bool = false
    var detectPayslipFormatResult: PayslipFormat = .unknown
    
    // Initialization tracking
    var mockPDFProcessingService = MockPDFProcessingService()
    
    // Init with mock service
    override init(pdfProcessingService: PDFProcessingServiceProtocol) {
        super.init(pdfProcessingService: pdfProcessingService)
    }
    
    // Convenience init
    init() {
        super.init(pdfProcessingService: MockPDFProcessingService())
    }
    
    // Reset all tracking properties and default stubs
    func reset() {
        processPDFCallCount = 0
        processPDFDataCallCount = 0
        processScannedImageCallCount = 0
        isPasswordProtectedCallCount = 0
        detectPayslipFormatCallCount = 0
        
        processPDFResult = .success(Data())
        processPDFDataResult = .success(PayslipItem.sample())
        processScannedImageResult = .success(PayslipItem.sample())
        isPasswordProtectedResult = false
        detectPayslipFormatResult = .unknown
    }
    
    // Override methods with tracking and stubbed responses
    
    override func processPDF(from url: URL) async -> Result<Data, Error> {
        processPDFCallCount += 1
        return processPDFResult
    }
    
    override func processPDFData(_ data: Data, from url: URL? = nil) async -> Result<PayslipItem, Error> {
        processPDFDataCallCount += 1
        return processPDFDataResult
    }
    
    override func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, Error> {
        processScannedImageCallCount += 1
        return processScannedImageResult
    }
    
    override func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        return isPasswordProtectedResult
    }
    
    override func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCallCount += 1
        return detectPayslipFormatResult
    }
}

// Mock PDFProcessingService for internal use
class MockPDFProcessingService: PDFProcessingServiceProtocol {
    var isInitialized: Bool = true
    var initializeCallCount = 0
    var processPDFCallCount = 0
    var processPDFDataCallCount = 0
    var processScannedImageCallCount = 0
    var isPasswordProtectedCallCount = 0
    var detectPayslipFormatCallCount = 0
    
    // Result stubs
    var initializeError: Error? = nil
    var processPDFResult: Result<Data, PDFProcessingError> = .success(Data())
    var processPDFDataResult: Result<PayslipItem, PDFProcessingError> = .success(PayslipItem.sample())
    var processScannedImageResult: Result<PayslipItem, PDFProcessingError> = .success(PayslipItem.sample())
    var isPasswordProtectedResult: Bool = false
    var detectPayslipFormatResult: PayslipFormat = .unknown
    
    func reset() {
        isInitialized = true
        initializeCallCount = 0
        processPDFCallCount = 0
        processPDFDataCallCount = 0
        processScannedImageCallCount = 0
        isPasswordProtectedCallCount = 0
        detectPayslipFormatCallCount = 0
        
        initializeError = nil
        processPDFResult = .success(Data())
        processPDFDataResult = .success(PayslipItem.sample())
        processScannedImageResult = .success(PayslipItem.sample())
        isPasswordProtectedResult = false
        detectPayslipFormatResult = .unknown
    }
    
    func initialize() async throws {
        initializeCallCount += 1
        if let error = initializeError {
            throw error
        }
    }
    
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        processPDFCallCount += 1
        return processPDFResult
    }
    
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        processPDFDataCallCount += 1
        return processPDFDataResult
    }
    
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        processScannedImageCallCount += 1
        return processScannedImageResult
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        return isPasswordProtectedResult
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCallCount += 1
        return detectPayslipFormatResult
    }
} 