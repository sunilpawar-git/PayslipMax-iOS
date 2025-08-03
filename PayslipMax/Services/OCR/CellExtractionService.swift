import Vision
import CoreGraphics
import UIKit

/// Advanced cell-level text extraction and processing service
class CellExtractionService {
    
    // MARK: - Configuration
    private struct ExtractionConfig {
        static let minConfidenceThreshold: Float = 0.5
        static let maxTextCandidates: Int = 3
        static let cellPaddingRatio: Double = 0.05
        static let multiLineDetectionThreshold: Double = 0.02
        static let numericValidationThreshold: Double = 0.8
    }
    
    // MARK: - Dependencies
    private let imageProcessor: AdvancedImageProcessor
    
    // MARK: - Testing Support
    var isTestMode: Bool = false
    var testModeResults: [String: String] = [:]
    
    init(imageProcessor: AdvancedImageProcessor = AdvancedImageProcessor()) {
        self.imageProcessor = imageProcessor
    }
    
    // MARK: - Cell Text Extraction
    func extractTextFromCells(
        _ cellMatrix: [[TableCell]],
        originalImage: UIImage
    ) async -> CellExtractionResult {
        
        var extractedCells: [[ExtractedCellData]] = []
        var processingMetrics = CellProcessingMetrics()
        
        let startTime = Date()
        
        for (rowIndex, cellRow) in cellMatrix.enumerated() {
            var extractedRow: [ExtractedCellData] = []
            
            for (colIndex, cell) in cellRow.enumerated() {
                let cellData = await extractSingleCell(
                    cell,
                    from: originalImage,
                    at: CellPosition(row: rowIndex, column: colIndex)
                )
                
                extractedRow.append(cellData)
                processingMetrics.totalCellsProcessed += 1
                
                if cellData.confidence > ExtractionConfig.minConfidenceThreshold {
                    processingMetrics.successfulExtractions += 1
                }
            }
            
            extractedCells.append(extractedRow)
        }
        
        processingMetrics.totalProcessingTime = Date().timeIntervalSince(startTime)
        
        // Post-process extracted data for consistency
        let postProcessedCells = postProcessExtractedCells(extractedCells)
        
        return CellExtractionResult(
            extractedCells: postProcessedCells,
            metrics: processingMetrics,
            overallConfidence: calculateOverallConfidence(postProcessedCells)
        )
    }
    
    // MARK: - Single Cell Extraction
    private func extractSingleCell(
        _ cell: TableCell,
        from image: UIImage,
        at position: CellPosition
    ) async -> ExtractedCellData {
        
        // Crop cell region with padding
        guard let cellImage = cropCellImage(cell, from: image) else {
            return createEmptyCellData(position)
        }
        
        // Optimize cell image for OCR
        let optimizedCellImage = imageProcessor.optimizeForOCR(cellImage)
        
        // Perform text recognition on cell
        let recognitionResult = await performCellTextRecognition(optimizedCellImage)
        
        // Extract and validate text content
        let extractedText = processRecognitionResult(recognitionResult, cellType: cell.cellType)
        
        // Perform cell-specific validation
        let validationResult = validateCellContent(extractedText, expectedType: cell.cellType)
        
        return ExtractedCellData(
            position: position,
            rawText: extractedText.rawText,
            processedText: extractedText.processedText,
            confidence: recognitionResult.confidence,
            cellType: cell.cellType,
            validationResult: validationResult,
            boundingBox: cell.boundingBox,
            textCandidates: recognitionResult.alternatives,
            metadata: CellMetadata(
                multiLine: recognitionResult.isMultiLine,
                hasNumericContent: extractedText.hasNumericContent,
                languageDetection: recognitionResult.detectedLanguage
            )
        )
    }
    
