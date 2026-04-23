import Foundation
import UIKit
import os

/// Extension adding offline structured OCR parsing for tabular (JCO/OR) payslips.
/// Uses position-aware OCR to separate two-column layout into Credits/Debits streams,
/// then feeds each column through the existing regex pipeline independently.
@MainActor
extension PDFProcessingService {

    private var structuredOCRLogger: os.Logger {
        os.Logger(subsystem: "com.payslipmax.ocr", category: "StructuredOCR")
    }

    /// Attempts to parse a scanned image using position-aware OCR (no network required).
    ///
    /// Algorithm:
    /// 1. Run structured OCR to get text blocks with bounding boxes
    /// 2. Assemble blocks into left (credits) and right (debits) columns
    /// 3. Combine columns for anchor extraction (gross, deductions, net)
    /// 4. Feed combined text through existing hybrid regex pipeline
    ///
    /// Returns nil if structured OCR doesn't detect a tabular layout,
    /// signaling the caller to fall back to flat OCR or LLM paths.
    func processWithStructuredOCR(
        image: UIImage,
        pdfData: Data
    ) async -> Result<PayslipItem, PDFProcessingError>? {
        let assembly = await imageProcessingStep.performStructuredOCR(on: image)

        guard let assembly else {
            structuredOCRLogger.info("No tabular layout detected, falling back")
            return nil
        }

        let combinedText = imageProcessingStep.combinedTextForAnchors(from: assembly)
        let digitCountInText = combinedText.reduce(0) { $0 + ($1.isNumber ? 1 : 0) }

        guard digitCountInText >= ScanThreshold.minimumDigitCount else {
            structuredOCRLogger.info("Too few digits (\(digitCountInText)), falling back")
            return nil
        }

        structuredOCRLogger.info("Tabular layout — left: \(assembly.leftColumn.blockCount), right: \(assembly.rightColumn.blockCount) blocks, confidence: \(String(format: "%.2f", assembly.columnSplitConfidence))")

        return await processOCRText(combinedText, pdfData: pdfData)
    }
}
