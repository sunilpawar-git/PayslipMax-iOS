import Foundation
import PDFKit
import UIKit

/// Utility class for PDF drawing operations
/// Handles text drawing, layout, and styling for military payslip PDFs
/// Follows SOLID principles with single responsibility focus
class PDFDrawingUtilities {

    // MARK: - Properties

    private let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

    // MARK: - Title Drawing

    func drawPayslipTitle(in context: UIGraphicsPDFRendererContext) {
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
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

    // MARK: - Date Drawing

    func drawPaymentDate(month: String, year: Int, in context: UIGraphicsPDFRendererContext) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
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

    // MARK: - Personal Information Drawing

    func drawPersonalInfo(name: String, rank: String, id: String, in context: UIGraphicsPDFRendererContext) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let personalInfoAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
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

    // MARK: - Table Drawing

    func drawTableHeaders(headerY: CGFloat, rowHeight: CGFloat, headerFont: UIFont) {
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

    func drawTableData(
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        headerY: CGFloat,
        rowHeight: CGFloat,
        textFont: UIFont
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

    func drawNetAmount(credits: Double, debits: Double, headerY: CGFloat, rowHeight: CGFloat, headerFont: UIFont) {
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

    func drawTableSeparator(headerY: CGFloat, rowHeight: CGFloat, in context: UIGraphicsPDFRendererContext) {
        let cgContext = context.cgContext
        cgContext.move(to: CGPoint(x: 50, y: headerY + 5 * rowHeight))
        cgContext.addLine(to: CGPoint(x: defaultPageRect.width - 50, y: headerY + 5 * rowHeight))
        cgContext.strokePath()
    }

    func drawTableBackground(headerY: CGFloat, rowHeight: CGFloat, in context: UIGraphicsPDFRendererContext) {
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50, y: headerY, width: defaultPageRect.width - 100, height: rowHeight))
    }

    // MARK: - Footer Drawing

    func drawPayslipFooter(in context: UIGraphicsPDFRendererContext) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
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

    // MARK: - Helper Methods

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