    // MARK: - Image Processing
    private func cropCellImage(_ cell: TableCell, from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Convert normalized coordinates to pixel coordinates
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Add padding to cell bounds
        let padding = min(cell.boundingBox.width, cell.boundingBox.height) * ExtractionConfig.cellPaddingRatio
        
        let expandedBounds = CGRect(
            x: max(0, cell.boundingBox.minX - padding),
            y: max(0, cell.boundingBox.minY - padding),
            width: min(1.0 - cell.boundingBox.minX, cell.boundingBox.width + 2 * padding),
            height: min(1.0 - cell.boundingBox.minY, cell.boundingBox.height + 2 * padding)
        )
        
        let pixelBounds = CGRect(
            x: expandedBounds.minX * imageSize.width,
            y: (1.0 - expandedBounds.maxY) * imageSize.height,
            width: expandedBounds.width * imageSize.width,
            height: expandedBounds.height * imageSize.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: pixelBounds) else { return nil }
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    // MARK: - Text Recognition
    private func performCellTextRecognition(_ image: UIImage) async -> CellRecognitionResult {
        // Test mode support - return mock results for testing
        if isTestMode {
            return createTestModeResult()
        }
        
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: CellRecognitionResult.empty)
                return
            }
            
            var isResumed = false
            
            let request = VNRecognizeTextRequest { request, error in
                guard !isResumed else { return }
                
                if error != nil {
                    isResumed = true
                    continuation.resume(returning: CellRecognitionResult.empty)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    isResumed = true
                    continuation.resume(returning: CellRecognitionResult.empty)
                    return
                }
                
                let result = self.processTextObservations(observations)
                isResumed = true
                continuation.resume(returning: result)
            }
            
