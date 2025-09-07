//
//  PDFProcessingPipeline.swift
//  PayslipMax
//
//  Created on: Phase 1 Refactoring
//  Description: Extracted PDF processing pipeline following SOLID principles and dependency injection
//

import Foundation
import PDFKit

/// Protocol defining PDF processing pipeline capabilities
protocol PDFProcessingPipelineProtocol {
    /// Processes PDF data through the complete pipeline
    func processPDF(_ pdfData: Data) async throws -> PDFProcessingResult

    /// Extracts text content from PDF data
    func extractText(from pdfData: Data) -> [String: String]

    /// Unlocks password-protected PDF
    func unlockPDF(data: Data, password: String) async throws -> Data

    /// Extracts structured text with spatial information
    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument
}

/// Result of PDF processing pipeline
struct PDFProcessingResult {
    let extractedText: [String: String]
    let fileType: PDFFileType
    let isPasswordProtected: Bool
    let processingTime: TimeInterval
}

/// Default implementation of PDF processing pipeline
class PDFProcessingPipeline: PDFProcessingPipelineProtocol {
    private let parser: PDFParserProtocol
    private let validator: PDFValidatorProtocol
    private let pcdaHandler: PCDAPayslipHandler
    private var positionalExtractor: PositionalElementExtractorProtocol?

    /// Initializes with dependencies following DI principles
    /// - Parameters:
    ///   - parser: PDF parser for text extraction
    ///   - validator: PDF validator for type detection and validation
    ///   - pcdaHandler: Specialized handler for PCDA military PDFs
    ///   - positionalExtractor: Optional extractor for structured text parsing
    init(
        parser: PDFParserProtocol,
        validator: PDFValidatorProtocol,
        pcdaHandler: PCDAPayslipHandler,
        positionalExtractor: PositionalElementExtractorProtocol? = nil
    ) {
        self.parser = parser
        self.validator = validator
        self.pcdaHandler = pcdaHandler
        self.positionalExtractor = positionalExtractor
    }

    func processPDF(_ pdfData: Data) async throws -> PDFProcessingResult {
        let startTime = Date()

        // Validate PDF data
        guard validator.validatePDFData(pdfData) else {
            throw PDFServiceError.invalidFormat
        }

        // Create PDF document
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw PDFServiceError.invalidFormat
        }

        // Detect file type
        let fileType = validator.detectFileType(pdfDocument)
        let isPasswordProtected = validator.isPasswordProtected(pdfDocument)

        // Extract text
        let extractedText = parser.extractText(from: pdfData)

        let processingTime = Date().timeIntervalSince(startTime)

