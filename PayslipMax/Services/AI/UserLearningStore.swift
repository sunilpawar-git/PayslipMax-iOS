import Foundation
import SwiftData
import Combine

/// Protocol for user learning data storage
public protocol UserLearningStoreProtocol {
    func storeCorrection(_ correction: UserCorrection) async throws
    func getUserPatterns(for documentType: LiteRTDocumentFormatType) async throws -> [UserPattern]
    func getCorrections(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> [UserCorrection]
    func getFieldCorrections(for field: String, documentType: LiteRTDocumentFormatType) async throws -> [UserCorrection]
    func getAllCorrections() async throws -> [UserCorrection]
    func updateConfidenceAdjustment(field: String, documentType: LiteRTDocumentFormatType, adjustment: Double) async throws
}

/// Store for user learning data with privacy-preserving storage
@MainActor
public class UserLearningStore: UserLearningStoreProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private var corrections: [UserCorrection] = []
    private var patterns: [UserPattern] = []
    private var confidenceAdjustments: [String: [LiteRTDocumentFormatType: Double]] = [:]
    private let maxStoredCorrections = 1000 // Limit for privacy
    private let dataRetentionDays = 90 // 3 months retention
    
    @Published public var storageStats: StorageStatistics = StorageStatistics()
    
    // MARK: - Initialization
    
