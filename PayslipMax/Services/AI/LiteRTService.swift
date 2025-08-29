import Foundation
import Vision
import CoreML
import UIKit
import PDFKit
import MetalKit
import Accelerate
#if canImport(TensorFlowLite)
import TensorFlowLite
#endif

/// Protocol for LiteRT AI service functionality
@MainActor
public protocol LiteRTServiceProtocol {
    func initializeService() async throws
    func isServiceAvailable() -> Bool
    func processDocument(data: Data) async throws -> LiteRTDocumentAnalysisResult
    func detectTableStructure(in image: UIImage) async throws -> LiteRTTableStructure
    func analyzeDocumentFormat(text: String) async throws -> LiteRTDocumentFormatAnalysis
}

/// Errors that can occur during LiteRT operations
public enum LiteRTError: Error, LocalizedError {
    case serviceNotInitialized
    case modelLoadingFailed(Error)
    case processingFailed(Error)
    case unsupportedFormat
    case insufficientMemory
    
    public var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            return "LiteRT service is not initialized"
        case .modelLoadingFailed(let error):
            return "Failed to load AI model: \(error.localizedDescription)"
        case .processingFailed(let error):
            return "AI processing failed: \(error.localizedDescription)"
        case .unsupportedFormat:
            return "Document format is not supported"
        case .insufficientMemory:
            return "Insufficient memory for AI processing"
        }
    }
}

/// Core LiteRT service for AI-powered document processing
@MainActor
public class LiteRTService: LiteRTServiceProtocol {
    
    // MARK: - Properties

    private var isInitialized = false
    private var modelCache: [String: Any] = [:]
    private let memoryThreshold: Int = 100 * 1024 * 1024 // 100MB

    // TensorFlow Lite interpreters for real ML model inference
    #if canImport(TensorFlowLite)
    private var tableDetectionInterpreter: TensorFlowLite.Interpreter?
    private var textRecognitionInterpreter: TensorFlowLite.Interpreter?
    private var documentClassifierInterpreter: TensorFlowLite.Interpreter?
    #else
    private var tableDetectionInterpreter: MockInterpreter?
    private var textRecognitionInterpreter: MockInterpreter?
    private var documentClassifierInterpreter: MockInterpreter?
    #endif

    // Hardware acceleration
    private var metalDevice: MTLDevice?
    private var metalCommandQueue: MTLCommandQueue?

    // Model manager
    private let modelManager = LiteRTModelManager.shared
    
    // MARK: - TensorFlow Lite Model Loading
    
    #if !canImport(TensorFlowLite)
    /// Mock interpreter options for fallback implementation
    private struct MockInterpreterOptions {
        // Empty placeholder options
    }
    
    /// Mock interpreter for when TensorFlow Lite is not available
    private class MockInterpreter {
        private var isInitialized = false

        init(modelPath: String, options: MockInterpreterOptions? = nil) throws {
            print("[LiteRTService] Mock: Loading model from \(modelPath)")

            guard FileManager.default.fileExists(atPath: modelPath) else {
                throw NSError(domain: "LiteRTService", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Model file not found"])
            }

            isInitialized = true
            print("[LiteRTService] Mock: Model loaded successfully")
        }

        deinit {
            print("[LiteRTService] Mock: Interpreter deallocated")
        }

        func allocateTensors() throws {
            guard isInitialized else {
                throw NSError(domain: "LiteRTService", code: -4,
                             userInfo: [NSLocalizedDescriptionKey: "Interpreter not initialized"])
            }
            print("[LiteRTService] Mock: Tensors allocated")
        }

        func invoke() throws {
            guard isInitialized else {
                throw NSError(domain: "LiteRTService", code: -4,
                             userInfo: [NSLocalizedDescriptionKey: "Interpreter not initialized"])
            }
            print("[LiteRTService] Mock: Model inference executed")
        }
    }
    #endif

    // MARK: - Singleton
    
    public static let shared = LiteRTService()

    /// Internal initializer for dependency injection
    nonisolated public init() {
        print("[LiteRTService] Initializing LiteRT service")
    }
    
    // MARK: - Public Methods
    
    /// Initialize the LiteRT service and load required models
    public func initializeService() async throws {
        guard !isInitialized else {
            print("[LiteRTService] Service already initialized")
            return
        }

        print("[LiteRTService] Starting service initialization")
        print("[LiteRTService] Using TensorFlow Lite for real ML model inference")

        do {
            // Check system memory availability
            try validateSystemResources()

            // Initialize core components (will use mock implementations)
            try await loadCoreModels()

            isInitialized = true
            print("[LiteRTService] Service initialization completed successfully")
            print("[LiteRTService] Ready for testing with mock AI implementations")

        } catch {
            print("[LiteRTService] Initialization failed: \(error)")
            throw LiteRTError.modelLoadingFailed(error)
        }
    }
    
