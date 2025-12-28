import Foundation

/// Protocol for detecting the type of input data (image vs PDF vs scanned PDF)
protocol InputTypeDetectorProtocol: Sendable {
    /// Determines the type of payslip input from raw data
    /// - Parameter data: The input data to analyze
    /// - Returns: The detected input type with associated data
    func getInputType(_ data: Data) async -> PayslipInputType
}

/// Represents the different types of payslip input formats
enum PayslipInputType: Sendable {
    /// Direct image input (JPG, PNG, screenshot) - always requires Vision LLM
    case imageDirect(Data)

    /// Text-based PDF - can be parsed with regex or LLM based on format
    case pdfTextBased(Data)

    /// Scanned PDF (image embedded in PDF) - requires Vision LLM
    case pdfScanned(Data)
}
