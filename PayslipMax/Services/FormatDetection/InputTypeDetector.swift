import Foundation
import PDFKit

/// Detects whether input data is an image, text-based PDF, or scanned PDF
final class InputTypeDetector: InputTypeDetectorProtocol {

    // MARK: - Constants

    private enum Constants {
        static let scannedPDFTextThreshold = 100
        static let minimumDataSize = 4
    }

    private enum ImageMagicBytes {
        static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        static let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF]
    }

    // MARK: - InputTypeDetectorProtocol

    func getInputType(_ data: Data) async -> PayslipInputType {
        // Check if it's an image format (JPG/PNG)
        if isImageData(data) {
            return .imageDirect(data)
        }

        // Check if it's a PDF
        guard let pdfDoc = PDFDocument(data: data) else {
            // If not a valid PDF and not an image, default to image
            return .imageDirect(data)
        }

        // Check if PDF is scanned (contains embedded image with minimal text)
        if isPDFScanned(pdfDoc) {
            return .pdfScanned(data)
        }

        return .pdfTextBased(data)
    }

    // MARK: - Private Methods

    /// Checks if data represents an image file based on magic bytes
    /// - Parameter data: The data to check
    /// - Returns: True if data is JPG or PNG format
    private func isImageData(_ data: Data) -> Bool {
        guard data.count > Constants.minimumDataSize else { return false }

        let bytes = [UInt8](data.prefix(Constants.minimumDataSize))

        // Check for PNG signature: 89 50 4E 47
        if Array(bytes.prefix(ImageMagicBytes.pngSignature.count)) == ImageMagicBytes.pngSignature {
            return true
        }

        // Check for JPEG signature: FF D8 FF
        if Array(bytes.prefix(ImageMagicBytes.jpegSignature.count)) == ImageMagicBytes.jpegSignature {
            return true
        }

        return false
    }

    /// Determines if a PDF contains primarily an image (scanned document)
    /// - Parameter pdfDoc: The PDF document to analyze
    /// - Returns: True if PDF appears to be a scanned image
    private func isPDFScanned(_ pdfDoc: PDFDocument) -> Bool {
        guard let firstPage = pdfDoc.page(at: 0) else { return false }

        let text = firstPage.string ?? ""
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If text content is very minimal, likely a scanned image
        return trimmedText.count < Constants.scannedPDFTextThreshold
    }
}
