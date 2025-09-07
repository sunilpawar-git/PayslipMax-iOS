import Foundation
import PDFKit
@testable import PayslipMax

/// Protocol for PDF generation operations
protocol PDFGeneratorProtocol {
    /// Creates a corporate payslip PDF for testing
    static func corporatePayslipPDF(
        name: String,
        employeeId: String,
        department: String,
        designation: String,
        month: String,
        year: Int,
        basicSalary: Double,
        hra: Double,
        specialAllowance: Double,
        totalEarnings: Double,
        providentFund: Double,
        professionalTax: Double,
        incomeTax: Double,
        totalDeductions: Double
    ) -> PDFDocument
}

/// A generator for payslip PDF documents for testing
class PDFGenerator: PDFGeneratorProtocol {

    // MARK: - Corporate PDF Generation

    /// Creates a corporate payslip PDF for testing
    static func corporatePayslipPDF(
        name: String = "Jane Smith",
        employeeId: String = "EMP78910",
        department: String = "Engineering",
        designation: String = "Senior Developer",
        month: String = "January",
        year: Int = 2023,
        basicSalary: Double = 60000.0,
        hra: Double = 20000.0,
        specialAllowance: Double = 15000.0,
        totalEarnings: Double = 95000.0,
        providentFund: Double = 7200.0,
        professionalTax: Double = 200.0,
        incomeTax: Double = 18000.0,
        totalDeductions: Double = 25400.0
    ) -> PDFDocument {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let pdfData = UIGraphicsPDFRenderer(bounds: pageRect, format: format).pdfData { context in
            context.beginPage()

            drawCorporatePayslipHeader(context: context, pageRect: pageRect, month: month, year: year)
            drawEmployeeInformation(context: context, pageRect: pageRect, name: name, employeeId: employeeId, department: department, designation: designation, month: month, year: year)
            drawEarningsTable(context: context, tableY: 220.0, basicSalary: basicSalary, hra: hra, specialAllowance: specialAllowance)
            drawDeductionsTable(context: context, tableY: 220.0, providentFund: providentFund, professionalTax: professionalTax, incomeTax: incomeTax)
            drawTotalsSection(context: context, totalY: 350.0, totalEarnings: totalEarnings, totalDeductions: totalDeductions)
            drawFooter(context: context, pageRect: pageRect)
        }

        return PDFDocument(data: pdfData)!
    }

    // MARK: - Private Drawing Methods