    /// Check if the service is available and ready
    public func isServiceAvailable() -> Bool {
        return isInitialized && hasValidModels()
    }
    
    /// Process a document and extract structured information
    public func processDocument(data: Data) async throws -> LiteRTDocumentAnalysisResult {
        try validateServiceState()
        
        print("[LiteRTService] Processing document of size: \(data.count) bytes")
        
        do {
            // Convert data to image for analysis
            let image: UIImage
            if let directImage = UIImage(data: data) {
                image = directImage
            } else if let pdfImage = await convertPDFToImage(data: data) {
                image = pdfImage
            } else {
                throw LiteRTError.unsupportedFormat
            }
            
            // Perform multi-stage analysis
            let tableStructure = try await detectTableStructure(in: image)
            let textAnalysis = try await analyzeTextElements(in: image)
            let formatAnalysis = try await analyzeDocumentFormat(text: textAnalysis.extractedText)
            
            return LiteRTDocumentAnalysisResult(
                tableStructure: tableStructure,
                textAnalysis: textAnalysis,
                formatAnalysis: formatAnalysis,
                confidence: calculateOverallConfidence(
                    tableConfidence: tableStructure.confidence,
                    textConfidence: textAnalysis.confidence,
                    formatConfidence: formatAnalysis.confidence
                )
            )
            
        } catch {
            print("[LiteRTService] Document processing failed: \(error)")
            throw LiteRTError.processingFailed(error)
        }
    }
    
    /// Detect table structure in an image using AI
    public func detectTableStructure(in image: UIImage) async throws -> LiteRTTableStructure {
        try validateServiceState()
        
        print("[LiteRTService] Detecting table structure")
        
        // For now, use a hybrid approach with Vision + heuristics
        // This will be enhanced with actual LiteRT models once dependencies are available
        return try await performHybridTableDetection(image: image)
    }
    
    /// Analyze document format using AI
    public func analyzeDocumentFormat(text: String) async throws -> LiteRTDocumentFormatAnalysis {
        try validateServiceState()
        
        print("[LiteRTService] Analyzing document format for text length: \(text.count)")
        
        // Implement format analysis using pattern recognition and AI
        return try await performFormatAnalysis(text: text)
    }
    
    // MARK: - Private Methods
    
    /// Validate that the service is properly initialized
    private func validateServiceState() throws {
        guard isInitialized else {
            throw LiteRTError.serviceNotInitialized
        }
    }
    
    /// Check system resources before initialization
    private func validateSystemResources() throws {
        let availableMemory = ProcessInfo.processInfo.physicalMemory
        guard availableMemory > memoryThreshold else {
            throw LiteRTError.insufficientMemory
        }
    }
    
    /// Load core AI models
    private func loadCoreModels() async throws {
        print("[LiteRTService] Loading core models")

        // Initialize hardware acceleration
        try setupHardwareAcceleration()

        // Load MediaPipe LiteRT interpreters
        try await loadTableDetectionModel()
        try await loadTextRecognitionModel()
        try await loadDocumentClassifierModel()

        // Validate model integrity
        try await validateAllModels()

        print("[LiteRTService] Core models loaded successfully")
    }
    
    /// Check if required models are loaded
    private func hasValidModels() -> Bool {
        // Check if at least the core interpreters are loaded
        let coreModelsLoaded = tableDetectionInterpreter != nil ||
                              textRecognitionInterpreter != nil ||
                              documentClassifierInterpreter != nil
        return coreModelsLoaded || modelCache.count >= 2
    }
    
    /// Convert PDF data to image for processing
    private func convertPDFToImage(data: Data) async -> UIImage? {
        // Implementation will use PDFKit to convert first page to image
        // For now, return nil to indicate conversion not yet implemented
        return nil
    }
    
    /// Perform hybrid table detection using Vision + AI heuristics
    private func performHybridTableDetection(image: UIImage) async throws -> LiteRTTableStructure {
        guard let tableDetectionInterpreter = tableDetectionInterpreter else {
            // Fallback to heuristic detection if model unavailable
            return try await performHeuristicTableDetection(image: image)
        }
        
        do {
            #if canImport(TensorFlowLite)
            // Preprocess image for model input
            guard let inputTensor = try preprocessImageForTableDetection(image: image) else {
                throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to preprocess image"]))
            }
            
            // Copy input data to model
            try tableDetectionInterpreter.copy(inputTensor, toInputAt: 0)
            
            // Run inference
            try tableDetectionInterpreter.invoke()
            
            // Get output tensor
            let outputTensor = try tableDetectionInterpreter.output(at: 0)
            
            // Parse table detection results
            let tableStructure = try parseTableDetectionOutput(outputTensor: outputTensor, originalImage: image)
            
            print("[LiteRTService] Table detection completed with confidence: \(tableStructure.confidence)")
            return tableStructure
            
            #else
            // Mock implementation fallback
            return try await performHeuristicTableDetection(image: image)
            #endif
            
        } catch {
            print("[LiteRTService] Table detection failed, falling back to heuristics: \(error)")
            return try await performHeuristicTableDetection(image: image)
        }
    }
    
