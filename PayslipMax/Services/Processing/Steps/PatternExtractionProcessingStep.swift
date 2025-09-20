import Foundation
import PDFKit

/// Processing step that performs pattern-based extraction using AsyncModularPDFExtractor
/// This integrates the pattern-based extraction system into the unified processing pipeline
@MainActor
class PatternExtractionProcessingStep: PayslipProcessingStep {

    // MARK: - Types

    typealias Input = (Data, String, PayslipFormat)
    typealias Output = PayslipItem

    // MARK: - Properties

    private let patternExtractor: AsyncModularPDFExtractor

    // MARK: - Initialization

    init(patternExtractor: AsyncModularPDFExtractor) {
        self.patternExtractor = patternExtractor
    }

    convenience init(patternRepository: PatternRepositoryProtocol = DefaultPatternRepository()) {
        let extractor = AsyncModularPDFExtractor(patternRepository: patternRepository)
        self.init(patternExtractor: extractor)
    }

    // MARK: - PayslipProcessingStep Implementation

    /// Processes the input using pattern-based extraction
    /// - Parameter input: Tuple containing (PDF data, extracted text, detected format)
    /// - Returns: Success with extracted PayslipItem or failure with processing error
    func process(_ input: Input) async -> Result<PayslipItem, PDFProcessingError> {
        let (pdfData, _, format) = input

        print("[PatternExtractionStep] Starting pattern-based extraction for format: \(format)")

        do {
            // Create PDFDocument for pattern extraction
            guard let pdfDocument = PDFDocument(data: pdfData) else {
                print("[PatternExtractionStep] Failed to create PDFDocument from data")
                return .failure(.invalidFormat)
            }

            // Use pattern extractor to extract payslip data
            if let payslipItem = try await patternExtractor.extractPayslipData(from: pdfDocument) {
                print("[PatternExtractionStep] Successfully extracted payslip data using patterns")

                // Ensure the detected format is preserved in the payslip metadata
                await payslipItem.setMetadata(String(describing: format), for: "detectedFormat")
                await payslipItem.setMetadata("pattern-based", for: "extractionMethod")

                return .success(payslipItem)
            } else {
                print("[PatternExtractionStep] Pattern extraction returned no results")
                return .failure(.processingFailed)
            }
        } catch {
            print("[PatternExtractionStep] Pattern extraction failed: \(error.localizedDescription)")
            return .failure(.processingFailed)
        }
    }
}