            // Configure for high accuracy cell-level OCR
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "hi-IN"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.005
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                guard !isResumed else { return }
                isResumed = true
                continuation.resume(returning: CellRecognitionResult.empty)
            }
        }
    }
    
    private func processTextObservations(_ observations: [VNRecognizedTextObservation]) -> CellRecognitionResult {
        guard !observations.isEmpty else {
            return CellRecognitionResult.empty
        }
        
        // Extract text candidates with confidence
        var textCandidates: [TextCandidate] = []
        var totalConfidence: Float = 0.0
        
        for observation in observations {
            let candidates = observation.topCandidates(ExtractionConfig.maxTextCandidates)
            
            for candidate in candidates {
                textCandidates.append(TextCandidate(
                    text: candidate.string,
                    confidence: candidate.confidence,
                    boundingBox: observation.boundingBox
                ))
                
                totalConfidence += candidate.confidence
            }
        }
        
        let averageConfidence = totalConfidence / Float(max(textCandidates.count, 1))
        
        // Detect multi-line content
        let isMultiLine = detectMultiLineContent(observations)
        
        // Detect language
        let detectedLanguage = detectPrimaryLanguage(textCandidates)
        
        return CellRecognitionResult(
            textCandidates: textCandidates,
            confidence: averageConfidence,
            isMultiLine: isMultiLine,
            detectedLanguage: detectedLanguage,
            alternatives: Array(textCandidates.prefix(ExtractionConfig.maxTextCandidates))
        )
    }
    
    // MARK: - Text Processing
    private func processRecognitionResult(
        _ result: CellRecognitionResult,
        cellType: CellType
    ) -> ProcessedTextContent {
        
        guard let primaryCandidate = result.textCandidates.first else {
            return ProcessedTextContent.empty
        }
        
        let rawText = primaryCandidate.text
        var processedText = rawText
        
        // Apply cell-type specific processing
        switch cellType {
        case .amount:
            processedText = processNumericText(rawText)
        case .header:
            processedText = processHeaderText(rawText)
        case .code:
            processedText = processGeneralText(rawText)
        case .empty:
            processedText = ""
        case .total:
            processedText = processNumericText(rawText)
        case .unknown:
            processedText = processGeneralText(rawText)
        }
        
        let hasNumericContent = containsNumericContent(processedText)
        
        return ProcessedTextContent(
            rawText: rawText,
            processedText: processedText,
            hasNumericContent: hasNumericContent
        )
    }
    
    private func processNumericText(_ text: String) -> String {
        // Clean and standardize numeric content
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common OCR artifacts in numbers
        cleaned = cleaned.replacingOccurrences(of: "O", with: "0")
        cleaned = cleaned.replacingOccurrences(of: "l", with: "1")
        cleaned = cleaned.replacingOccurrences(of: "I", with: "1")
        
        // Standardize currency symbols
        cleaned = cleaned.replacingOccurrences(of: "Rs.", with: "₹")
        cleaned = cleaned.replacingOccurrences(of: "Rs", with: "₹")
        
        return cleaned
    }
    
    private func processHeaderText(_ text: String) -> String {
        return text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func processGeneralText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Validation
    private func validateCellContent(
        _ content: ProcessedTextContent,
        expectedType: CellType
    ) -> CellValidationResult {
        
        var validationErrors: [CellValidationError] = []
        var confidenceAdjustment: Double = 1.0
        
        switch expectedType {
        case .amount:
            if !content.hasNumericContent {
                validationErrors.append(.typeValidationFailed("Expected numeric content"))
                confidenceAdjustment *= 0.5
            }
            
        case .total:
            if !content.hasNumericContent {
                validationErrors.append(.typeValidationFailed("Expected numeric content"))
                confidenceAdjustment *= 0.5
            }
            
        case .header:
            if content.processedText.count < 2 {
                validationErrors.append(.contentValidationFailed("Header too short"))
                confidenceAdjustment *= 0.7
            }
            
        case .code:
            if content.processedText.isEmpty {
                validationErrors.append(.contentValidationFailed("Empty text cell"))
                confidenceAdjustment *= 0.3
            }
            
        case .empty:
            if !content.processedText.isEmpty {
                validationErrors.append(.typeValidationFailed("Expected empty cell"))
                confidenceAdjustment *= 0.8
            }
            
        case .unknown:
            // No specific validation for unknown types
            break
        }
        
        return CellValidationResult(
            isValid: validationErrors.isEmpty,
            errors: validationErrors,
            confidenceAdjustment: confidenceAdjustment
        )
    }
    
    // MARK: - Post-Processing
    private func postProcessExtractedCells(_ cells: [[ExtractedCellData]]) -> [[ExtractedCellData]] {
        var processedCells = cells
        
        // Apply cross-cell validation and correction
        processedCells = applyCrossValidation(processedCells)
        
        // Standardize currency and numeric formats
        processedCells = standardizeFormats(processedCells)
        
        // Apply military payslip specific corrections
        processedCells = applyMilitarySpecificCorrections(processedCells)
        
        return processedCells
    }
    
    private func applyCrossValidation(_ cells: [[ExtractedCellData]]) -> [[ExtractedCellData]] {
        // Look for patterns and consistency across cells
        return cells
    }
    
    private func standardizeFormats(_ cells: [[ExtractedCellData]]) -> [[ExtractedCellData]] {
        // Standardize number formats, dates, and currency
        return cells
    }
    
    private func applyMilitarySpecificCorrections(_ cells: [[ExtractedCellData]]) -> [[ExtractedCellData]] {
        // Apply military payslip specific text corrections
        return cells
    }
    
    // MARK: - Helper Methods
    private func createEmptyCellData(_ position: CellPosition) -> ExtractedCellData {
        return ExtractedCellData(
            position: position,
            rawText: "",
            processedText: "",
            confidence: 0.0,
            cellType: .empty,
            validationResult: CellValidationResult(isValid: true, errors: [], confidenceAdjustment: 1.0),
            boundingBox: CGRect.zero,
            textCandidates: [],
            metadata: CellMetadata(multiLine: false, hasNumericContent: false, languageDetection: .english)
        )
    }
    
    private func calculateOverallConfidence(_ cells: [[ExtractedCellData]]) -> Double {
        let allCells = cells.flatMap { $0 }
        guard !allCells.isEmpty else { return 0.0 }
        
        let totalConfidence = allCells.reduce(0.0) { sum, cell in
            sum + Double(cell.confidence) * cell.validationResult.confidenceAdjustment
        }
        
        return totalConfidence / Double(allCells.count)
    }
    
    private func detectMultiLineContent(_ observations: [VNRecognizedTextObservation]) -> Bool {
        guard observations.count > 1 else { return false }
        
        let yPositions = observations.map { $0.boundingBox.midY }
        let minY = yPositions.min() ?? 0
        let maxY = yPositions.max() ?? 0
        
        return (maxY - minY) > ExtractionConfig.multiLineDetectionThreshold
    }
    
    private func detectPrimaryLanguage(_ candidates: [TextCandidate]) -> DetectedLanguage {
        // Simple language detection based on character patterns
        let combinedText = candidates.map { $0.text }.joined(separator: " ")
        
        let hindiPattern = #"[\u0900-\u097F]"#
        if combinedText.range(of: hindiPattern, options: .regularExpression) != nil {
            return .hindi
        }
        
        return .english
    }
    
    private func containsNumericContent(_ text: String) -> Bool {
        let numericPattern = #"[\d₹,.%]"#
        return text.range(of: numericPattern, options: .regularExpression) != nil
    }
    
    // MARK: - Test Mode Support
    private func createTestModeResult() -> CellRecognitionResult {
        let testText = testModeResults["defaultText"] ?? "Mock Text"
        let confidence = Float(testModeResults["confidence"] ?? "0.9") ?? 0.9
        
        // Create text candidate, but handle empty text scenarios
        let actualText = testText.isEmpty ? "" : testText
        let textCandidate = TextCandidate(
            text: actualText,
            confidence: actualText.isEmpty ? 0.0 : confidence,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 50)
        )
        
        return CellRecognitionResult(
            textCandidates: [textCandidate],
            confidence: actualText.isEmpty ? 0.0 : confidence,
            isMultiLine: false,
            detectedLanguage: .english,
            alternatives: []
        )
    }
    
    // Test mode enhancement to use cell-specific text
    private func createTestModeResultForCell(_ cell: TableCell) -> CellRecognitionResult {
        // Try to extract meaningful text from the cell context
        let cellText = testModeResults["cell_\(cell.position.row)_\(cell.position.column)"] ?? 
                      testModeResults["defaultText"] ?? 
                      "Mock \(cell.position.row),\(cell.position.column)"
        
        let confidence = Float(testModeResults["confidence"] ?? "0.9") ?? 0.9
        
        let textCandidate = TextCandidate(
            text: cellText,
            confidence: confidence,
            boundingBox: cell.boundingBox
        )
        
        return CellRecognitionResult(
            textCandidates: [textCandidate],
            confidence: confidence,
            isMultiLine: false,
            detectedLanguage: cellText.range(of: "[हिन्दी]", options: .regularExpression) != nil ? .hindi : .english,
            alternatives: []
        )
    }
}