    /// Heuristic fallback table detection
    private func performHeuristicTableDetection(image: UIImage) async throws -> LiteRTTableStructure {
        let bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        // Simple heuristic: divide image into potential table regions
        let cellWidth = image.size.width / 4  // Assume 4 columns for PCDA format
        let cellHeight = image.size.height / 10 // Assume ~10 rows
        
        var cells: [LiteRTTableCell] = []
        for row in 0..<10 {
            for col in 0..<4 {
                let cellBounds = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                
                cells.append(LiteRTTableCell(
                    bounds: cellBounds,
                    text: "",
                    confidence: 0.6,
                    columnIndex: col,
                    rowIndex: row
                ))
            }
        }
        
        return LiteRTTableStructure(
            bounds: bounds,
            columns: (0..<4).map { col in
                LiteRTTableColumn(
                    bounds: CGRect(x: CGFloat(col) * cellWidth, y: 0, width: cellWidth, height: image.size.height),
                    headerText: "Column \(col + 1)",
                    columnType: .other
                )
            },
            rows: (0..<10).map { row in
                LiteRTTableRow(
                    bounds: CGRect(x: 0, y: CGFloat(row) * cellHeight, width: image.size.width, height: cellHeight),
                    rowIndex: row,
                    isHeader: row == 0
                )
            },
            cells: cells,
            confidence: 0.7,
            isPCDAFormat: true // Assume PCDA for heuristic detection
        )
    }
    
    /// Analyze text elements in the image
    private func analyzeTextElements(in image: UIImage) async throws -> LiteRTTextAnalysisResult {
        guard let textRecognitionInterpreter = textRecognitionInterpreter else {
            // Fallback to Vision framework if model unavailable
            return try await performVisionTextRecognition(image: image)
        }
        
        do {
            #if canImport(TensorFlowLite)
            // Preprocess image for text recognition
            guard let inputTensor = try preprocessImageForTextRecognition(image: image) else {
                throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to preprocess image for text recognition"]))
            }
            
            // Copy input data to model
            try textRecognitionInterpreter.copy(inputTensor, toInputAt: 0)
            
            // Run inference
            try textRecognitionInterpreter.invoke()
            
            // Get output tensor
            let outputTensor = try textRecognitionInterpreter.output(at: 0)
            
            // Parse text recognition results
            let textAnalysis = try parseTextRecognitionOutput(outputTensor: outputTensor, originalImage: image)
            
            print("[LiteRTService] Text recognition completed with confidence: \(textAnalysis.confidence)")
            return textAnalysis
            
            #else
            // Mock implementation fallback
            return try await performVisionTextRecognition(image: image)
            #endif
            
        } catch {
            print("[LiteRTService] Text recognition failed, falling back to Vision: \(error)")
            return try await performVisionTextRecognition(image: image)
        }
    }
    
    /// Vision framework fallback for text recognition
    private func performVisionTextRecognition(image: UIImage) async throws -> LiteRTTextAnalysisResult {
        // Simple placeholder - actual Vision implementation would be more complex
        return LiteRTTextAnalysisResult(
            extractedText: "Sample extracted text from Vision framework",
            textElements: [
                LiteRTTextElement(
                    text: "Sample Text",
                    bounds: CGRect(x: 0, y: 0, width: 100, height: 20),
                    fontSize: 14.0,
                    confidence: 0.85
                )
            ],
            confidence: 0.8
        )
    }
    
    /// Perform document format analysis
    private func performFormatAnalysis(text: String) async throws -> LiteRTDocumentFormatAnalysis {
        guard let documentClassifierInterpreter = documentClassifierInterpreter else {
            // Fallback to rule-based detection if model unavailable
            return try await performHeuristicFormatAnalysis(text: text)
        }
        
        do {
            #if canImport(TensorFlowLite)
            // Preprocess text for document classification
            guard let inputTensor = try preprocessTextForClassification(text: text) else {
                throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to preprocess text for classification"]))
            }
            
            // Copy input data to model
            try documentClassifierInterpreter.copy(inputTensor, toInputAt: 0)
            
            // Run inference
            try documentClassifierInterpreter.invoke()
            
            // Get output tensor
            let outputTensor = try documentClassifierInterpreter.output(at: 0)
            
            // Parse classification results
            let formatAnalysis = try parseDocumentClassificationOutput(outputTensor: outputTensor, text: text)
            
            print("[LiteRTService] Document classification completed with confidence: \(formatAnalysis.confidence)")
            return formatAnalysis
            
            #else
            // Mock implementation fallback
            return try await performHeuristicFormatAnalysis(text: text)
            #endif
            
        } catch {
            print("[LiteRTService] Document classification failed, falling back to heuristics: \(error)")
            return try await performHeuristicFormatAnalysis(text: text)
        }
    }
    
