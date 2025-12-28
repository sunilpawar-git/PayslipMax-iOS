import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Protocol for basic PDF generation operations
protocol BasicPDFGeneratorProtocol {
    /// Creates a sample PDF document with text for testing
    func createSamplePDFDocument(withText text: String) -> PDFDocument

    /// Creates a PDF with image content for testing (simulated scanned content)
    func createPDFWithImage() -> Data

    /// Creates a multi-page PDF for testing large documents
    func createMultiPagePDF(pageCount: Int) -> Data

    /// Creates a PDF with table content for testing
    func createPDFWithTable() -> Data
}

/// Generator for basic PDF documents (text, image, multi-page, table)
class BasicPDFGenerator: BasicPDFGeneratorProtocol {

    private let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

    // MARK: - BasicPDFGeneratorProtocol Implementation

    func createSamplePDFDocument(withText text: String = "Sample PDF for testing") -> PDFDocument {
        let pdfData = createPDFWithText(text)
        return PDFDocument(data: pdfData)!
    }

    func createPDFWithImage() -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawImageContent(in: context)
        }
    }

    func createMultiPagePDF(pageCount: Int) -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        return renderer.pdfData { context in
            for pageNumber in 1...pageCount {
                context.beginPage()
                self.drawMultiPageContent(
                    in: context,
                    pageNumber: pageNumber,
                    totalPages: pageCount
                )
            }
        }
    }

    func createPDFWithTable() -> Data {
        let tableDrawer = BasicPDFTableDrawer(pageRect: defaultPageRect)
        return tableDrawer.createPDFWithTable()
    }

    // MARK: - Private Helper Methods

    private func createPDFMetadata() -> [String: String] {
        return [
            kCGPDFContextCreator as String: "PayslipMax Tests",
            kCGPDFContextAuthor as String: "Test Framework"
        ]
    }

    private func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawTextContent(text, in: context)
        }
    }

    private func drawTextContent(_ text: String, in context: UIGraphicsPDFRendererContext) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: textFont
        ]

        text.draw(
            with: CGRect(
                x: 10,
                y: 10,
                width: defaultPageRect.width - 20,
                height: defaultPageRect.height - 20
            ),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
    }

    private func drawImageContent(in context: UIGraphicsPDFRendererContext) {
        let cgContext = context.cgContext

        // Draw some rectangles to simulate scanned content
        cgContext.setFillColor(UIColor.lightGray.cgColor)
        cgContext.fill(CGRect(x: 50, y: 50, width: 200, height: 100))

        cgContext.setFillColor(UIColor.gray.cgColor)
        cgContext.fill(CGRect(x: 300, y: 50, width: 200, height: 100))

        cgContext.setFillColor(UIColor.darkGray.cgColor)
        cgContext.fill(CGRect(x: 50, y: 200, width: 450, height: 50))

        // Add minimal text to ensure low text density
        let textFont = UIFont.systemFont(ofSize: 8.0, weight: .regular)
        let attributes = [NSAttributedString.Key.font: textFont]

        "IMG".draw(
            with: CGRect(x: 10, y: 10, width: 50, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
    }

    private func drawMultiPageContent(
        in context: UIGraphicsPDFRendererContext,
        pageNumber: Int,
        totalPages: Int
    ) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let attributes = [NSAttributedString.Key.font: textFont]

        // Generate dense text content
        let pageInfo = "This is page \(pageNumber) of a large multi-page document. "
        let denseText = String(repeating: pageInfo, count: 50)
        let loremText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
        Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.
        """
        let pageText = "Page \(pageNumber) of \(totalPages)\n\n" +
            denseText + "\n\n" +
            "Additional content for text-heavy document classification. " +
            loremText

        pageText.draw(
            with: CGRect(
                x: 50,
                y: 50,
                width: defaultPageRect.width - 100,
                height: defaultPageRect.height - 100
            ),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
    }
}
