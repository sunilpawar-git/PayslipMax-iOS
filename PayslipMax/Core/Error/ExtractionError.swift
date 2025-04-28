import Foundation

/// Errors specific to the data extraction process.
enum ExtractionError: Error, LocalizedError {
    /// Failed to extract text content from the source (e.g., PDF).
    case pdfTextExtractionFailed
    /// A required pattern definition was not found.
    case patternNotFound
    /// Failed to extract a specific value using the available patterns.
    case valueExtractionFailed
    /// An invalid parameter was provided for extraction.
    case invalidParameter(String)
    /// The format of the data to be extracted from was unexpected.
    case unexpectedFormat

    public var errorDescription: String? {
        switch self {
        case .pdfTextExtractionFailed:
            return NSLocalizedString("Failed to extract text content from the PDF.", comment: "Error description")
        case .patternNotFound:
            return NSLocalizedString("Could not find the required pattern definition.", comment: "Error description")
        case .valueExtractionFailed:
            return NSLocalizedString("Failed to extract the required value using the defined patterns.", comment: "Error description")
        case .invalidParameter(let description):
            return String(format: NSLocalizedString("Invalid extraction parameter: %@", comment: "Error description"), description)
        case .unexpectedFormat:
            return NSLocalizedString("The data format was unexpected during extraction.", comment: "Error description")
        }
    }
} 