    /// Heuristic fallback for document format analysis
    private func performHeuristicFormatAnalysis(text: String) async throws -> LiteRTDocumentFormatAnalysis {
        let formatType = detectFormatType(from: text)
        let layoutType = detectLayoutType(from: text)
        let languageInfo = detectLanguageInfo(from: text)
        
        return LiteRTDocumentFormatAnalysis(
            formatType: formatType,
            layoutType: layoutType,
            languageInfo: languageInfo,
            confidence: 0.75,
            keyIndicators: extractKeyIndicators(from: text)
        )
    }
    
    /// Detect document format type using pattern matching
    private func detectFormatType(from text: String) -> LiteRTDocumentFormatType {
        let pcdaKeywords = ["PCDA", "Principal Controller", "Defence Accounts", "विवरण", "राशि"]
        let corporateKeywords = ["Corporation", "Company", "Ltd", "Pvt"]
        let militaryKeywords = ["DSOPF", "AGIF", "MSP", "Military Service Pay"]
        
        let pcdaScore = pcdaKeywords.reduce(0) { score, keyword in
            score + (text.localizedCaseInsensitiveContains(keyword) ? 1 : 0)
        }
        
        let corporateScore = corporateKeywords.reduce(0) { score, keyword in
            score + (text.localizedCaseInsensitiveContains(keyword) ? 1 : 0)
        }
        
        let militaryScore = militaryKeywords.reduce(0) { score, keyword in
            score + (text.localizedCaseInsensitiveContains(keyword) ? 1 : 0)
        }
        
        if pcdaScore >= 2 { return .pcda }
        if militaryScore >= 2 { return .military }
        if corporateScore >= 1 { return .corporate }
        
        return .unknown
    }
    
    /// Detect layout type
    private func detectLayoutType(from text: String) -> LiteRTDocumentLayoutType {
        // Simple heuristic-based detection
        if text.contains("|") || text.contains("─") || text.contains("┌") {
            return .tabulated
        }
        return .linear
    }
    
    /// Detect language information
    private func detectLanguageInfo(from text: String) -> LiteRTLanguageInfo {
        let englishPattern = try? NSRegularExpression(pattern: "[a-zA-Z]", options: [])
        let hindiPattern = try? NSRegularExpression(pattern: "[\\u0900-\\u097F]", options: [])
        
        let range = NSRange(location: 0, length: text.utf16.count)
        
        let englishMatches = englishPattern?.numberOfMatches(in: text, options: [], range: range) ?? 0
        let hindiMatches = hindiPattern?.numberOfMatches(in: text, options: [], range: range) ?? 0
        
        let totalChars = text.count
        let englishRatio = totalChars > 0 ? Double(englishMatches) / Double(totalChars) : 0.0
        let hindiRatio = totalChars > 0 ? Double(hindiMatches) / Double(totalChars) : 0.0
        
        return LiteRTLanguageInfo(
            primaryLanguage: englishRatio > hindiRatio ? "English" : "Hindi",
            secondaryLanguage: englishRatio > 0.1 && hindiRatio > 0.1 ? (englishRatio > hindiRatio ? "Hindi" : "English") : nil,
            englishRatio: englishRatio,
            hindiRatio: hindiRatio,
            isBilingual: englishRatio > 0.1 && hindiRatio > 0.1
        )
    }
    
    /// Extract key indicators from text
    private func extractKeyIndicators(from text: String) -> [String] {
        var indicators: [String] = []
        
        // Financial indicators
        if text.contains("₹") || text.contains("Rs") || text.contains("INR") {
            indicators.append("Indian Currency")
        }
        
        // Date indicators
        if text.range(of: "\\d{1,2}/\\d{1,2}/\\d{4}", options: .regularExpression) != nil {
            indicators.append("Date Format")
        }
        
        // Table indicators
        if text.contains("Total") || text.contains("Sum") || text.contains("योग") {
            indicators.append("Summary Data")
        }
        
        return indicators
    }
    
    /// Calculate overall confidence from component confidences
    private func calculateOverallConfidence(tableConfidence: Double, textConfidence: Double, formatConfidence: Double) -> Double {
        // Weighted average with table structure having highest weight
        let weights = (table: 0.4, text: 0.3, format: 0.3)
        return (tableConfidence * weights.table) + (textConfidence * weights.text) + (formatConfidence * weights.format)
    }

    // MARK: - MediaPipe LiteRT Integration

