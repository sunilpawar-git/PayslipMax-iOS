import Foundation
import PDFKit

// MARK: - Parsing Models
// Models used in the payslip parsing system

/// Represents the confidence level of a parsing result
enum ParsingConfidence: Int, Comparable, Codable {
    /// Low confidence, parsing may have significant errors.
    case low = 0
    /// Medium confidence, parsing is likely correct but may have minor inaccuracies.
    case medium = 1
    /// High confidence, parsing is very likely accurate.
    case high = 2

    static func < (lhs: ParsingConfidence, rhs: ParsingConfidence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Represents a parsing result with confidence level
struct ParsingResult {
    /// The parsed `PayslipItem` object.
    let payslipItem: PayslipItem
    /// The confidence level of the parsing result.
    let confidence: ParsingConfidence
    /// The name of the parser that produced this result.
    let parserName: String

    /// Initializes a new parsing result.
    /// - Parameters:
    ///   - payslipItem: The parsed payslip item.
    ///   - confidence: The confidence level.
    ///   - parserName: The name of the parser.
    init(payslipItem: PayslipItem, confidence: ParsingConfidence, parserName: String) {
        self.payslipItem = payslipItem
        self.confidence = confidence
        self.parserName = parserName
    }
}

/// Represents personal details extracted from a payslip
struct PersonalDetails {
    /// Name of the payslip owner.
    var name: String = ""
    /// Account number associated with the payslip.
    var accountNumber: String = ""
    /// PAN (Permanent Account Number) of the owner.
    var panNumber: String = ""
    /// The month the payslip pertains to.
    var month: String = ""
    /// The year the payslip pertains to.
    var year: String = ""
    /// Posting location mentioned in the payslip.
    var location: String = ""
}

/// Represents income tax details extracted from a payslip
struct IncomeTaxDetails {
    /// Total income subject to taxation.
    var totalTaxableIncome: Double = 0
    /// Standard deduction applied.
    var standardDeduction: Double = 0
    /// Net income after deductions, used for tax calculation.
    var netTaxableIncome: Double = 0
    /// Total tax amount calculated as payable.
    var totalTaxPayable: Double = 0
    /// Amount of income tax actually deducted in this payslip.
    var incomeTaxDeducted: Double = 0
    /// Amount of education cess deducted.
    var educationCessDeducted: Double = 0
}

/// Represents DSOP fund details extracted from a payslip
struct DSOPFundDetails {
    /// Opening balance of the DSOP fund for the period.
    var openingBalance: Double = 0
    /// Subscription/contribution amount for the period.
    var subscription: Double = 0
    /// Any miscellaneous adjustments to the fund.
    var miscAdjustment: Double = 0
    /// Amount withdrawn from the fund during the period.
    var withdrawal: Double = 0
    /// Any refund amount credited to the fund.
    var refund: Double = 0
    /// Closing balance of the DSOP fund for the period.
    var closingBalance: Double = 0
}

/// Represents a contact person extracted from a payslip
struct ContactPerson {
    /// Designation or title of the contact person.
    var designation: String
    /// Name of the contact person.
    var name: String
    /// Phone number of the contact person.
    var phoneNumber: String
}

/// Represents contact details extracted from a payslip
struct ContactDetails {
    /// List of contact persons mentioned.
    var contactPersons: [ContactPerson] = []
    /// List of email addresses found.
    var emails: [String] = []
    /// Website URL found.
    var website: String = ""
}

// NOTE: The PayslipParser protocol has been moved to Protocols/PayslipParserProtocol.swift

// MARK: - Parser Result Models

/// Result object for parsing attempts
struct ParseAttemptResult {
    /// Name of the parser used for the attempt.
    let parserName: String
    /// Indicates whether the parsing was considered successful.
    let success: Bool
    /// The confidence level of the result, if successful.
    let confidence: ParsingConfidence?
    /// The error encountered, if parsing failed.
    let error: Error?
    /// The time taken for the parsing attempt.
    let processingTime: TimeInterval
}
