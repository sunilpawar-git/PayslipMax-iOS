import Foundation
import Vision
import CoreGraphics
import PDFKit
import UIKit

/// Protocol for Vision-based text extraction services
public protocol VisionTextExtractorProtocol {
    func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void)
    func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void)
    func extractText(from pdfDocument: PDFDocument, progressHandler: ((Double) -> Void)?, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void)
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
    private let preprocessor: ImagePreprocessingServiceProtocol
    
    /// Initialize with configuration options
    /// - Parameters:
    ///   - recognitionLevel: The level of text recognition accuracy vs speed
    ///   - recognitionLanguages: Languages to prioritize during recognition
    ///   - minimumTextHeight: Minimum height for text to be considered valid
    public init(recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
                recognitionLanguages: [String] = ["en-US"],
                minimumTextHeight: Float = 0.01,
                preprocessor: ImagePreprocessingServiceProtocol = ImagePreprocessingService()) {
        self.recognitionLevel = recognitionLevel
        self.recognitionLanguages = recognitionLanguages
        self.minimumTextHeight = minimumTextHeight
        self.preprocessor = preprocessor
    }
    
    /// Extract text from an image using Vision framework
    /// - Parameters:
    ///   - image: The image to extract text from
    ///   - completion: Completion handler with extracted text elements or error
    public func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        _ = PerformanceTimer(operation: "Vision text extraction from image")
        MemoryMonitor.logMemoryUsage(for: "Vision extraction start")
        
        guard let cgImage = image.cgImage else {
            OCRLogger.shared.logVisionError("Image extraction", 
                                          error: VisionTextExtractionError.imageConversionFailed,
                                          details: ["imageSize": "\(image.size)"])
            completion(.failure(.imageConversionFailed))
            return
        }
        
        OCRLogger.shared.logVisionOperation("Starting image text extraction", 
                                          details: ["imageSize": "\(image.size)",
                                                   "recognitionLevel": "\(recognitionLevel)",
                                                   "languages": recognitionLanguages.joined(separator: ",")])
        
        // Preprocess for OCR robustness (contrast, sharpen, pseudo-binarize)
        let processed = preprocessor.preprocess(image)
        let processedCG = processed.cgImage ?? cgImage
        let requestHandler = VNImageRequestHandler(cgImage: processedCG, options: [:])
        let request = createTextRecognitionRequest { result in
            MemoryMonitor.logMemoryUsage(for: "Vision extraction complete")
            completion(result)
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            OCRLogger.shared.logVisionError("Vision request performance", error: error)
            completion(.failure(.visionRequestFailed(error)))
        }
    }
    
    /// Extract text from PDF document by rendering pages as images
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract text from
    ///   - completion: Completion handler with extracted text elements or error
    public func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        extractText(from: pdfDocument, progressHandler: nil, completion: completion)
    }
    
    /// Extract text from PDF document with progress tracking and memory optimization
    /// - Parameters:
    ///   - pdfDocument: The PDF document to extract text from
    ///   - progressHandler: Optional progress handler (0.0 to 1.0)
    ///   - completion: Completion handler with extracted text elements or error
    public func extractText(from pdfDocument: PDFDocument, 
                           progressHandler: ((Double) -> Void)?, 
                           completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        _ = PerformanceTimer(operation: "Vision PDF text extraction")
        let totalPages = pdfDocument.pageCount
        
        OCRLogger.shared.logVisionOperation("Starting PDF text extraction", 
                                          details: ["totalPages": totalPages,
                                                   "recognitionLevel": "\(recognitionLevel)",
                                                   "languages": recognitionLanguages.joined(separator: ",")])
        
        guard totalPages > 0 else {
            OCRLogger.shared.logVisionError("PDF extraction", 
                                          error: VisionTextExtractionError.noTextDetected,
                                          details: ["totalPages": totalPages])
            completion(.failure(.noTextDetected))
            return
        }
        
        MemoryMonitor.logMemoryUsage(for: "PDF extraction start")
        
        let allTextElements: [TextElement] = []
        let processedPages = 0
        let hasError = false
        let firstError: VisionTextExtractionError? = nil
        
        // Process pages sequentially to reduce memory pressure
        processPageSequentially(
            pdfDocument: pdfDocument,
            pageIndex: 0,
            totalPages: totalPages,
            allTextElements: allTextElements,
            processedPages: processedPages,
            hasError: hasError,
            firstError: firstError,
            progressHandler: progressHandler,
            completion: { result in
                MemoryMonitor.logMemoryUsage(for: "PDF extraction complete")
                
                switch result {
                case .success(let elements):
                    OCRLogger.shared.logVisionOperation("PDF extraction completed successfully", 
                                                      details: ["elementsExtracted": elements.count,
                                                               "pagesProcessed": totalPages])
                case .failure(let error):
                    OCRLogger.shared.logVisionError("PDF extraction failed", error: error,
                                                  details: ["pagesProcessed": totalPages])
                }
                
                completion(result)
            }
        )
    }
    
    /// Process PDF pages sequentially to optimize memory usage
    private func processPageSequentially(
        pdfDocument: PDFDocument,
        pageIndex: Int,
        totalPages: Int,
        allTextElements: [TextElement],
        processedPages: Int,
        hasError: Bool,
        firstError: VisionTextExtractionError?,
        progressHandler: ((Double) -> Void)?,
        completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void
    ) {
        guard pageIndex < totalPages else {
            // All pages processed
            if hasError, let error = firstError {
                completion(.failure(error))
            } else if allTextElements.isEmpty {
                completion(.failure(.noTextDetected))
            } else {
                completion(.success(allTextElements))
            }
            return
        }
        
        guard let page = pdfDocument.page(at: pageIndex) else {
            // Skip invalid page and continue
            let newProcessedPages = processedPages + 1
            if let progressHandler = progressHandler {
                progressHandler(Double(newProcessedPages) / Double(totalPages))
            }
            processPageSequentially(
                pdfDocument: pdfDocument,
                pageIndex: pageIndex + 1,
                totalPages: totalPages,
                allTextElements: allTextElements,
                processedPages: newProcessedPages,
                hasError: hasError,
                firstError: firstError,
                progressHandler: progressHandler,
                completion: completion
            )
            return
        }
        
        renderPageAsImage(page: page) { [weak self] result in
            guard let self = self else { return }
            
            var updatedTextElements = allTextElements
            var updatedProcessedPages = processedPages
            var updatedHasError = hasError
            var updatedFirstError = firstError
            
            switch result {
            case .success(let image):
                // Preprocess page image before OCR
                let preprocessed = self.preprocessor.preprocess(image)
                self.extractText(from: preprocessed) { textResult in
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
                        updatedTextElements.append(contentsOf: adjustedElements)
                    case .failure(let error):
                        if !updatedHasError {
                            updatedHasError = true
                            updatedFirstError = error
                        }
                    }
                    
                    updatedProcessedPages += 1
                    if let progressHandler = progressHandler {
                        progressHandler(Double(updatedProcessedPages) / Double(totalPages))
                    }
                    
                    // Continue with next page (allows memory cleanup between pages)
                    DispatchQueue.main.async {
                        self.processPageSequentially(
                            pdfDocument: pdfDocument,
                            pageIndex: pageIndex + 1,
                            totalPages: totalPages,
                            allTextElements: updatedTextElements,
                            processedPages: updatedProcessedPages,
                            hasError: updatedHasError,
                            firstError: updatedFirstError,
                            progressHandler: progressHandler,
                            completion: completion
                        )
                    }
                }
            case .failure(let error):
                if !updatedHasError {
                    updatedHasError = true
                    updatedFirstError = error
                }
                
                updatedProcessedPages += 1
                if let progressHandler = progressHandler {
                    progressHandler(Double(updatedProcessedPages) / Double(totalPages))
                }
                
                // Continue with next page
                DispatchQueue.main.async {
                    self.processPageSequentially(
                        pdfDocument: pdfDocument,
                        pageIndex: pageIndex + 1,
                        totalPages: totalPages,
                        allTextElements: updatedTextElements,
                        processedPages: updatedProcessedPages,
                        hasError: updatedHasError,
                        firstError: updatedFirstError,
                        progressHandler: progressHandler,
                        completion: completion
                    )
                }
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
    
    /// Render a PDF page as a UIImage with memory optimization
    private func renderPageAsImage(page: PDFPage, completion: @escaping (Result<UIImage, VisionTextExtractionError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            autoreleasepool {
                let pageRect = page.bounds(for: .mediaBox)
                
                // Adaptive scale factor with no upscaling to reduce memory usage
                let maxImageSize: CGFloat = 1024.0
                let maxDimension = max(pageRect.width, pageRect.height)
                let scaleFactor = min(1.0, maxImageSize / maxDimension)
                
                let scaledSize = CGSize(
                    width: pageRect.width * scaleFactor,
                    height: pageRect.height * scaleFactor
                )
                
                // Use renderer for better memory management
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let image = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Set white background
                    cgContext.setFillColor(UIColor.white.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    // Scale and render the page
                    cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
                    page.draw(with: .mediaBox, to: cgContext)
                }
                
                DispatchQueue.main.async {
                    completion(.success(image))
                }
            }
        }
    }
}