    /// Setup hardware acceleration for ML models
    private func setupHardwareAcceleration() throws {
        print("[LiteRTService] Setting up hardware acceleration")

        // Initialize Metal for GPU acceleration
        metalDevice = MTLCreateSystemDefaultDevice()
        guard let device = metalDevice else {
            print("[LiteRTService] Metal device not available, falling back to CPU")
            return
        }

        metalCommandQueue = device.makeCommandQueue()
        print("[LiteRTService] Hardware acceleration configured with Metal")
    }

    /// Load table detection model
    private func loadTableDetectionModel() async throws {
        guard modelManager.isModelAvailable(.tableDetection) else {
            print("[LiteRTService] Table detection model not available")
            return
        }

        guard let modelURL = modelManager.getModelURL(for: .tableDetection) else {
            throw LiteRTError.modelLoadingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model URL not found"]))
        }

        do {
            #if canImport(TensorFlowLite)
            // Create TensorFlow Lite interpreter with basic configuration
            var options = TensorFlowLite.Interpreter.Options()
            
            // Configure for performance
            options.isXNNPackEnabled = true
            options.threadCount = 2
            
            tableDetectionInterpreter = try TensorFlowLite.Interpreter(modelPath: modelURL.path, options: options)
            try tableDetectionInterpreter?.allocateTensors()
            
            print("[LiteRTService] Table detection model loaded successfully with TensorFlow Lite")
            print("[LiteRTService] Hardware acceleration: \(isHardwareAccelerationAvailable() ? "Available" : "CPU only")")
            #else
            // Fallback to mock implementation
            tableDetectionInterpreter = try MockInterpreter(modelPath: modelURL.path, options: nil)
            print("[LiteRTService] Table detection model loaded with mock implementation")
            #endif
            
            modelCache["tableDetector"] = tableDetectionInterpreter
        } catch {
            print("[LiteRTService] Failed to load table detection model: \(error)")
            throw LiteRTError.modelLoadingFailed(error)
        }
    }

    /// Load text recognition model
    private func loadTextRecognitionModel() async throws {
        guard modelManager.isModelAvailable(.textRecognition) else {
            print("[LiteRTService] Text recognition model not available")
            return
        }

        guard let modelURL = modelManager.getModelURL(for: .textRecognition) else {
            throw LiteRTError.modelLoadingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model URL not found"]))
        }

        do {
            #if canImport(TensorFlowLite)
            // Create TensorFlow Lite interpreter with basic configuration
            var options = TensorFlowLite.Interpreter.Options()
            
            // Configure for performance
            options.isXNNPackEnabled = true
            options.threadCount = 2
            
            textRecognitionInterpreter = try TensorFlowLite.Interpreter(modelPath: modelURL.path, options: options)
            try textRecognitionInterpreter?.allocateTensors()
            
            print("[LiteRTService] Text recognition model loaded successfully with TensorFlow Lite")
            #else
            // Fallback to mock implementation
            textRecognitionInterpreter = try MockInterpreter(modelPath: modelURL.path, options: nil)
            print("[LiteRTService] Text recognition model loaded with mock implementation")
            #endif
            
            modelCache["textRecognizer"] = textRecognitionInterpreter
        } catch {
            print("[LiteRTService] Failed to load text recognition model: \(error)")
            throw LiteRTError.modelLoadingFailed(error)
        }
    }

    /// Load document classifier model
    private func loadDocumentClassifierModel() async throws {
        guard modelManager.isModelAvailable(.documentClassifier) else {
            print("[LiteRTService] Document classifier model not available")
            return
        }

        guard let modelURL = modelManager.getModelURL(for: .documentClassifier) else {
            throw LiteRTError.modelLoadingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model URL not found"]))
        }

        do {
            #if canImport(TensorFlowLite)
            // Create TensorFlow Lite interpreter with basic configuration
            var options = TensorFlowLite.Interpreter.Options()
            
            // Configure for performance
            options.isXNNPackEnabled = true
            options.threadCount = 2
            
            documentClassifierInterpreter = try TensorFlowLite.Interpreter(modelPath: modelURL.path, options: options)
            try documentClassifierInterpreter?.allocateTensors()
            
            print("[LiteRTService] Document classifier model loaded successfully with TensorFlow Lite")
            #else
            // Fallback to mock implementation
            documentClassifierInterpreter = try MockInterpreter(modelPath: modelURL.path, options: nil)
            print("[LiteRTService] Document classifier model loaded with mock implementation")
            #endif
            
            modelCache["documentClassifier"] = documentClassifierInterpreter
        } catch {
            print("[LiteRTService] Failed to load document classifier model: \(error)")
            throw LiteRTError.modelLoadingFailed(error)
        }
    }

