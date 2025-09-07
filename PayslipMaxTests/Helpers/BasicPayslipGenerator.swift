import Foundation
import PDFKit
@testable import PayslipMax

/// Protocol for basic payslip generation operations
protocol BasicPayslipGeneratorProtocol {
    /// Creates a standard military payslip for testing
    static func standardMilitaryPayslip(
        id: UUID,
        month: String,
        year: Int,
        rank: String,
        name: String,
        serviceNumber: String,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        includeAllowances: Bool
    ) -> PayslipItem

    /// Creates a PCDA payslip for testing defense personnel
    static func standardPCDAPayslip(
        id: UUID,
        month: String,
        year: Int,
        name: String,
        serviceNumber: String,
        basicPay: Double,
        msp: Double,
        da: Double,
        dsop: Double,
        incomeTax: Double
    ) -> PayslipItem

    /// Creates a military payslip PDF for testing
    static func militaryPayslipPDF(
        name: String,
        rank: String,
        serviceNumber: String,
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double
    ) -> PDFDocument
}

/// A generator for basic payslip-related test data
class BasicPayslipGenerator: BasicPayslipGeneratorProtocol {

    // MARK: - Standard Payslip Data Generation

    /// Creates a standard military payslip for testing
    static func standardMilitaryPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        rank: String = "Major",
        name: String = "John Doe",
        serviceNumber: String = "MIL123456",
        credits: Double = 85000.0,
        debits: Double = 15000.0,
        dsop: Double = 6000.0,
        tax: Double = 25000.0,
        includeAllowances: Bool = true
    ) -> PayslipItem {
        let payslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: "XXXX5678",
            panNumber: "ABCDE1234F"
        )

        // Note: Military-specific metadata would be set here if PayslipItem conformed to MilitaryPayslipRepresentable
        // For now, we return the base PayslipItem as military payslips are handled by MilitaryPayslipGenerator

        return payslip
    }

    /// Creates a PCDA payslip for testing defense personnel
    static func standardPCDAPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        name: String = "Major Jane Smith",
        serviceNumber: String = "PCDA123456",
        basicPay: Double = 67700.0,
        msp: Double = 15500.0,
        da: Double = 4062.0,
        dsop: Double = 6770.0,
        incomeTax: Double = 15000.0
    ) -> PayslipItem {
        // PCDA payslip fields
        let credits = basicPay + msp + da
        let debits = dsop
        let tax = incomeTax

        let payslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,  // PCDA payslips include DSOP
            tax: tax,
            name: name,
            accountNumber: "XXXX4321",
            panNumber: "FGHIJ5678K"
        )

        // Note: PCDA-specific metadata would be set here if needed

        return payslip
    }

    // MARK: - PDF Generation

    /// Creates a military payslip PDF for testing
    static func militaryPayslipPDF(
        name: String = "John Doe",
        rank: String = "Major",
        serviceNumber: String = "MIL123456",
        month: String = "January",
        year: Int = 2023,
        credits: Double = 85000.0,
        debits: Double = 15000.0,
        dsop: Double = 6000.0,
        tax: Double = 25000.0
    ) -> PDFDocument {
        // Utilize the core PDF generation capability from the main test data generator
        return TestDataGenerator.samplePayslipPDF(
            name: name,
            rank: rank,
            id: serviceNumber,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax
        )
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
