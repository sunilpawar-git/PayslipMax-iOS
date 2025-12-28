import Foundation
import PDFKit
@testable import PayslipMax

/// Protocol for generating PDF documents for testing
protocol PDFGeneratorProtocol {
    /// Creates a sample PDF document with text for testing
    func createSamplePDFDocument(withText text: String) -> PDFDocument

    /// Creates a sample payslip PDF for testing using parameter struct
    func createSamplePayslipPDF(params: PayslipPDFParams) -> PDFDocument

    /// Creates a PDF with image content for testing (simulated scanned content)
    func createPDFWithImage() -> Data

    /// Creates a multi-page PDF for testing large documents
    func createMultiPagePDF(pageCount: Int) -> Data

    /// Creates a PDF with table content for testing
    func createPDFWithTable() -> Data

    /// Creates a defense payslip PDF for testing using parameter struct
    func createDefensePayslipPDF(params: DefensePayslipPDFParams) -> PDFDocument
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

    func createSamplePayslipPDF(params: PayslipPDFParams = .default) -> PDFDocument {
        return militaryGenerator.createSamplePayslipPDF(params: params)
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

    func createDefensePayslipPDF(params: DefensePayslipPDFParams = .default) -> PDFDocument {
        // Create defense payslip using military generator with service-specific formatting
        let payslipParams = PayslipPDFParams(
            name: params.name,
            rank: params.rank,
            id: params.serviceNumber,
            month: params.month,
            year: params.year,
            credits: params.totalCredits,
            debits: params.totalDebits,
            dsop: params.dsop,
            tax: params.incomeTax
        )
        return militaryGenerator.createSamplePayslipPDF(params: payslipParams)
    }

    // MARK: - Defense-Specific Helper Methods

    /// Creates metadata for defense payslip PDFs
    private func createDefensePDFMetadata(for serviceBranch: DefenseServiceBranch) -> [String: Any] {
        let serviceName: String
        switch serviceBranch {
        case .army: serviceName = "Indian Army"
        case .navy: serviceName = "Indian Navy"
        case .airForce: serviceName = "Indian Air Force"
        case .pcda: serviceName = "PCDA"
        }

        return [
            kCGPDFContextCreator as String: "PayslipMax Defense Test Generator",
            kCGPDFContextAuthor as String: serviceName,
            kCGPDFContextTitle as String: "Defense Payslip Test Document"
        ]
    }

    // MARK: - Static Corporate PDF Generation

    /// Creates a corporate payslip PDF for testing using parameter struct
    static func corporatePayslipPDF(params: CorporatePayslipPDFParams = .default) -> PDFDocument {
        let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "PayslipMax Corporate Test Generator",
            kCGPDFContextAuthor as String: "Corporate HR",
            kCGPDFContextTitle as String: "Corporate Payslip Test Document"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: defaultPageRect, format: format)

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)

            // Draw title
            "CORPORATE PAYSLIP".draw(
                with: CGRect(x: 50, y: 50, width: 495, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: [.font: titleFont, .foregroundColor: UIColor.black],
                context: nil
            )

            // Draw employee info
            "Name: \(params.name)".draw(
                with: CGRect(x: 50, y: 100, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Employee ID: \(params.employeeId)".draw(
                with: CGRect(x: 50, y: 120, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Department: \(params.department)".draw(
                with: CGRect(x: 50, y: 140, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            // Draw earnings table
            "Basic Salary".draw(
                with: CGRect(x: 50, y: 180, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: headerFont, .foregroundColor: UIColor.black],
                context: nil
            )

            String(format: "₹%.2f", params.basicSalary).draw(
                with: CGRect(x: 400, y: 180, width: 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            // Add more earnings and deductions as needed...
            "Total Earnings: ₹\(String(format: "%.2f", params.totalEarnings))".draw(
                with: CGRect(x: 50, y: 220, width: 300, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: headerFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Total Deductions: ₹\(String(format: "%.2f", params.totalDeductions))".draw(
                with: CGRect(x: 50, y: 250, width: 300, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: headerFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Net Pay: ₹\(String(format: "%.2f", params.netPay))".draw(
                with: CGRect(x: 50, y: 280, width: 300, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: [.font: titleFont, .foregroundColor: UIColor.black],
                context: nil
            )
        }

        return PDFDocument(data: pdfData)!
    }

}
