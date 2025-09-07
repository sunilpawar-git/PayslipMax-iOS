//
//  PDFService.swift
//  PayslipMax
//
//  Refactored on: Phase 1 Refactoring
//  Description: Refactored to use extracted components following SOLID principles and dependency injection
//

import Foundation
import PDFKit

protocol PDFService {
    func extract(_ pdfData: Data) -> [String: String]
    func unlockPDF(data: Data, password: String) async throws -> Data
    var fileType: PDFFileType { get }

    /// New method for extracting structured text with spatial information
    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument
}

enum PDFServiceError: Error, Equatable {
    case incorrectPassword
    case unsupportedEncryptionMethod
    case unableToProcessPDF
    case militaryPDFNotSupported
    case failedToExtractText
    case invalidFormat
}

enum PDFFileType {
    case standard
    case military
    case pcda
}

class DefaultPDFService: PDFService {
    var fileType: PDFFileType = .standard

    // Dependencies following DI principles
    private let processingPipeline: PDFProcessingPipelineProtocol
    private let validator: PDFValidatorProtocol

    // MARK: - Initialization

    /// Initializes with dependency injection following SOLID principles
    /// - Parameters:
    ///   - processingPipeline: The PDF processing pipeline
    ///   - validator: PDF validator for type detection
    init(
        processingPipeline: PDFProcessingPipelineProtocol,
        validator: PDFValidatorProtocol
    ) {
        self.processingPipeline = processingPipeline
        self.validator = validator
    }

    /// Convenience initializer for backward compatibility
    convenience init(positionalExtractor: PositionalElementExtractorProtocol? = nil) {
        let parser = PDFParser()
        let validator = PDFValidator()
        let pcdaHandler = PCDAPayslipHandler()
        let processingPipeline = PDFProcessingPipeline(
            parser: parser,
            validator: validator,
            pcdaHandler: pcdaHandler,
            positionalExtractor: positionalExtractor
        )
        self.init(processingPipeline: processingPipeline, validator: validator)
    }

    func extract(_ pdfData: Data) -> [String: String] {
        print("PDFService: Starting extraction process")

        // Validate PDF data first
        guard validator.validatePDFData(pdfData) else {
            print("PDFService: Invalid PDF data")
            return ["page_0": "Invalid PDF format"]
        }

        // Create PDF document to detect file type
        if let pdfDocument = PDFDocument(data: pdfData) {
            fileType = validator.detectFileType(pdfDocument)
            print("PDFService: PDF detected as \(fileType) format")

            // Check if password protected
            if validator.isPasswordProtected(pdfDocument) {
                print("PDFService: Document is locked, cannot extract text. Will need password first.")
                return ["page_1": "This PDF is password protected. Please enter the password to view content."]
            }
        }

        // Use processing pipeline for text extraction
        let extractedText = processingPipeline.extractText(from: pdfData)

        if extractedText.isEmpty {
            print("PDFService: Warning: No text extracted from PDF despite successful document opening")
            return ["page_0": "PDF text extraction failed"]
        }

        return extractedText
    }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        let unlockedData = try await processingPipeline.unlockPDF(data: data, password: password)

        // Update file type after unlocking
        if let pdfDocument = PDFDocument(data: unlockedData) {
            fileType = validator.detectFileType(pdfDocument)
        }

        return unlockedData
    }

    // MARK: - Structured Text Extraction

    /// Extracts structured text with spatial information from PDF data
    /// This provides enhanced parsing capabilities while maintaining backward compatibility
    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument {
        return try await processingPipeline.extractStructuredText(from: pdfData)
    }
}
