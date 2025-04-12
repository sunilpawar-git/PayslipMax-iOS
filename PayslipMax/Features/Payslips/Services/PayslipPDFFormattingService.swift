import Foundation
import UIKit
import PDFKit

/// Service responsible for formatting and creating professional PDF documents based on payslip data
final class PayslipPDFFormattingService: PayslipPDFFormattingServiceProtocol {
    /// Shared instance of the service
    static let shared = PayslipPDFFormattingService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Creates a professionally formatted PDF with payslip details
    /// - Parameters:
    ///   - payslipData: The parsed payslip data to format
    ///   - payslip: The payslip item containing metadata
    /// - Returns: Formatted PDF data
    public func createFormattedPlaceholderPDF(from payslipData: Models.PayslipData, payslip: AnyPayslip) -> Data {
        // Define the page size (A4)
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Set up PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate the PDF
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Define colors and fonts
            let primaryColor = UIColor(red: 0/255, green: 123/255, blue: 255/255, alpha: 1)
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            let normalFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            
            // Set margin sizes
            let margin: CGFloat = 50
            let titleOffset: CGFloat = 80
            let contentStartY: CGFloat = 140
            let lineSpacing: CGFloat = 25
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: primaryColor
            ]
            
            let titleText = "Payslip - \(payslipData.month) \(payslipData.year)"
            titleText.draw(at: CGPoint(x: margin, y: titleOffset), withAttributes: titleAttributes)
            
            // Employee Details
            var currentY = contentStartY
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ]
            
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .font: normalFont,
                .foregroundColor: UIColor.black
            ]
            
            // Employee info
            "Employee Details".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            currentY += lineSpacing
            
            "Name: \(payslipData.name)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
            
            "Service Number: \(payslipData.serviceNumber)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
            
            "Rank: \(payslipData.rank)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing * 1.5
            
            // Earnings Section
            "Earnings".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            currentY += lineSpacing
            
            // Draw earnings items
            let earningsLabelWidth: CGFloat = 250
            let earningsValueX = margin + earningsLabelWidth
            
            // Basic Pay (not optional)
            "Basic Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
            formatAmount(payslipData.basicPay).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
            currentY += lineSpacing
            
            // Military Service Pay (if available)
            if payslipData.militaryServicePay > 0 {
                "Military Service Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.militaryServicePay).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // Dearness Pay (if available)
            if payslipData.dearnessPay > 0 {
                "Dearness Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.dearnessPay).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // Misc Credits (if available)
            if payslipData.miscCredits > 0 {
                "Other Allowances".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.miscCredits).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // Display other specific earnings if any
            for (key, value) in payslipData.earnings {
                // Skip items we've already displayed
                if key == "BPAY" || key == "Basic Pay" || key == "DA" || key == "Dearness Allowance" || 
                   key == "MSP" || key == "Military Service Pay" {
                    continue
                }
                
                if value > 0 {
                    key.draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                    formatAmount(value).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                    currentY += lineSpacing
                }
            }
            
            // Add line for total earnings
            drawLine(x: margin, y: currentY, width: pageWidth - (margin * 2), context: context)
            currentY += lineSpacing / 2
            
            let totalEarnings = payslipData.totalCredits
            "Total Earnings".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            formatAmount(totalEarnings).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: headerAttributes)
            currentY += lineSpacing * 1.5
            
            // Deductions Section
            "Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            currentY += lineSpacing
            
            // Draw deduction items
            // Income Tax
            if payslipData.incomeTax > 0 {
                "Income Tax".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.incomeTax, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // DSOP
            if payslipData.dsop > 0 {
                "DSOP".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.dsop, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // AGIF
            if payslipData.agif > 0 {
                "AGIF".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.agif, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // Misc Debits
            if payslipData.miscDebits > 0 {
                "Other Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                formatAmount(payslipData.miscDebits, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                currentY += lineSpacing
            }
            
            // Display other specific deductions if any
            for (key, value) in payslipData.deductions {
                // Skip items we've already displayed
                if key == "AGIF" || key == "Army Group Insurance Fund" || key == "DSOP" || 
                   key == "ITAX" || key == "Income Tax" {
                    continue
                }
                
                if value > 0 {
                    key.draw(at: CGPoint(x: margin, y: currentY), withAttributes: normalAttributes)
                    formatAmount(value, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: normalAttributes)
                    currentY += lineSpacing
                }
            }
            
            // Add line for total deductions
            drawLine(x: margin, y: currentY, width: pageWidth - (margin * 2), context: context)
            currentY += lineSpacing / 2
            
            let totalDeductions = payslipData.totalDebits
            "Total Deductions".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            formatAmount(totalDeductions, isDeduction: true).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: headerAttributes)
            currentY += lineSpacing * 1.5
            
            // Net Pay
            let netPay = totalEarnings - totalDeductions
            "Net Pay".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttributes)
            formatAmount(netPay).draw(at: CGPoint(x: earningsValueX, y: currentY), withAttributes: headerAttributes)
            
            // Footer
            let footerY = pageHeight - 40
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: smallFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            "Generated by PayslipMax • \(Date().formatted(date: .abbreviated, time: .shortened))".draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
        }
        
        return pdfData
    }
    
    // MARK: - Helper Methods
    
    /// Formats an amount as a currency string
    private func formatAmount(_ amount: Double, isDeduction: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        
        guard let formattedAmount = formatter.string(from: NSNumber(value: abs(amount))) else {
            return isDeduction ? "-£0.00" : "£0.00"
        }
        
        return isDeduction ? "-\(formattedAmount)" : formattedAmount
    }
    
    /// Draws a horizontal line
    private func drawLine(x: CGFloat, y: CGFloat, width: CGFloat, context: UIGraphicsPDFRendererContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.lineWidth = 0.5
        UIColor.lightGray.setStroke()
        path.stroke()
    }
} 