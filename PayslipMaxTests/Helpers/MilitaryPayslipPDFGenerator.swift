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
/// Orchestrates PDF creation using extracted utilities
/// Follows SOLID principles with single responsibility focus
class MilitaryPayslipPDFGenerator: MilitaryPayslipPDFGeneratorProtocol {

    // MARK: - Properties

    private let drawingUtilities = PDFDrawingUtilities()
    private let layoutConstants = PDFLayoutConstants()

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
            kCGPDFContextCreator as String: "PayslipMax Tests",
            kCGPDFContextAuthor as String: "Test Framework"
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

        let renderer = UIGraphicsPDFRenderer(bounds: layoutConstants.pageRect, format: format)

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
        let headerFont = PDFLayoutConstants.headerFont()
        let textFont = PDFLayoutConstants.textFont()

        // Draw title
        drawingUtilities.drawPayslipTitle(in: context)

        // Draw payment date
        drawingUtilities.drawPaymentDate(month: month, year: year, in: context)

        // Draw personal information
        drawingUtilities.drawPersonalInfo(name: name, rank: rank, id: id, in: context)

        // Draw table
        drawPayslipTable(
            credits: credits, debits: debits, dsop: dsop, tax: tax,
            in: context, headerFont: headerFont, textFont: textFont
        )

        // Draw footer
        drawingUtilities.drawPayslipFooter(in: context)
    }

    private func drawPayslipTable(
        credits: Double, debits: Double, dsop: Double, tax: Double,
        in context: UIGraphicsPDFRendererContext, headerFont: UIFont, textFont: UIFont
    ) {
        let headerY = PDFLayoutConstants.tableHeaderY
        let rowHeight = PDFLayoutConstants.rowHeight

        // Draw header background
        drawingUtilities.drawTableBackground(headerY: headerY, rowHeight: rowHeight, in: context)

        // Draw headers
        drawingUtilities.drawTableHeaders(headerY: headerY, rowHeight: rowHeight, headerFont: headerFont)

        // Draw data rows
        drawingUtilities.drawTableData(
            credits: credits, debits: debits, dsop: dsop, tax: tax,
            headerY: headerY, rowHeight: rowHeight, textFont: textFont
        )

        // Draw separator line
        drawingUtilities.drawTableSeparator(headerY: headerY, rowHeight: rowHeight, in: context)

        // Draw net amount
        drawingUtilities.drawNetAmount(credits: credits, debits: debits, headerY: headerY, rowHeight: rowHeight, headerFont: headerFont)
    }
}
