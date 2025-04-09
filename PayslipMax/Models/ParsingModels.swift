import Foundation
import PDFKit
import Darwin  // For memory tracking

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

// MARK: - Parser Result Models

/// Result object for parsing attempts
struct ParseAttemptResult {
    let parserName: String
    let success: Bool
    let confidence: ParsingConfidence?
    let error: Error?
    let processingTime: TimeInterval
}

// MARK: - Telemetry Models

/// Collects telemetry data for parser performance
struct ParserTelemetry {
    let parserName: String
    let processingTime: TimeInterval
    let confidence: ParsingConfidence
    let success: Bool
    let timestamp: Date = Date()
    let memoryUsage: Int64? // In bytes
    
    // Additional parser-specific metrics
    let extractedItemCount: Int
    let textLength: Int
    let errorMessage: String?
    
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
    case documentError
    case extractionError
    case parsingError
    case emptyResult
    case lowConfidence
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
    let type: ParserErrorType
    let parserName: String
    let message: String
    let timestamp: Date = Date()
    
    init(type: ParserErrorType, parserName: String, message: String = "") {
        self.type = type
        self.parserName = parserName
        self.message = message.isEmpty ? type.description : message
    }
    
    func logError() {
        print("[Parser Error] Type: \(type)")
        print("[Parser Error] Parser: \(parserName)")
        print("[Parser Error] Message: \(message)")
        print("[Parser Error] Time: \(timestamp)")
    }
} 