import Foundation
import PDFKit

/// A concrete processing step for detecting payslip formats
@MainActor
class FormatDetectionProcessingStep: PayslipProcessingStep {
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