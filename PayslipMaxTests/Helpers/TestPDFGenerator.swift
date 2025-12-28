import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Utility class for generating test PDF documents for use in tests
///
/// Additional methods in extensions:
/// - TestPDFGenerator+SpecializedContent.swift (Table, Mixed Content, Columns)
class TestPDFGenerator {

    // MARK: - Standard PDF Generation

    /// Creates a simple PDF with text content
    static func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()

            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: textFont
            ]

            let textRect = CGRect(
                x: 10,
                y: 10,
                width: pageRect.width - 20,
                height: pageRect.height - 20
            )

            text.draw(
                with: textRect,
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
        }
    }

    /// Creates a PDF with an image to simulate scanned content
    static func createPDFWithImage() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()

            // Create a simple image (a colored rectangle)
            UIColor.blue.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 300, height: 200))

            // Add some text to indicate it's a test document
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural

            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: textFont
            ]

            "This is a test document with an image.".draw(
                with: CGRect(x: 50, y: 300, width: 300, height: 50),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
        }
    }

    /// Creates a multi-page PDF document
    static func createMultiPagePDF(pageCount: Int) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            for i in 0..<pageCount {
                context.beginPage()

                let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .natural

                let attributes: [NSAttributedString.Key: Any] = [
                    .paragraphStyle: paragraphStyle,
                    .font: textFont
                ]

                "Page \(i+1) of the test document.".draw(
                    with: CGRect(x: 50, y: 50, width: 300, height: 50),
                    options: .usesLineFragmentOrigin,
                    attributes: attributes,
                    context: nil
                )
            }
        }
    }
}