        return PDFProcessingResult(
            extractedText: extractedText,
            fileType: fileType,
            isPasswordProtected: isPasswordProtected,
            processingTime: processingTime
        )
    }

    func extractText(from pdfData: Data) -> [String: String] {
        return parser.extractText(from: pdfData)
    }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFServiceError.invalidFormat
        }

        // If the PDF is locked, attempt to unlock it with the password
        if pdfDocument.isLocked {
            let unlocked = pdfDocument.unlock(withPassword: password)

            if !unlocked {
                // Try with specific format for PCDA military PDFs (all caps)
                if pdfDocument.unlock(withPassword: password.uppercased()) {
                    print("PDFProcessingPipeline: PDF unlocked successfully with uppercased password")
                } else if pdfDocument.unlock(withPassword: password.lowercased()) {
                    print("PDFProcessingPipeline: PDF unlocked successfully with lowercased password")
                } else {
                    // Try the specialized PCDA handler if normal methods fail
                    let (unlockedData, successfulPassword) = await pcdaHandler.unlockPDF(data: data, basePassword: password)
                    if let unlockedData = unlockedData, successfulPassword != nil {
                        print("PDFProcessingPipeline: PDF unlocked successfully by PCDAPayslipHandler")
                        return unlockedData
                    }

                    // Try with common military PDF passwords
                    let militaryDefaults = ["pcda", "PCDA", "army", "ARMY", password + "1", password + "@"]
                    var success = false

                    for defaultPwd in militaryDefaults {
                        if pdfDocument.unlock(withPassword: defaultPwd) {
                            print("PDFProcessingPipeline: PDF unlocked with military default password")
                            success = true
                            break
                        }
                    }

                    if !success {
                        throw PDFServiceError.incorrectPassword
                    }
                }
            }

            print("PDFProcessingPipeline: PDF unlocked successfully")

            // Check if this is a military PDF
            let isMilitary = validator.detectFileType(pdfDocument) == .military
            let isPCDA = validator.detectFileType(pdfDocument) == .pcda

            // For military PDFs, we need special handling after unlocking
            if isMilitary || isPCDA {
                print("PDFProcessingPipeline: Using special military PDF handling")

                // Military PDFs need special treatment after unlocking
                guard let pdfData = createUnlockedPDF(from: pdfDocument) else {
                    print("PDFProcessingPipeline: Failed to create unlocked version of military PDF")
                    throw PDFServiceError.unableToProcessPDF
                }

                return pdfData
            } else {
                // Standard PDF handling
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFServiceError.unableToProcessPDF
                }

                // Verify the new data can be opened without password
                if let verificationDoc = PDFDocument(data: pdfData),
                   !verificationDoc.isLocked {
                    print("PDFProcessingPipeline: Successfully created data representation of unlocked PDF")
                    return pdfData
                }

                print("PDFProcessingPipeline: Warning - Generated PDF is still locked, trying alternative method")
                return try createPermanentlyUnlockedPDF(from: pdfDocument)
            }
        }

        // If not locked, return original data
        return data
    }

    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument {
        print("PDFProcessingPipeline: Starting structured text extraction")

        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("PDFProcessingPipeline: Failed to create PDF document from data")
            throw PDFServiceError.invalidFormat
        }

        print("PDFProcessingPipeline: Created PDF document, is locked: \(pdfDocument.isLocked)")

        // Check if the document is locked
        if pdfDocument.isLocked {
            print("PDFProcessingPipeline: Document is locked, cannot extract structured text without unlocking first")
            throw PDFServiceError.unableToProcessPDF
        }

        // Get the positional extractor
        let extractor = await getPositionalExtractor()

        // Initialize the positional extractor if needed
        if !(await extractor.isInitialized) {
            try await extractor.initialize()
        }

        // Extract structured document using the positional extractor
        let structuredDocument = try await extractor.extractStructuredDocument(
            from: pdfDocument
        ) { progress in
            print("PDFProcessingPipeline: Structured extraction progress: \(Int(progress * 100))%")
        }

        print("PDFProcessingPipeline: Completed structured text extraction")
        print("Total elements extracted: \(structuredDocument.totalElementCount)")
        print("Pages processed: \(structuredDocument.pageCount)")

        return structuredDocument
    }

    // MARK: - Private Helpers

    /// Gets or creates the positional extractor
    private func getPositionalExtractor() async -> PositionalElementExtractorProtocol {
        if let extractor = positionalExtractor {
            return extractor
        }

        // Create the default extractor on the main actor
        await MainActor.run {
            let extractor = DefaultPositionalElementExtractor()
            self.positionalExtractor = extractor
        }
        return positionalExtractor!
    }

    /// Create a permanently unlocked PDF from a password-protected one
    private func createPermanentlyUnlockedPDF(from document: PDFDocument) throws -> Data {
        // Create a new document and copy all pages
        let newDocument = PDFDocument()

        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                newDocument.insert(page, at: i)
            }
        }

        // Get data representation of the new document
        guard let unlockedData = newDocument.dataRepresentation(),
              let finalCheck = PDFDocument(data: unlockedData),
              !finalCheck.isLocked else {
            throw PDFServiceError.unableToProcessPDF
        }

        print("PDFProcessingPipeline: Successfully created permanently unlocked version")
        return unlockedData
    }

    /// Handle military PDFs specifically
    private func createUnlockedPDF(from document: PDFDocument) -> Data? {
        // First try standard data representation
        if let pdfData = document.dataRepresentation(),
           let verificationDoc = PDFDocument(data: pdfData),
           !verificationDoc.isLocked {
            print("PDFProcessingPipeline: Standard unlocking worked for military PDF")
            return pdfData
        }

        // Try alternative approach by creating a new document
        let newDocument = PDFDocument()
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                newDocument.insert(page, at: i)
            }
        }

        // Get data representation of the new document
        if let unlockedData = newDocument.dataRepresentation(),
           let finalCheck = PDFDocument(data: unlockedData),
           !finalCheck.isLocked {
            print("PDFProcessingPipeline: Created new unlocked document for military PDF")
            return unlockedData
        }

        print("PDFProcessingPipeline: Could not create permanently unlocked version for military PDF")
        return document.dataRepresentation()
    }
}
