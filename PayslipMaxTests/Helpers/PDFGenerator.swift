import Foundation
import PDFKit
@testable import PayslipMax

/// Protocol for generating PDF documents for testing
protocol PDFGeneratorProtocol {
    /// Creates a sample PDF document with text for testing
    func createSamplePDFDocument(withText text: String) -> PDFDocument

    /// Creates a sample payslip PDF for testing
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

    /// Creates a PDF with image content for testing (simulated scanned content)
    func createPDFWithImage() -> Data

    /// Creates a multi-page PDF for testing large documents
    func createMultiPagePDF(pageCount: Int) -> Data

    /// Creates a PDF with table content for testing
    func createPDFWithTable() -> Data

    /// Creates a corporate payslip PDF for testing
    func createCorporatePayslipPDF(
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

/// Refactored PDF Generator that uses extracted components
/// This class serves as a facade for the modular PDF generation system
class PDFGenerator: PDFGeneratorProtocol {

    // MARK: - Dependencies

    private let basicGenerator: BasicPDFGeneratorProtocol
    private let militaryGenerator: MilitaryPayslipPDFGeneratorProtocol

    // MARK: - Initialization

    init(
        basicGenerator: BasicPDFGeneratorProtocol = BasicPDFGenerator(),
        militaryGenerator: MilitaryPayslipPDFGeneratorProtocol = MilitaryPayslipPDFGenerator()
    ) {
        self.basicGenerator = basicGenerator
        self.militaryGenerator = militaryGenerator
    }

    // MARK: - PDFGeneratorProtocol Implementation

    func createSamplePDFDocument(withText text: String = "Sample PDF for testing") -> PDFDocument {
        return basicGenerator.createSamplePDFDocument(withText: text)
    }

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
        return militaryGenerator.createSamplePayslipPDF(
            name: name, rank: rank, id: id, month: month, year: year,
            credits: credits, debits: debits, dsop: dsop, tax: tax
        )
    }

    func createPDFWithImage() -> Data {
        return basicGenerator.createPDFWithImage()
    }

    func createMultiPagePDF(pageCount: Int) -> Data {
        return basicGenerator.createMultiPagePDF(pageCount: pageCount)
    }

    func createPDFWithTable() -> Data {
        return basicGenerator.createPDFWithTable()
    }

    func createCorporatePayslipPDF(
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
        // Create corporate payslip using basic renderer with corporate styling
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let pdfData = renderer.pdfData { context in
            context.beginPage()
            drawCorporatePayslipContent(
                context: context,
                name: name, employeeId: employeeId, department: department, designation: designation,
                month: month, year: year, basicSalary: basicSalary, hra: hra, specialAllowance: specialAllowance,
                totalEarnings: totalEarnings, providentFund: providentFund, professionalTax: professionalTax,
                incomeTax: incomeTax, totalDeductions: totalDeductions
            )
        }

        return PDFDocument(data: pdfData)!
    }

    // MARK: - Private Helper Methods

    private func drawCorporatePayslipContent(
        context: UIGraphicsPDFRendererContext,
        name: String, employeeId: String, department: String, designation: String,
        month: String, year: Int, basicSalary: Double, hra: Double, specialAllowance: Double,
        totalEarnings: Double, providentFund: Double, professionalTax: Double,
        incomeTax: Double, totalDeductions: Double
    ) {
        let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)

        // Draw company header
        drawCorporateHeader(context: context, month: month, year: year, titleFont: titleFont, headerFont: headerFont)

        // Draw employee information
        drawEmployeeInformation(context: context, name: name, employeeId: employeeId, department: department, designation: designation, month: month, year: year, textFont: textFont)

        // Draw earnings and deductions tables
        drawEarningsTable(context: context, basicSalary: basicSalary, hra: hra, specialAllowance: specialAllowance, headerFont: headerFont, textFont: textFont)

        drawDeductionsTable(context: context, providentFund: providentFund, professionalTax: professionalTax, incomeTax: incomeTax, headerFont: headerFont, textFont: textFont)

        // Draw totals section
        drawTotalsSection(context: context, totalEarnings: totalEarnings, totalDeductions: totalDeductions, headerFont: headerFont)

        // Draw footer
        drawCorporateFooter(context: context)
    }

