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
    var mockValidationResult = PayslipContentValidationResult(
        isValid: true,
        confidence: 1.0,
        detectedFields: [],
        missingRequiredFields: []
    )
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        if shouldFail {
            throw MockError.processingFailed
        }
        return Data()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        if shouldFail {
            throw MockError.unlockFailed
        }
        if password != "correct" {
            throw MockError.incorrectPassword
        }
        return unlockResult ?? data
    }
    
    func extract(_ data: Data) -> [String: String] {
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        return .pcda
    }
    
    func validateContent(_ data: Data) -> PayslipContentValidationResult {
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
    
    func initialize() async throws {
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        return .success(Data())
    }
    
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .success(PayslipItemFactory.createSample() as! PayslipItem)
    }
    
    func isPasswordProtected(_ data: Data) -> Bool {
        return false
    }
    
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        if shouldFail {
            return .failure(.incorrectPassword)
        }
        return .success(data)
    }
    
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        if shouldFail {
            return .failure(.parsingFailed("Mock processing failed"))
        }
        if let item = mockPayslipItem {
            return .success(item)
        }
        return .failure(.invalidData)
    }
    
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        return .pcda
    }
    
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
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
    }
}

// MARK: - Mock PDF Extractor
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFail = false
    var mockPayslipItem: PayslipItem?
    var mockText = "This is mock extracted text"
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        if shouldFail {
            return nil
        }
        if let item = mockPayslipItem {
            return item
        }
        return PayslipItemFactory.createSample() as? PayslipItem
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        if shouldFail {
            return ""
        }
        return mockText
    }
    
    func getAvailableParsers() -> [String] {
        return ["MockParser1", "MockParser2"]
    }
    
    func reset() {
        shouldFail = false
        mockPayslipItem = nil
        mockText = "This is mock extracted text"
    }
} 