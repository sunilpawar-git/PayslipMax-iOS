import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Protocol for military payslip PDF generation operations
protocol MilitaryPayslipPDFGeneratorProtocol {
    /// Creates a sample military payslip PDF for testing using parameter struct
    func createSamplePayslipPDF(params: PayslipPDFParams) -> PDFDocument
}

/// Generator for military payslip PDF documents
/// Orchestrates PDF creation using extracted utilities
/// Follows SOLID principles with single responsibility focus
class MilitaryPayslipPDFGenerator: MilitaryPayslipPDFGeneratorProtocol {

    // MARK: - Properties

    private let drawingUtilities = PDFDrawingUtilities()
    private let layoutConstants = PDFLayoutConstants()

    // MARK: - MilitaryPayslipPDFGeneratorProtocol Implementation

    func createSamplePayslipPDF(params: PayslipPDFParams = .default) -> PDFDocument {
        let pdfData = createPayslipPDF(params: params)
        return PDFDocument(data: pdfData)!
    }

    // MARK: - Private Helper Methods

    private func createPDFMetadata() -> [String: String] {
        return [
            kCGPDFContextCreator as String: "PayslipMax Tests",
            kCGPDFContextAuthor as String: "Test Framework"
        ]
    }

    private func createPayslipPDF(params: PayslipPDFParams) -> Data {
        let pdfMetaData = createPDFMetadata()
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: layoutConstants.pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawPayslipContent(params: params, in: context)
        }
    }

    private func drawPayslipContent(params: PayslipPDFParams, in context: UIGraphicsPDFRendererContext) {
        let headerFont = PDFLayoutConstants.headerFont()
        let textFont = PDFLayoutConstants.textFont()

        // Draw title
        drawingUtilities.drawPayslipTitle(in: context)

        // Draw payment date
        drawingUtilities.drawPaymentDate(month: params.month, year: params.year, in: context)

        // Draw personal information
        drawingUtilities.drawPersonalInfo(name: params.name, rank: params.rank, id: params.id, in: context)

        // Draw table
        drawPayslipTable(
            credits: params.credits, debits: params.debits,
            dsop: params.dsop, tax: params.tax,
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
