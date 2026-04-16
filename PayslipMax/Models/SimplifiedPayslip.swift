import Foundation
import SwiftData

/// Simplified payslip model focused on essential financial insights
/// Replaces complex 243-code parsing with user-centric value proposition:
/// - Core earnings: BPAY, DA, MSP
/// - Core deductions: DSOP, AGIF, Income Tax
/// - Calculated miscellaneous amounts
/// - User-editable breakdowns for edge cases
/// - Confidence scoring for data quality
@Model
final class SimplifiedPayslip: Identifiable, Codable {

    // MARK: - Identity & Timestamp

    @Attribute(.unique) var id: UUID
    var timestamp: Date

    // MARK: - Basic Information

    /// Name of the payslip recipient
    var name: String

    /// Month of the payslip (e.g., "August", "अगस्त")
    var month: String

    /// Year of the payslip
    var year: Int

    // MARK: - Core Earnings (Individually Parsed)

    /// Basic Pay (BPAY) - Foundation of all calculations
    var basicPay: Double

    /// Dearness Allowance (DA) - Typically 40-65% of Basic Pay
    var dearnessAllowance: Double

    /// Military Service Pay (MSP) - Fixed allowance (₹15,500 standard)
    var militaryServicePay: Double

    /// Other Earnings - Calculated: Gross Pay - (BPAY + DA + MSP)
    /// Includes all other allowances: RH, HRA, CEA, TPTA, etc.
    var otherEarnings: Double

    /// Gross Pay - Total earnings before deductions
    var grossPay: Double

    // MARK: - Core Deductions (Individually Parsed)

    /// Defence Services Officers Provident Fund (DSOP)
    var dsop: Double

    /// Army Group Insurance Fund (AGIF)
    var agif: Double

    /// Income Tax (ITAX/IT)
    var incomeTax: Double

    /// Other Deductions - Calculated: Total Deductions - (DSOP + AGIF + Tax)
    /// Includes EHCESS, PF, GPF, and miscellaneous deductions
    var otherDeductions: Double

    /// Total Deductions - Sum of all deductions
    var totalDeductions: Double

    // MARK: - Final Value

    /// Net Remittance - Take-home pay (Gross Pay - Total Deductions)
    var netRemittance: Double

    // MARK: - User-Editable Breakdowns

    /// Breakdown of "Other Earnings" by pay code
    /// User can manually add/edit codes like ["RH12": 21125, "CEA": 5000]
    var otherEarningsBreakdown: [String: Double]

    /// Breakdown of "Other Deductions" by pay code
    /// User can manually add/edit codes like ["EHCESS": 1905, "GPF": 3000]
    var otherDeductionsBreakdown: [String: Double]

    // MARK: - Confidence & Metadata

    /// Parsing confidence score (0.0 to 1.0)
    /// - 0.9-1.0: Excellent (all validations passed)
    /// - 0.75-0.89: Good (minor discrepancies)
    /// - 0.5-0.74: Review recommended (validation warnings)
    /// - <0.5: Manual verification required
    var parsingConfidence: Double

    /// Original PDF data
    var pdfData: Data?

    /// Source of the payslip (e.g., "PDF Upload", "Web Upload", "Manual Entry")
    var source: String

    /// Whether user has manually edited the breakdown
    var isEdited: Bool

    // MARK: - Computed Properties

    /// Investment Returns - DSOP + AGIF (reframed as future wealth)
    var investmentReturns: Double {
        return dsop + agif
    }

    /// True Net Earnings - Net Remittance + Investment Returns
    /// Shows total value including money going to user's future wealth
    var trueNetEarnings: Double {
        return netRemittance + investmentReturns
    }

    /// Display name for the payslip (e.g., "August 2025")
    var displayName: String {
        return "\(month) \(year)"
    }

    // MARK: - Initialization

    /// Full initializer with all properties
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        name: String,
        month: String,
        year: Int,
        basicPay: Double,
        dearnessAllowance: Double,
        militaryServicePay: Double,
        otherEarnings: Double,
        grossPay: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double,
        otherDeductions: Double,
        totalDeductions: Double,
        netRemittance: Double,
        otherEarningsBreakdown: [String: Double] = [:],
        otherDeductionsBreakdown: [String: Double] = [:],
        parsingConfidence: Double = 0.0,
        pdfData: Data? = nil,
        source: String = "PDF Upload",
        isEdited: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.month = month
        self.year = year
        self.basicPay = basicPay
        self.dearnessAllowance = dearnessAllowance
        self.militaryServicePay = militaryServicePay
        self.otherEarnings = otherEarnings
        self.grossPay = grossPay
        self.dsop = dsop
        self.agif = agif
        self.incomeTax = incomeTax
        self.otherDeductions = otherDeductions
        self.totalDeductions = totalDeductions
        self.netRemittance = netRemittance
        self.otherEarningsBreakdown = otherEarningsBreakdown
        self.otherDeductionsBreakdown = otherDeductionsBreakdown
        self.parsingConfidence = parsingConfidence
        self.pdfData = pdfData
        self.source = source
        self.isEdited = isEdited
    }
}
