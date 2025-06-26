import Foundation
import PDFKit
#if canImport(UIKit)
import UIKit
#endif

/// Mock implementation of PDFProcessingServiceProtocol for testing purposes.
///
/// This mock service provides controllable behavior for testing PDF processing
/// functionality. It includes call tracking for verification in tests and
/// configurable return values for different scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPDFProcessingService: PDFProcessingServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether the service is considered initialized
    var isInitialized: Bool = false
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    /// The payslip item to return from processing operations
    var mockPayslipItem: PayslipItem?
    
    // MARK: - Call Tracking Properties
    
    /// Tracks the number of times initialize() was called
    var initializeCallCount = 0
    
    /// Tracks the number of times processPDF(from:) was called
    var processPDFCallCount = 0
    
    /// Tracks the number of times processPDFData(_:) was called
    var processPDFDataCallCount = 0
    
    /// Tracks the number of times isPasswordProtected(_:) was called
    var isPasswordProtectedCallCount = 0
    
    /// Tracks the number of times unlockPDF(_:password:) was called
    var unlockPDFCallCount = 0
    
    /// Tracks the number of times processScannedImage(_:) was called
    var processScannedImageCallCount = 0
    
    /// Tracks the number of times detectPayslipFormat(_:) was called
    var detectPayslipFormatCallCount = 0
    
    /// Tracks the number of times validatePayslipContent(_:) was called
    var validatePayslipContentCallCount = 0
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state and call counters to default values.
    func reset() {
        isInitialized = false
        shouldFail = false
        mockPayslipItem = nil
        initializeCallCount = 0
        processPDFCallCount = 0
        processPDFDataCallCount = 0
        isPasswordProtectedCallCount = 0
        unlockPDFCallCount = 0
        processScannedImageCallCount = 0
        detectPayslipFormatCallCount = 0
        validatePayslipContentCallCount = 0
    }
    
    // MARK: - PDFProcessingServiceProtocol Implementation
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        processPDFCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        return .success(Data())
    }
    
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        processPDFDataCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .success(PayslipItemFactory.createSample() as! PayslipItem)
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        return false
    }
    
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        unlockPDFCallCount += 1
        if shouldFail {
            return .failure(.incorrectPassword)
        }
        return .success(data)
    }
    
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        processScannedImageCallCount += 1
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .failure(.invalidData)
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        detectPayslipFormatCallCount += 1
        return .pcda
    }
    
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        validatePayslipContentCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
} 