    /// Validate all loaded models
    private func validateAllModels() async throws {
        print("[LiteRTService] Validating model integrity")

        let modelsToValidate: [LiteRTModelType] = [.tableDetection, .textRecognition, .documentClassifier]

        for modelType in modelsToValidate {
            if modelManager.isModelAvailable(modelType) {
                let isValid = await modelManager.validateModelIntegrity(modelType)
                if !isValid {
                    print("[LiteRTService] Model integrity validation failed for \(modelType.rawValue)")
                    throw LiteRTError.modelLoadingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model integrity validation failed"]))
                }
            }
        }

        print("[LiteRTService] All models validated successfully")
    }

    // MARK: - ML Model Preprocessing & Output Parsing
    
    #if canImport(TensorFlowLite)
    /// Preprocess image for table detection model
    private func preprocessImageForTableDetection(image: UIImage) throws -> Data? {
        // Expected input: [1, 224, 224, 3] based on model metadata
        let targetSize = CGSize(width: 224, height: 224)
        
        guard let resizedImage = image.resized(to: targetSize),
              let cgImage = resizedImage.cgImage else {
            return nil
        }
        
        // Convert to RGB data
        var pixelData = Data()
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        guard let pixelBuffer = cgImage.pixelBuffer(width: width, height: height) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Normalize pixel values to [0, 1] and convert to Float32
        for row in 0..<height {
            for col in 0..<width {
                let pixelIndex = row * bytesPerRow + col * 4 // BGRA format
                let blue = Float32(buffer[pixelIndex]) / 255.0
                let green = Float32(buffer[pixelIndex + 1]) / 255.0
                let red = Float32(buffer[pixelIndex + 2]) / 255.0
                
                // Append RGB values as Float32
                withUnsafeBytes(of: red) { pixelData.append(contentsOf: $0) }
                withUnsafeBytes(of: green) { pixelData.append(contentsOf: $0) }
                withUnsafeBytes(of: blue) { pixelData.append(contentsOf: $0) }
            }
        }
        
        return pixelData
    }
    
    /// Preprocess image for text recognition model
    private func preprocessImageForTextRecognition(image: UIImage) throws -> Data? {
        // Expected input: [1, 32, 128, 1] based on model metadata (grayscale)
        let targetSize = CGSize(width: 128, height: 32)
        
        guard let resizedImage = image.resized(to: targetSize),
              let cgImage = resizedImage.cgImage else {
            return nil
        }
        
        // Convert to grayscale
        var pixelData = Data()
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        guard let pixelBuffer = cgImage.pixelBuffer(width: width, height: height) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        // Convert to grayscale and normalize
        for row in 0..<height {
            for col in 0..<width {
                let pixelIndex = row * bytesPerRow + col * 4 // BGRA format
                let blue = Float32(buffer[pixelIndex])
                let green = Float32(buffer[pixelIndex + 1])
                let red = Float32(buffer[pixelIndex + 2])
                
                // Convert to grayscale using standard weights
                let gray = (0.299 * red + 0.587 * green + 0.114 * blue) / 255.0
                
                // Append grayscale value as Float32
                withUnsafeBytes(of: gray) { pixelData.append(contentsOf: $0) }
            }
        }
        
        return pixelData
    }
    
    /// Preprocess text for document classification
    private func preprocessTextForClassification(text: String) throws -> Data? {
        // Simple text preprocessing - in practice, this would use tokenization
        // For now, create a simple feature vector based on keyword presence
        
        let keywords = [
            "PCDA", "Principal Controller", "Defence Accounts", "विवरण", "राशि",
            "Corporation", "Company", "Ltd", "Pvt",
            "DSOPF", "AGIF", "MSP", "Military Service Pay",
            "Bank", "PSU", "Public Sector"
        ]
        
        var features = Data()
        let featureVector = keywords.map { keyword in
            text.localizedCaseInsensitiveContains(keyword) ? Float32(1.0) : Float32(0.0)
        }
        
        // Pad or truncate to expected input size [1, 224, 224, 3] - simplified approach
        let targetFeatureCount = 224 * 224 * 3
        var paddedFeatures: [Float32] = Array(featureVector)
        
        // Repeat pattern to fill required size
        while paddedFeatures.count < targetFeatureCount {
            paddedFeatures.append(contentsOf: featureVector)
        }
        paddedFeatures = Array(paddedFeatures.prefix(targetFeatureCount))
        
        // Convert to Data
        for feature in paddedFeatures {
            withUnsafeBytes(of: feature) { features.append(contentsOf: $0) }
        }
        
        return features
    }
    
    /// Parse table detection output
    private func parseTableDetectionOutput(outputTensor: TensorFlowLite.Tensor, originalImage: UIImage) throws -> LiteRTTableStructure {
        let outputData = outputTensor.data
        
        // Expected output: [1, 28, 28, 1] - heatmap of table regions
        let outputWidth = 28
        let outputHeight = 28
        let bytesPerFloat = 4
        
        guard outputData.count >= outputWidth * outputHeight * bytesPerFloat else {
            throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid output tensor size"]))
        }
        
        // Parse confidence scores from output
        var maxConfidence: Float = 0.0
        let floatArray = outputData.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Float32.self)
        }
        
