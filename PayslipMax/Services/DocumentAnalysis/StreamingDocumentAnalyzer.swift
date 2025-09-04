import Foundation
import PDFKit

/// Memory-efficient document analyzer that streams document properties without loading entire PDFs
/// 
/// Following Phase 4A modular pattern: Single responsibility for streaming analysis
/// Eliminates dataRepresentation() memory violations through intelligent sampling
class StreamingDocumentAnalyzer {
    
    // MARK: - Memory-Optimized Configuration
    
    /// Maximum number of pages to sample for large documents (memory limit)
    private let maxSamplePages: Int
    
    /// Memory threshold for switching to ultra-conservative sampling
    private let memoryThreshold: Int64
    
    /// Cache for document size estimations to avoid recalculation
    private var sizeEstimationCache: [String: Int64] = [:]
    
    // MARK: - Initialization
    
    /// Initialize with memory-conscious configuration
    /// - Parameters:
    ///   - maxSamplePages: Maximum pages to sample (default: 10 for memory efficiency)  
    ///   - memoryThreshold: Memory threshold in bytes (default: 100MB)
    init(maxSamplePages: Int = 10, memoryThreshold: Int64 = 100 * 1024 * 1024) {
        self.maxSamplePages = maxSamplePages
        self.memoryThreshold = memoryThreshold
    }
    
    // MARK: - Memory-Efficient Size Analysis
    
    /// Analyze document size without loading entire PDF into memory
    /// - Parameter document: PDF document to analyze
    /// - Returns: Size characteristics with memory estimation
    func analyzeSizeCharacteristics(of document: PDFDocument) -> (isLarge: Bool, estimatedMemory: Int64) {
        let pageCount = document.pageCount
        
        // Generate cache key for this document
        let cacheKey = generateCacheKey(for: document)
        
        // Check cache first to avoid recalculation
        if let cachedEstimate = sizeEstimationCache[cacheKey] {
            let isLarge = pageCount >= 50 || 
                         cachedEstimate >= 100 * 1024 * 1024 // 100MB
            return (isLarge, cachedEstimate)
        }
        
        // Use memory-efficient estimation instead of dataRepresentation()
        let estimatedMemory = estimateMemoryRequirementWithoutLoading(document: document)
        
        // Cache the result for future use
        sizeEstimationCache[cacheKey] = estimatedMemory
        
        // Determine if document is large
        let isLarge = pageCount >= 50 || 
                     estimatedMemory >= 100 * 1024 * 1024 // 100MB
        
        return (isLarge, estimatedMemory)
    }
    
    /// Memory-efficient streaming content detection
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - pageIndices: Sample page indices for analysis
    /// - Returns: True if scanned content detected through sampling
    func detectScannedContentStreaming(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        var imageCount = 0
        var totalElements = 0
        var lowTextRatioCount = 0
        
        // Use intelligent sampling for memory efficiency
        let sampleIndices = selectMemoryEfficientSample(from: pageIndices, maxSample: min(5, pageIndices.count))
        
        for pageIndex in sampleIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Count annotations (memory-efficient approach)
            for annotation in page.annotations {
                if let typeString = annotation.type {
                    if typeString == "Stamp" || typeString == "Widget" {
                        imageCount += 1
                    }
                }
                totalElements += 1
            }
            
            // Memory-efficient text ratio analysis without loading entire PDF
            if let text = page.string {
                let textSize = text.count
                
                // Estimate page data size instead of loading entire document
                let estimatedPageSize = estimatePageDataSize(page: page, pageIndex: pageIndex, totalPages: document.pageCount)
                
                if textSize > 0 && estimatedPageSize > 0 {
                    let ratio = Double(textSize) / Double(estimatedPageSize)
                    if ratio < 0.01 {
                        lowTextRatioCount += 1
                    }
                }
            }
        }
        
        // Use proportion of low-text-ratio pages to determine scanned content
        let scannedContentByRatio = sampleIndices.count > 0 && 
                                   Double(lowTextRatioCount) / Double(sampleIndices.count) > 0.5
        
        // Use annotation analysis
        let scannedContentByAnnotations = totalElements > 0 && 
                                         Double(imageCount) / Double(totalElements) >= 0.3 // 30% threshold for scanned content
        
