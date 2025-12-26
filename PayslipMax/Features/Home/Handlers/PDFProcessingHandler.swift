import Foundation
import PDFKit
import UIKit

/// A handler for PDF processing operations
@MainActor
class PDFProcessingHandler {
    /// The PDF processing service
    private let pdfProcessingService: PDFProcessingServiceProtocol

    /// Flag indicating whether the PDF processing service is initialized
    private var isServiceInitialized: Bool {
        pdfProcessingService.isInitialized
    }

    /// Initializes a new PDF processing handler
    /// - Parameter pdfProcessingService: The PDF processing service to use
    init(pdfProcessingService: PDFProcessingServiceProtocol) {
        self.pdfProcessingService = pdfProcessingService
    }

    /// Processes a PDF file from a URL.
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: A result containing the PDF data or a PDF processing error.
    func processPDF(from url: URL) async -> Result<Data, Error> {
        print("[PDFProcessingHandler] Processing PDF from \(url)")
        let result = await pdfProcessingService.processPDF(from: url)

        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let data):
            return .success(data)
        case .failure(let error):
            return .failure(error as Error)
        }
    }

    /// Checks if the PDF data is password protected.
    /// - Parameter data: The PDF data to check.
    /// - Returns: A boolean indicating whether the PDF is password protected.
    func isPasswordProtected(_ data: Data) -> Bool {
        // First try using the built-in method
        let isProtected = pdfProcessingService.isPasswordProtected(data)
        print("[PDFProcessingHandler] PDF is password protected: \(isProtected)")

        // Double-check by creating a PDF document
        if let pdfDocument = PDFDocument(data: data) {
            let isLocked = pdfDocument.isLocked
            print("[PDFProcessingHandler] PDF document is locked: \(isLocked)")

            // Return true if either check says it's protected
            return isProtected || isLocked
        }

        return isProtected
    }

    /// Processes the PDF data
    /// - Parameter data: The PDF data to process
    /// - Parameter url: The original URL of the PDF (optional)
    /// - Returns: A result containing the parsed payslip or an error
    func processPDFData(_ data: Data, from url: URL? = nil, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        print("[PDFProcessingHandler] Process PDF Data started with \(data.count) bytes")
        if let url = url {
            print("[PDFProcessingHandler] PDF Source URL: \(url.lastPathComponent)")
        }

        // Verify we can create a valid PDFDocument from the data
        var pdfDocument: PDFDocument? = PDFDocument(data: data)

        if pdfDocument == nil {
            print("[PDFProcessingHandler] WARNING: Could not create PDFDocument from data")
            // Try to repair the PDF
            let repairedData = PDFManager.shared.verifyAndRepairPDF(data: data)
            print("[PDFProcessingHandler] Repaired PDF data size: \(repairedData.count) bytes")

            pdfDocument = PDFDocument(data: repairedData)
            if pdfDocument != nil {
                print("[PDFProcessingHandler] Successfully created PDF document from repaired data")
            }
        } else {
            print("[PDFProcessingHandler] Valid PDF document created with \(pdfDocument!.pageCount) pages")
        }

        // Detect format before processing
        let format = detectPayslipFormat(data)
        print("[PDFProcessingHandler] Detected format: \(format)")

        // Apply user hint before processing
        pdfProcessingService.updateUserHint(hint)

        // Use the PDF processing service to process the data
        print("[PDFProcessingHandler] Calling pdfProcessingService.processPDFData")
        let result = await pdfProcessingService.processPDFData(data)
        print("[PDFProcessingHandler] processPDFData completed")

        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image to process
    /// - Returns: A result containing the parsed payslip or an error
    func processScannedImage(_ image: UIImage, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        // Check if PDF processing service is initialized
        if !isServiceInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                return .failure(error)
            }
        }

        // Apply user hint before processing
        pdfProcessingService.updateUserHint(hint)

        // Use the service to process the scanned image
        let result = await pdfProcessingService.processScannedImage(image)
        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Processes a scanned payslip using OCR + LLM only (bypasses regex pipeline).
    /// - Parameter image: The cropped/PII-trimmed image to process
    /// - Returns: A result containing the parsed payslip or an error
    func processScannedImageLLMOnly(_ image: UIImage, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        if !isServiceInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                return .failure(error)
            }
        }

        pdfProcessingService.updateUserHint(hint)
        let result = await pdfProcessingService.processScannedImageLLMOnly(image, hint: hint)

        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Processes both original and cropped scanned images.
    /// Original image is converted to PDF for storage, cropped image is used for LLM/OCR processing.
    /// - Parameters:
    ///   - originalImage: The uncropped original image (for PDF storage)
    ///   - croppedImage: The cropped image (for LLM/OCR processing)
    ///   - imageIdentifier: UUID for linking to saved image files
    ///   - hint: User hint for payslip type
    /// - Returns: A result containing the parsed payslip or an error
    func processScannedImages(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        hint: PayslipUserHint = .auto
    ) async -> Result<PayslipItem, Error> {
        if !isServiceInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                return .failure(error)
            }
        }

        pdfProcessingService.updateUserHint(hint)

        // Call service to process with BOTH images
        let result = await pdfProcessingService.processScannedImages(
            originalImage: originalImage,
            croppedImage: croppedImage,
            imageIdentifier: imageIdentifier,
            hint: hint
        )

        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Detects the format of a PDF.
    /// - Parameter data: The PDF data to check.
    /// - Returns: The detected format.
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        // Handle password-protected PDFs gracefully
        if isPasswordProtected(data) {
            print("[PDFProcessingHandler] Attempting to detect format of password-protected PDF")

            // Try to infer the format from the file metadata
            if let pdfDocument = PDFDocument(data: data),
               let attributes = pdfDocument.documentAttributes {

                if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String,
                   (creator.contains("PCDA") || creator.contains("Defence") || creator.contains("Military")) {
                    print("[PDFProcessingHandler] Detected defense format from metadata")
                    return .defense
                }
            }
        }

        // If not protected or no metadata, use the standard detection
        return pdfProcessingService.detectPayslipFormat(data)
    }
}
