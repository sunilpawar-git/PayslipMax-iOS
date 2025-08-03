
import Vision
import UIKit

/// Represents the structured result of an ultimate OCR operation.
struct UltimateOCRResult {
    let originalImage: UIImage
    let groupedText: GeometricTextAnalyzer.GroupedTextResult
    let recognizedTables: [GeometricTextAnalyzer.Table]
}

/// Ultimate Vision OCR service with complete Vision framework integration.
final class UltimateVisionService {

    private let imageProcessor = AdvancedImageProcessor()
    private let textAnalyzer = GeometricTextAnalyzer()

    /// Performs the ultimate OCR pipeline on an image.
    @MainActor
    func performUltimateOCR(on image: UIImage) async -> UltimateOCRResult? {
        let optimizedImage = imageProcessor.optimizeForOCR(image)
        guard let cgImage = optimizedImage.cgImage else { return nil }

        let textObservations = await detectText(from: cgImage)
                var groupedText = textAnalyzer.groupTextObservations(textObservations)
        
        let recognizedTables = await recognizeTextInTables(from: cgImage, tables: &groupedText.tables)

        return UltimateOCRResult(originalImage: image,
                                 groupedText: groupedText,
                                 recognizedTables: recognizedTables)
    }

    /// Detects text rectangles in a `CGImage`.
    private func detectText(from cgImage: CGImage) async -> [VNTextObservation] {
        let request = VNDetectTextRectanglesRequest()
        request.reportCharacterBoxes = true

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        return await withCheckedContinuation { continuation in
            do {
                try requestHandler.perform([request])
                continuation.resume(returning: request.results ?? [])
            } catch {
                print("Error detecting text: \(error)")
                continuation.resume(returning: [])
            }
        }
    }

    /// Recognizes text within the cells of detected tables.
    private func recognizeTextInTables(from cgImage: CGImage, tables: inout [GeometricTextAnalyzer.Table]) async -> [GeometricTextAnalyzer.Table] {
        var recognizedTables: [GeometricTextAnalyzer.Table] = []

        for table in tables {
            var recognizedRows: [GeometricTextAnalyzer.Row] = []
            for row in table.rows {
                var recognizedCells: [GeometricTextAnalyzer.Cell] = []
                for var cell in row.cells {
                    let recognizedText = await recognizeText(from: cgImage, in: cell.boundingBox)
                    cell.text = recognizedText
                    recognizedCells.append(cell)
                }
                recognizedRows.append(GeometricTextAnalyzer.Row(cells: recognizedCells, boundingBox: row.boundingBox))
            }
            recognizedTables.append(GeometricTextAnalyzer.Table(rows: recognizedRows, boundingBox: table.boundingBox))
        }
        
        return recognizedTables
    }

    /// Recognizes text within a specific bounding box.
    private func recognizeText(from cgImage: CGImage, in boundingBox: CGRect) async -> String {
        let request = VNRecognizeTextRequest()
        request.regionOfInterest = boundingBox

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        return await withCheckedContinuation { continuation in
            do {
                try requestHandler.perform([request])
                let recognizedString = request.results?.first?.topCandidates(1).first?.string ?? ""
                continuation.resume(returning: recognizedString)
            } catch {
                print("Error recognizing text for region: \(error)")
                continuation.resume(returning: "")
            }
        }
    }
}
