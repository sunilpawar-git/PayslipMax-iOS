import Foundation

/// Represents a result from PCDAPayslipParser operations
enum PCDAPayslipParserResult<T> {
    case success(T)
    case failure(PCDAPayslipParserError)
}

/// Represents errors that can occur during PCDAPayslipParser operations
enum PCDAPayslipParserError: Error, LocalizedError {
    case emptyPDF
    case extractionFailed
    case invalidFormat
    case missingData(field: String)
    case invalidData(field: String, value: String)
    case testPDFDetected
    case unknown(message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyPDF:
            return "The PDF document has no pages."
        case .extractionFailed:
            return "Failed to extract text from the PDF document."
        case .invalidFormat:
            return "The PDF document is not in a recognized format."
        case .missingData(let field):
            return "Missing required data: \(field)."
        case .invalidData(let field, let value):
            return "Invalid data for \(field): \(value)."
        case .testPDFDetected:
            return "Test PDF detected, returning test data."
        case .unknown(let message):
            return "An unknown error occurred: \(message)."
        }
    }
} 