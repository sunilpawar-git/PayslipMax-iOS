import Foundation

// MARK: - Document Fingerprint and Similarity Analysis

/// Complete document fingerprint with all levels of analysis
struct DocumentFingerprint: Codable, Hashable {
    let contentHash: String
    let structuralFingerprint: DocumentFingerprintGenerator.StructuralFingerprint?
    let semanticFingerprint: DocumentFingerprintGenerator.SemanticFingerprint?
    let generatedAt: Date
    
    /// Generate composite key from all available fingerprints
    func compositeKey() -> String {
        var components = [contentHash]
        
        if let structural = structuralFingerprint {
            components.append(structural.structuralHash)
        }
        
        if let semantic = semanticFingerprint {
            components.append(semantic.contentPattern)
            components.append(semantic.topKeywords.prefix(5).joined(separator: "_"))
        }
        
        return components.joined(separator: "_")
    }
    
    /// Check similarity with another fingerprint
    func similarity(to other: DocumentFingerprint) -> Double {
        var similarity = 0.0
        var factors = 0
        
        // Content similarity (exact match or not)
        if contentHash == other.contentHash {
            similarity += 1.0
        }
        factors += 1
        
        // Structural similarity
        if let selfStructural = structuralFingerprint,
           let otherStructural = other.structuralFingerprint {
            let structuralSimilarity = calculateStructuralSimilarity(selfStructural, otherStructural)
            similarity += structuralSimilarity
            factors += 1
        }
        
        // Semantic similarity
        if let selfSemantic = semanticFingerprint,
           let otherSemantic = other.semanticFingerprint {
            let semanticSimilarity = calculateSemanticSimilarity(selfSemantic, otherSemantic)
            similarity += semanticSimilarity
            factors += 1
        }
        
        return factors > 0 ? similarity / Double(factors) : 0.0
    }
    
    private func calculateStructuralSimilarity(_ a: DocumentFingerprintGenerator.StructuralFingerprint, 
                                             _ b: DocumentFingerprintGenerator.StructuralFingerprint) -> Double {
        var score = 0.0
        var factors = 0
        
        // Page count similarity
        let pageCountDiff = abs(a.pageCount - b.pageCount)
        score += max(0.0, 1.0 - Double(pageCountDiff) / 10.0)
        factors += 1
        
        // Boolean properties
        if a.hasImages == b.hasImages { score += 1.0 }
        if a.hasText == b.hasText { score += 1.0 }
        factors += 2
        
        return score / Double(factors)
    }
    
    private func calculateSemanticSimilarity(_ a: DocumentFingerprintGenerator.SemanticFingerprint, 
                                           _ b: DocumentFingerprintGenerator.SemanticFingerprint) -> Double {
        var score = 0.0
        var factors = 0
        
        // Keyword overlap
        let aKeywords = Set(a.topKeywords)
        let bKeywords = Set(b.topKeywords)
        let intersection = aKeywords.intersection(bKeywords)
        let union = aKeywords.union(bKeywords)
        
        if !union.isEmpty {
            score += Double(intersection.count) / Double(union.count)
            factors += 1
        }
        
        // Document type similarity
        if a.documentType == b.documentType {
            score += 1.0
        }
        factors += 1
        
        // Content pattern similarity
        if a.contentPattern == b.contentPattern {
            score += 1.0
        }
        factors += 1
        
        return factors > 0 ? score / Double(factors) : 0.0
    }
}
