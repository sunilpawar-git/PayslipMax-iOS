import Foundation

/// Protocol for detecting JCO/OR format payslips based on text markers
protocol JCOORFormatDetectorProtocol: Sendable {
    /// Determines if the provided text represents a JCO/OR format payslip
    /// - Parameter text: The extracted text from a payslip
    /// - Returns: True if text contains JCO/OR format markers
    func isJCOORFormat(text: String) async -> Bool
}
