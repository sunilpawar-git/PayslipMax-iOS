import Foundation
import PDFKit
import UIKit

// MARK: - JCO/OR Processing Helpers

extension PDFProcessingService {

    /// Converts the first page of a PDF to a UIImage for Vision LLM processing
    /// - Parameter data: The PDF data to convert
    /// - Returns: UIImage of the first PDF page, or nil if conversion fails
    internal func convertPDFToImage(_ data: Data) -> UIImage? {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else {
            print("[PDFProcessingService] Could not load PDF page for conversion")
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)

        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)

            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        print("[PDFProcessingService] Successfully converted PDF to image (\(Int(image.size.width)) x \(Int(image.size.height)))")
        return image
    }

    /// Processes an image through Vision LLM (optimized for JCO/OR PDFs)
    /// - Parameters:
    ///   - image: The image to process
    ///   - hint: User hint for parsing context
    /// - Returns: Result containing parsed PayslipItem or error
    internal func processWithVisionLLM(image: UIImage, hint: PayslipUserHint) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFProcessingService] Processing with Vision LLM (hint: \(hint.rawValue))")

        // Resolve Vision LLM configuration
        guard let config = resolveVisionLLMConfiguration() else {
            print("[PDFProcessingService] Vision LLM not configured")
            return .failure(.processingFailed)
        }

        // Create Vision LLM parser with optimization (Phase 3)
        guard let parser = LLMPayslipParserFactory.createVisionParser(for: config) else {
            print("[PDFProcessingService] Could not create Vision LLM parser")
            return .failure(.processingFailed)
        }

        do {
            let payslip = try await parser.parse(image: image)
            payslip.source = "JCO/OR PDF (Vision LLM)"
            print("[PDFProcessingService] Vision LLM parsing successful")
            return .success(payslip)
        } catch {
            print("[PDFProcessingService] Vision LLM parsing failed: \(error.localizedDescription)")
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }


}
