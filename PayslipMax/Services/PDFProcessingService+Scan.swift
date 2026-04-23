import Foundation
import UIKit
import PDFKit
import os

@MainActor
extension PDFProcessingService {

    private var scanLogger: os.Logger {
        os.Logger(subsystem: "com.payslipmax.scan", category: "PDFProcessing")
    }

    /// Processes a scanned image by converting it to PDF data and then running it through the standard processing pipeline.
    /// Applies OCR fallback when the initial text extraction fails.
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        scanLogger.info("Processing scanned image")

        let pdfDataResult = await imageProcessingStep.process(image)

        switch pdfDataResult {
        case .success(let pdfData):
            let pipelineResult = await processingPipeline.executePipeline(pdfData)

            if case .success = pipelineResult {
                return pipelineResult
            }

            if case .failure(let error) = pipelineResult,
               error == .textExtractionFailed || error == .notAPayslip {
                // Try position-aware OCR first (offline, handles tabular JCO/OR layout)
                if let structuredResult = await processWithStructuredOCR(image: image, pdfData: pdfData) {
                    return structuredResult
                }

                let croppedImage = cropTopBand(from: image, heightRatio: ScanThreshold.topBandHeightRatio)
                var ocrCandidates: [(text: String, label: String)] = []

                if let topText = await imageProcessingStep.performOCR(on: croppedImage), !topText.isEmpty {
                    ocrCandidates.append((topText, "ocr-top"))
                    logOCRCandidate(topText, label: "ocr-top")
                }
                if let fullText = await imageProcessingStep.performOCR(on: image), !fullText.isEmpty {
                    ocrCandidates.append((fullText, "ocr-full"))
                    logOCRCandidate(fullText, label: "ocr-full")
                }

                // Retry with preprocessed full image if digit counts are too low
                let maxDigits = ocrCandidates.map { digitCount($0.text) }.max() ?? 0
                if maxDigits < ScanThreshold.minimumDigitCount {
                    let enhancedImage = imageProcessingStep.preprocessForOCR(image)
                    if let enhancedText = await imageProcessingStep.performOCR(on: enhancedImage), !enhancedText.isEmpty {
                        ocrCandidates.append((enhancedText, "ocr-preprocessed-full"))
                        logOCRCandidate(enhancedText, label: "ocr-preprocessed-full")
                    }
                }

                if let best = ocrCandidates.max(by: { digitCount($0.text) < digitCount($1.text) }) {
                    return await processOCRText(best.text, pdfData: pdfData)
                }
            }

            return pipelineResult
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Processes a scanned image via OCR + LLM only, bypassing the regex pipeline.
    /// Designed for user-cropped, PII-reduced images to improve LLM accuracy.
    func processScannedImageLLMOnly(_ image: UIImage, hint: PayslipUserHint) async -> Result<PayslipItem, PDFProcessingError> {
        scanLogger.info("Processing scanned image (LLM-only)")

        // 0) Vision LLM attempt
        if let visionConfig = resolveVisionLLMConfiguration(),
           let visionParser = LLMPayslipParserFactory.createVisionParser(for: visionConfig) {
            do {
                let visionResult = try await visionParser.parse(image: image)
                return .success(visionResult)
            } catch {
                scanLogger.warning("Vision LLM failed, falling back to OCR+text LLM")
            }
        }

        // 1) Fallback: multi-pass OCR + text LLM (no redaction)
        var ocrCandidates: [(text: String, label: String)] = []
        let topCropped = cropTopBand(from: image, heightRatio: ScanThreshold.narrowTopBandHeightRatio)

        if let topText = await imageProcessingStep.performOCR(on: topCropped), !topText.isEmpty {
            ocrCandidates.append((topText, "ocr-top"))
            logOCRCandidate(topText, label: "ocr-top")
        }
        if let fullText = await imageProcessingStep.performOCR(on: image), !fullText.isEmpty {
            ocrCandidates.append((fullText, "ocr-full"))
            logOCRCandidate(fullText, label: "ocr-full")
        }
        // Preprocess for OCR and retry
        let enhanced = imageProcessingStep.preprocessForOCR(image)
        if let enhancedText = await imageProcessingStep.performOCR(on: enhanced), !enhancedText.isEmpty {
            ocrCandidates.append((enhancedText, "ocr-preprocessed-full"))
            logOCRCandidate(enhancedText, label: "ocr-preprocessed-full")
        }

        guard let best = ocrCandidates.max(by: { digitCount($0.text) < digitCount($1.text) }),
              !best.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.textExtractionFailed)
        }

        guard let config = resolveLLMConfiguration(),
              let parser = LLMPayslipParserFactory.createParserWithoutRedaction(for: config) else {
            return .failure(.processingFailed)
        }

        scanLogger.info("LLM parser configured for cropped input")

        do {
            let hintPrefix = llmHintPrefix(for: hint)
            let promptText = hintPrefix + best.text
            let payslip = try await parser.parse(promptText)
            payslip.source = "Scan (LLM-only)"
            return .success(payslip)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }

