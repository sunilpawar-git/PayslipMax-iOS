import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Protocol for generating defense-specific payslip PDFs
protocol DefensePayslipPDFGeneratorProtocol {
    func createDefensePayslipPDF(
        serviceBranch: DefenseServiceBranch,
        name: String,
        rank: String,
        serviceNumber: String,
        month: String,
        year: Int,
        basicPay: Double,
        msp: Double,
        da: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double
    ) -> PDFDocument
}

/// Generator for defense personnel payslip PDFs (Army, Navy, Air Force, PCDA)
class DefensePayslipPDFGenerator: DefensePayslipPDFGeneratorProtocol {

    private let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

    // MARK: - DefensePayslipPDFGeneratorProtocol Implementation

    func createDefensePayslipPDF(
        serviceBranch: DefenseServiceBranch,
        name: String,
        rank: String,
        serviceNumber: String,
        month: String,
        year: Int,
        basicPay: Double,
        msp: Double,
        da: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double
    ) -> PDFDocument {
        let pdfMetaData = createDefensePDFMetadata(serviceBranch: serviceBranch)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        let pdfData = renderer.pdfData { context in
            context.beginPage()
            drawDefensePayslip(
                context: context,
                serviceBranch: serviceBranch,
                name: name, rank: rank, serviceNumber: serviceNumber,
                month: month, year: year,
                basicPay: basicPay, msp: msp, da: da,
                dsop: dsop, agif: agif, incomeTax: incomeTax
            )
        }

        return PDFDocument(data: pdfData)!
    }


    // MARK: - Private Drawing Methods

    private func drawDefensePayslip(
        context: UIGraphicsPDFRendererContext,
        serviceBranch: DefenseServiceBranch,
        name: String, rank: String, serviceNumber: String,
        month: String, year: Int,
        basicPay: Double, msp: Double, da: Double,
        dsop: Double, agif: Double, incomeTax: Double
    ) {
        // Draw service-specific header
        drawServiceHeader(context: context, serviceBranch: serviceBranch, month: month, year: year)

        // Draw personnel information
        drawPersonnelInfo(context: context, name: name, rank: rank, serviceNumber: serviceNumber)

        // Draw earnings table
        drawEarningsTable(
            context: context,
            basicPay: basicPay, msp: msp, da: da
        )

        // Draw deductions table
        drawDeductionsTable(
            context: context,
            dsop: dsop, agif: agif, incomeTax: incomeTax
        )

        // Draw net pay
        drawNetPaySection(
            context: context,
            totalEarnings: basicPay + msp + da,
            totalDeductions: dsop + agif + incomeTax
        )
    }


    private func drawServiceHeader(context: UIGraphicsPDFRendererContext, serviceBranch: DefenseServiceBranch, month: String, year: Int) {
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)

        // Service-specific title
        let serviceTitle: String
        switch serviceBranch {
        case .army: serviceTitle = "INDIAN ARMY PAYSLIP"
        case .navy: serviceTitle = "INDIAN NAVY PAYSLIP"
        case .airForce: serviceTitle = "INDIAN AIR FORCE PAYSLIP"
        case .pcda: serviceTitle = "PCDA PAYSLIP STATEMENT"
        }

        drawText(context: context, text: serviceTitle, font: titleFont, x: 50, y: 50, width: 495, height: 30, alignment: .center)
        drawText(context: context, text: "Payment for \(month) \(year)", font: subtitleFont, x: 50, y: 80, width: 495, height: 20, alignment: .center)
    }

    private func drawPersonnelInfo(context: UIGraphicsPDFRendererContext, name: String, rank: String, serviceNumber: String) {
        let infoFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)

        drawText(context: context, text: "Name: \(name)", font: infoFont, x: 50, y: 120, width: 250, height: 20, alignment: .left)
        drawText(context: context, text: "Rank: \(rank)", font: infoFont, x: 50, y: 140, width: 250, height: 20, alignment: .left)
        drawText(context: context, text: "Service No: \(serviceNumber)", font: infoFont, x: 50, y: 160, width: 250, height: 20, alignment: .left)
    }

    private func drawEarningsTable(context: UIGraphicsPDFRendererContext, basicPay: Double, msp: Double, da: Double) {
        let headerFont = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 11.0, weight: .regular)

        // Earnings header
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50, y: 200, width: 495, height: 20))
        drawText(context: context, text: "EARNINGS", font: headerFont, x: 50, y: 200, width: 495, height: 20, alignment: .center)

        // Earnings rows
        drawText(context: context, text: "Basic Pay", font: textFont, x: 60, y: 230, width: 300, height: 20, alignment: .left)
        drawText(context: context, text: String(format: "₹%.2f", basicPay), font: textFont, x: 400, y: 230, width: 100, height: 20, alignment: .right)

        drawText(context: context, text: "Military Service Pay", font: textFont, x: 60, y: 250, width: 300, height: 20, alignment: .left)
        drawText(context: context, text: String(format: "₹%.2f", msp), font: textFont, x: 400, y: 250, width: 100, height: 20, alignment: .right)

        drawText(context: context, text: "Dearness Allowance", font: textFont, x: 60, y: 270, width: 300, height: 20, alignment: .left)
        drawText(context: context, text: String(format: "₹%.2f", da), font: textFont, x: 400, y: 270, width: 100, height: 20, alignment: .right)

        // Total with separator
        let cgContext = context.cgContext
        cgContext.move(to: CGPoint(x: 50, y: 288))
        cgContext.addLine(to: CGPoint(x: 545, y: 288))
        cgContext.strokePath()

        drawText(context: context, text: "Total Earnings", font: headerFont, x: 60, y: 290, width: 300, height: 20, alignment: .left)
        drawText(context: context, text: String(format: "₹%.2f", basicPay + msp + da), font: headerFont, x: 400, y: 290, width: 100, height: 20, alignment: .right)
    }

        let headerFont = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 11.0, weight: .regular)

