import Foundation
import PDFKit

/// Memory-efficient layout detector for complex document structures
///
/// Following Phase 4A modular pattern: Focused responsibility for layout analysis
/// Optimizes table detection, form elements, and column analysis with minimal memory footprint
class MemoryEfficientLayoutDetector {
    
    // MARK: - Configuration
    
    /// Maximum text length to analyze per page (memory limit)
    private let maxTextAnalysisLength: Int
    
    /// Cache for layout analysis results
    private var layoutCache: [String: LayoutAnalysisResult] = [:]
    
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
    
    /// Check if a line has consistent spacing (memory-optimized)
    /// - Parameter line: Line to analyze
    /// - Returns: True if consistent spacing detected
    private func hasConsistentSpacing(_ line: String) -> Bool {
        let truncatedLine = String(line.prefix(150))
        var spaceGroups: [Int] = []
        var currentSpaceCount = 0
        var inSpace = false
        
        for char in truncatedLine {
            if char == " " {
                if !inSpace {
                    inSpace = true
                    currentSpaceCount = 1
                } else {
                    currentSpaceCount += 1
                }
            } else {
                if inSpace {
                    inSpace = false
                    spaceGroups.append(currentSpaceCount)
                    currentSpaceCount = 0
                }
            }
        }
        
        if spaceGroups.count >= 2 && spaceGroups.count <= 15 {
            let uniqueGroups = Set(spaceGroups)
            return Double(uniqueGroups.count) / Double(spaceGroups.count) <= 0.5
        }
        
        return false
    }
    
    /// Estimate column count with memory optimization
    /// - Parameters:
    ///   - text: Text to analyze (already truncated)
    ///   - pageWidth: Page width
    /// - Returns: Estimated column count
    private func estimateColumnCount(from text: String, pageWidth: CGFloat) -> Int {
        let lines = text.components(separatedBy: .newlines)
        
        // Sample lines for analysis (memory efficiency)
        let maxLinesToAnalyze = min(30, lines.count)
        let sampleLines = Array(lines.prefix(maxLinesToAnalyze))
        
        var lineLengths: [Int] = []
        
        for line in sampleLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lineLengths.append(trimmed.count)
            }
        }
        
        guard !lineLengths.isEmpty else { return 1 }
        
        lineLengths.sort()
        
        // Memory-efficient distribution analysis
        let median = lineLengths[lineLengths.count / 2]
        let thresholdValue = Double(median) * 0.6
        let shortLines = lineLengths.filter { Double($0) < thresholdValue }.count
        let longLines = lineLengths.filter { Double($0) > thresholdValue }.count
        
        if shortLines > lineLengths.count / 3 && longLines > lineLengths.count / 3 {
            return 2
        }
        
        if pageWidth > 800 {
            return 2
        }
        
        return 1
    }
    

    

    
    /// Generate cache key for layout analysis
    /// - Parameters:
    ///   - document: PDF document
    ///   - pageIndices: Page indices
    /// - Returns: Cache key
    private func generateLayoutCacheKey(document: PDFDocument, pageIndices: [Int]) -> String {
        let documentKey = document.documentURL?.lastPathComponent ?? "unknown"
        let pageKey = pageIndices.map(String.init).joined(separator: ",")
        return "\(documentKey)_layout_\(pageKey)"
    }
    
    /// Clear layout cache to manage memory
    func clearCache() {
        layoutCache.removeAll()
    }
} 