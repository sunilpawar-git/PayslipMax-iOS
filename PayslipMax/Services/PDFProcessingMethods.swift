import Foundation

/// Container for PDF processing methods extracted from PDFProcessingService.
/// This file contains processing methods for different PDF formats to reduce file size.
@MainActor
class PDFProcessingMethods {
    private let pdfExtractor: PDFExtractorProtocol

    init(pdfExtractor: PDFExtractorProtocol) {
        self.pdfExtractor = pdfExtractor
    }

    /// Processes extracted text assuming it's from a Military format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processMilitaryPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing military PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract military payslip data")
    }

    /// Processes extracted text assuming it's from a PCDA format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processPCDAPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing PCDA PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract PCDA payslip data")
    }

    /// Processes extracted text assuming it's from a standard (non-specific) format payslip.
    /// Delegates the actual extraction to the `pdfExtractor`.
    /// - Parameter text: The full text extracted from the PDF.
    /// - Returns: A `PayslipItem` containing the extracted data.
    /// - Throws: `PDFProcessingError.parsingFailed` if data extraction fails.
    func processStandardPDF(from text: String) throws -> PayslipItem {
        print("[PDFProcessingService] Processing standard PDF")
        if let payslipItem = pdfExtractor.extractPayslipData(from: text) {
            return payslipItem
        }
        throw PDFProcessingError.parsingFailed("Failed to extract standard payslip data")
    }
}
