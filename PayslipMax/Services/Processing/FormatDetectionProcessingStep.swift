import Foundation
import PDFKit

/// A concrete processing step for detecting payslip formats.
///
/// This processing step is responsible for analyzing extracted text from a PDF
/// and determining the specific payslip format using format detection services.
/// It represents a critical stage in the processing pipeline where the system
/// identifies the appropriate processor to use for subsequent data extraction.
///
/// Format detection enables the system to handle diverse payslip structures by
/// routing each document to specialized processing logic. The detection process
/// relies on pattern matching, keywords, and structural analysis to determine
/// the most likely format with high confidence.
final class FormatDetectionProcessingStep: PayslipProcessingStep {
    typealias Input = (Data, String)
    typealias Output = (Data, String, PayslipFormat)
    
    /// The format detection service
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol
    
    /// Initialize with a format detection service
    /// - Parameter formatDetectionService: The service to use for format detection
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol) {
        self.formatDetectionService = formatDetectionService
    }
    
    /// Process the input by detecting the payslip format
    /// - Parameter input: Tuple of (PDF data, extracted text)
    /// - Returns: Success with tuple of (PDF data, extracted text, detected format) or failure with error
    /// - Note: This method logs performance metrics and returns the original data along with the detected format
    func process(_ input: (Data, String)) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        let (data, text) = input
        let startTime = Date()
        defer {
            print("[FormatDetectionStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }
        
        // Detect the format from the extracted text
        let format = formatDetectionService.detectFormat(fromText: text)
        print("[FormatDetectionStep] Detected format: \(format)")
        
        return .success((data, text, format))
    }
} 