// MARK: - Supporting Data Structures
struct CellExtractionResult {
    let extractedCells: [[ExtractedCellData]]
    let metrics: CellProcessingMetrics
    let overallConfidence: Double
}

struct ExtractedCellData {
    let position: CellPosition
    let rawText: String
    let processedText: String
    let confidence: Float
    let cellType: CellType
    let validationResult: CellValidationResult
    let boundingBox: CGRect
    let textCandidates: [TextCandidate]
    let metadata: CellMetadata
}

struct CellRecognitionResult {
    let textCandidates: [TextCandidate]
    let confidence: Float
    let isMultiLine: Bool
    let detectedLanguage: DetectedLanguage
    let alternatives: [TextCandidate]
    
    static let empty = CellRecognitionResult(
        textCandidates: [],
        confidence: 0.0,
        isMultiLine: false,
        detectedLanguage: .english,
        alternatives: []
    )
}

struct TextCandidate {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

struct ProcessedTextContent {
    let rawText: String
    let processedText: String
    let hasNumericContent: Bool
    
    static let empty = ProcessedTextContent(
        rawText: "",
        processedText: "",
        hasNumericContent: false
    )
}

struct CellValidationResult {
    let isValid: Bool
    let errors: [CellValidationError]
    let confidenceAdjustment: Double
}

enum CellValidationError {
    case typeValidationFailed(String)
    case contentValidationFailed(String)
    case formatValidationFailed(String)
}

struct CellMetadata {
    let multiLine: Bool
    let hasNumericContent: Bool
    let languageDetection: DetectedLanguage
}

enum DetectedLanguage {
    case english
    case hindi
    case mixed
}

struct CellProcessingMetrics {
    var totalCellsProcessed: Int = 0
    var successfulExtractions: Int = 0
    var totalProcessingTime: TimeInterval = 0.0
    
    var successRate: Double {
        guard totalCellsProcessed > 0 else { return 0.0 }
        return Double(successfulExtractions) / Double(totalCellsProcessed)
    }
}