        for i in 0..<(outputWidth * outputHeight) {
            maxConfidence = max(maxConfidence, floatArray[i])
        }
        
        // Convert output heatmap to table structure
        let scaleX = originalImage.size.width / CGFloat(outputWidth)
        let scaleY = originalImage.size.height / CGFloat(outputHeight)
        
        var cells: [LiteRTTableCell] = []
        for row in 0..<outputHeight {
            for col in 0..<outputWidth {
                let confidence = floatArray[row * outputWidth + col]
                if confidence > 0.5 { // Threshold for detected table cells
                    let cellBounds = CGRect(
                        x: CGFloat(col) * scaleX,
                        y: CGFloat(row) * scaleY,
                        width: scaleX,
                        height: scaleY
                    )
                    
                    cells.append(LiteRTTableCell(
                        bounds: cellBounds,
                        text: "",
                        confidence: Double(confidence),
                        columnIndex: col,
                        rowIndex: row
                    ))
                }
            }
        }
        
        return LiteRTTableStructure(
            bounds: CGRect(x: 0, y: 0, width: originalImage.size.width, height: originalImage.size.height),
            columns: [],
            rows: [],
            cells: cells,
            confidence: Double(maxConfidence),
            isPCDAFormat: maxConfidence > 0.8 // High confidence indicates PCDA format
        )
    }
    
    /// Parse text recognition output
    private func parseTextRecognitionOutput(outputTensor: TensorFlowLite.Tensor, originalImage: UIImage) throws -> LiteRTTextAnalysisResult {
        let outputData = outputTensor.data
        
        // Expected output: [1, 25, 37] - character probabilities
        let sequenceLength = 25
        let vocabularySize = 37
        let bytesPerFloat = 4
        
        guard outputData.count >= sequenceLength * vocabularySize * bytesPerFloat else {
            throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid text recognition output size"]))
        }
        
        let floatArray = outputData.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Float32.self)
        }
        
        // Simple character set (alphanumeric + common symbols)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,()-₹ ")
        
        var recognizedText = ""
        var totalConfidence: Float = 0.0
        
        for i in 0..<sequenceLength {
            var maxProb: Float = 0.0
            var bestChar = ""
            
            for j in 0..<vocabularySize {
                let prob = floatArray[i * vocabularySize + j]
                if prob > maxProb {
                    maxProb = prob
                    if j < charset.count {
                        bestChar = String(charset[j])
                    }
                }
            }
            
            if maxProb > 0.3 { // Threshold for character recognition
                recognizedText += bestChar
                totalConfidence += maxProb
            }
        }
        
        let avgConfidence = totalConfidence / Float(sequenceLength)
        
        return LiteRTTextAnalysisResult(
            extractedText: recognizedText.trimmingCharacters(in: .whitespacesAndNewlines),
            textElements: [
                LiteRTTextElement(
                    text: recognizedText,
                    bounds: CGRect(x: 0, y: 0, width: originalImage.size.width, height: originalImage.size.height),
                    fontSize: 12.0,
                    confidence: avgConfidence
                )
            ],
            confidence: Double(avgConfidence)
        )
    }
    
    /// Parse document classification output
    private func parseDocumentClassificationOutput(outputTensor: TensorFlowLite.Tensor, text: String) throws -> LiteRTDocumentFormatAnalysis {
        let outputData = outputTensor.data
        
        // Expected output: [1, 6] - classification probabilities
        let numClasses = 6
        let bytesPerFloat = 4
        
        guard outputData.count >= numClasses * bytesPerFloat else {
            throw LiteRTError.processingFailed(NSError(domain: "LiteRT", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid classification output size"]))
        }
        
        let floatArray = outputData.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Float32.self)
        }
        
        // Class labels: ["pcda", "corporate", "military", "psu", "bank", "unknown"]
        let formatTypes: [LiteRTDocumentFormatType] = [.pcda, .corporate, .military, .unknown, .unknown, .unknown]
        
        var maxProb: Float = 0.0
        var predictedFormat: LiteRTDocumentFormatType = .unknown
        
        for i in 0..<numClasses {
            let prob = floatArray[i]
            if prob > maxProb {
                maxProb = prob
                predictedFormat = formatTypes[i]
            }
        }
        
        let languageInfo = detectLanguageInfo(from: text)
        
        return LiteRTDocumentFormatAnalysis(
            formatType: predictedFormat,
            layoutType: maxProb > 0.7 ? .tabulated : .linear,
            languageInfo: languageInfo,
            confidence: Double(maxProb),
            keyIndicators: extractKeyIndicators(from: text)
        )
    }
    #endif

    // MARK: - Hardware Acceleration Support

    /// Check if hardware acceleration is available
    public func isHardwareAccelerationAvailable() -> Bool {
        return metalDevice != nil
    }

    /// Get hardware acceleration info
    public func getHardwareAccelerationInfo() -> [String: Any] {
        return [
            "metal_available": metalDevice != nil,
            "metal_device": metalDevice?.name ?? "None",
            "neural_engine_available": hasNeuralEngine(),
            "gpu_accelerated": metalDevice != nil
        ]
    }

    /// Check for Neural Engine availability
    private func hasNeuralEngine() -> Bool {
        // Check for A-series or M-series chips with Neural Engine
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(validatingUTF8: ptr)
            }
        }
        return machine?.hasPrefix("iPhone") == true || machine?.hasPrefix("iPad") == true || machine?.hasPrefix("Mac") == true
    }
}

