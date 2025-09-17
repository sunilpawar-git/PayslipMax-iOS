import Foundation
import UIKit

/// Protocol for image-based PDF processing operations
protocol PDFImageProcessorProtocol {
    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: A `Result` containing the extracted `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError>
}

/// Handles scanned image processing operations
/// Responsible for converting images to PDF format and processing them through the pipeline
@MainActor
class PDFImageProcessor: PDFImageProcessorProtocol {
    // MARK: - Properties

    /// A pipeline step specifically for handling image-based inputs and converting them to PDF.
    private let imageProcessingStep: ImageProcessingStep

    /// The pipeline coordinating the sequential steps of payslip processing.
    private let processingPipeline: PayslipProcessingPipeline

    // MARK: - Initialization

    /// Initializes a new PDFImageProcessor with its required dependencies.
    /// - Parameters:
    ///   - imageProcessingStep: Pipeline step for image-to-PDF conversion.
    ///   - processingPipeline: The main processing pipeline for PDF data.
    init(imageProcessingStep: ImageProcessingStep, processingPipeline: PayslipProcessingPipeline) {
        self.imageProcessingStep = imageProcessingStep
        self.processingPipeline = processingPipeline
    }

    // MARK: - PDFImageProcessorProtocol Implementation

    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: A `Result` containing the extracted `PayslipItem` on success, or a `PDFProcessingError` on failure.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFImageProcessor] Processing scanned image")

        // Use the image processing step to convert image to PDF
        let pdfDataResult = await imageProcessingStep.process(image)

        switch pdfDataResult {
        case .success(let pdfData):
            // Process the PDF data using the pipeline
            return await processingPipeline.executePipeline(pdfData)
        case .failure(let error):
            return .failure(error)
        }
    }
}
