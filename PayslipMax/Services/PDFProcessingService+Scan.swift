import Foundation
import UIKit
import PDFKit

@MainActor
extension PDFProcessingService {
    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// Applies OCR fallback when the initial text extraction fails.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFProcessingService] Processing scanned image")

        let pdfDataResult = await imageProcessingStep.process(image)

        switch pdfDataResult {
        case .success(let pdfData):
            let pipelineResult = await processingPipeline.executePipeline(pdfData)

            if case .success = pipelineResult {
                return pipelineResult
            }

            if case .failure(let error) = pipelineResult,
               error == .textExtractionFailed || error == .notAPayslip,
               let ocrText = await imageProcessingStep.performOCR(on: image),
               !ocrText.isEmpty {
                return await processOCRText(ocrText, pdfData: pdfData)
            }

            return pipelineResult
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Processes OCR text as a fallback for image-only scans.
    private func processOCRText(_ text: String, pdfData: Data) async -> Result<PayslipItem, PDFProcessingError> {
        let format = formatDetectionService.detectFormat(fromText: text)
        do {
            let methods = PDFProcessingMethods(pdfExtractor: pdfExtractor)
            let payslip: PayslipItem
            switch format {
            case .defense:
                payslip = try await methods.processMilitaryPDF(from: text)
            case .unknown:
                payslip = try await methods.processStandardPDF(from: text)
            }
            payslip.pdfData = pdfData
            payslip.source = "Scan"
            return .success(payslip)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
}

