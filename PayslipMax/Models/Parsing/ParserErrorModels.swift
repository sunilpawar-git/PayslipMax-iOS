import Foundation

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
