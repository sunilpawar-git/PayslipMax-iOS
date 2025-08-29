import Foundation
import CryptoKit
import OSLog

/// Manages LiteRT model versioning, validation, and metadata
@MainActor
public class LiteRTModelManager {

    // MARK: - Singleton

    public static let shared = LiteRTModelManager()

    private init() {
        setupLogging()
        loadModelMetadata()
    }

    // MARK: - Properties

    private let modelsDirectory = "Models"
    private let metadataFilename = "model_metadata.json"
    private var modelMetadata: LiteRTModelMetadata?

    // Logger instance (using print statements for now)
    // private let logger = Logger()

    // MARK: - Public Methods

    /// Get the models directory URL
    public func getModelsDirectory() -> URL? {
        guard let bundleURL = Bundle.main.resourceURL else {
            print("[LiteRTModelManager] Failed to get bundle resource URL")
            return nil
        }
        return bundleURL.appendingPathComponent(modelsDirectory)
    }

    /// Get model file URL for a specific model
    public func getModelURL(for modelType: LiteRTModelType) -> URL? {
        guard let modelsDir = getModelsDirectory() else { return nil }
        let filename = getModelFilename(for: modelType)
        return modelsDir.appendingPathComponent(filename)
    }

    /// Check if a model file exists and is valid
    public func isModelAvailable(_ modelType: LiteRTModelType) -> Bool {
        guard let modelURL = getModelURL(for: modelType) else { return false }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelURL.path) else { return false }

        // Validate file size
        do {
            let attributes = try fileManager.attributesOfItem(atPath: modelURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            return fileSize > 0
        } catch {
            print("[LiteRTModelManager] Failed to get file attributes for \(modelType.rawValue): \(error)")
            return false
        }
    }

    /// Validate model integrity using checksum
    public func validateModelIntegrity(_ modelType: LiteRTModelType) async -> Bool {
        guard let modelURL = getModelURL(for: modelType),
              let modelInfo = getModelInfo(for: modelType) else {
            return false
        }

        do {
            let data = try Data(contentsOf: modelURL)
            let checksum = calculateSHA256Checksum(data)

            // Compare with expected checksum from metadata
            if let expectedChecksum = modelInfo.checksum, !expectedChecksum.isEmpty {
                return checksum == expectedChecksum
            }

            // If no checksum in metadata, at least validate file size
            return data.count == modelInfo.sizeBytes
        } catch {
            print("[LiteRTModelManager] Failed to validate model \(modelType.rawValue): \(error)")
            return false
        }
    }

    /// Get model information from metadata
    public func getModelInfo(for modelType: LiteRTModelType) -> LiteRTModelInfo? {
        return modelMetadata?.models[modelType.rawValue]
    }

    /// Get all available models
    public func getAvailableModels() -> [LiteRTModelType] {
        return LiteRTModelType.allCases.filter { isModelAvailable($0) }
    }

    /// Get model version information
    public func getModelVersion(_ modelType: LiteRTModelType) -> String? {
        return getModelInfo(for: modelType)?.version
    }

    /// Update model metadata after downloading new models
    public func updateModelMetadata() {
        loadModelMetadata()
    }

    /// Calculate checksum for data validation
    public func calculateSHA256Checksum(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Get model performance targets
    public func getPerformanceTarget(for modelType: LiteRTModelType) -> TimeInterval? {
        guard let targetMs = getModelInfo(for: modelType)?.performanceTargetMs else { return nil }
        return TimeInterval(targetMs) / 1000.0
    }

    /// Get model accuracy baseline
    public func getAccuracyBaseline(for modelType: LiteRTModelType) -> Double? {
        return getModelInfo(for: modelType)?.accuracyBaseline
    }

    // MARK: - Private Methods

    private func setupLogging() {
        print("[LiteRTModelManager] LiteRTModelManager initialized")
    }

    private func loadModelMetadata() {
        guard let metadataURL = getMetadataURL() else {
            print("[LiteRTModelManager] Could not get metadata URL")
            return
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            modelMetadata = try decoder.decode(LiteRTModelMetadata.self, from: data)
            print("[LiteRTModelManager] Model metadata loaded successfully")
        } catch {
            print("[LiteRTModelManager] Failed to load model metadata: \(error)")
            // Create default metadata if file doesn't exist
            createDefaultMetadata()
        }
    }

    private func getMetadataURL() -> URL? {
        guard let modelsDir = getModelsDirectory() else { return nil }
        return modelsDir.appendingPathComponent(metadataFilename)
    }

    private func getModelFilename(for modelType: LiteRTModelType) -> String {
        switch modelType {
        // Phase 3 Core Models
        case .tableDetection:
            return "table_detection.tflite"
        case .textRecognition:
            return "text_recognition.tflite"
        case .documentClassifier:
            return "document_classifier.tflite"

        // Phase 4 Advanced Models
        case .financialValidation:
            return "financial_validation.tflite"
        case .anomalyDetection:
            return "anomaly_detection.tflite"
        case .layoutAnalysis:
            return "layout_analysis.tflite"
        case .languageDetection:
            return "language_detection.tflite"
        }
    }

    private func createDefaultMetadata() {
        modelMetadata = LiteRTModelMetadata(
            version: "1.0.0",
            models: [:],
            metadata: LiteRTModelMetadataInfo(
                createdAt: Date(),
                updatedAt: Date(),
                frameworkVersion: "LiteRT-1.0.0",
                compatibilityVersion: "iOS-15.0+",
                totalSizeMb: 0.0
            )
        )
        print("[LiteRTModelManager] Default model metadata created")
    }
}

// MARK: - Supporting Types

/// LiteRT model types
public enum LiteRTModelType: String, CaseIterable, Sendable {
    // Phase 3 Core Models
    case tableDetection = "table_detection"
    case textRecognition = "text_recognition"
    case documentClassifier = "document_classifier"

    // Phase 4 Advanced Models
    case financialValidation = "financial_validation"
    case anomalyDetection = "anomaly_detection"
    case layoutAnalysis = "layout_analysis"
    case languageDetection = "language_detection"
}

/// Model metadata structure
public struct LiteRTModelMetadata: Codable, Sendable {
    public let version: String
    public let models: [String: LiteRTModelInfo]
    public let metadata: LiteRTModelMetadataInfo
}

/// Individual model information
public struct LiteRTModelInfo: Codable, Sendable {
    public let filename: String
    public let version: String
    public let sizeBytes: Int
    public let checksum: String?
    public let description: String
    public let inputShape: [Int]
    public let outputShape: [Int]
    public let supportedFormats: [String]?
    public let supportedLanguages: [String]?
    public let accuracyBaseline: Double
    public let performanceTargetMs: Int

    private enum CodingKeys: String, CodingKey {
        case filename, version, sizeBytes = "size_bytes", checksum, description
        case inputShape = "input_shape", outputShape = "output_shape"
        case supportedFormats = "supported_formats", supportedLanguages = "supported_languages"
        case accuracyBaseline = "accuracy_baseline", performanceTargetMs = "performance_target_ms"
    }
}

/// Model metadata information
public struct LiteRTModelMetadataInfo: Codable, Sendable {
    public let createdAt: Date
    public let updatedAt: Date
    public let frameworkVersion: String
    public let compatibilityVersion: String
    public let totalSizeMb: Double

    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at", updatedAt = "updated_at"
        case frameworkVersion = "framework_version", compatibilityVersion = "compatibility_version"
        case totalSizeMb = "total_size_mb"
    }
}
