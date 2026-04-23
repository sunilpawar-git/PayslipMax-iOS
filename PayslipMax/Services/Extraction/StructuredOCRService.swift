import Foundation
import Vision
import UIKit

/// Position-aware OCR service using Apple Vision framework.
///
/// Unlike flat OCR that returns a single concatenated string, this service
/// returns each recognized text block with its bounding box, enabling
/// downstream column separation for tabular military payslips (JCO/OR format).
///
/// Security: OCR results are transient and never persisted. No PII is logged.
final class StructuredOCRService: StructuredOCRServiceProtocol, Sendable {

    private let recognitionLevel: VNRequestTextRecognitionLevel
    private let recognitionLanguages: [String]
    private let minimumConfidence: Float

    init(
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        recognitionLanguages: [String] = ["en-US", "en-IN", "hi-IN"],
        minimumConfidence: Float = 0.3
    ) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.minimumConfidence = minimumConfidence
    }

    func recognizeText(from imageData: Data) async -> StructuredOCRResult? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return nil
        }
        return await recognizeText(from: cgImage)
    }

    func recognizeText(from cgImage: CGImage) async -> StructuredOCRResult? {
        let minimumConf = minimumConfidence
        let level = recognitionLevel
        let languages = recognitionLanguages

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation]
                let blocks = Self.buildTextBlocks(from: observations, minimumConfidence: minimumConf)
                continuation.resume(returning: StructuredOCRResult(blocks: blocks.sortedTopToBottom()))
            }

            request.recognitionLevel = level
            request.recognitionLanguages = languages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Private

    private static func buildTextBlocks(
        from observations: [VNRecognizedTextObservation]?,
        minimumConfidence: Float
    ) -> [OCRTextBlock] {
        guard let observations else { return [] }

        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= minimumConfidence else {
                return nil
            }
            return OCRTextBlock(
                text: candidate.string,
                boundingBox: observation.boundingBox,
                confidence: candidate.confidence
            )
        }
    }
}
