import Foundation
import PDFKit

/// Memory-efficient layout detector for complex document structures
///
/// Following Phase 4A modular pattern: Focused responsibility for layout analysis
/// Optimizes table detection, form elements, and column analysis with minimal memory footprint
class MemoryEfficientLayoutDetector {
    
    // MARK: - Configuration
    
    /// Maximum text length to analyze per page (memory limit)
    let maxTextAnalysisLength: Int
    
    /// Cache for layout analysis results
    var layoutCache: [String: LayoutAnalysisResult] = [:]
    
    // MARK: - Layout Analysis Result
    
    struct LayoutAnalysisResult {
        let hasTabularStructure: Bool
        let columnCount: Int
        let hasFormElements: Bool
        let isComplexLayout: Bool
        let textDensity: Double
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    /// Initialize with memory-conscious configuration
    /// - Parameter maxTextAnalysisLength: Maximum text length per page (default: 50KB)
    init(maxTextAnalysisLength: Int = 50_000) {
        self.maxTextAnalysisLength = maxTextAnalysisLength
    }
    
    // MARK: - Memory-Optimized Layout Analysis
    
    /// Analyze layout complexity with memory optimization
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - pageIndices: Sample page indices
    /// - Returns: Layout complexity analysis result
    func analyzeLayoutComplexity(of document: PDFDocument, pageIndices: [Int]) -> (isComplex: Bool, columnCount: Int) {
        // Generate cache key
        let cacheKey = generateLayoutCacheKey(document: document, pageIndices: pageIndices)
        
        // Check cache first
        if let cached = layoutCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < 300 { // 5-minute cache
            return (cached.isComplexLayout, cached.columnCount)
        }
        
        var maxColumnCount = 1
        var complexityScore = 0
        
        // Use intelligent sampling for memory efficiency
        let sampleIndices = LayoutAnalysisHelpers.selectRepresentativeSample(from: pageIndices, maxSample: 5)
        
        for pageIndex in sampleIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Memory-efficient text analysis
            if let text = page.string {
                let truncatedText = truncateTextForAnalysis(text)
                let columnCount = estimateColumnCount(from: truncatedText, pageWidth: page.bounds(for: .mediaBox).width)
                maxColumnCount = max(maxColumnCount, columnCount)
                
                // Complexity scoring
                if columnCount > 1 { complexityScore += 2 }
                if truncatedText.contains("\t") { complexityScore += 1 }
                let features = LayoutAnalysisHelpers.detectLayoutFeatures(in: truncatedText)
        if features.hasMultipleColumns { complexityScore += 2 }
            }
            
            // Annotation complexity
            if page.annotations.count > 5 {
                complexityScore += 1
            }
        }
        
        let isComplex = maxColumnCount >= 3 || complexityScore >= 3
        
        // Cache result
        let result = LayoutAnalysisResult(
            hasTabularStructure: false, // Will be set by table detection
            columnCount: maxColumnCount,
            hasFormElements: false, // Will be set by form detection
            isComplexLayout: isComplex,
            textDensity: 0.0, // Will be set by density analysis
            timestamp: Date()
        )
        layoutCache[cacheKey] = result
        
        return (isComplex, maxColumnCount)
    }
    
    /// Memory-efficient table detection
    /// - Parameters:
    ///   - document: PDF document
    ///   - pageIndices: Sample page indices
    /// - Returns: True if tables detected
    func detectTables(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        // Use small sample for table detection to minimize memory usage
        let sampleIndices = LayoutAnalysisHelpers.selectRepresentativeSample(from: pageIndices, maxSample: 3)
        
        for pageIndex in sampleIndices {
            guard let page = document.page(at: pageIndex), let text = page.string else { continue }
            
            // Memory-efficient table detection
            let truncatedText = truncateTextForAnalysis(text)
            if hasTabularStructure(truncatedText) {
                return true
            }
        }
        
        return false
    }
    
    /// Memory-efficient form element detection
    /// - Parameters:
    ///   - document: PDF document
    ///   - pageIndices: Sample page indices
    /// - Returns: True if form elements detected
    func detectFormElements(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        // Use minimal sampling for form detection
        let sampleIndices = LayoutAnalysisHelpers.selectRepresentativeSample(from: pageIndices, maxSample: 2)
        
        for pageIndex in sampleIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Check annotations efficiently
            for annotation in page.annotations {
                if let typeString = annotation.type, typeString == "Widget" {
                    return true
                }
            }
            
            // Check text patterns with memory limits
            if let text = page.string {
                let truncatedText = truncateTextForAnalysis(text)
                let features = LayoutAnalysisHelpers.detectLayoutFeatures(in: truncatedText)
                if features.hasFormFields {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Private Memory-Efficient Helpers
    
    /// Truncate text for analysis to prevent memory issues
    /// - Parameter text: Original text
    /// - Returns: Truncated text within memory limits
    private func truncateTextForAnalysis(_ text: String) -> String {
        if text.count <= maxTextAnalysisLength {
            return text
        }
        
        // Take first and last portions for better analysis coverage
        let halfLimit = maxTextAnalysisLength / 2
        let startIndex = text.startIndex
        let midStart = text.index(startIndex, offsetBy: halfLimit)
        let endStart = text.index(text.endIndex, offsetBy: -halfLimit)
        
        let firstPart = String(text[startIndex..<midStart])
        let lastPart = String(text[endStart..<text.endIndex])
        
        return firstPart + "\n...[truncated]...\n" + lastPart
    }
    
    /// Check if text has tabular structure with memory optimization
    /// - Parameter text: Text to analyze (already truncated)
    /// - Returns: True if tabular structure detected
    private func hasTabularStructure(_ text: String) -> Bool {
        let sampleLines = Array(text.components(separatedBy: .newlines).prefix(30))
        var consecutiveTabLines = 0
        var tabLineCount = 0
        
        for line in sampleLines {
            if line.contains("\t") || hasConsistentSpacing(line) {
                consecutiveTabLines += 1
                tabLineCount += 1
                if consecutiveTabLines >= 3 { return true }
            } else {
                consecutiveTabLines = 0
            }
        }
        
        return tabLineCount > sampleLines.count / 4
    }
    
}