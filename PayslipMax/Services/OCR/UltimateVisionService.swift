import Vision
import UIKit
import CoreImage

/// Ultimate Vision OCR service with complete Vision framework integration
class UltimateVisionService: VisionPayslipParserProtocol {
    
    // MARK: - Properties
    private let documentDetector: DocumentDetectionService
    private let textAnalyzer: GeometricTextAnalyzer
    private let imageProcessor: AdvancedImageProcessor
    private let confidenceCalculator: ConfidenceCalculatorProtocol
    private let languageDetector: LanguageDetectorProtocol
    
    // MARK: - Initialization
    init(
        documentDetector: DocumentDetectionService = DocumentDetectionService(),
        textAnalyzer: GeometricTextAnalyzer = GeometricTextAnalyzer(),
        imageProcessor: AdvancedImageProcessor = AdvancedImageProcessor(),
        confidenceCalculator: ConfidenceCalculatorProtocol = ConfidenceCalculator(),
        languageDetector: LanguageDetectorProtocol = LanguageDetector()
    ) {
        self.documentDetector = documentDetector
        self.textAnalyzer = textAnalyzer
        self.imageProcessor = imageProcessor
        self.confidenceCalculator = confidenceCalculator
        self.languageDetector = languageDetector
    }
    
    // MARK: - Ultimate OCR Pipeline
    func performUltimateOCR(_ image: UIImage) async -> UltimateOCRResult {
        // 1. Document boundary detection and rectification
        let documentBounds = await documentDetector.detectDocumentBounds(in: image)
        let rectifiedImage = imageProcessor.rectifyDocument(image, bounds: documentBounds)
        
        // 2. Advanced image preprocessing
        let optimizedImage = imageProcessor.optimizeForOCR(rectifiedImage)
        
        // 3. Table structure detection
        let tableStructure = await detectTableStructure(in: optimizedImage)
        
        // 4. Multi-language text recognition with geometric analysis
        let textResult = await performGeometricTextRecognition(optimizedImage, tableStructure: tableStructure)
        
        // 5. Spatial text association for tabular data
        let structuredData = textAnalyzer.associateTextWithTableStructure(textResult, tableStructure)
        
        return UltimateOCRResult(
            rawText: textResult.text,
            structuredData: structuredData,
            tableStructure: tableStructure,
            confidence: textResult.confidence,
            processingMetrics: textResult.metrics
        )
    }
    
    // MARK: - Document Structure Detection
    private func detectTableStructure(in image: UIImage) async -> TableStructure {
        // Use VNDetectTextRectangles for precise cell boundary detection
        let textRectangles = await detectTextRectangles(in: image)
        
        // Use VNDetectRectangles for layout analysis
        let documentSegments = await detectDocumentRectangles(in: image)
        
        // Combine results to identify table structure
        return textAnalyzer.buildTableStructure(
            textRectangles: textRectangles,
            documentSegments: documentSegments
        )
    }
    
    private func detectTextRectangles(in image: UIImage) async -> [VNRecognizedTextObservation] {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: [])
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations)
            }
            
            // Configure for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func detectDocumentRectangles(in image: UIImage) async -> [VNRectangleObservation] {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: [])
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                let observations = request.results as? [VNRectangleObservation] ?? []
                continuation.resume(returning: observations)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Geometric Text Recognition
    private func performGeometricTextRecognition(_ image: UIImage, tableStructure: TableStructure) async -> GeometricTextResult {
        // Configure advanced text recognition
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en-US", "hi-IN"] // English and Hindi
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01 // Detect small text in tables
        
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: GeometricTextResult.empty)
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let observations = request.results else {
                    continuation.resume(returning: GeometricTextResult.empty)
                    return
                }
                
                // Perform geometric analysis
                let result = self.textAnalyzer.analyzeTextGeometry(
                    observations: observations,
                    tableStructure: tableStructure
                )
                
                continuation.resume(returning: result)
            } catch {
                continuation.resume(returning: GeometricTextResult.empty)
            }
        }
    }
}

// MARK: - Supporting Protocols
protocol VisionPayslipParserProtocol {
    func performUltimateOCR(_ image: UIImage) async -> UltimateOCRResult
}

protocol ConfidenceCalculatorProtocol {
    func calculateConfidence(from observations: [VNRecognizedTextObservation]) -> Double
}

protocol LanguageDetectorProtocol {
    func detectLanguage(in text: String) -> String
}

// MARK: - Data Models
struct UltimateOCRResult {
    let rawText: String
    let structuredData: StructuredTableData
    let tableStructure: TableStructure
    let confidence: Double
    let processingMetrics: ProcessingMetrics
}

struct GeometricTextResult {
    let text: String
    let observations: [VNRecognizedTextObservation]
    let confidence: Double
    let metrics: ProcessingMetrics
    
    static let empty = GeometricTextResult(
        text: "",
        observations: [],
        confidence: 0.0,
        metrics: ProcessingMetrics()
    )
}

struct ProcessingMetrics {
    let processingTime: TimeInterval
    let memoryUsage: UInt64
    let textDetectionCount: Int
    
    init(processingTime: TimeInterval = 0, memoryUsage: UInt64 = 0, textDetectionCount: Int = 0) {
        self.processingTime = processingTime
        self.memoryUsage = memoryUsage
        self.textDetectionCount = textDetectionCount
    }
}

// MARK: - Default Implementations
class ConfidenceCalculator: ConfidenceCalculatorProtocol {
    func calculateConfidence(from observations: [VNRecognizedTextObservation]) -> Double {
        guard !observations.isEmpty else { return 0.0 }
        
        let totalConfidence = observations.reduce(0.0) { sum, observation in
            sum + Double(observation.confidence)
        }
        
        return totalConfidence / Double(observations.count)
    }
}

class LanguageDetector: LanguageDetectorProtocol {
    func detectLanguage(in text: String) -> String {
        // Simple heuristic for now - can be enhanced with NLLanguageRecognizer
        let hindiCharacterSet = CharacterSet(charactersIn: "\u{0900}...\u{097F}")
        let hasHindiCharacters = text.rangeOfCharacter(from: hindiCharacterSet) != nil
        
        return hasHindiCharacters ? "hi-IN" : "en-US"
    }
}