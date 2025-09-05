import Foundation

// MARK: - Async Modular PDF Extraction Error Types

enum AsyncModularExtractionError: Error, LocalizedError {
    case pdfTextExtractionFailed
    case payslipCreationFailed
    case invalidPDFData
    case patternProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .pdfTextExtractionFailed:
            return "Failed to extract text from PDF document"
        case .payslipCreationFailed:
            return "Failed to create PayslipItem from extracted data"
        case .invalidPDFData:
            return "Invalid or corrupted PDF data"
        case .patternProcessingFailed:
            return "Failed to process extraction patterns"
        }
    }
}
