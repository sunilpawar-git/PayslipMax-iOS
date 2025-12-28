import Foundation
import PDFKit
@testable import PayslipMax

/// Protocol for basic payslip generation operations
protocol BasicPayslipGeneratorProtocol {
    /// Creates a standard military payslip for testing using parameter struct
    static func standardMilitaryPayslip(params: MilitaryPayslipParams) -> PayslipItem

    /// Creates a PCDA payslip for testing defense personnel using parameter struct
    static func standardPCDAPayslip(params: PCDAPayslipParams) -> PayslipItem

    /// Creates a military payslip PDF for testing using parameter struct
    static func militaryPayslipPDF(params: PayslipPDFParams) -> PDFDocument
}

/// A generator for basic payslip-related test data
class BasicPayslipGenerator: BasicPayslipGeneratorProtocol {

    // MARK: - Standard Payslip Data Generation

    /// Creates a standard military payslip for testing using parameter struct
    static func standardMilitaryPayslip(params: MilitaryPayslipParams = .default) -> PayslipItem {
        let payslip = PayslipItem(
            id: params.id,
            month: params.month,
            year: params.year,
            credits: params.credits,
            debits: params.debits,
            dsop: params.dsop,
            tax: params.tax,
            name: params.name,
            accountNumber: "XXXX5678",
            panNumber: "ABCDE1234F"
        )

        // Note: Military-specific metadata would be set here if PayslipItem conformed to MilitaryPayslipRepresentable
        // For now, we return the base PayslipItem as military payslips are handled by MilitaryPayslipGenerator

        return payslip
    }

    /// Creates a PCDA payslip for testing defense personnel using parameter struct
    static func standardPCDAPayslip(params: PCDAPayslipParams = .default) -> PayslipItem {
        let payslip = PayslipItem(
            id: params.id,
            month: params.month,
            year: params.year,
            credits: params.credits,
            debits: params.dsop,
            dsop: params.dsop,  // PCDA payslips include DSOP
            tax: params.incomeTax,
            name: params.name,
            accountNumber: "XXXX4321",
            panNumber: "FGHIJ5678K"
        )

        // Note: PCDA-specific metadata would be set here if needed

        return payslip
    }

    // MARK: - PDF Generation

    /// Creates a military payslip PDF for testing using parameter struct
    static func militaryPayslipPDF(params: PayslipPDFParams = .default) -> PDFDocument {
        // Utilize the core PDF generation capability from the main test data generator
        let defenseParams = DefensePayslipPDFParams(
            serviceBranch: .army,
            name: params.name,
            rank: params.rank,
            serviceNumber: params.id,
            month: params.month,
            year: params.year,
            basicPay: params.credits,
            msp: params.debits,
            da: 5610.0,
            dsop: params.dsop,
            agif: 150.0,
            incomeTax: params.tax
        )
        return TestDataGenerator.samplePayslipPDF(params: defenseParams)
    }

    // MARK: - Helper Methods

    /// Generate a random set of military allowances
    private static func generateMilitaryAllowances() -> [String: Double] {
        return [
            "Field Area Allowance": 3000.0,
            "Transport Allowance": 1500.0,
            "Uniform Allowance": 2000.0,
            "Ration Allowance": 1000.0,
            "Housing Allowance": 5000.0
        ]
    }
}
