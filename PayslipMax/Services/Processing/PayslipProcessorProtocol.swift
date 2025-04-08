import Foundation
import PDFKit

/// Protocol for format-specific payslip processors
protocol PayslipProcessorProtocol {
    /// Processes a payslip in a specific format
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A PayslipItem if processing was successful
    /// - Throws: Error if processing fails
    func processPayslip(from text: String) throws -> PayslipItem
    
    /// Checks if this processor can handle the given text
    /// - Parameter text: The extracted text from the PDF
    /// - Returns: A confidence score between 0 and 1 (0 = cannot process, 1 = definitely can process)
    func canProcess(text: String) -> Double
    
    /// The format that this processor handles
    var handlesFormat: PayslipFormat { get }
} 