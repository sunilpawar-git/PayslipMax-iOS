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
               error == .textExtractionFailed || error == .notAPayslip {
                // Prefer OCR on the top band to reduce noise; fall back to full image OCR
                let croppedImage = cropTopBand(from: image)
                let ocrCandidates: [String?] = [
                    await imageProcessingStep.performOCR(on: croppedImage),
                    await imageProcessingStep.performOCR(on: image)
                ]

                if let ocrText = ocrCandidates.compactMap({ $0 }).first(where: { !$0.isEmpty }) {
                    return await processOCRText(ocrText, pdfData: pdfData)
                }
            }

            return pipelineResult
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Crops the top band of an image (default ~45%) to focus on header and totals.
    private func cropTopBand(from image: UIImage, heightRatio: CGFloat = 0.45) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropHeight = max(1, min(height, height * heightRatio))
        let rect = CGRect(x: 0, y: 0, width: width, height: cropHeight)
        if let cropped = cgImage.cropping(to: rect) {
            return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
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

