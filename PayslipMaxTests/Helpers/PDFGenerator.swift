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

    /// Creates a defense payslip PDF for testing (Army, Navy, Air Force, PCDA formats)
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

    func createDefensePayslipPDF(
        serviceBranch: DefenseServiceBranch = .army,
        name: String = "Capt. Rajesh Kumar",
        rank: String = "Captain",
        serviceNumber: String = "IC-12345",
        month: String = "January",
        year: Int = 2024,
        basicPay: Double = 56100.0,
        msp: Double = 15500.0,
        da: Double = 5610.0,
        dsop: Double = 1200.0,
        agif: Double = 150.0,
        incomeTax: Double = 2800.0
    ) -> PDFDocument {
        // Create defense payslip using military generator with service-specific formatting
        return militaryGenerator.createSamplePayslipPDF(
            name: name, rank: rank, id: serviceNumber, month: month, year: year,
            credits: basicPay + msp + da,  // Total earnings
            debits: dsop + agif,           // Total deductions before tax
            dsop: dsop,
            tax: incomeTax
        )
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
    ) -> PDFDocument {
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
            "Name: \(name)".draw(
                with: CGRect(x: 50, y: 100, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Employee ID: \(employeeId)".draw(
                with: CGRect(x: 50, y: 120, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Department: \(department)".draw(
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

            String(format: "₹%.2f", basicSalary).draw(
                with: CGRect(x: 400, y: 180, width: 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: textFont, .foregroundColor: UIColor.black],
                context: nil
            )

            // Add more earnings and deductions as needed...
            "Total Earnings: ₹\(String(format: "%.2f", totalEarnings))".draw(
                with: CGRect(x: 50, y: 220, width: 300, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: headerFont, .foregroundColor: UIColor.black],
                context: nil
            )

            "Total Deductions: ₹\(String(format: "%.2f", totalDeductions))".draw(
                with: CGRect(x: 50, y: 250, width: 300, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: [.font: headerFont, .foregroundColor: UIColor.black],
                context: nil
            )

            let netPay = totalEarnings - totalDeductions
            "Net Pay: ₹\(String(format: "%.2f", netPay))".draw(
                with: CGRect(x: 50, y: 280, width: 300, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: [.font: titleFont, .foregroundColor: UIColor.black],
                context: nil
            )
        }

        return PDFDocument(data: pdfData)!
    }

}
