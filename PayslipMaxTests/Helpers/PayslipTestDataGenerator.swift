import Foundation
import PDFKit
@testable import PayslipMax

/// A facade for payslip-related test data generation
/// Delegates to specialized generators to maintain architectural principles
class PayslipTestDataGenerator {

    // MARK: - Factory

    private static let factory: PayslipTestDataFactory = DefaultPayslipTestDataFactory()

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
        let params = MilitaryPayslipParams(
            id: id,
            month: month,
            year: year,
            rank: rank,
            name: name,
            serviceNumber: serviceNumber,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            includeAllowances: includeAllowances
        )
        return BasicPayslipGenerator.standardMilitaryPayslip(params: params)
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
        let params = PCDAPayslipParams(
            id: id,
            month: month,
            year: year,
            name: name,
            serviceNumber: serviceNumber,
            basicPay: basicPay,
            msp: msp,
            da: da,
            dsop: dsop,
            incomeTax: incomeTax
        )
        return BasicPayslipGenerator.standardPCDAPayslip(params: params)
    }

    // MARK: - Specialized Data Generation

    /// Creates a payslip with anomalies for testing edge cases
    static func anomalousPayslip(anomalyType: AnomalyType) -> PayslipItem {
        return EdgeCaseGenerator.anomalousPayslip(anomalyType: anomalyType)
    }

    /// Creates a collection of payslips with varied date ranges
    static func payslipTimeSeriesData(
        startMonth: Int = 1,
        startYear: Int = 2022,
        count: Int = 12,
        baseCredits: Double = 5000.0,
        incrementAmount: Double = 200.0
    ) -> [PayslipItem] {
        return ComplexPayslipGenerator.payslipTimeSeriesData(
            startMonth: startMonth,
            startYear: startYear,
            count: count,
            baseCredits: baseCredits,
            incrementAmount: incrementAmount
        )
    }

    /// Creates a set of payslips with various allowances and deductions
    static func detailedPayslipWithBreakdown(
        name: String = "James Wilson",
        month: String = "September",
        year: Int = 2023
    ) -> PayslipItem {
        return ComplexPayslipGenerator.detailedPayslipWithBreakdown(
            name: name,
            month: month,
            year: year
        )
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
        let params = PayslipPDFParams(
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
        return BasicPayslipGenerator.militaryPayslipPDF(params: params)
    }

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
        let params = CorporatePayslipPDFParams(
            name: name,
            employeeId: employeeId,
            department: department,
            designation: designation,
            month: month,
            year: year,
            basicSalary: basicSalary,
            hra: hra,
            specialAllowance: specialAllowance,
            totalEarnings: totalEarnings,
            providentFund: providentFund,
            professionalTax: professionalTax,
            incomeTax: incomeTax,
            totalDeductions: totalDeductions
        )
        return PDFGenerator.corporatePayslipPDF(params: params)
    }

    // MARK: - Enums
    // Note: AnomalyType is defined in EdgeCaseGenerator.swift
}
