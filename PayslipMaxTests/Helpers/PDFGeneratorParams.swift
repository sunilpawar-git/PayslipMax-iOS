import Foundation
@testable import PayslipMax

// MARK: - Parameter Structs for PDF Generation

/// Parameters for creating a sample payslip PDF
struct PayslipPDFParams {
    let name: String
    let rank: String
    let id: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double

    static let `default` = PayslipPDFParams(
        name: "John Doe",
        rank: "Captain",
        id: "ID123456",
        month: "January",
        year: 2023,
        credits: 5000.0,
        debits: 1000.0,
        dsop: 300.0,
        tax: 800.0
    )
}

/// Parameters for creating a defense payslip PDF
struct DefensePayslipPDFParams {
    let serviceBranch: DefenseServiceBranch
    let name: String
    let rank: String
    let serviceNumber: String
    let month: String
    let year: Int
    let basicPay: Double
    let msp: Double
    let da: Double
    let dsop: Double
    let agif: Double
    let incomeTax: Double

    static let `default` = DefensePayslipPDFParams(
        serviceBranch: .army,
        name: "Capt. Rajesh Kumar",
        rank: "Captain",
        serviceNumber: "IC-12345",
        month: "January",
        year: 2024,
        basicPay: 56100.0,
        msp: 15500.0,
        da: 5610.0,
        dsop: 1200.0,
        agif: 150.0,
        incomeTax: 2800.0
    )

    /// Computed total credits (earnings)
    var totalCredits: Double {
        basicPay + msp + da
    }

    /// Computed total debits (deductions before tax)
    var totalDebits: Double {
        dsop + agif
    }
}

/// Parameters for creating a corporate payslip PDF
struct CorporatePayslipPDFParams {
    let name: String
    let employeeId: String
    let department: String
    let designation: String
    let month: String
    let year: Int
    let basicSalary: Double
    let hra: Double
    let specialAllowance: Double
    let totalEarnings: Double
    let providentFund: Double
    let professionalTax: Double
    let incomeTax: Double
    let totalDeductions: Double

    static let `default` = CorporatePayslipPDFParams(
        name: "John Doe",
        employeeId: "EMP001",
        department: "Engineering",
        designation: "Software Engineer",
        month: "January",
        year: 2024,
        basicSalary: 50000.0,
        hra: 20000.0,
        specialAllowance: 10000.0,
        totalEarnings: 80000.0,
        providentFund: 6000.0,
        professionalTax: 200.0,
        incomeTax: 5000.0,
        totalDeductions: 11200.0
    )

    /// Computed net pay
    var netPay: Double {
        totalEarnings - totalDeductions
    }
}

/// Parameters for creating a defense payslip data item
struct DefensePayslipDataParams {
    let serviceBranch: DefenseServiceBranch
    let name: String
    let rank: String
    let serviceNumber: String
    let month: String
    let year: Int
    let basicPay: Double
    let msp: Double
    let da: Double
    let dsop: Double
    let agif: Double
    let incomeTax: Double

    static let `default` = DefensePayslipDataParams(
        serviceBranch: .army,
        name: "Capt. Rajesh Kumar",
        rank: "Captain",
        serviceNumber: "IC-12345",
        month: "January",
        year: 2024,
        basicPay: 56100.0,
        msp: 15500.0,
        da: 5610.0,
        dsop: 1200.0,
        agif: 150.0,
        incomeTax: 2800.0
    )

    /// Computed total credits
    var totalCredits: Double {
        basicPay + msp + da
    }

    /// Computed total debits
    var totalDebits: Double {
        dsop + agif + incomeTax
    }
}

/// Parameters for creating a PayslipItem
struct PayslipItemParams {
    let id: UUID
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
    let name: String
    let accountNumber: String
    let panNumber: String

    static let `default` = PayslipItemParams(
        id: UUID(),
        month: "January",
        year: 2023,
        credits: 5000.0,
        debits: 1000.0,
        dsop: 300.0,
        tax: 800.0,
        name: "John Doe",
        accountNumber: "XXXX1234",
        panNumber: "ABCDE1234F"
    )
}

/// Parameters for creating a military payslip
struct MilitaryPayslipParams {
    let id: UUID
    let month: String
    let year: Int
    let rank: String
    let name: String
    let serviceNumber: String
    let credits: Double
    let debits: Double
    let dsop: Double
    let tax: Double
    let includeAllowances: Bool

    static let `default` = MilitaryPayslipParams(
        id: UUID(),
        month: "January",
        year: 2023,
        rank: "Major",
        name: "John Doe",
        serviceNumber: "MIL123456",
        credits: 85000.0,
        debits: 15000.0,
        dsop: 6000.0,
        tax: 25000.0,
        includeAllowances: true
    )
}

/// Parameters for creating a PCDA payslip
struct PCDAPayslipParams {
    let id: UUID
    let month: String
    let year: Int
    let name: String
    let serviceNumber: String
    let basicPay: Double
    let msp: Double
    let da: Double
    let dsop: Double
    let incomeTax: Double

    static let `default` = PCDAPayslipParams(
        id: UUID(),
        month: "January",
        year: 2023,
        name: "Major Jane Smith",
        serviceNumber: "PCDA123456",
        basicPay: 67700.0,
        msp: 15500.0,
        da: 4062.0,
        dsop: 6770.0,
        incomeTax: 15000.0
    )

    /// Computed credits (earnings)
    var credits: Double {
        basicPay + msp + da
    }
}

