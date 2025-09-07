import Foundation
import PDFKit

/// Protocol defining document management capabilities for payslip items.
///
/// This protocol provides document-related properties and methods
/// for handling various document formats with a focus on PDFs.
protocol DocumentManagementProtocol: PayslipBaseProtocol {
    // MARK: - Document Data Properties
    
    /// The document data, typically a PDF.
    var documentData: Data? { get set }
    
    /// The source URL of the document, if available.
    var documentURL: URL? { get set }
    
    /// The document type/format (e.g., "PDF", "Image", "Text").
    var documentType: String { get set }
    
    // MARK: - Document Metadata
    
    /// The date when the document was created or last modified.
    var documentDate: Date? { get set }
    
    /// The file size of the document in bytes.
    var documentSize: Int? { get }
    
    // MARK: - Document Operations
    
    /// Generates a thumbnail image for the document.
    /// - Returns: A thumbnail image if available, nil otherwise.
    func generateThumbnail() -> UIImage?
    
    /// Validates the document data integrity.
    /// - Returns: True if the document data is valid, false otherwise.
    func validateDocument() -> Bool
}

// MARK: - Default Implementations

extension DocumentManagementProtocol {
    /// The file size of the document in bytes.
    var documentSize: Int? {
        return documentData?.count
    }

    /// Default implementation for generating a thumbnail from PDF data.
    func generateThumbnail() -> UIImage? {
        guard let data = documentData, let pdfDocument = PDFDocument(data: data) else {
            return nil
        }

        guard let pdfPage = pdfDocument.page(at: 0) else {
            return nil
        }

        let pageRect = pdfPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: pageRect.size))

            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)

            pdfPage.draw(with: .mediaBox, to: context.cgContext)
        }

        return image
    }

    /// Default implementation for validating document data.
    func validateDocument() -> Bool {
        guard let data = documentData else {
            return false
        }

        // For PDFs, attempt to create a PDFDocument
        if documentType.lowercased() == "pdf" {
            return PDFDocument(data: data) != nil
        }

        // For other document types, just check that we have data
        return !data.isEmpty
    }
}
