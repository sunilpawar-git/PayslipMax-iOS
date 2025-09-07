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
                self.drawMultiPageContent(in: context, pageNumber: pageNumber, totalPages: pageCount)
            }
        }
    }

    func createPDFWithTable() -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawTableContent(in: context)
        }
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
            with: CGRect(x: 10, y: 10, width: defaultPageRect.width - 20, height: defaultPageRect.height - 20),
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

    private func drawMultiPageContent(in context: UIGraphicsPDFRendererContext, pageNumber: Int, totalPages: Int) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let attributes = [NSAttributedString.Key.font: textFont]

        // Generate dense text content
        let denseText = String(repeating: "This is page \(pageNumber) of a large multi-page document with extensive text content. ", count: 50)
        let pageText = "Page \(pageNumber) of \(totalPages)\n\n" + denseText + "\n\n" +
                      "Additional content to ensure this is recognized as a text-heavy document rather than scanned content. " +
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " +
                      "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."

        pageText.draw(
            with: CGRect(x: 50, y: 50, width: defaultPageRect.width - 100, height: defaultPageRect.height - 100),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
    }

    private func drawTableContent(in context: UIGraphicsPDFRendererContext) {
        let cgContext = context.cgContext
        let textFont = UIFont.systemFont(ofSize: 8.0, weight: .regular)
        let headerFont = UIFont.systemFont(ofSize: 10.0, weight: .bold)
        let titleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)

        // Draw title
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        "Complex Multi-Column Table Document with High Text Density".draw(
            with: CGRect(x: 50, y: 30, width: 500, height: 40),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )

        // Draw columns with dense text
        drawTableColumns(textFont: textFont, headerFont: headerFont)

        // Draw table grid
        drawTableGrid(cgContext: cgContext)

        // Draw table headers and data
        drawTableHeadersAndData(headerFont: headerFont, textFont: textFont)

        // Add additional dense text
        addAdditionalDenseText(textFont: textFont)
    }

    private func drawTableColumns(textFont: UIFont, headerFont: UIFont) {
        let leftColumnX: CGFloat = 50
        let rightColumnX: CGFloat = 320
        let columnWidth: CGFloat = 200

        let shortLines = Array(repeating: "Short line text content for density", count: 100)
        let longLines = Array(repeating: "This is a much longer line of text that should create a bimodal distribution for column detection and increase overall text density significantly with many more characters per line", count: 100)
        let mediumLines = Array(repeating: "Medium length text for better distribution and higher character count", count: 100)
        let extraLongLines = Array(repeating: "This is an extremely long line of text with many characters designed specifically to boost the overall character count and text density to meet the required threshold of 0.6 for text-heavy document classification", count: 50)

        let leftColumnLines = shortLines + longLines + mediumLines + extraLongLines
        let rightColumnLines = longLines + shortLines + mediumLines + extraLongLines

        let leftColumnText = "LEFT COLUMN HEADER:\n\n" + leftColumnLines.joined(separator: "\n")
        let rightColumnText = "RIGHT COLUMN HEADER:\n\n" + rightColumnLines.joined(separator: "\n")

        let textAttributes = [NSAttributedString.Key.font: textFont]

        leftColumnText.draw(
            with: CGRect(x: leftColumnX, y: 80, width: columnWidth, height: 350),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )

        rightColumnText.draw(
            with: CGRect(x: rightColumnX, y: 80, width: columnWidth, height: 350),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )
    }

    private func drawTableGrid(cgContext: CGContext) {
        let tableX: CGFloat = 50
        let tableY: CGFloat = 450
        let cellWidth: CGFloat = 120
        let cellHeight: CGFloat = 25
        let columns = 4
        let rows = 8

        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1.0)

        // Draw vertical lines
        for col in 0...columns {
            let x = tableX + CGFloat(col) * cellWidth
            cgContext.move(to: CGPoint(x: x, y: tableY))
            cgContext.addLine(to: CGPoint(x: x, y: tableY + CGFloat(rows) * cellHeight))
            cgContext.strokePath()
        }

        // Draw horizontal lines
        for row in 0...rows {
            let y = tableY + CGFloat(row) * cellHeight
            cgContext.move(to: CGPoint(x: tableX, y: y))
            cgContext.addLine(to: CGPoint(x: tableX + CGFloat(columns) * cellWidth, y: y))
            cgContext.strokePath()
        }
    }

    private func drawTableHeadersAndData(headerFont: UIFont, textFont: UIFont) {
        let tableX: CGFloat = 50
        let tableY: CGFloat = 450
        let cellWidth: CGFloat = 120
        let cellHeight: CGFloat = 25

        let headers = ["Item Code | Description", "Amount Value | Currency", "Type Category | Classification", "Status State | Condition"]
        let headerAttributes = [NSAttributedString.Key.font: headerFont]
        let textAttributes = [NSAttributedString.Key.font: textFont]

        // Draw headers
        for (col, header) in headers.enumerated() {
            let cellRect = CGRect(
                x: tableX + CGFloat(col) * cellWidth + 2,
                y: tableY + 2,
                width: cellWidth - 4,
                height: cellHeight - 4
            )
            header.draw(with: cellRect, options: .usesLineFragmentOrigin, attributes: headerAttributes, context: nil)
        }

        // Draw data rows
        let tableData = [
            ["Basic Pay | BP001", "5000.00 | INR", "Credit Earning | CR", "Active Status | ACT"],
            ["Allowances | AL002", "1500.00 | INR", "Credit Earning | CR", "Active Status | ACT"],
            ["House Rent | HR003", "2000.00 | INR", "Credit Earning | CR", "Active Status | ACT"],
            ["Transport | TR004", "800.00 | INR", "Credit Earning | CR", "Active Status | ACT"],
            ["Deductions | DED005", "800.00 | INR", "Debit Charge | DR", "Active Status | ACT"],
            ["Income Tax | TAX006", "600.00 | INR", "Debit Charge | DR", "Active Status | ACT"],
            ["DSOP Fund | DSOP007", "300.00 | INR", "Debit Charge | DR", "Active Status | ACT"]
        ]

        for (row, rowData) in tableData.enumerated() {
            for (col, cellData) in rowData.enumerated() {
                let cellRect = CGRect(
                    x: tableX + CGFloat(col) * cellWidth + 2,
                    y: tableY + CGFloat(row + 1) * cellHeight + 2,
                    width: cellWidth - 4,
                    height: cellHeight - 4
                )
                cellData.draw(with: cellRect, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
            }
        }
    }

    private func addAdditionalDenseText(textFont: UIFont) {
        let textAttributes = [NSAttributedString.Key.font: textFont]

        let additionalText = String(repeating: "Additional dense text content to ensure high text density for table extraction strategy validation. This text is repeated many times to increase character count per unit area. ", count: 150)
        additionalText.draw(
            with: CGRect(x: 50, y: 650, width: 500, height: 180),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )

        let footerText = String(repeating: "Footer text content for additional text density boost with many characters. ", count: 80)
        footerText.draw(
            with: CGRect(x: 50, y: 750, width: 500, height: 80),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )
    }
}