    private static func drawCorporatePayslipHeader(context: UIGraphicsPDFRendererContext, pageRect: CGRect, month: String, year: Int) {
        // Constants for styling
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        // Draw company logo placeholder and header
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50, y: 50, width: 80, height: 40))

        paragraphStyle.alignment = .center
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "ACME CORPORATION".draw(
            with: CGRect(x: 140, y: 50, width: 315, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        "Payslip for \(month) \(year)".draw(
            with: CGRect(x: 140, y: 75, width: 315, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: subtitleAttributes,
            context: nil
        )
    }

    private static func drawEmployeeInformation(context: UIGraphicsPDFRendererContext, pageRect: CGRect, name: String, employeeId: String, department: String, designation: String, month: String, year: Int) {
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        // Left column
        "Employee Name: \(name)".draw(
            with: CGRect(x: 50, y: 130, width: 250, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: infoAttributes,
            context: nil
        )

        "Employee ID: \(employeeId)".draw(
            with: CGRect(x: 50, y: 150, width: 250, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: infoAttributes,
            context: nil
        )

        "Designation: \(designation)".draw(
            with: CGRect(x: 50, y: 170, width: 250, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: infoAttributes,
            context: nil
        )

        // Right column
        "Department: \(department)".draw(
            with: CGRect(x: 320, y: 130, width: 250, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: infoAttributes,
            context: nil
        )

        "Pay Period: \(month) \(year)".draw(
            with: CGRect(x: 320, y: 150, width: 250, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: infoAttributes,
            context: nil
        )
    }

    private static func drawEarningsTable(context: UIGraphicsPDFRendererContext, tableY: CGFloat, basicSalary: Double, hra: Double, specialAllowance: Double) {
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let columnWidth: CGFloat = 125.0

        // Headers
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        // Earnings Header
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50, y: tableY, width: 2 * columnWidth, height: 30))

        "EARNINGS".draw(
            with: CGRect(x: 50, y: tableY, width: 2 * columnWidth, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: tableHeaderAttributes,
            context: nil
        )

        // Column Headers
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50, y: tableY + 30, width: columnWidth, height: 25))
        context.fill(CGRect(x: 50 + columnWidth, y: tableY + 30, width: columnWidth, height: 25))

        paragraphStyle.alignment = .left
        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "Description".draw(
            with: CGRect(x: 60, y: tableY + 30, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        paragraphStyle.alignment = .right
        "Amount (₹)".draw(
            with: CGRect(x: 50 + columnWidth + 10, y: tableY + 30, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        // Earnings Rows
        let leftDescAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                return style
            }()
        ]

        let rightAmountAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .right
                return style
            }()
        ]

        let earningItems = [
            ("Basic Salary", basicSalary),
            ("House Rent Allowance", hra),
            ("Special Allowance", specialAllowance)
        ]

        for (index, item) in earningItems.enumerated() {
            let y = tableY + 55 + (CGFloat(index) * CGFloat(25))

            // Description
            item.0.draw(
                with: CGRect(x: 60, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: leftDescAttributes,
                context: nil
            )

            // Amount
            String(format: "%.2f", item.1).draw(
                with: CGRect(x: 50 + columnWidth + 10, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: rightAmountAttributes,
                context: nil
            )
        }
    }

    private static func drawDeductionsTable(context: UIGraphicsPDFRendererContext, tableY: CGFloat, providentFund: Double, professionalTax: Double, incomeTax: Double) {
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        let columnWidth: CGFloat = 125.0

        // Deductions Header
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY, width: 2 * columnWidth, height: 30))

        "DEDUCTIONS".draw(
            with: CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY, width: 2 * columnWidth, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: tableHeaderAttributes,
            context: nil
        )

        // Column Headers
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY + 30, width: columnWidth, height: 25))
        context.fill(CGRect(x: 50 + (3 * columnWidth) + 20, y: tableY + 30, width: columnWidth, height: 25))

        paragraphStyle.alignment = .left
        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        "Description".draw(
            with: CGRect(x: 60 + (2 * columnWidth) + 20, y: tableY + 30, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        paragraphStyle.alignment = .right
        "Amount (₹)".draw(
            with: CGRect(x: 50 + (3 * columnWidth) + 30, y: tableY + 30, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        // Deduction Rows
        let leftDescAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                return style
            }()
        ]

        let rightAmountAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .right
                return style
            }()
        ]

        let deductionItems = [
            ("Provident Fund", providentFund),
            ("Professional Tax", professionalTax),
            ("Income Tax", incomeTax)
        ]

        for (index, item) in deductionItems.enumerated() {
            let y = tableY + 55 + (CGFloat(index) * CGFloat(25))

            // Description
            item.0.draw(
                with: CGRect(x: 60 + (2 * columnWidth) + 20, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: leftDescAttributes,
                context: nil
            )

            // Amount
            String(format: "%.2f", item.1).draw(
                with: CGRect(x: 50 + (3 * columnWidth) + 30, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: rightAmountAttributes,
                context: nil
            )
        }
    }

    private static func drawTotalsSection(context: UIGraphicsPDFRendererContext, totalY: CGFloat, totalEarnings: Double, totalDeductions: Double) {
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        let columnWidth: CGFloat = 125.0

        var paragraphStyle = NSMutableParagraphStyle()
        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraphStyle
        ]

        // Total Lines
        let cgContext = context.cgContext

        // Earnings Total Line
        cgContext.move(to: CGPoint(x: 50, y: totalY))
        cgContext.addLine(to: CGPoint(x: 50 + (2 * columnWidth), y: totalY))
        cgContext.strokePath()

        // Deductions Total Line
        cgContext.move(to: CGPoint(x: 50 + (2 * columnWidth) + 20, y: totalY))
        cgContext.addLine(to: CGPoint(x: 50 + (4 * columnWidth) + 20, y: totalY))
        cgContext.strokePath()

        // Total Earnings
        paragraphStyle.alignment = .left
        "Total Earnings".draw(
            with: CGRect(x: 60, y: totalY + 10, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        paragraphStyle.alignment = .right
        String(format: "%.2f", totalEarnings).draw(
            with: CGRect(x: 50 + columnWidth + 10, y: totalY + 10, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        // Total Deductions
        paragraphStyle.alignment = .left
        "Total Deductions".draw(
            with: CGRect(x: 60 + (2 * columnWidth) + 20, y: totalY + 10, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        paragraphStyle.alignment = .right
        String(format: "%.2f", totalDeductions).draw(
            with: CGRect(x: 50 + (3 * columnWidth) + 30, y: totalY + 10, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        // Net Pay
        let netPayY = totalY + 60
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 150, y: netPayY, width: 300, height: 40))

        paragraphStyle.alignment = .center
        let netPayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16.0, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let netPay = totalEarnings - totalDeductions
        "NET PAY: ₹\(String(format: "%.2f", netPay))".draw(
            with: CGRect(x: 150, y: netPayY, width: 300, height: 40),
            options: .usesLineFragmentOrigin,
            attributes: netPayAttributes,
            context: nil
        )
    }

    private static func drawFooter(context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let smallFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        let footerY = pageRect.height - 50

        UIColor.lightGray.setFill()
        context.fill(CGRect(x: 50, y: footerY, width: pageRect.width - 100, height: 1))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        "This is a test payslip generated for testing purposes only. Not valid for financial transactions.".draw(
            with: CGRect(x: 50, y: footerY + 10, width: pageRect.width - 100, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: footerAttributes,
            context: nil
        )
    }
}
