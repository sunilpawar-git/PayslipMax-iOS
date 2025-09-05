import Foundation
import PDFKit
import Darwin  // For memory tracking

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

// MARK: - Telemetry Models

/// Collects telemetry data for parser performance
struct ParserTelemetry: Codable {
    /// Name of the parser being measured.
    let parserName: String
    /// Time taken for the parsing process.
    let processingTime: TimeInterval
    /// Confidence level achieved by the parser.
    let confidence: ParsingConfidence
    /// Indicates if the parsing was successful.
    let success: Bool
    /// Timestamp when the telemetry was recorded.
    let timestamp: Date = Date()
    /// Memory usage recorded during parsing (resident set size).
    let memoryUsage: Int64? // In bytes
    
    // Additional parser-specific metrics
    /// Number of key items successfully extracted.
    let extractedItemCount: Int
    /// Length of the text processed by the parser.
    let textLength: Int
    /// Error message, if parsing failed.
    let errorMessage: String?
    
    /// Initializes parser telemetry data.
    /// - Parameters:
    ///   - parserName: Name of the parser.
    ///   - processingTime: Time taken for parsing.
    ///   - confidence: Confidence level achieved.
    ///   - success: Whether parsing was successful.
    ///   - extractedItemCount: Number of items extracted.
    ///   - textLength: Length of the text processed.
    ///   - errorMessage: Error message if parsing failed.
    init(
        parserName: String,
        processingTime: TimeInterval,
        confidence: ParsingConfidence = .low,
        success: Bool,
        extractedItemCount: Int = 0,
        textLength: Int = 0,
        errorMessage: String? = nil
    ) {
        self.parserName = parserName
        self.processingTime = processingTime
        self.confidence = confidence
        self.success = success
        self.extractedItemCount = extractedItemCount
        self.textLength = textLength
        self.errorMessage = errorMessage
        
        // Get memory usage if available
        self.memoryUsage = ParserTelemetry.getMemoryUsage()
    }
    
    /// Retrieves the current memory usage (resident set size) of the task.
    /// - Returns: Memory usage in bytes, or nil if it cannot be determined.
    private static func getMemoryUsage() -> Int64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : nil
    }
    
    /// Logs the collected telemetry data to the console.
    func logTelemetry() {
        print("[Telemetry] Parser: \(parserName)")
        print("[Telemetry] Time: \(String(format: "%.3f", processingTime))s")
        print("[Telemetry] Success: \(success)")
        if success {
            print("[Telemetry] Confidence: \(confidence)")
        }
        print("[Telemetry] Items extracted: \(extractedItemCount)")
        print("[Telemetry] Text length: \(textLength)")
        if let memory = memoryUsage {
            print("[Telemetry] Memory usage: \(ByteCountFormatter.string(fromByteCount: memory, countStyle: .memory))")
        }
        if let error = errorMessage {
            print("[Telemetry] Error: \(error)")
        }
    }
    
    /// Aggregates and logs telemetry data from multiple parsing attempts.
    /// Calculates and prints overall success rate, average processing time, fastest parser, and most reliable parser.
    /// - Parameter telemetryData: An array of `ParserTelemetry` objects to aggregate.
    static func aggregateAndLogTelemetry(telemetryData: [ParserTelemetry]) {
        print("[Telemetry] ===== AGGREGATE PARSER PERFORMANCE =====")
        
        // Overall success rate
        let successCount = telemetryData.filter { $0.success }.count
        let totalCount = telemetryData.count
        let successRate = Double(successCount) / Double(totalCount)
        print("[Telemetry] Success rate: \(String(format: "%.1f", successRate * 100))% (\(successCount)/\(totalCount))")
        
        // Average processing time
        let avgTime = telemetryData.map { $0.processingTime }.reduce(0, +) / Double(totalCount)
        print("[Telemetry] Average processing time: \(String(format: "%.3f", avgTime))s")
        
        // Fastest parser
        if let fastest = telemetryData.min(by: { $0.processingTime < $1.processingTime }) {
            print("[Telemetry] Fastest parser: \(fastest.parserName) (\(String(format: "%.3f", fastest.processingTime))s)")
        }
        
        // Most reliable parser
        let parserSuccessRates = Dictionary(grouping: telemetryData, by: { $0.parserName })
            .mapValues { parsers in
                let successes = parsers.filter { $0.success }.count
                return Double(successes) / Double(parsers.count)
            }
        
        if let mostReliable = parserSuccessRates.max(by: { $0.value < $1.value }) {
            print("[Telemetry] Most reliable parser: \(mostReliable.key) (\(String(format: "%.1f", mostReliable.value * 100))%)")
        }
        
        print("[Telemetry] =======================================")
    }
}

// MARK: - Error Models

/// Types of errors that can occur during parsing
enum ParserErrorType {
    /// Error related to the input document itself (e.g., invalid format, corrupted).
    case documentError
    /// Error during the text extraction phase from the document.
    case extractionError
    /// Error during the parsing of extracted text into structured data.
    case parsingError
    /// Parsing completed but yielded no meaningful data.
    case emptyResult
    /// Parsing completed but the confidence score was below the required threshold.
    case lowConfidence
    /// An unspecified or unexpected error occurred.
    case unknown
    
    var description: String {
        switch self {
        case .documentError:
            return "Invalid PDF document"
        case .extractionError:
            return "Failed to extract text from PDF"
        case .parsingError:
            return "Failed to parse payslip data"
        case .emptyResult:
            return "Parsing returned empty result"
        case .lowConfidence:
            return "Parsing confidence too low"
        case .unknown:
            return "Unknown error"
        }
    }
}

/// Represents an error that occurred during parsing
struct ParserError {
    /// The category of the parsing error.
    let type: ParserErrorType
    /// The name of the parser where the error occurred.
    let parserName: String
    /// A descriptive message detailing the error.
    let message: String
    /// Timestamp when the error was recorded.
    let timestamp: Date = Date()
    
    /// Initializes a new parser error.
    /// - Parameters:
    ///   - type: The category of the error.
    ///   - parserName: The name of the parser that failed.
    ///   - message: An optional specific error message. If empty, uses the default description from `ParserErrorType`.
    init(type: ParserErrorType, parserName: String, message: String = "") {
        self.type = type
        self.parserName = parserName
        self.message = message.isEmpty ? type.description : message
    }
    
    /// Logs the details of the parser error to the console.
    func logError() {
        print("[Parser Error] Type: \(type)")
        print("[Parser Error] Parser: \(parserName)")
        print("[Parser Error] Message: \(message)")
        print("[Parser Error] Time: \(timestamp)")
    }
} 