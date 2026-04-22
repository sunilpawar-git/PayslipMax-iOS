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
final class StructuredOCRService: StructuredOCRServiceProtocol, @unchecked Sendable {

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
        return await withCheckedContinuation { continuation in
            performRecognition(on: cgImage) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Private

    private func performRecognition(
        on cgImage: CGImage,
        completion: @escaping (StructuredOCRResult?) -> Void
    ) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else {
                completion(nil)
                return
            }

            if error != nil {
                completion(nil)
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation]
            let blocks = self.buildTextBlocks(from: observations)
            let sortedBlocks = blocks.sortedTopToBottom()
            completion(StructuredOCRResult(blocks: sortedBlocks))
        }

        request.recognitionLevel = recognitionLevel
        request.recognitionLanguages = recognitionLanguages
        request.usesLanguageCorrection = true

        do {
            try handler.perform([request])
        } catch {
            completion(nil)
        }
    }

    private func buildTextBlocks(
        from observations: [VNRecognizedTextObservation]?
    ) -> [OCRTextBlock] {
        guard let observations = observations else { return [] }

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