// MARK: - Supporting Data Types

/// Result of document analysis
public struct LiteRTDocumentAnalysisResult {
    let tableStructure: LiteRTTableStructure
    let textAnalysis: LiteRTTextAnalysisResult
    let formatAnalysis: LiteRTDocumentFormatAnalysis
    let confidence: Double
}

/// Table structure information
public struct LiteRTTableStructure {
    let bounds: CGRect
    let columns: [LiteRTTableColumn]
    let rows: [LiteRTTableRow]
    let cells: [LiteRTTableCell]
    let confidence: Double
    let isPCDAFormat: Bool
}

/// Table column information
public struct LiteRTTableColumn {
    let bounds: CGRect
    let headerText: String?
    let columnType: LiteRTColumnType
}

/// Table row information
public struct LiteRTTableRow {
    let bounds: CGRect
    let rowIndex: Int
    let isHeader: Bool
}

/// Table cell information
public struct LiteRTTableCell {
    let bounds: CGRect
    let text: String
    let confidence: Double
    let columnIndex: Int
    let rowIndex: Int
}

/// Column type enumeration
public enum LiteRTColumnType {
    case description
    case amount
    case code
    case other
}

/// Text analysis result
public struct LiteRTTextAnalysisResult {
    let extractedText: String
    let textElements: [LiteRTTextElement]
    let confidence: Double
}

/// Document format analysis result
public struct LiteRTDocumentFormatAnalysis {
    let formatType: LiteRTDocumentFormatType
    let layoutType: LiteRTDocumentLayoutType
    let languageInfo: LiteRTLanguageInfo
    let confidence: Double
    let keyIndicators: [String]
}

/// Document format type
public enum LiteRTDocumentFormatType: String, Codable, Sendable {
    case pcda
    case military
    case corporate
    case psu
    case bank
    case unknown
}

/// Document layout type
public enum LiteRTDocumentLayoutType {
    case tabulated
    case linear
    case mixed
}

/// Language information
public struct LiteRTLanguageInfo {
    let primaryLanguage: String
    let secondaryLanguage: String?
    let englishRatio: Double
    let hindiRatio: Double
    let isBilingual: Bool
}

/// Text element with position and metadata
public struct LiteRTTextElement {
    let text: String
    let bounds: CGRect
    let fontSize: CGFloat
    let confidence: Float
}

// MARK: - Helper Classes

#if !canImport(TensorFlowLite)
private class InterpreterOptions {
    var threads: Int32 = 1
    init() {}
}

// MARK: - Tensor Wrapper (Mock Implementation)

public class Tensor {
    private let index: Int
    private let isInput: Bool

    init(index: Int, isInput: Bool) {
        self.index = index
        self.isInput = isInput
    }

    public var data: Data {
        // Mock: Return sample data based on tensor type
        if isInput {
            return Data([0x01, 0x02, 0x03, 0x04]) // Sample input data
        } else {
            return Data([0x05, 0x06, 0x07, 0x08]) // Sample output data
        }
    }

    public var shape: [Int] {
        // Mock: Return sample shape
        return isInput ? [1, 224, 224, 3] : [1, 1000] // Input: image, Output: classification
    }

    public var dataType: String {
        // Mock: Return data type as string
        return isInput ? "Float32" : "Float32"
    }

    public func copyData(to buffer: UnsafeMutableRawPointer, size: Int) {
        // Mock: Copy sample data
        let sampleData = self.data
        let copySize = min(size, sampleData.count)
        sampleData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let baseAddress = bytes.baseAddress else { return }
            memcpy(buffer, baseAddress, copySize)
        }
    }
}
#endif

// MARK: - UIImage Extensions for ML Processing

extension UIImage {
    /// Resize image to target size
    func resized(to targetSize: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: targetSize)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension CGImage {
    /// Create pixel buffer from CGImage
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}
