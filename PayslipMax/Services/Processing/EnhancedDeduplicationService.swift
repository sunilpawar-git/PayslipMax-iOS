import Foundation
import PDFKit
import Combine

/// Enhanced deduplication service that implements semantic document fingerprinting
/// and multi-level content-based deduplication for optimal processing efficiency
final class EnhancedDeduplicationServiceSimplified {
    
    // MARK: - Dependencies
    
    private let fingerprintGenerator: DocumentFingerprintGenerator
    private let cacheKeyGenerator: EnhancedCacheKeyGenerator
    
    // MARK: - Configuration
    
    private struct DeduplicationConfig {
        static let contentHashCacheSize = 1000 // Maximum number of content hashes to keep
        static let similarityThreshold = 0.85 // Threshold for considering documents similar
        static let maxProcessingHistory = 500 // Maximum processing history to keep
    }
    
    // MARK: - Properties
    
    /// Cache for computed content hashes to avoid recomputation
    private var contentHashCache: [String: String] = [:]
    
    /// Cache for document fingerprints
    private var fingerprintCache: [String: DocumentFingerprint] = [:]
    
    /// Processing history for deduplication tracking
    private var processingHistory: [ProcessingRecord] = []
    
    
    /// Deduplication metrics tracking
    @Published private(set) var deduplicationStats = DeduplicationStatistics()
    
    // MARK: - Initialization
    
    init(fingerprintGenerator: DocumentFingerprintGenerator? = nil,
         cacheKeyGenerator: EnhancedCacheKeyGenerator? = nil) {
        self.fingerprintGenerator = fingerprintGenerator ?? DocumentFingerprintGenerator()
        self.cacheKeyGenerator = cacheKeyGenerator ?? EnhancedCacheKeyGenerator()
    }
    
    // MARK: - Public Interface
    
    /// Generate enhanced cache key with multi-level deduplication
    /// - Parameters:
    ///   - data: PDF data for content-based hashing
    ///   - document: Optional PDFDocument for semantic analysis
    ///   - context: Processing context for additional identification
    /// - Returns: Enhanced cache key with content and semantic fingerprints
    func generateEnhancedCacheKey(data: Data, 
                                 document: PDFDocument? = nil,
                                 context: ProcessingContext = .general) async -> String {
        let startTime = Date()
        
        let key = await cacheKeyGenerator.generateEnhancedCacheKey(data: data, document: document, context: context)
        
        // Update statistics
        let duration = Date().timeIntervalSince(startTime)
        updateKeyGenerationStats(duration: duration)
        
        return key
    }
    
    /// Check if document has been processed before (deduplication check)
    /// - Parameters:
    ///   - data: PDF data to check
    ///   - document: Optional PDFDocument for enhanced matching
    /// - Returns: ProcessingRecord if duplicate found, nil otherwise
    func checkForDuplicate(data: Data, document: PDFDocument? = nil) async -> ProcessingRecord? {
        let fingerprint = await fingerprintGenerator.generateFingerprint(data: data, document: document)
        
        // Use actor-isolated access to processing history
        return await MainActor.run {
            // Check exact content match first
            if let exactMatch = self.processingHistory.first(where: { $0.fingerprint.contentHash == fingerprint.contentHash }) {
                self.recordMatch(type: .content)
                return exactMatch
            }
            
            // Check semantic similarity
            for record in self.processingHistory {
                let similarity = fingerprint.similarity(to: record.fingerprint)
                if similarity >= DeduplicationConfig.similarityThreshold {
                    self.recordMatch(type: similarity > 0.95 ? .structural : .semantic)
                    return record
                }
            }
            
            return nil
        }
    }
    
    /// Record successful processing for future deduplication
    /// - Parameters:
    ///   - data: Processed PDF data
    ///   - document: Processed PDFDocument
    ///   - result: Processing result to associate with this document
    func recordProcessing(data: Data, document: PDFDocument?, result: Any) async {
        let fingerprint = await fingerprintGenerator.generateFingerprint(data: data, document: document)
        
        let record = ProcessingRecord(
            fingerprint: fingerprint,
            result: result,
            processedAt: Date()
        )
        
        await addProcessingRecord(record)
    }
    
    /// Find similar documents in processing history
    /// - Parameters:
    ///   - data: PDF data to compare
    ///   - document: Optional PDFDocument for enhanced matching
    ///   - threshold: Similarity threshold (0.0-1.0)
    /// - Returns: Array of similar processing records
    func findSimilarDocuments(data: Data, document: PDFDocument? = nil, threshold: Double = 0.7) async -> [ProcessingRecord] {
        let fingerprint = await fingerprintGenerator.generateFingerprint(data: data, document: document)
        
        return await MainActor.run {
            let similarRecords = self.processingHistory.compactMap { record in
                let similarity = fingerprint.similarity(to: record.fingerprint)
                return similarity >= threshold ? record : nil
            }.sorted { record1, record2 in
                let sim1 = fingerprint.similarity(to: record1.fingerprint)
                let sim2 = fingerprint.similarity(to: record2.fingerprint)
                return sim1 > sim2
            }
            
            return similarRecords
        }
    }
    
    /// Clear deduplication caches to free memory
    func clearCaches() async {
        await MainActor.run {
            self.contentHashCache.removeAll()
            self.fingerprintCache.removeAll()
            self.processingHistory.removeAll()
        }
        
        cacheKeyGenerator.clearCache()
    }
    
    /// Get current deduplication statistics
    func getStatistics() -> DeduplicationStatistics {
        return deduplicationStats
    }
    
    // MARK: - Private Methods
    
    private func addProcessingRecord(_ record: ProcessingRecord) async {
        await MainActor.run {
            self.processingHistory.append(record)
            
            // Prune old records if needed
            if self.processingHistory.count > DeduplicationConfig.maxProcessingHistory {
                self.processingHistory.removeFirst(self.processingHistory.count - DeduplicationConfig.maxProcessingHistory)
            }
        }
    }
    
    private func updateKeyGenerationStats(duration: TimeInterval) {
        deduplicationStats.totalKeyGenerations += 1
        
        // Update rolling average
        let count = Double(deduplicationStats.totalKeyGenerations)
        let currentAvg = deduplicationStats.averageKeyGenerationTime
        deduplicationStats.averageKeyGenerationTime = ((currentAvg * (count - 1)) + duration) / count
    }
    
    @MainActor
    private func recordMatch(type: MatchType) {
        switch type {
        case .content:
            deduplicationStats.contentMatches += 1
        case .structural:
            deduplicationStats.structuralMatches += 1
        case .semantic:
            deduplicationStats.semanticMatches += 1
        }
    }
}

// MARK: - Supporting Types

/// Record of processed document for deduplication tracking
struct ProcessingRecord: Codable {
    let fingerprint: DocumentFingerprint
    let result: Data // Serialized processing result
    let processedAt: Date
    
    init(fingerprint: DocumentFingerprint, result: Any, processedAt: Date) {
        self.fingerprint = fingerprint
        self.processedAt = processedAt
        
        // Serialize result (simplified - in production use proper serialization)
        if let data = result as? Data {
            self.result = data
        } else if let codable = result as? Codable {
            self.result = (try? JSONEncoder().encode(AnyEncodable(codable))) ?? Data()
        } else {
            self.result = String(describing: result).data(using: .utf8) ?? Data()
        }
    }
}

/// Type of deduplication match
private enum MatchType {
    case content    // Exact content match
    case structural // Similar structure
    case semantic   // Similar semantic content
}

/// Helper for encoding any codable type
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
