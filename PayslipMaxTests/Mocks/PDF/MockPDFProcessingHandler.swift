import Foundation
import PDFKit
@testable import Payslip_Max

class MockPDFProcessingHandler: PDFProcessingHandlerProtocol {
    var processCallCount = 0
    var validateCallCount = 0
    var extractCallCount = 0
    var generatePreviewCallCount = 0
    
    var isProcessingCalled = false
    var isValidationCalled = false
    var isExtractionCalled = false
    var isPreviewGenerationCalled = false
    
    var shouldFailProcessing = false
    var shouldFailValidation = false
    var shouldFailExtraction = false
    var shouldFailPreviewGeneration = false
    
    var processedData: Data?
    var validationResult: Bool = true
    var extractionResult: [String: String] = [:]
    var previewImage: UIImage?
    
    var processing: ((URL) async throws -> Data)?
    var validation: ((Data) async throws -> Bool)?
    var extraction: ((Data) async throws -> [String: String])?
    var previewGeneration: ((Data) async throws -> UIImage?)?
    
    // Default implementations for processing steps
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        isProcessingCalled = true
        
        if shouldFailProcessing {
            throw MockError.processingFailed
        }
        
        if let processing = processing {
            return try await processing(url)
        }
        
        return processedData ?? Data()
    }
    
    func validate(_ data: Data) async throws -> Bool {
        validateCallCount += 1
        isValidationCalled = true
        
        if shouldFailValidation {
            throw MockError.validationFailed
        }
        
        if let validation = validation {
            return try await validation(data)
        }
        
        return validationResult
    }
    
    func extract(_ data: Data) async throws -> [String: String] {
        extractCallCount += 1
        isExtractionCalled = true
        
        if shouldFailExtraction {
            throw MockError.extractionFailed
        }
        
        if let extraction = extraction {
            return try await extraction(data)
        }
        
        return extractionResult
    }
    
    func generatePreview(_ data: Data) async throws -> UIImage? {
        generatePreviewCallCount += 1
        isPreviewGenerationCalled = true
        
        if shouldFailPreviewGeneration {
            throw MockError.previewGenerationFailed
        }
        
        if let previewGeneration = previewGeneration {
            return try await previewGeneration(data)
        }
        
        return previewImage
    }
    
    // Helper method to mock successful processing pipeline with custom data
    func mockSuccessfulProcessing(withData data: Data, extraction: [String: String], preview: UIImage) {
        processedData = data
        validationResult = true
        extractionResult = extraction
        previewImage = preview
        
        shouldFailProcessing = false
        shouldFailValidation = false
        shouldFailExtraction = false
        shouldFailPreviewGeneration = false
    }
    
    // Reset the mock state
    func reset() {
        processCallCount = 0
        validateCallCount = 0
        extractCallCount = 0
        generatePreviewCallCount = 0
        
        isProcessingCalled = false
        isValidationCalled = false
        isExtractionCalled = false
        isPreviewGenerationCalled = false
        
        shouldFailProcessing = false
        shouldFailValidation = false
        shouldFailExtraction = false
        shouldFailPreviewGeneration = false
        
        processedData = nil
        validationResult = true
        extractionResult = [:]
        previewImage = nil
        
        processing = nil
        validation = nil
        extraction = nil
        previewGeneration = nil
    }
} 