import Foundation
import PDFKit

/// Enhanced cache key generator with multi-level deduplication support
/// Provides intelligent cache key generation based on content, structure, and semantics
final class EnhancedCacheKeyGenerator {
    
    // MARK: - Dependencies
    
    private let fingerprintGenerator: DocumentFingerprintGenerator
    
    // MARK: - Configuration
    
    private struct KeyConfig {
        static let maxKeyLength = 255 // Maximum cache key length
        static let contextSeparator = "_"
        static let versionPrefix = "v2" // Cache key version for compatibility
    }
    
    // MARK: - Cache Management
    
    /// Cache for generated keys to avoid recomputation
    private var keyCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.payslipmax.cachekey", attributes: .concurrent)
    private let maxCacheSize = 500
    
    // MARK: - Initialization
    
    init(fingerprintGenerator: DocumentFingerprintGenerator = DocumentFingerprintGenerator()) {
        self.fingerprintGenerator = fingerprintGenerator
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
        
        // Check cache first
        let quickHash = generateQuickHash(data: data, context: context)
        if let cachedKey = getCachedKey(quickHash) {
            return cachedKey
        }
        
        // Generate comprehensive fingerprint
        let fingerprint = await fingerprintGenerator.generateFingerprint(data: data, document: document)
        
        // Build enhanced key
        let enhancedKey = buildEnhancedKey(fingerprint: fingerprint, context: context)
        
        // Cache the result
        setCachedKey(quickHash, enhancedKey)
        
        return enhancedKey
    }
    
    /// Generate standard cache key for basic operations
    func generateStandardCacheKey(data: Data, context: ProcessingContext = .general) async -> String {
        let contentHash = await fingerprintGenerator.generateContentHash(data: data)
        return "\(KeyConfig.versionPrefix)\(KeyConfig.contextSeparator)\(context.rawValue)\(KeyConfig.contextSeparator)\(contentHash.prefix(32))"
    }
    
    /// Generate semantic cache key for content-based matching
    func generateSemanticCacheKey(document: PDFDocument, context: ProcessingContext = .general) async -> String {
        let keywords = await fingerprintGenerator.extractSemanticKeywords(document: document)
        let semanticHash = generateSemanticHash(keywords: keywords)
        return "\(KeyConfig.versionPrefix)\(KeyConfig.contextSeparator)semantic\(KeyConfig.contextSeparator)\(context.rawValue)\(KeyConfig.contextSeparator)\(semanticHash)"
    }
    
    /// Check if two cache keys represent similar content
    func areKeysSimilar(_ key1: String, _ key2: String, threshold: Double = 0.8) -> Bool {
        // Extract fingerprint information from keys (simplified implementation)
        let components1 = key1.components(separatedBy: KeyConfig.contextSeparator)
        let components2 = key2.components(separatedBy: KeyConfig.contextSeparator)
        
        guard components1.count >= 3, components2.count >= 3 else { return false }
        
        // Compare content hashes
        if components1.count > 3 && components2.count > 3 {
            let hash1 = components1[3]
            let hash2 = components2[3]
            return hash1 == hash2
        }
        
        return false
    }
    
    /// Clear cache to free memory
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.keyCache.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func buildEnhancedKey(fingerprint: DocumentFingerprint, context: ProcessingContext) -> String {
        var keyComponents = [
            KeyConfig.versionPrefix,
            "enhanced",
            context.rawValue
        ]
        
        // Add content hash (truncated for key length)
        keyComponents.append(String(fingerprint.contentHash.prefix(16)))
        
        // Add structural fingerprint if available
        if let structural = fingerprint.structuralFingerprint {
            let structuralKey = "\(structural.pageCount)p\(structural.hasImages ? "i" : "")\(structural.hasText ? "t" : "")"
            keyComponents.append(structuralKey)
        }
        
        // Add semantic fingerprint if available
        if let semantic = fingerprint.semanticFingerprint {
            let semanticKey = "\(semantic.documentType)\(semantic.languageHint)"
            keyComponents.append(semanticKey)
            
            // Add top keywords (limited)
            if !semantic.topKeywords.isEmpty {
                let keywordHash = generateSemanticHash(keywords: semantic.topKeywords.prefix(5).map { String($0) })
                keyComponents.append(String(keywordHash.prefix(8)))
            }
        }
        
        let fullKey = keyComponents.joined(separator: KeyConfig.contextSeparator)
        
        // Ensure key length doesn't exceed limits
        if fullKey.count > KeyConfig.maxKeyLength {
            return String(fullKey.prefix(KeyConfig.maxKeyLength))
        }
        
        return fullKey
    }
    
