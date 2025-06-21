import Foundation
import PDFKit

/// Memory-optimized document analysis coordinator
///
/// Following Phase 4A modular pattern: Coordinator orchestrates memory-efficient analysis
/// Eliminates dataRepresentation() violations and provides single interface for all analysis
/// Line count target: ~200 lines (within 300-line rule)
class DocumentAnalysisCoordinator {
    
    // MARK: - Memory-Optimized Components
    
    /// Streaming document analyzer for size and content analysis
    private let streamingAnalyzer: StreamingDocumentAnalyzer
    
    /// Memory-efficient layout detector for complex structures
    private let layoutDetector: MemoryEfficientLayoutDetector
    
    /// Memory usage monitor for pressure handling
    private let memoryMonitor: MemoryPressureMonitor?
    
    // MARK: - Configuration
    
    /// Configuration for memory-conscious analysis
    struct AnalysisConfiguration {
        let maxMemoryUsage: Int64
        let enableMemoryPressureHandling: Bool
        let maxSamplePagesForLargeDocuments: Int
        let cacheAnalysisResults: Bool
        
        static let `default` = AnalysisConfiguration(
            maxMemoryUsage: 150 * 1024 * 1024, // 150MB
            enableMemoryPressureHandling: true,
            maxSamplePagesForLargeDocuments: 10,
            cacheAnalysisResults: true
        )
    }
    
    private let configuration: AnalysisConfiguration
    
    // MARK: - Analysis Results Cache
    
    private var analysisResultsCache: [String: DocumentAnalysisResult] = [:]
    private let cacheQueue = DispatchQueue(label: "document.analysis.cache", qos: .utility)
    
    // MARK: - Initialization
    
    /// Initialize with memory-optimized configuration
    /// - Parameter configuration: Analysis configuration (default: memory-optimized)
    init(configuration: AnalysisConfiguration = .default) {
        self.configuration = configuration
        
        // Initialize memory-optimized components
        self.streamingAnalyzer = StreamingDocumentAnalyzer(
            maxSamplePages: configuration.maxSamplePagesForLargeDocuments,
            memoryThreshold: configuration.maxMemoryUsage
        )
        
        self.layoutDetector = MemoryEfficientLayoutDetector(
            maxTextAnalysisLength: 50_000 // 50KB per page limit
        )
        
        // Initialize memory pressure monitor if enabled
        self.memoryMonitor = configuration.enableMemoryPressureHandling ? MemoryPressureMonitor() : nil
    }
    
    // MARK: - Main Analysis Interface
    
    /// Perform comprehensive document analysis with memory optimization
    /// - Parameter document: PDF document to analyze
    /// - Returns: Analysis result without memory violations
    func analyzeDocument(_ document: PDFDocument) async -> DocumentAnalysisResult {
        // Generate cache key
        let cacheKey = generateCacheKey(for: document)
        
        // Check cache first
        if configuration.cacheAnalysisResults,
           let cachedResult = getCachedResult(key: cacheKey) {
            return cachedResult
        }
        
        
        // Memory pressure check before analysis
        if let monitor = memoryMonitor, monitor.isMemoryPressureHigh() {
            await handleMemoryPressure()
        }
        
        // Perform memory-efficient analysis
        let result = await performMemoryOptimizedAnalysis(document)
        
        // Cache result if enabled
        if configuration.cacheAnalysisResults {
            setCachedResult(key: cacheKey, result: result)
        }
        
        return result
    }
    
    // MARK: - Memory-Optimized Analysis Implementation
    
    /// Perform the actual analysis with memory optimization
    /// - Parameter document: PDF document
    /// - Returns: Analysis result
    private func performMemoryOptimizedAnalysis(_ document: PDFDocument) async -> DocumentAnalysisResult {
        let pageCount = document.pageCount
        
        // Calculate smart sample size based on document size and memory limits
        let sampleIndices = calculateOptimalSampleIndices(pageCount: pageCount)
        
        // Perform analysis with streaming components
        async let sizeAnalysis = streamingAnalyzer.analyzeSizeCharacteristics(of: document)
        async let scannedContentDetection = streamingAnalyzer.detectScannedContentStreaming(in: document, pageIndices: sampleIndices)
        async let textDensityAnalysis = streamingAnalyzer.analyzeTextDensityStreaming(in: document, pageIndices: sampleIndices)
        
        async let layoutComplexityAnalysis = layoutDetector.analyzeLayoutComplexity(of: document, pageIndices: sampleIndices)
        async let tableDetection = layoutDetector.detectTables(in: document, pageIndices: sampleIndices)
        async let formElementDetection = layoutDetector.detectFormElements(in: document, pageIndices: sampleIndices)
        
        // Await all results concurrently
        let (sizeResult, hasScannedContent, textDensity, layoutResult, hasTables, hasFormElements) = await (
            sizeAnalysis, scannedContentDetection, textDensityAnalysis,
            layoutComplexityAnalysis, tableDetection, formElementDetection
        )
        
        // Compile comprehensive result
        return DocumentAnalysisResult(
            pageCount: pageCount,
            isLargeDocument: sizeResult.isLarge,
            estimatedMemoryRequirement: sizeResult.estimatedMemory,
            hasScannedContent: hasScannedContent,
            hasTabularData: hasTables,
            hasFormElements: hasFormElements,
            isComplexLayout: layoutResult.isComplex,
            columnCount: layoutResult.columnCount,
            textDensity: textDensity,
            processingRecommendation: generateProcessingRecommendation(
                isLarge: sizeResult.isLarge,
                hasScannedContent: hasScannedContent,
                isComplex: layoutResult.isComplex,
                estimatedMemory: sizeResult.estimatedMemory
            ),
            sampledPageIndices: sampleIndices,
            analysisTimestamp: Date()
        )
    }
    