    public init() {
        Task {
            await loadStoredData()
            await cleanupOldData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Store a user correction
    public func storeCorrection(_ correction: UserCorrection) async throws {
        print("[UserLearningStore] Storing correction for field: \(correction.fieldName)")
        
        // Add to memory store
        corrections.append(correction)
        
        // Maintain storage limits
        await enforceStorageLimits()
        
        // Update patterns
        await updatePatterns(with: correction)
        
        // Update statistics
        await updateStorageStatistics()
        
        // Persist to disk (in production, this would use Core Data or similar)
        await persistData()
        
        print("[UserLearningStore] Correction stored successfully")
    }
    
    /// Get user patterns for document type
    public func getUserPatterns(for documentType: LiteRTDocumentFormatType) async throws -> [UserPattern] {
        return patterns.filter { pattern in
            // Filter patterns based on corrections for this document type
            let relatedCorrections = corrections.filter { $0.documentType == documentType && $0.fieldName == pattern.fieldName }
            return !relatedCorrections.isEmpty
        }
    }
    
    /// Get corrections for specific parser and document type
    public func getCorrections(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> [UserCorrection] {
        return corrections.filter { $0.parserUsed == parser && $0.documentType == documentType }
    }
    
    /// Get corrections for specific field and document type
    public func getFieldCorrections(for field: String, documentType: LiteRTDocumentFormatType) async throws -> [UserCorrection] {
        return corrections.filter { $0.fieldName == field && $0.documentType == documentType }
    }
    
    /// Get all corrections
    public func getAllCorrections() async throws -> [UserCorrection] {
        return corrections
    }
    
    /// Update confidence adjustment for field
    public func updateConfidenceAdjustment(field: String, documentType: LiteRTDocumentFormatType, adjustment: Double) async throws {
        if confidenceAdjustments[field] == nil {
            confidenceAdjustments[field] = [:]
        }
        confidenceAdjustments[field]?[documentType] = adjustment
        
        await persistData()
    }
    
    /// Get confidence adjustment for field
    public func getConfidenceAdjustment(field: String, documentType: LiteRTDocumentFormatType) async -> Double {
        return confidenceAdjustments[field]?[documentType] ?? 0.0
    }
    
    /// Clear all learning data (for privacy)
    public func clearAllData() async throws {
        corrections.removeAll()
        patterns.removeAll()
        confidenceAdjustments.removeAll()
        
        await updateStorageStatistics()
        await persistData()
        
        print("[UserLearningStore] All learning data cleared")
    }
    
    /// Export learning data for backup
    public func exportLearningData() async throws -> LearningDataExport {
        return LearningDataExport(
            corrections: corrections,
            patterns: [],
            validations: [],
            exportDate: Date(),
            version: "1.0"
        )
    }
    
    /// Import learning data from backup
    public func importLearningData(_ data: LearningDataExport) async throws {
        // Validate data version
        guard data.version == "1.0" else {
            throw LearningStoreError.incompatibleVersion(data.version)
        }
        
        // Import corrections
        corrections.append(contentsOf: data.corrections)
        
        // Enforce limits after import
        await enforceStorageLimits()
        
        // Update patterns
        for correction in data.corrections {
            await updatePatterns(with: correction)
        }
        
        await persistData()
        
        print("[UserLearningStore] Learning data imported successfully")
    }
    
    // MARK: - Private Methods
    
    /// Load stored data from persistent storage
    private func loadStoredData() async {
        // In production, this would load from Core Data, SQLite, or other persistent store
        // For now, we'll start with empty data
        print("[UserLearningStore] Loading stored data")
        
        await updateStorageStatistics()
    }
    
    /// Clean up old data based on retention policy
    private func cleanupOldData() async {
        let cutoffDate = Date().addingTimeInterval(-Double(dataRetentionDays) * 24 * 3600)
        
        let initialCount = corrections.count
        corrections.removeAll { $0.timestamp < cutoffDate }
        
        let removedCount = initialCount - corrections.count
        if removedCount > 0 {
            print("[UserLearningStore] Cleaned up \(removedCount) old corrections")
            await updateStorageStatistics()
            await persistData()
        }
    }
    
    /// Enforce storage limits for privacy
    private func enforceStorageLimits() async {
        if corrections.count > maxStoredCorrections {
            // Remove oldest corrections
            corrections.sort { $0.timestamp < $1.timestamp }
            let excessCount = corrections.count - maxStoredCorrections
            corrections.removeFirst(excessCount)
            
            print("[UserLearningStore] Enforced storage limit, removed \(excessCount) old corrections")
        }
    }
    
    /// Update patterns based on new correction
    private func updatePatterns(with correction: UserCorrection) async {
        // Find existing pattern for this field
        if let existingIndex = patterns.firstIndex(where: { $0.fieldName == correction.fieldName && $0.type == .fieldExtraction }) {
            // Update existing pattern
            let existingPattern = patterns[existingIndex]
            
            // Check if this correction matches the pattern
            if existingPattern.commonValue == correction.correctedValue {
                // Increase frequency and confidence
                let newFrequency = existingPattern.frequency + 1
                let newConfidence = min(1.0, existingPattern.confidence + 0.1)
                
                let updatedPattern = UserPattern(
                    id: existingPattern.id,
                    fieldName: existingPattern.fieldName,
                    type: existingPattern.type,
                    commonValue: existingPattern.commonValue,
                    preferredParser: existingPattern.preferredParser,
                    validationRule: existingPattern.validationRule,
                    confidence: newConfidence,
                    frequency: newFrequency
                )
                
                patterns[existingIndex] = updatedPattern
            }
        } else {
            // Create new pattern
            let newPattern = UserPattern(
                fieldName: correction.fieldName,
                type: .fieldExtraction,
                commonValue: correction.correctedValue,
                confidence: 0.3, // Start with low confidence
                frequency: 1
            )
            
            patterns.append(newPattern)
        }
        
        // Update parser preference pattern
        await updateParserPreferencePattern(correction)
    }
    
    /// Update parser preference patterns
    private func updateParserPreferencePattern(_ correction: UserCorrection) async {
        if let existingIndex = patterns.firstIndex(where: { $0.fieldName == correction.fieldName && $0.type == .parserPreference }) {
            // Update existing parser preference
            let existingPattern = patterns[existingIndex]
            
            if existingPattern.preferredParser == correction.parserUsed {
                let newFrequency = existingPattern.frequency + 1
                let newConfidence = min(1.0, existingPattern.confidence + 0.05)
                
                let updatedPattern = UserPattern(
                    id: existingPattern.id,
                    fieldName: existingPattern.fieldName,
                    type: existingPattern.type,
                    commonValue: existingPattern.commonValue,
                    preferredParser: existingPattern.preferredParser,
                    validationRule: existingPattern.validationRule,
                    confidence: newConfidence,
                    frequency: newFrequency
                )
                
                patterns[existingIndex] = updatedPattern
            }
        } else {
            // Create new parser preference pattern
            let newPattern = UserPattern(
                fieldName: correction.fieldName,
                type: .parserPreference,
                commonValue: "",
                preferredParser: correction.parserUsed,
                confidence: 0.2,
                frequency: 1
            )
            
            patterns.append(newPattern)
        }
    }
    
    /// Update storage statistics
    private func updateStorageStatistics() async {
        storageStats.totalCorrections = corrections.count
        storageStats.totalPatterns = patterns.count
        storageStats.lastUpdateDate = Date()
        
        // Calculate data usage estimate
        let correctionSize = corrections.count * 200 // Rough estimate: 200 bytes per correction
        let patternSize = patterns.count * 100 // Rough estimate: 100 bytes per pattern
        storageStats.estimatedDataUsage = correctionSize + patternSize
        
        // Calculate field distribution
        let fieldCounts = corrections.reduce(into: [:]) { counts, correction in
            counts[correction.fieldName, default: 0] += 1
        }
        storageStats.fieldDistribution = fieldCounts
        
        // Calculate document type distribution
        let docTypeCounts = corrections.reduce(into: [:]) { counts, correction in
            counts[correction.documentType.rawValue, default: 0] += 1
        }
        storageStats.documentTypeDistribution = docTypeCounts
    }
    
    /// Persist data to storage
    private func persistData() async {
        // In production, this would persist to Core Data, SQLite, or other storage
        // For now, we'll just simulate the operation
        print("[UserLearningStore] Persisting data to storage")
    }
    
    /// Get patterns for specific criteria
    public func getPatterns(field: String? = nil, type: UserPatternType? = nil) async -> [UserPattern] {
        return patterns.filter { pattern in
            if let field = field, pattern.fieldName != field {
                return false
            }
            if let type = type, pattern.type != type {
                return false
            }
            return true
        }
    }
}

// MARK: - Supporting Classes

/// Statistics about stored learning data
public struct StorageStatistics {
    public var totalCorrections: Int = 0
    public var totalPatterns: Int = 0
    public var lastUpdateDate: Date?
    public var estimatedDataUsage: Int = 0 // in bytes
    public var fieldDistribution: [String: Int] = [:]
    public var documentTypeDistribution: [String: Int] = [:]
}

/// Errors for learning store operations
public enum LearningStoreError: Error, LocalizedError {
    case incompatibleVersion(String)
    case storageQuotaExceeded
    case dataCorruption
    case persistenceFailure(Error)
    
    public var errorDescription: String? {
        switch self {
        case .incompatibleVersion(let version):
            return "Incompatible data version: \(version)"
        case .storageQuotaExceeded:
            return "Storage quota exceeded"
        case .dataCorruption:
            return "Data corruption detected"
        case .persistenceFailure(let error):
            return "Failed to persist data: \(error.localizedDescription)"
        }
    }
}
