import Foundation
import UIKit

/// Extension adding position-aware OCR capabilities for tabular payslip parsing.
/// Uses StructuredOCRService + TabularTextAssembler to separate columns.
@MainActor
extension ImageProcessingStep {

    /// Performs position-aware OCR that preserves text block positions,
    /// then assembles blocks into separate left/right column text streams.
    ///
    /// Designed for JCO/OR military payslips with two-column "ACCOUNTS AT A GLANCE" layout.
    /// Returns nil if the image doesn't contain a recognizable tabular layout.
    ///
    /// - Parameters:
    ///   - image: The payslip image to process
    ///   - ocrService: The structured OCR service to use (injected for testability)
    ///   - assembler: The tabular text assembler to use (injected for testability)
    /// - Returns: Assembly result with column-separated text, or nil
    func performStructuredOCR(
        on image: UIImage,
        ocrService: StructuredOCRServiceProtocol = StructuredOCRService(),
        assembler: TabularTextAssemblerProtocol = TabularTextAssembler()
    ) async -> TabularAssemblyResult? {
        guard let cgImage = image.cgImage else { return nil }

        guard let ocrResult = await ocrService.recognizeText(from: cgImage) else {
            return nil
        }

        guard ocrResult.hasMinimumContent else { return nil }

        let result = assembler.assemble(from: ocrResult)
        // Return nil when layout is non-tabular so callers can fall back to flat OCR
        return result.isTabularLayoutDetected ? result : nil
    }

    /// Builds a combined text string from a tabular assembly result suitable for
    /// anchor extraction (which needs data from both columns).
    ///
    /// For line-item extraction, use leftColumn.text and rightColumn.text separately.
    func combinedTextForAnchors(from assembly: TabularAssemblyResult) -> String {
        [assembly.fullWidthText, assembly.leftColumn.text, assembly.rightColumn.text]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
