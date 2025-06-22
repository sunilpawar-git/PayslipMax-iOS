import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var extractResult: [String: String] = [:]
    var unlockResult: Data?
    var isInitialized: Bool = false
    
    // Track method calls for verification in tests
    var extractCallCount = 0
    var unlockCallCount = 0
    var processCallCount = 0
    var initializeCallCount = 0
    var detectFormatCallCount = 0
    var validateContentCallCount = 0
    var validationCallCount = 0
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw MockError.unlockFailed
        }
        if password != "correct" {
            throw MockError.incorrectPassword
        }
        if let result = unlockResult {
            return result
        }
        return data
    }
    
    func extract(_ data: Data) -> [String: String] {
        extractCallCount += 1
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        detectFormatCallCount += 1
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
        validateContentCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func validatePayslipData(_ data: [String: String]) -> PayslipContentValidationResult {
        validationCallCount += 1
        if shouldFail {
            return PayslipContentValidationResult(
                isValid: false,
                confidence: 0.0,
                detectedFields: [],
                missingRequiredFields: ["Mock validation failed"]
            )
        }
        return mockValidationResult
    }
    
    func reset() {
        shouldFail = false
        extractResult.removeAll()
        unlockResult = nil
        isInitialized = false
        extractCallCount = 0
        unlockCallCount = 0
        processCallCount = 0
        initializeCallCount = 0
        detectFormatCallCount = 0
        validateContentCallCount = 0
        validationCallCount = 0
        mockValidationResult = PayslipContentValidationResult(
            isValid: true,
            confidence: 1.0,
            detectedFields: [],
            missingRequiredFields: []
        )
    }
}

// MARK: - Mock PDF Processing Service
class MockPDFProcessingService: PDFProcessingServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var processPDFCallCount = 0
    var processPDFDataCallCount = 0
    var isPasswordProtectedCallCount = 0
    var unlockPDFCallCount = 0
    var processScannedImageCallCount = 0
    var detectPayslipFormatCallCount = 0
    var validatePayslipContentCallCount = 0
    
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
}

// MARK: - Mock PDF Extractor
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    var mockText = "This is mock extracted text"
    
    // Track method calls for verification in tests
    var extractPayslipDataFromPDFCallCount = 0
    var extractPayslipDataFromTextCallCount = 0
    var extractTextCallCount = 0
    var getAvailableParsersCallCount = 0
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        extractPayslipDataFromPDFCallCount += 1
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        extractPayslipDataFromTextCallCount += 1
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        extractTextCallCount += 1
        if shouldFail {
            return ""
        }
        return mockText
    }
    
    func getAvailableParsers() -> [String] {
        getAvailableParsersCallCount += 1
        return ["MockParser1", "MockParser2"]
    }
    
    func reset() {
        shouldFail = false
        mockPayslipItem = nil
        mockText = "This is mock extracted text"
        extractPayslipDataFromPDFCallCount = 0
        extractPayslipDataFromTextCallCount = 0
        extractTextCallCount = 0
        getAvailableParsersCallCount = 0
    }
} 