    // MARK: - Memory Management
    
    /// Handle memory pressure by clearing caches and optimizing components
    private func handleMemoryPressure() async {
        await Task.detached { [weak self] in
            self?.clearAllCaches()
        }.value
    }
    
    /// Clear all caches to free memory
    func clearAllCaches() {
        cacheQueue.sync {
            analysisResultsCache.removeAll()
        }
        streamingAnalyzer.clearCache()
        layoutDetector.clearCache()
    }
    
    // MARK: - Cache Management
    
    /// Get cached analysis result
    /// - Parameter key: Cache key
    /// - Returns: Cached result if available and valid
    private func getCachedResult(key: String) -> DocumentAnalysisResult? {
        return cacheQueue.sync {
            guard let result = analysisResultsCache[key] else { return nil }
            
            // Check if cache is still valid (5 minutes)
            if Date().timeIntervalSince(result.analysisTimestamp) > 300 {
                analysisResultsCache.removeValue(forKey: key)
                return nil
            }
            
            return result
        }
    }
    
    /// Set cached analysis result
    /// - Parameters:
    ///   - key: Cache key
    ///   - result: Analysis result to cache
    private func setCachedResult(key: String, result: DocumentAnalysisResult) {
        cacheQueue.async { [weak self] in
            self?.analysisResultsCache[key] = result
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate cache key for document
    /// - Parameter document: PDF document
    /// - Returns: Cache key
    private func generateCacheKey(for document: PDFDocument) -> String {
        let url = document.documentURL?.lastPathComponent ?? "unknown"
        let pageCount = document.pageCount
        return "analysis_\(url)_\(pageCount)_v2"
    }
    
    /// Calculate optimal sample indices based on memory constraints
    /// - Parameter pageCount: Total page count
    /// - Returns: Optimal sample indices
    private func calculateOptimalSampleIndices(pageCount: Int) -> [Int] {
        // Conservative sampling for memory efficiency
        let maxSample = min(configuration.maxSamplePagesForLargeDocuments, pageCount)
        
        if pageCount <= maxSample {
            return Array(0..<pageCount)
        }
        
        // Smart sampling: first, last, middle, and evenly distributed
        var indices: [Int] = []
        
        // Always include first and last page
        indices.append(0)
        if pageCount > 1 {
            indices.append(pageCount - 1)
        }
        
        // Add middle page
        if pageCount > 2 {
            indices.append(pageCount / 2)
        }
        
        // Fill remaining slots evenly
        let remaining = maxSample - indices.count
        if remaining > 0 && pageCount > 3 {
            let strideValue = max(1, pageCount / (remaining + 1))
            for i in stride(from: strideValue, to: pageCount - strideValue, by: strideValue) {
                if indices.count < maxSample && !indices.contains(i) {
                    indices.append(i)
                }
            }
        }
        
        return indices.sorted()
    }
    
    /// Generate processing recommendation based on analysis
    /// - Parameters:
    ///   - isLarge: Is document large
    ///   - hasScannedContent: Has scanned content
    ///   - isComplex: Is layout complex
    ///   - estimatedMemory: Estimated memory requirement
    /// - Returns: Processing recommendation
    private func generateProcessingRecommendation(
        isLarge: Bool,
        hasScannedContent: Bool,
        isComplex: Bool,
        estimatedMemory: Int64
    ) -> DocumentAnalysisResult.ProcessingRecommendation {
        
        if estimatedMemory > configuration.maxMemoryUsage {
            return .useStreamingMode
        }
        
        if isLarge && hasScannedContent {
            return .useOCRWithBatching
        }
        
        if isComplex {
            return .useStructuredExtraction
        }
        
        return .useStandardProcessing
    }
}

 