    /// Processes both original and cropped scanned images.
    /// Original image is converted to PDF for storage, cropped image is used for LLM/OCR processing.
    /// - Parameters:
    ///   - originalImage: The uncropped original image (for PDF storage)
    ///   - croppedImage: The cropped image (for LLM/OCR processing)
    ///   - imageIdentifier: UUID for linking to saved image files
    ///   - hint: User hint for payslip type
    /// - Returns: A result containing the parsed payslip or an error
    func processScannedImages(
        originalImage: UIImage,
        croppedImage: UIImage,
        imageIdentifier: UUID?,
        hint: PayslipUserHint
    ) async -> Result<PayslipItem, PDFProcessingError> {
        scanLogger.info("Processing with original + cropped images")

        // 1. Convert ORIGINAL image to PDF (for storage)
        let originalPDFResult = await imageProcessingStep.process(originalImage)
        guard case .success(let originalPDFData) = originalPDFResult else {
            return .failure(.conversionFailed)
        }

        // 2. Vision LLM attempt with CROPPED image (primary method)
        if let visionConfig = resolveVisionLLMConfiguration(),
           let visionParser = LLMPayslipParserFactory.createVisionParser(for: visionConfig) {
            do {
                scanLogger.info("Starting Vision LLM parsing")
                let payslip = try await visionParser.parse(image: croppedImage)

                payslip.pdfData = originalPDFData
                payslip.source = "Scan (Vision LLM)"

                if let id = imageIdentifier {
                    payslip.metadata["originalImageID"] = id.uuidString
                    payslip.metadata["hasCroppedVersion"] = "true"
                }

                scanLogger.info("Vision LLM parsing successful")
                return .success(payslip)
            } catch {
                scanLogger.warning("Vision LLM failed, falling back to OCR+text LLM")
            }
        }

        // 3. Fallback: OCR on CROPPED image + text LLM (if Vision LLM fails)
        var ocrCandidates: [(text: String, label: String)] = []

        let topCropped = cropTopBand(from: croppedImage, heightRatio: ScanThreshold.narrowTopBandHeightRatio)
        if let topText = await imageProcessingStep.performOCR(on: topCropped), !topText.isEmpty {
            ocrCandidates.append((topText, "ocr-top"))
        }

        if let fullText = await imageProcessingStep.performOCR(on: croppedImage), !fullText.isEmpty {
            ocrCandidates.append((fullText, "ocr-full"))
        }

        let enhanced = imageProcessingStep.preprocessForOCR(croppedImage)
        if let enhancedText = await imageProcessingStep.performOCR(on: enhanced), !enhancedText.isEmpty {
            ocrCandidates.append((enhancedText, "ocr-preprocessed"))
        }

        guard let best = ocrCandidates.max(by: { digitCount($0.text) < digitCount($1.text) }) else {
            return .failure(.textExtractionFailed)
        }

        // 5. Parse with text LLM
        guard let config = resolveLLMConfiguration(),
              let parser = LLMPayslipParserFactory.createParserWithoutRedaction(for: config) else {
            return .failure(.processingFailed)
        }

        do {
            let hintPrefix = llmHintPrefix(for: hint)
            let payslip = try await parser.parse(hintPrefix + best.text)

            // Attach ORIGINAL image PDF
            payslip.pdfData = originalPDFData
            payslip.source = "Scan (OCR + LLM)"

            if let id = imageIdentifier {
                payslip.metadata["originalImageID"] = id.uuidString
                payslip.metadata["hasCroppedVersion"] = "true"
            }

            return .success(payslip)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }

    private func resolveLLMConfiguration() -> LLMConfiguration? {
        let settings = LLMSettingsService(keychain: KeychainSecureStorage())
        return settings.getConfiguration()
    }

    internal func resolveVisionLLMConfiguration() -> LLMConfiguration? {
        let settings = LLMSettingsService(keychain: KeychainSecureStorage())
        return settings.getConfiguration()
    }

    private func llmHintPrefix(for hint: PayslipUserHint) -> String {
        switch hint {
        case .auto:
            return ""
        case .officer:
            return "[CONTEXT] This payslip belongs to an OFFICER rank. Parse using officer pay structure.\n"
        case .jcoOr:
            return "[CONTEXT] This payslip belongs to a JCO/OR rank. Parse using JCO/OR pay structure.\n"
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

    private func digitCount(_ text: String) -> Int {
        return text.reduce(0) { $0 + ($1.isNumber ? 1 : 0) }
    }

    private func logOCRCandidate(_ text: String, label: String) {
        let digits = digitCount(text)
        scanLogger.debug("OCR candidate '\(label)': len=\(text.count), digits=\(digits)")
    }

    /// Processes OCR text as a fallback for image-only scans.
    /// Processes OCR text through the hybrid regex pipeline.
    /// Internal access allows the structured OCR extension to reuse this method.
    func processOCRText(_ text: String, pdfData: Data) async -> Result<PayslipItem, PDFProcessingError> {
        let format = formatDetectionService.detectFormat(fromText: text)
        do {
            // Reuse the hybrid processor (regex + LLM) for OCR text so JCO/OR also gets redaction + LLM fallback
            let processor = processorFactory.getProcessor(for: format)
            let payslip = try await processor.processPayslip(from: text)

            // Attach metadata
            payslip.pdfData = pdfData
            payslip.source = "Scan"
            return .success(payslip)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
}

