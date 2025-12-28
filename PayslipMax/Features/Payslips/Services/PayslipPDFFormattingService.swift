import Foundation
import UIKit
import PDFKit

/// Service responsible for formatting and creating professional PDF documents based on payslip data
final class PayslipPDFFormattingService: PayslipPDFFormattingServiceProtocol {
    /// Shared instance of the service
    static let shared = PayslipPDFFormattingService()

    /// Display name service for clean component names
    private let displayNameService: PayslipDisplayNameService

    /// Private initializer to enforce singleton pattern
    private init() {
        self.displayNameService = PayslipDisplayNameService.shared
    }

    /// Creates a professionally formatted PDF with payslip details
    public func createFormattedPlaceholderPDF(from payslipData: PayslipData, payslip: AnyPayslip) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()

            var currentY: CGFloat = 140
            let margin: CGFloat = 50
            let pageWidth = pageRect.width
            let pageHeight = pageRect.height

            drawTitle(payslipData: payslipData, margin: margin)
            currentY = drawEmployeeDetails(payslipData: payslipData, startY: currentY, margin: margin)
            currentY = drawEarningsSection(payslipData: payslipData, startY: currentY, margin: margin, pageWidth: pageWidth, context: context)
            currentY = drawDeductionsSection(payslipData: payslipData, startY: currentY, margin: margin, pageWidth: pageWidth, context: context)
            drawNetPay(payslipData: payslipData, currentY: currentY, margin: margin)
            drawFooter(margin: margin, pageHeight: pageHeight)
        }
    }

    // MARK: - Drawing Methods

    private func drawTitle(payslipData: PayslipData, margin: CGFloat) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(red: 0/255, green: 123/255, blue: 255/255, alpha: 1)
        ]
        let titleText = "Payslip - \(payslipData.month) \(payslipData.year)"
        titleText.draw(at: CGPoint(x: margin, y: 80), withAttributes: titleAttributes)
    }

    private func drawEmployeeDetails(payslipData: PayslipData, startY: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = startY
        let lineSpacing: CGFloat = 25

        "Employee Details".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        currentY += lineSpacing

        "Name: \(payslipData.name)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
        currentY += lineSpacing

        "Service Number: \(payslipData.serviceNumber)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
        currentY += lineSpacing

        "Rank: \(payslipData.rank)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
        currentY += lineSpacing * 1.5

        return currentY
    }

    private func drawEarningsSection(payslipData: PayslipData, startY: CGFloat, margin: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let lineSpacing: CGFloat = 25
        let earningsValueX = margin + 250

        "Earnings".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        currentY += lineSpacing

        currentY = drawEarningsItems(payslipData: payslipData, startY: currentY, margin: margin, valueX: earningsValueX, lineSpacing: lineSpacing)

        drawLine(x: margin, y: currentY, width: pageWidth - (margin * 2), context: context)
        currentY += lineSpacing / 2

        "Total Earnings".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        formatAmount(payslipData.totalCredits).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: headerAttributes)
        currentY += lineSpacing * 1.5

        return currentY
    }

    private func drawEarningsItems(payslipData: PayslipData, startY: CGFloat, margin: CGFloat, valueX: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        var currentY = startY

        "Basic Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
        formatAmount(payslipData.basicPay).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
        currentY += lineSpacing

        if payslipData.militaryServicePay > 0 {
            "Military Service Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.militaryServicePay).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        if payslipData.dearnessPay > 0 {
            "Dearness Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.dearnessPay).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        if payslipData.miscCredits > 0 {
            "Other Allowances".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.miscCredits).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        currentY = drawAdditionalEarnings(payslipData: payslipData, currentY: currentY, margin: margin, valueX: valueX, lineSpacing: lineSpacing)

        return currentY
    }

    private func drawAdditionalEarnings(payslipData: PayslipData, currentY: CGFloat, margin: CGFloat, valueX: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        var y = currentY
        let skipKeys = Set(["BPAY", "Basic Pay", "DA", "Dearness Allowance", "MSP", "Military Service Pay"])

        for (key, value) in payslipData.earnings where value > 0 && !skipKeys.contains(key) {
            let displayName = displayNameService.getDisplayName(for: key)
            displayName.draw(at: CGPoint(x: margin, y: y), withAttributes: normalAttributes)
            formatAmount(value).draw(at: CGPoint(x: valueX, y: y), withAttributes: normalAttributes)
            y += lineSpacing
        }

        return y
    }

    private func drawDeductionsSection(payslipData: PayslipData, startY: CGFloat, margin: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = startY
        let lineSpacing: CGFloat = 25
        let valueX = margin + 250

        "Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        currentY += lineSpacing

        currentY = drawDeductionItems(payslipData: payslipData, startY: currentY, margin: margin, valueX: valueX, lineSpacing: lineSpacing)

        drawLine(x: margin, y: currentY, width: pageWidth - (margin * 2), context: context)
        currentY += lineSpacing / 2

        "Total Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        formatAmount(payslipData.totalDebits, isDeduction: true).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: headerAttributes)
        currentY += lineSpacing * 1.5

        return currentY
    }

    private func drawDeductionItems(payslipData: PayslipData, startY: CGFloat, margin: CGFloat, valueX: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        var currentY = startY

        if payslipData.incomeTax > 0 {
            "Income Tax".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.incomeTax, isDeduction: true).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        if payslipData.dsop > 0 {
            "DSOP".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.dsop, isDeduction: true).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        if payslipData.agif > 0 {
            "AGIF".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.agif, isDeduction: true).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        if payslipData.miscDebits > 0 {
            "Other Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.miscDebits, isDeduction: true).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
        }

        currentY = drawAdditionalDeductions(payslipData: payslipData, currentY: currentY, margin: margin, valueX: valueX, lineSpacing: lineSpacing)

        return currentY
    }

    private func drawAdditionalDeductions(payslipData: PayslipData, currentY: CGFloat, margin: CGFloat, valueX: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        var y = currentY
        let skipKeys = Set(["AGIF", "Army Group Insurance Fund", "DSOP", "ITAX", "Income Tax"])

        for (key, value) in payslipData.deductions where value > 0 && !skipKeys.contains(key) {
            let displayName = displayNameService.getDisplayName(for: key)
            displayName.draw(at: CGPoint(x: margin, y: y), withAttributes: normalAttributes)
            formatAmount(value, isDeduction: true).draw(at: CGPoint(x: valueX, y: y), withAttributes: normalAttributes)
            y += lineSpacing
        }

        return y
    }

    private func drawNetPay(payslipData: PayslipData, currentY: CGFloat, margin: CGFloat) {
        let valueX = margin + 250
        let netPay = payslipData.totalCredits - payslipData.totalDebits
        "Net Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
        formatAmount(netPay).draw(at: CGPoint(x: valueX, y: currentY), withAttributes: headerAttributes)
    }

    private func drawFooter(margin: CGFloat, pageHeight: CGFloat) {
        let footerY = pageHeight - 40
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        "Generated by PayslipMax • \(Date().formatted(date: .abbreviated, time: .shortened))".draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - Attributes

    private var headerAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.black
        ]
    }

    private var normalAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.black
        ]
    }

    // MARK: - Helper Methods

    private func formatAmount(_ amount: Double, isDeduction: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true

        guard let formattedAmount = formatter.string(from: NSNumber(value: abs(amount))) else {
            return isDeduction ? "-₹0" : "₹0"
        }

        return isDeduction ? "-\(formattedAmount)" : formattedAmount
    }

    private func drawLine(x: CGFloat, y: CGFloat, width: CGFloat, context: UIGraphicsPDFRendererContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.lineWidth = 0.5
        UIColor.lightGray.setStroke()
        path.stroke()
    }
}
