import Foundation
import PDFKit

// MARK: - Parsing Models
// Models used in the payslip parsing system

/// Represents the confidence level of a parsing result
enum ParsingConfidence: Int, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    
    static func < (lhs: ParsingConfidence, rhs: ParsingConfidence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Represents a parsing result with confidence level
struct ParsingResult {
    let payslipItem: PayslipItem
    let confidence: ParsingConfidence
    let parserName: String
    
    init(payslipItem: PayslipItem, confidence: ParsingConfidence, parserName: String) {
        self.payslipItem = payslipItem
        self.confidence = confidence
        self.parserName = parserName
    }
}

/// Represents personal details extracted from a payslip
struct PersonalDetails {
    var name: String = ""
    var accountNumber: String = ""
    var panNumber: String = ""
    var month: String = ""
    var year: String = ""
    var location: String = ""
}

/// Represents income tax details extracted from a payslip
struct IncomeTaxDetails {
    var totalTaxableIncome: Double = 0
    var standardDeduction: Double = 0
    var netTaxableIncome: Double = 0
    var totalTaxPayable: Double = 0
    var incomeTaxDeducted: Double = 0
    var educationCessDeducted: Double = 0
}

/// Represents DSOP fund details extracted from a payslip
struct DSOPFundDetails {
    var openingBalance: Double = 0
    var subscription: Double = 0
    var miscAdjustment: Double = 0
    var withdrawal: Double = 0
    var refund: Double = 0
    var closingBalance: Double = 0
}

/// Represents a contact person extracted from a payslip
struct ContactPerson {
    var designation: String
    var name: String
    var phoneNumber: String
}

/// Represents contact details extracted from a payslip
struct ContactDetails {
    var contactPersons: [ContactPerson] = []
    var emails: [String] = []
    var website: String = ""
}

/// Protocol for payslip parsers
protocol PayslipParser {
    /// Name of the parser for identification
    var name: String { get }
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem?
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence
} 