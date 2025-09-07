import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Protocol for military payslip PDF generation operations
protocol MilitaryPayslipPDFGeneratorProtocol {
    /// Creates a sample military payslip PDF for testing
    func createSamplePayslipPDF(
        name: String,
        rank: String,
        id: String,
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double
    ) -> PDFDocument
}

/// Generator for military payslip PDF documents
class MilitaryPayslipPDFGenerator: MilitaryPayslipPDFGeneratorProtocol {

    private let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

    // MARK: - MilitaryPayslipPDFGeneratorProtocol Implementation

    func createSamplePayslipPDF(
        name: String = "John Doe",
        rank: String = "Captain",
        id: String = "ID123456",
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0
    ) -> PDFDocument {
        let pdfData = createPayslipPDF(
            name: name,
            rank: rank,
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax
        )
        return PDFDocument(data: pdfData)!
    }

    // MARK: - Private Helper Methods

    private func createPDFMetadata() -> [String: String] {
        return [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
    }

    private func createPayslipPDF(
        name: String,
        rank: String,
        id: String,
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double
    ) -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawPayslipContent(
                name: name, rank: rank, id: id, month: month, year: year,
                credits: credits, debits: debits, dsop: dsop, tax: tax,
                in: context
            )
        }
    }

    private func drawPayslipContent(
        name: String, rank: String, id: String, month: String, year: Int,
        credits: Double, debits: Double, dsop: Double, tax: Double,
        in context: UIGraphicsPDFRendererContext
    ) {
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)

        // Draw title
        drawPayslipTitle(in: context, font: titleFont)

        // Draw payment date
        drawPaymentDate(month: month, year: year, in: context, font: textFont)

        // Draw personal information
        drawPersonalInfo(name: name, rank: rank, id: id, in: context, font: textFont)

        // Draw table
        drawPayslipTable(
            credits: credits, debits: debits, dsop: dsop, tax: tax,
            in: context, headerFont: headerFont, textFont: textFont
        )

        // Draw footer
        drawPayslipFooter(in: context, font: textFont)
    }

    private func drawPayslipTitle(in context: UIGraphicsPDFRendererContext, font: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "MILITARY PAYSLIP".draw(
            with: CGRect(x: 0, y: 50, width: defaultPageRect.width, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )
    }

    private func drawPaymentDate(month: String, year: Int, in context: UIGraphicsPDFRendererContext, font: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "Payment for \(month) \(year)".draw(
            with: CGRect(x: defaultPageRect.width - 230, y: 100, width: 200, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: dateAttributes,
            context: nil
        )
    }

    private func drawPersonalInfo(name: String, rank: String, id: String, in context: UIGraphicsPDFRendererContext, font: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let personalInfoAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "Name: \(name)".draw(
            with: CGRect(x: 50, y: 150, width: defaultPageRect.width - 100, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: personalInfoAttributes,
            context: nil
        )

        "Rank: \(rank)".draw(
            with: CGRect(x: 50, y: 170, width: defaultPageRect.width - 100, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: personalInfoAttributes,
            context: nil
        )

        "ID: \(id)".draw(
            with: CGRect(x: 50, y: 190, width: defaultPageRect.width - 100, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: personalInfoAttributes,
            context: nil
        )
    }

    private func drawPayslipTable(
        credits: Double, debits: Double, dsop: Double, tax: Double,
        in context: UIGraphicsPDFRendererContext, headerFont: UIFont, textFont: UIFont
    ) {
        let cgContext = context.cgContext
        let headerY: CGFloat = 250
        let rowHeight: CGFloat = 30

        // Draw header background
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50, y: headerY, width: defaultPageRect.width - 100, height: rowHeight))

        // Draw headers
        drawTableHeaders(headerY: headerY, rowHeight: rowHeight, headerFont: headerFont)

        // Draw data rows
        drawTableData(
            credits: credits, debits: debits, dsop: dsop, tax: tax,
            headerY: headerY, rowHeight: rowHeight, textFont: textFont
        )

        // Draw separator line
        cgContext.move(to: CGPoint(x: 50, y: headerY + 5 * rowHeight))
        cgContext.addLine(to: CGPoint(x: defaultPageRect.width - 50, y: headerY + 5 * rowHeight))
        cgContext.strokePath()

        // Draw net amount
        drawNetAmount(credits: credits, debits: debits, headerY: headerY, rowHeight: rowHeight, headerFont: headerFont)
    }

    private func drawTableHeaders(headerY: CGFloat, rowHeight: CGFloat, headerFont: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        "Description".draw(
            with: CGRect(x: 50, y: headerY, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: tableHeaderAttributes,
            context: nil
        )

        "Amount (₹)".draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: tableHeaderAttributes,
            context: nil
        )
    }

    private func drawTableData(
        credits: Double, debits: Double, dsop: Double, tax: Double,
        headerY: CGFloat, rowHeight: CGFloat, textFont: UIFont
    ) {
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
        ]

        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]

        // Credits row
        "Total Credits".draw(
            with: CGRect(x: 50, y: headerY + rowHeight, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: descriptionAttributes,
            context: nil
        )

        String(format: "%.2f", credits).draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY + rowHeight, width: 180, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: amountAttributes,
            context: nil
        )

        // Debits row
        "Total Debits".draw(
            with: CGRect(x: 50, y: headerY + 2 * rowHeight, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: descriptionAttributes,
            context: nil
        )

        String(format: "%.2f", debits).draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY + 2 * rowHeight, width: 180, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: amountAttributes,
            context: nil
        )

        // DSOP row
        "DSOP Contribution".draw(
            with: CGRect(x: 50, y: headerY + 3 * rowHeight, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: descriptionAttributes,
            context: nil
        )

        String(format: "%.2f", dsop).draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY + 3 * rowHeight, width: 180, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: amountAttributes,
            context: nil
        )

        // Tax row
        "Income Tax".draw(
            with: CGRect(x: 50, y: headerY + 4 * rowHeight, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: descriptionAttributes,
            context: nil
        )

        String(format: "%.2f", tax).draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY + 4 * rowHeight, width: 180, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: amountAttributes,
            context: nil
        )
    }

    private func drawNetAmount(credits: Double, debits: Double, headerY: CGFloat, rowHeight: CGFloat, headerFont: UIFont) {
        let netAmount = credits - debits
        let netAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]

        "Net Amount".draw(
            with: CGRect(x: 50, y: headerY + 5 * rowHeight + 10, width: 200, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: netAttributes,
            context: nil
        )

        String(format: "%.2f", netAmount).draw(
            with: CGRect(x: defaultPageRect.width - 250, y: headerY + 5 * rowHeight + 10, width: 180, height: rowHeight),
            options: .usesLineFragmentOrigin,
            attributes: netAttributes,
            context: nil
        )
    }

    private func drawPayslipFooter(in context: UIGraphicsPDFRendererContext, font: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "This is a generated test payslip for testing purposes only".draw(
            with: CGRect(x: 50, y: defaultPageRect.height - 50, width: defaultPageRect.width - 100, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: footerAttributes,
            context: nil
        )
    }

    private func createLeftAlignedParagraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        return paragraphStyle
    }

    private func createRightAlignedParagraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        return paragraphStyle
    }
}