    private func generateQuickHash(data: Data, context: ProcessingContext) -> String {
        let sampleSize = min(data.count, 1024) // Sample first 1KB for quick hash
        let sampleData = data.prefix(sampleSize)
        let hash = sampleData.withUnsafeBytes { bytes in
            var hasher = Hasher()
            hasher.combine(bytes: UnsafeRawBufferPointer(start: bytes.bindMemory(to: UInt8.self).baseAddress, count: bytes.count))
            hasher.combine(context.rawValue)
            return hasher.finalize()
        }
        return String(hash)
    }
    
    private func generateSemanticHash(keywords: [String]) -> String {
        let combinedKeywords = keywords.joined(separator: "_").lowercased()
        let data = combinedKeywords.data(using: .utf8) ?? Data()
        let hash = data.withUnsafeBytes { bytes in
            var hasher = Hasher()
            hasher.combine(bytes: UnsafeRawBufferPointer(start: bytes.bindMemory(to: UInt8.self).baseAddress, count: bytes.count))
            return hasher.finalize()
        }
        return String(hash)
    }
    
    private func getCachedKey(_ quickHash: String) -> String? {
        return cacheQueue.sync {
            return keyCache[quickHash]
        }
    }
    
    private func setCachedKey(_ quickHash: String, _ key: String) {
        cacheQueue.async(flags: .barrier) {
            // Ensure cache doesn't grow too large
            if self.keyCache.count >= self.maxCacheSize {
                // Remove oldest entries (simplified LRU)
                let keysToRemove = Array(self.keyCache.keys.prefix(self.maxCacheSize / 4))
                keysToRemove.forEach { self.keyCache.removeValue(forKey: $0) }
            }
            
            self.keyCache[quickHash] = key
        }
    }
}

// MARK: - Processing Context

/// Processing context for cache key generation
enum ProcessingContext: String, CaseIterable {
    case general = "gen"
    case validation = "val"
    case textExtraction = "txt"
    case formatDetection = "fmt"
    case processing = "proc"
    case defense = "def"
    case civilian = "civ"
    case testing = "test"
    
    /// Get context from pipeline stage
    static func from(stage: String) -> ProcessingContext {
        switch stage.lowercased() {
        case "validation", "validate": return .validation
        case "text", "extraction": return .textExtraction
        case "format", "detection": return .formatDetection
        case "processing", "process": return .processing
        case "military", "defense", "pcda": return .defense
        case "civilian": return .civilian
        case "test", "testing": return .testing
        default: return .general
        }
    }
}

// MARK: - Deduplication Statistics

/// Statistics for tracking deduplication effectiveness
struct DeduplicationStatistics: Codable {
    var totalKeyGenerations: Int = 0
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var averageKeyGenerationTime: TimeInterval = 0.0
    var semanticMatches: Int = 0
    var structuralMatches: Int = 0
    var contentMatches: Int = 0
    
    /// Cache hit rate percentage
    var cacheHitRate: Double {
        let totalAttempts = cacheHits + cacheMisses
        return totalAttempts > 0 ? (Double(cacheHits) / Double(totalAttempts)) * 100.0 : 0.0
    }
    
    /// Total deduplication effectiveness
    var deduplicationEffectiveness: Double {
        let totalMatches = semanticMatches + structuralMatches + contentMatches
        return totalKeyGenerations > 0 ? (Double(totalMatches) / Double(totalKeyGenerations)) * 100.0 : 0.0
    }
}
