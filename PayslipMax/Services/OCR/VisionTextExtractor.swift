import Foundation
import Vision
import CoreGraphics
import PDFKit
import UIKit

/// Protocol for Vision-based text extraction services
public protocol VisionTextExtractorProtocol {
    func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void)
    func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void)
}

/// Errors that can occur during Vision text extraction
public enum VisionTextExtractionError: Error, LocalizedError, Equatable {
    case imageConversionFailed
    case visionRequestFailed(Error)
    case noTextDetected
    case pdfRenderingFailed
    
    public var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert PDF page to image"
        case .visionRequestFailed(let error):
            return "Vision text recognition failed: \(error.localizedDescription)"
        case .noTextDetected:
            return "No text was detected in the image"
        case .pdfRenderingFailed:
            return "Failed to render PDF page as image"
        }
    }
    
    public static func == (lhs: VisionTextExtractionError, rhs: VisionTextExtractionError) -> Bool {
        switch (lhs, rhs) {
        case (.imageConversionFailed, .imageConversionFailed),
             (.noTextDetected, .noTextDetected),
             (.pdfRenderingFailed, .pdfRenderingFailed):
            return true
        case (.visionRequestFailed(_), .visionRequestFailed(_)):
            return true // Simplified comparison for testing
        default:
            return false
        }
    }
}

/// Service that uses Apple's Vision framework for enhanced text recognition
public class VisionTextExtractor: VisionTextExtractorProtocol {
    
    private let recognitionLevel: VNRequestTextRecognitionLevel
    private let recognitionLanguages: [String]
    private let minimumTextHeight: Float
    
    /// Initialize with configuration options
    /// - Parameters:
    ///   - recognitionLevel: The level of text recognition accuracy vs speed
    ///   - recognitionLanguages: Languages to prioritize during recognition
    ///   - minimumTextHeight: Minimum height for text to be considered valid
    public init(recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
                recognitionLanguages: [String] = ["en-US"],
                minimumTextHeight: Float = 0.01) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.minimumTextHeight = minimumTextHeight
    }
    
    /// Extract text from an image using Vision framework
    /// - Parameters:
    ///   - image: The image to extract text from
    ///   - completion: Completion handler with extracted text elements or error
    public func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.imageConversionFailed))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = createTextRecognitionRequest(completion: completion)
        
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(.visionRequestFailed(error)))
        }
    }
    
    /// Extract text from PDF document by rendering pages as images
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract text from
    ///   - completion: Completion handler with extracted text elements or error
    public func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        var allTextElements: [TextElement] = []
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var firstError: VisionTextExtractionError?
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            dispatchGroup.enter()
            renderPageAsImage(page: page) { [weak self] result in
                defer { dispatchGroup.leave() }
                
                switch result {
                case .success(let image):
                    self?.extractText(from: image) { textResult in
                        switch textResult {
                        case .success(let textElements):
                            // Adjust coordinates for page offset
                            let adjustedElements = textElements.map { element in
                                var adjustedBounds = element.bounds
                                adjustedBounds.origin.y += CGFloat(pageIndex) * page.bounds(for: .mediaBox).height
                                return TextElement(
                                    text: element.text,
                                    bounds: adjustedBounds,
                                    fontSize: element.fontSize,
                                    confidence: element.confidence
                                )
                            }
                            allTextElements.append(contentsOf: adjustedElements)
                        case .failure(let error):
                            if !hasError {
                                hasError = true
                                firstError = error
                            }
                        }
                    }
                case .failure(let error):
                    if !hasError {
                        hasError = true
                        firstError = error
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError, let error = firstError {
                completion(.failure(error))
            } else if allTextElements.isEmpty {
                completion(.failure(.noTextDetected))
            } else {
                completion(.success(allTextElements))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Create a VNRecognizeTextRequest with appropriate configuration
    private func createTextRecognitionRequest(completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(.visionRequestFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(.noTextDetected))
                return
            }
            
            let textElements = self.processTextObservations(observations)
            
            if textElements.isEmpty {
                completion(.failure(.noTextDetected))
            } else {
                completion(.success(textElements))
            }
        }
        
        request.recognitionLevel = recognitionLevel
        request.recognitionLanguages = recognitionLanguages
        request.usesLanguageCorrection = true
        request.minimumTextHeight = minimumTextHeight
        
        return request
    }
    
    /// Process Vision text observations into TextElement objects
    private func processTextObservations(_ observations: [VNRecognizedTextObservation]) -> [TextElement] {
        var textElements: [TextElement] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            let boundingBox = observation.boundingBox
            
            // Convert normalized coordinates to actual coordinates
            // Note: Vision uses bottom-left origin, need to flip Y coordinate
            let bounds = CGRect(
                x: boundingBox.minX,
                y: 1.0 - boundingBox.maxY,  // Flip Y coordinate
                width: boundingBox.width,
                height: boundingBox.height
            )
            
            // Estimate font size based on bounding box height
            let estimatedFontSize = bounds.height * 72.0  // Convert to points (rough estimate)
            
            let textElement = TextElement(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                bounds: bounds,
                fontSize: estimatedFontSize,
                confidence: confidence
            )
            
            textElements.append(textElement)
        }
        
        return textElements
    }
    
    /// Render a PDF page as a UIImage
    private func renderPageAsImage(page: PDFPage, completion: @escaping (Result<UIImage, VisionTextExtractionError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pageRect = page.bounds(for: .mediaBox)
            
            // Scale factor for better resolution
            let scaleFactor: CGFloat = 2.0
            let scaledSize = CGSize(
                width: pageRect.width * scaleFactor,
                height: pageRect.height * scaleFactor
            )
            
            UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
            guard let context = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    completion(.failure(.pdfRenderingFailed))
                }
                return
            }
            
            // Set white background
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: scaledSize))
            
            // Scale and render the page
            context.scaleBy(x: scaleFactor, y: scaleFactor)
            page.draw(with: .mediaBox, to: context)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                if let image = image {
                    completion(.success(image))
                } else {
                    completion(.failure(.pdfRenderingFailed))
                }
            }
        }
    }
}