    private func drawCorporateHeader(context: UIGraphicsPDFRendererContext, month: String, year: Int, titleFont: UIFont, headerFont: UIFont) {
        // Draw company logo placeholder
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50, y: 50, width: 80, height: 40))

        // Company title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        "ACME CORPORATION".draw(
            with: CGRect(x: 140, y: 50, width: 315, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )

        // Payslip subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        "Payslip for \(month) \(year)".draw(
            with: CGRect(x: 140, y: 75, width: 315, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: subtitleAttributes,
            context: nil
        )
    }

    private func drawEmployeeInformation(context: UIGraphicsPDFRendererContext, name: String, employeeId: String, department: String, designation: String, month: String, year: Int, textFont: UIFont) {
        let infoAttributes: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
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

    private func drawEarningsTable(context: UIGraphicsPDFRendererContext, basicSalary: Double, hra: Double, specialAllowance: Double, headerFont: UIFont, textFont: UIFont) {
        let columnWidth: CGFloat = 125.0

        // Earnings Header
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50, y: 220, width: 2 * columnWidth, height: 30))

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        "EARNINGS".draw(
            with: CGRect(x: 50, y: 220, width: 2 * columnWidth, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: headerAttributes,
            context: nil
        )

        // Column Headers
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50, y: 250, width: columnWidth, height: 25))
        context.fill(CGRect(x: 50 + columnWidth, y: 250, width: columnWidth, height: 25))

        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
        ]

        "Description".draw(
            with: CGRect(x: 60, y: 250, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        let rightColumnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]

        "Amount (₹)".draw(
            with: CGRect(x: 50 + columnWidth + 10, y: 250, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: rightColumnHeaderAttributes,
            context: nil
        )

        // Earnings Rows
        let earningItems = [
            ("Basic Salary", basicSalary),
            ("House Rent Allowance", hra),
            ("Special Allowance", specialAllowance)
        ]

        for (index, item) in earningItems.enumerated() {
            let y = 275 + (CGFloat(index) * CGFloat(25))

            item.0.draw(
                with: CGRect(x: 60, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: createLeftAlignedTextAttributes(textFont),
                context: nil
            )

            String(format: "%.2f", item.1).draw(
                with: CGRect(x: 50 + columnWidth + 10, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: createRightAlignedTextAttributes(textFont),
                context: nil
            )
        }
    }

    private func drawDeductionsTable(context: UIGraphicsPDFRendererContext, providentFund: Double, professionalTax: Double, incomeTax: Double, headerFont: UIFont, textFont: UIFont) {
        let columnWidth: CGFloat = 125.0

        // Deductions Header
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: 220, width: 2 * columnWidth, height: 30))

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        "DEDUCTIONS".draw(
            with: CGRect(x: 50 + (2 * columnWidth) + 20, y: 220, width: 2 * columnWidth, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: headerAttributes,
            context: nil
        )

        // Column Headers
        UIColor.lightGray.withAlphaComponent(0.3).setFill()
        context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: 250, width: columnWidth, height: 25))
        context.fill(CGRect(x: 50 + (3 * columnWidth) + 20, y: 250, width: columnWidth, height: 25))

        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
        ]

        "Description".draw(
            with: CGRect(x: 60 + (2 * columnWidth) + 20, y: 250, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        let rightColumnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]

        "Amount (₹)".draw(
            with: CGRect(x: 50 + (3 * columnWidth) + 30, y: 250, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: rightColumnHeaderAttributes,
            context: nil
        )

        // Deduction Rows
        let deductionItems = [
            ("Provident Fund", providentFund),
            ("Professional Tax", professionalTax),
            ("Income Tax", incomeTax)
        ]

        for (index, item) in deductionItems.enumerated() {
            let y = 275 + (CGFloat(index) * CGFloat(25))

            item.0.draw(
                with: CGRect(x: 60 + (2 * columnWidth) + 20, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: createLeftAlignedTextAttributes(textFont),
                context: nil
            )

            String(format: "%.2f", item.1).draw(
                with: CGRect(x: 50 + (3 * columnWidth) + 30, y: y, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: createRightAlignedTextAttributes(textFont),
                context: nil
            )
        }
    }

    private func drawTotalsSection(context: UIGraphicsPDFRendererContext, totalEarnings: Double, totalDeductions: Double, headerFont: UIFont) {
        let columnWidth: CGFloat = 125.0
        let cgContext = context.cgContext

        // Total Lines
        cgContext.move(to: CGPoint(x: 50, y: 350))
        cgContext.addLine(to: CGPoint(x: 50 + (2 * columnWidth), y: 350))
        cgContext.strokePath()

        cgContext.move(to: CGPoint(x: 50 + (2 * columnWidth) + 20, y: 350))
        cgContext.addLine(to: CGPoint(x: 50 + (4 * columnWidth) + 20, y: 350))
        cgContext.strokePath()

        let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
        ]

        let rightColumnHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]

        // Total Earnings
        "Total Earnings".draw(
            with: CGRect(x: 60, y: 360, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        String(format: "%.2f", totalEarnings).draw(
            with: CGRect(x: 50 + columnWidth + 10, y: 360, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: rightColumnHeaderAttributes,
            context: nil
        )

        // Total Deductions
        "Total Deductions".draw(
            with: CGRect(x: 60 + (2 * columnWidth) + 20, y: 360, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: columnHeaderAttributes,
            context: nil
        )

        String(format: "%.2f", totalDeductions).draw(
            with: CGRect(x: 50 + (3 * columnWidth) + 30, y: 360, width: columnWidth - 20, height: 25),
            options: .usesLineFragmentOrigin,
            attributes: rightColumnHeaderAttributes,
            context: nil
        )

        // Net Pay
        let netPayY = 400
        UIColor.darkGray.setFill()
        context.fill(CGRect(x: 150, y: netPayY, width: 300, height: 40))

        let netPayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16.0, weight: .bold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        let netPay = totalEarnings - totalDeductions
        "NET PAY: ₹\(String(format: "%.2f", netPay))".draw(
            with: CGRect(x: 150, y: netPayY, width: 300, height: 40),
            options: .usesLineFragmentOrigin,
            attributes: netPayAttributes,
            context: nil
        )
    }

    private func drawCorporateFooter(context: UIGraphicsPDFRendererContext) {
        let smallFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
        let footerY = 791.8 // A4 height minus margin

        UIColor.lightGray.setFill()
        context.fill(CGRect(x: 50, y: footerY, width: 495.2, height: 1))

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: createCenterAlignedParagraphStyle()
        ]

        "This is a test payslip generated for testing purposes only. Not valid for financial transactions.".draw(
            with: CGRect(x: 50, y: footerY + 10, width: 495.2, height: 30),
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

    private func createCenterAlignedParagraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }

    private func createLeftAlignedTextAttributes(_ font: UIFont) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createLeftAlignedParagraphStyle()
        ]
    }

    private func createRightAlignedTextAttributes(_ font: UIFont) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: createRightAlignedParagraphStyle()
        ]
    }
}
