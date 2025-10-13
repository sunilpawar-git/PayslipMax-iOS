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

    // MARK: - Codable Implementation

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case name
        case month
        case year
        case basicPay
        case dearnessAllowance
        case militaryServicePay
        case otherEarnings
        case grossPay
        case dsop
        case agif
        case incomeTax
        case otherDeductions
        case totalDeductions
        case netRemittance
        case otherEarningsBreakdown
        case otherDeductionsBreakdown
        case parsingConfidence
        case pdfData
        case source
        case isEdited
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.name = try container.decode(String.self, forKey: .name)
        self.month = try container.decode(String.self, forKey: .month)
        self.year = try container.decode(Int.self, forKey: .year)
        self.basicPay = try container.decode(Double.self, forKey: .basicPay)
        self.dearnessAllowance = try container.decode(Double.self, forKey: .dearnessAllowance)
        self.militaryServicePay = try container.decode(Double.self, forKey: .militaryServicePay)
        self.otherEarnings = try container.decode(Double.self, forKey: .otherEarnings)
        self.grossPay = try container.decode(Double.self, forKey: .grossPay)
        self.dsop = try container.decode(Double.self, forKey: .dsop)
        self.agif = try container.decode(Double.self, forKey: .agif)
        self.incomeTax = try container.decode(Double.self, forKey: .incomeTax)
        self.otherDeductions = try container.decode(Double.self, forKey: .otherDeductions)
        self.totalDeductions = try container.decode(Double.self, forKey: .totalDeductions)
        self.netRemittance = try container.decode(Double.self, forKey: .netRemittance)
        self.otherEarningsBreakdown = try container.decode([String: Double].self, forKey: .otherEarningsBreakdown)
        self.otherDeductionsBreakdown = try container.decode([String: Double].self, forKey: .otherDeductionsBreakdown)
        self.parsingConfidence = try container.decode(Double.self, forKey: .parsingConfidence)
        self.pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        self.source = try container.decode(String.self, forKey: .source)
        self.isEdited = try container.decode(Bool.self, forKey: .isEdited)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(name, forKey: .name)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(basicPay, forKey: .basicPay)
        try container.encode(dearnessAllowance, forKey: .dearnessAllowance)
        try container.encode(militaryServicePay, forKey: .militaryServicePay)
        try container.encode(otherEarnings, forKey: .otherEarnings)
        try container.encode(grossPay, forKey: .grossPay)
        try container.encode(dsop, forKey: .dsop)
        try container.encode(agif, forKey: .agif)
        try container.encode(incomeTax, forKey: .incomeTax)
        try container.encode(otherDeductions, forKey: .otherDeductions)
        try container.encode(totalDeductions, forKey: .totalDeductions)
        try container.encode(netRemittance, forKey: .netRemittance)
        try container.encode(otherEarningsBreakdown, forKey: .otherEarningsBreakdown)
        try container.encode(otherDeductionsBreakdown, forKey: .otherDeductionsBreakdown)
        try container.encode(parsingConfidence, forKey: .parsingConfidence)
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encode(source, forKey: .source)
        try container.encode(isEdited, forKey: .isEdited)
    }
}

// MARK: - Factory Methods

extension SimplifiedPayslip {

    /// Creates a sample payslip for testing and previews
    static func createSample() -> SimplifiedPayslip {
        return SimplifiedPayslip(
            name: "Sunil Suresh Pawar",
            month: "August",
            year: 2025,
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            otherEarnings: 27355, // RH12 + TPTA + TPTADA
            grossPay: 275665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 47624,
            otherDeductions: 2905, // EHCESS + misc
            totalDeductions: 103029,
            netRemittance: 172636,
            otherEarningsBreakdown: [
                "RH12": 21125,
                "TPTA": 3600,
                "TPTADA": 1980,
                "RSHNA": 650
            ],
            otherDeductionsBreakdown: [
                "EHCESS": 1905,
                "MISC": 1000
            ],
            parsingConfidence: 0.95,
            source: "Sample Data",
            isEdited: false
        )
    }
}

