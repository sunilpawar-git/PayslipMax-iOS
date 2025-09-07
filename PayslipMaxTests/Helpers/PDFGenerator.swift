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
            kCGPDFContextCreator: "PayslipMax Defense Test Generator",
            kCGPDFContextAuthor: serviceName,
            kCGPDFContextTitle: "Defense Payslip Test Document"
        ]
    }

}
