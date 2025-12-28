import Foundation
import UIKit
import PDFKit
@testable import PayslipMax

// MARK: - Mock PDF Processing Handler

/// Mock implementation of PDFProcessingHandler for testing purposes.
/// Provides configurable behavior for PDF processing operations.
class MockPDFProcessingHandler: PDFProcessingHandler {
    var processPDFCalled = false
    var processPDFDataCalled = false
    var processScannedImageCalled = false
    var detectPayslipFormatCalled = false
    var isPasswordProtectedCalled = false

    var mockProcessPDFResult: Result<Data, Error> = .success(Data())
    var mockProcessPDFDataResult: Result<PayslipItem, Error> = .success(TestDataGenerator.samplePayslipItem())
    var mockProcessScannedImageResult: Result<PayslipItem, Error> = .success(TestDataGenerator.samplePayslipItem())
    var mockDetectFormatResult: PayslipFormat = .defense
    var mockIsPasswordProtectedResult = false

    // TODO: Fix complex mock - temporarily simplified for quick stabilization
    init() {
        // Use basic mock for quick stabilization
        super.init(pdfProcessingService: MockPDFService() as! PDFProcessingServiceProtocol)
    }

    override func processPDF(from url: URL) async -> Result<Data, Error> {
        processPDFCalled = true
        return mockProcessPDFResult
    }

    override func processPDFData(_ data: Data, from url: URL?, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        processPDFDataCalled = true
        return mockProcessPDFDataResult
    }

    override func processScannedImage(_ image: UIImage, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        processScannedImageCalled = true
        return mockProcessScannedImageResult
    }

    override func processScannedImageLLMOnly(_ image: UIImage, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        processScannedImageCalled = true
        return mockProcessScannedImageResult
    }

    override func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCalled = true
        return mockDetectFormatResult
    }

    override func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCalled = true
        return mockIsPasswordProtectedResult
    }

    /// Resets all tracking flags and mock results to default values
    func reset() {
        processPDFCalled = false
        processPDFDataCalled = false
        processScannedImageCalled = false
        detectPayslipFormatCalled = false
        isPasswordProtectedCalled = false
        mockProcessPDFResult = .success(Data())
        mockProcessPDFDataResult = .success(TestDataGenerator.samplePayslipItem())
        mockProcessScannedImageResult = .success(TestDataGenerator.samplePayslipItem())
        mockDetectFormatResult = .defense
        mockIsPasswordProtectedResult = false
    }
}
