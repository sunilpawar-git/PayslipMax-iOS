import Foundation
import UIKit
import Vision
import PDFKit

/// A processing pipeline step responsible for handling image inputs.
/// It can convert a `UIImage` into PDF `Data` and also perform Optical Character Recognition (OCR)
/// on an image to extract text content.
@MainActor
class ImageProcessingStep: PayslipProcessingStep {
    typealias Input = UIImage
    typealias Output = Data
    
    /// Process the input image by converting it to PDF data
    /// - Parameter input: The UIImage to process
    /// - Returns: Success with PDF data or failure with error
    func process(_ input: UIImage) async -> Result<Data, PDFProcessingError> {
        let startTime = Date()
        defer {
            print("[ImageProcessingStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }
        
        // Convert image to PDF data
        guard let pdfData = createPDFFromImage(input) else {
            print("[ImageProcessingStep] Failed to convert image to PDF")
            return .failure(.conversionFailed)
        }
        
        return .success(pdfData)
    }
    
    /// Creates a PDF from an image
    private func createPDFFromImage(_ image: UIImage) -> Data? {
        // Use higher resolution for better text recognition
        let originalImage = image
        let scaleFactor: CGFloat = 2.0
        let scaledSize = CGSize(width: originalImage.size.width * scaleFactor, 
                                height: originalImage.size.height * scaleFactor)
        
        // Create a high-resolution renderer with the scaled size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: scaledSize))
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Draw with high quality
            let renderingIntent = CGColorRenderingIntent.defaultIntent
            let interpolationQuality = CGInterpolationQuality.high
            
            // Set graphics state for better quality
            let cgContext = context.cgContext
            cgContext.setRenderingIntent(renderingIntent)
            cgContext.interpolationQuality = interpolationQuality
            
            // Draw the image at higher quality
            originalImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
    
    /// Performs Optical Character Recognition (OCR) on the provided image to extract text.
    /// Uses the Vision framework for text recognition.
    /// - Parameter image: The `UIImage` to perform OCR on.
    /// - Returns: An optional `String` containing the recognized text, or `nil` if OCR fails or no text is found.
    func performOCR(on image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            var recognizedText: String?
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("[ImageProcessingStep] OCR error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                // Process the results to extract text
                if let observations = request.results {
                    var textPieces = [String]()
                    
                    for observation in observations {
                        // We need to cast to the specific type to access the text methods
                        if let textObservation = observation as? VNRecognizedTextObservation,
                           let candidate = textObservation.topCandidates(1).first {
                            textPieces.append(candidate.string)
                        }
                    }
                    
                    recognizedText = textPieces.joined(separator: "\n")
                }
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            do {
                try handler.perform([request])
            } catch {
                print("[ImageProcessingStep] Error performing OCR: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
} 