        return scannedContentByRatio || scannedContentByAnnotations
    }
    
    /// Streaming text density analysis with memory optimization
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - pageIndices: Sample page indices
    /// - Returns: Estimated text density (0.0-1.0)
    func analyzeTextDensityStreaming(in document: PDFDocument, pageIndices: [Int]) -> Double {
        var totalTextLength = 0
        var totalPageArea: CGFloat = 0
        
        // Use memory-efficient sampling
        let sampleIndices = selectMemoryEfficientSample(from: pageIndices, maxSample: min(3, pageIndices.count))
        
        for pageIndex in sampleIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if let text = page.string {
                totalTextLength += text.count
            }
            
            let pageSize = page.bounds(for: .mediaBox).size
            totalPageArea += pageSize.width * pageSize.height
        }
        
        // Calculate text density with extrapolation for unsampled pages
        let density = totalPageArea > 0 ? Double(totalTextLength) / Double(totalPageArea) : 0
        let normalizedDensity = min(1.0, density / 0.1)
        
        return normalizedDensity
    }
    
    // MARK: - Private Memory-Efficient Helpers
    
    /// Generate cache key for document without loading entire content
    /// - Parameter document: PDF document
    /// - Returns: Cache key string
    private func generateCacheKey(for document: PDFDocument) -> String {
        // Use document metadata for cache key instead of content hash
        let pageCount = document.pageCount
        let documentURL = document.documentURL?.lastPathComponent ?? "unknown"
        return "\(documentURL)_\(pageCount)_pages"
    }
    
    /// Estimate memory requirement without loading entire PDF
    /// - Parameter document: PDF document
    /// - Returns: Estimated memory in bytes
    private func estimateMemoryRequirementWithoutLoading(document: PDFDocument) -> Int64 {
        let pageCount = document.pageCount
        
        // Sample first few pages to estimate average page complexity
        let sampleSize = min(3, pageCount)
        var totalSampleComplexity: Int64 = 0
        
        for i in 0..<sampleSize {
            guard let page = document.page(at: i) else { continue }
            
            // Estimate page complexity based on bounds and text length
            let pageBounds = page.bounds(for: .mediaBox)
            let pageArea = Int64(pageBounds.width * pageBounds.height)
            
            let textLength = page.string?.count ?? 0
            let textComplexity = Int64(textLength * 2) // Unicode chars
            
            // Combined complexity estimate
            let pageComplexity = max(pageArea / 1000, textComplexity)
            totalSampleComplexity += pageComplexity
        }
        
        // Extrapolate to full document
        let avgPageComplexity = sampleSize > 0 ? totalSampleComplexity / Int64(sampleSize) : 1_000_000
        let estimatedMemory = avgPageComplexity * Int64(pageCount)
        
        // Add processing overhead
        let overhead: Int64 = 50_000_000 // 50MB overhead
        return estimatedMemory + overhead
    }
    
    /// Estimate individual page data size without document.dataRepresentation()
    /// - Parameters:
    ///   - page: PDF page
    ///   - pageIndex: Page index
    ///   - totalPages: Total pages in document  
    /// - Returns: Estimated page data size
    private func estimatePageDataSize(page: PDFPage, pageIndex: Int, totalPages: Int) -> Int {
        // Estimate based on page properties
        let pageBounds = page.bounds(for: .mediaBox)
        let pageArea = pageBounds.width * pageBounds.height
        
        // Estimate based on content complexity
        let textLength = page.string?.count ?? 0
        let annotationCount = page.annotations.count
        
        // Base size estimation
        let baseSizeFromArea = Int(pageArea / 10) // Rough heuristic
        let textContribution = textLength * 2 // Unicode
        let annotationContribution = annotationCount * 1000 // Rough estimate
        
        return baseSizeFromArea + textContribution + annotationContribution
    }
    
    /// Select memory-efficient sample from page indices
    /// - Parameters:
    ///   - pageIndices: All available page indices
    ///   - maxSample: Maximum number of pages to sample
    /// - Returns: Optimally selected sample indices
    private func selectMemoryEfficientSample(from pageIndices: [Int], maxSample: Int) -> [Int] {
        guard pageIndices.count > maxSample else { return pageIndices }
        
        // Select representative sample: first, middle, last, and evenly distributed
        var sample: [Int] = []
        
        // Always include first page
        if let first = pageIndices.first {
            sample.append(first)
        }
        
        // Include middle page(s)
        let middleIndex = pageIndices.count / 2
        if middleIndex > 0 && middleIndex < pageIndices.count {
            sample.append(pageIndices[middleIndex])
        }
        
        // Always include last page if different from first
        if let last = pageIndices.last, last != pageIndices.first {
            sample.append(last)
        }
        
        // Fill remaining slots with evenly distributed pages
        let remainingSlots = maxSample - sample.count
        if remainingSlots > 0 {
            let strideValue = max(1, pageIndices.count / (remainingSlots + 1))
            for i in stride(from: strideValue, to: pageIndices.count - strideValue, by: strideValue) {
                if sample.count < maxSample && !sample.contains(pageIndices[i]) {
                    sample.append(pageIndices[i])
                }
            }
        }
        
        return sample.sorted()
    }
    
    /// Clear cache to manage memory usage
    func clearCache() {
        sizeEstimationCache.removeAll()
    }
} 