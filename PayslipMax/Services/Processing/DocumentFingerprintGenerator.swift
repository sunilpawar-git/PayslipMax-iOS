import Foundation
@preconcurrency import PDFKit
import CommonCrypto
import CryptoKit

/// Generates document fingerprints for advanced deduplication
/// Implements multi-level fingerprinting: content → structure → semantic
final class DocumentFingerprintGenerator {
    
    // MARK: - Configuration
    
    private struct FingerprintConfig {
        static let maxFingerprintSize = 50 * 1024 * 1024 // 50MB for large PDF sampling
        static let semanticSamplePages = 5 // Number of pages to sample for semantic analysis
        static let structuralFingerprintSize = 64 // Bytes for structural hash
        static let semanticKeywordCount = 20 // Number of top keywords to extract
    }
    
    // MARK: - Types
    
    /// Structural fingerprint representing PDF layout and organization
    struct StructuralFingerprint: Codable, Hashable {
        let pageCount: Int
        let hasImages: Bool
        let hasText: Bool
        let fontCount: Int
        let colorSpaceCount: Int
        let structuralHash: String
        
        /// Create fingerprint from PDF document
        init(document: PDFDocument) {
            self.pageCount = document.pageCount
            
            var hasImages = false
            var hasText = false
            let fonts: Set<String> = []
            let colorSpaces: Set<String> = []
            
            // Sample first few pages for structural analysis
            let pagesToAnalyze = min(FingerprintConfig.semanticSamplePages, document.pageCount)
            for i in 0..<pagesToAnalyze {
                guard let page = document.page(at: i) else { continue }
                
                // Check for images and text
                if let pageString = page.string, !pageString.isEmpty {
                    hasText = true
                }
                
                // Note: Image and font detection would require more complex PDF parsing
                // For now, we use heuristics based on page content
                if page.bounds(for: .mediaBox).width > 0 && page.bounds(for: .mediaBox).height > 0 {
                    hasImages = true // Simplified detection
                }
            }
            
            self.hasImages = hasImages
            self.hasText = hasText
            self.fontCount = fonts.count
            self.colorSpaceCount = colorSpaces.count
            
            // Create structural hash from properties
            let structuralData = "\(pageCount)_\(hasImages)_\(hasText)_\(fonts.count)_\(colorSpaces.count)"
            self.structuralHash = SHA256.hash(data: structuralData.data(using: .utf8) ?? Data()).compactMap { String(format: "%02x", $0) }.joined()
        }
    }
    
    /// Semantic fingerprint with extracted keywords and content patterns
    struct SemanticFingerprint: Codable, Hashable {
        let topKeywords: [String]
        let contentPattern: String
        let documentType: String
        let languageHint: String
        
        /// Create semantic fingerprint from document text
        init(text: String) {
            // Extract top keywords
            let keywords = Self.extractKeywords(from: text, count: FingerprintConfig.semanticKeywordCount)
            self.topKeywords = keywords
            
            // Create content pattern (simplified)
            self.contentPattern = Self.createContentPattern(from: text)
            
            // Detect document type (simplified heuristics)
            self.documentType = Self.detectDocumentType(from: text)
            
            // Detect language (simplified)
            self.languageHint = Self.detectLanguage(from: text)
        }
        
        private static func extractKeywords(from text: String, count: Int) -> [String] {
            // Simple keyword extraction (in production, use more sophisticated NLP)
            let words = text.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 3 }
                .filter { !commonWords.contains($0) }
            
            let wordFrequency = Dictionary(grouping: words, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            return Array(wordFrequency.prefix(count).map { $0.key })
        }
        
        private static func createContentPattern(from text: String) -> String {
            // Create a pattern based on text structure
            let lines = text.components(separatedBy: .newlines)
            let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let pattern = nonEmptyLines.prefix(10).map { line in
                if line.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil {
                    return "DATE"
                } else if line.range(of: #"\$\d+\.\d{2}"#, options: .regularExpression) != nil {
                    return "CURRENCY"
                } else if line.range(of: #"\d{3}-\d{2}-\d{4}"#, options: .regularExpression) != nil {
                    return "SSN"
                } else if line.count < 50 {
                    return "HEADER"
                } else {
                    return "TEXT"
                }
            }.joined(separator: "_")
            
            return pattern
        }
        
        private static func detectDocumentType(from text: String) -> String {
            let lowercaseText = text.lowercased()
            
            if lowercaseText.contains("earnings statement") || lowercaseText.contains("pay stub") {
                return "payslip"
            } else if lowercaseText.contains("leave") && lowercaseText.contains("earnings") {
                return "military_les"
            } else if lowercaseText.contains("w-2") || lowercaseText.contains("wage and tax") {
                return "tax_document"
            } else {
                return "unknown"
            }
        }
        
        private static func detectLanguage(from text: String) -> String {
            // Simplified language detection
            let englishWords = ["the", "and", "or", "but", "in", "on", "at", "to"]
            let englishCount = englishWords.reduce(0) { count, word in
                count + (text.lowercased().contains(word) ? 1 : 0)
            }
            
            return englishCount > 3 ? "en" : "unknown"
        }
        
        private static let commonWords = Set([
            "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
            "from", "up", "about", "into", "through", "during", "before", "after", "above",
            "below", "between", "among", "until", "since", "while", "because", "although"
        ])
    }
    
    // MARK: - Public Interface
    
    /// Generate comprehensive document fingerprint
    func generateFingerprint(data: Data, document: PDFDocument? = nil) async -> DocumentFingerprint {
        let contentHash = await generateContentHash(data: data)
        
        var structuralFingerprint: StructuralFingerprint?
        var semanticFingerprint: SemanticFingerprint?
        
        if let document = document {
            structuralFingerprint = StructuralFingerprint(document: document)
            
            if let text = await extractDocumentText(from: document) {
                semanticFingerprint = SemanticFingerprint(text: text)
            }
        }
        
        return DocumentFingerprint(
            contentHash: contentHash,
            structuralFingerprint: structuralFingerprint,
            semanticFingerprint: semanticFingerprint,
            generatedAt: Date()
        )
    }
    
    /// Generate content-based hash for raw data
    func generateContentHash(data: Data) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let hash = SHA256.hash(data: data)
                let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
                continuation.resume(returning: hashString)
            }
        }
    }
    
    /// Extract semantic keywords from document
    func extractSemanticKeywords(document: PDFDocument) async -> [String] {
        guard let text = await extractDocumentText(from: document) else {
            return []
        }
        
        let semanticFingerprint = SemanticFingerprint(text: text)
        return semanticFingerprint.topKeywords
    }
    
    // MARK: - Private Methods
    
    private func extractDocumentText(from document: PDFDocument) async -> String? {
        return await withCheckedContinuation { continuation in
            // Extract text synchronously as PDFDocument isn't sendable
            var fullText = ""
            let pagesToSample = min(DocumentFingerprintGenerator.FingerprintConfig.semanticSamplePages, document.pageCount)
            
            for i in 0..<pagesToSample {
                if let page = document.page(at: i),
                   let pageText = page.string {
                    fullText += pageText + "\n"
                }
            }
            
            continuation.resume(returning: fullText.isEmpty ? nil : fullText)
        }
    }
}

