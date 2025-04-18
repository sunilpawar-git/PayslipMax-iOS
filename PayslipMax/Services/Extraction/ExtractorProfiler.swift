import Foundation
import PDFKit

/// Result structure containing performance metrics from a text extraction profiling run
struct ProfilerResult {
    let strategyName: String
    let extractionTime: TimeInterval
    let characterCount: Int
    let charactersPerSecond: Double
    let peakMemoryUsage: UInt64
    let pagesPerSecond: Double
    let pageCount: Int
    let detailedMetrics: [String: Any]?
    
    init(strategyName: String, extractionTime: TimeInterval, text: String, pageCount: Int, peakMemoryUsage: UInt64, detailedMetrics: [String: Any]? = nil) {
        self.strategyName = strategyName
        self.extractionTime = extractionTime
        self.characterCount = text.count
        self.pageCount = pageCount
        self.charactersPerSecond = extractionTime > 0 ? Double(text.count) / extractionTime : 0
        self.pagesPerSecond = extractionTime > 0 ? Double(pageCount) / extractionTime : 0
        self.peakMemoryUsage = peakMemoryUsage
        self.detailedMetrics = detailedMetrics
    }
}

/// A performance profiling tool for comparing different text extraction strategies
class ExtractorProfiler {
    
    // MARK: - Services
    private let standardService = StandardTextExtractionService()
    private let optimizedService = OptimizedTextExtractionService()
    private let enhancedService = EnhancedTextExtractionService()
    
    /// Enum to define presets for extraction options
    enum Preset {
        case speed
        case quality
        case memoryEfficient
    }
    
    // MARK: - Profiling Methods
    
    /// Profile the standard text extraction method
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: Performance metrics for the extraction
    func profileStandardExtraction(on document: PDFDocument) async -> ProfilerResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        var peakMemory: UInt64 = 0
        var extractedText = ""
        
        return await withCheckedContinuation { continuation in
            standardService.extractTextWithCompletion(from: document) { text in
                let endTime = CFAbsoluteTimeGetCurrent()
                extractedText = text
                peakMemory = self.currentMemoryUsage()
                
                let result = ProfilerResult(
                    strategyName: "Standard",
                    extractionTime: endTime - startTime,
                    text: extractedText,
                    pageCount: document.pageCount,
                    peakMemoryUsage: peakMemory
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Profile the optimized text extraction method
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: Performance metrics for the extraction
    func profileOptimizedExtraction(on document: PDFDocument) async -> ProfilerResult {
        return await withCheckedContinuation { continuation in
            let startTime = CFAbsoluteTimeGetCurrent()
            let peakMemory: UInt64
            
            let extractedText = optimizedService.extractOptimizedText(from: document)
            let endTime = CFAbsoluteTimeGetCurrent()
            peakMemory = currentMemoryUsage()
            
            let result = ProfilerResult(
                strategyName: "Optimized",
                extractionTime: endTime - startTime,
                text: extractedText,
                pageCount: document.pageCount,
                peakMemoryUsage: peakMemory
            )
            
            continuation.resume(returning: result)
        }
    }
    
    /// Profile the enhanced text extraction method using a preset configuration
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - preset: The preset configuration to use (speed, quality, or memoryEfficient)
    /// - Returns: Performance metrics for the extraction
    func profileEnhancedExtraction(on document: PDFDocument, preset: Preset) async -> ProfilerResult {
        let options: ExtractionOptions
        
        switch preset {
        case .speed:
            options = ExtractionOptions.speed
        case .quality:
            options = ExtractionOptions.quality
        case .memoryEfficient:
            options = ExtractionOptions.memoryEfficient
        }
        
        return await profileEnhancedExtraction(on: document, options: options)
    }
    
    /// Profile the enhanced text extraction method using custom options
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - options: Custom extraction options
    /// - Returns: Performance metrics for the extraction
    func profileEnhancedExtraction(on document: PDFDocument, options: ExtractionOptions) async -> ProfilerResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        var peakMemory: UInt64 = 0
        var metrics: [String: Any]? = nil
        
        let result = await enhancedService.extractTextEnhanced(from: document, options: options)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        peakMemory = currentMemoryUsage()
        metrics = options.collectDetailedMetrics ? result.metrics.asDictionary() : nil
        
        return ProfilerResult(
            strategyName: "Enhanced (\(describeOptions(options)))",
            extractionTime: endTime - startTime,
            text: result.text,
            pageCount: document.pageCount,
            peakMemoryUsage: peakMemory,
            detailedMetrics: metrics
        )
    }
    
    // MARK: - Helper Methods
    
    /// Get the current memory usage of the application
    /// - Returns: Current memory usage in bytes
    private func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Generate a description of the extraction options
    /// - Parameter options: The extraction options to describe
    /// - Returns: A short string describing the key options
    private func describeOptions(_ options: ExtractionOptions) -> String {
        var description = ""
        
        if options.useParallelProcessing {
            description += "Parallel"
        } else {
            description += "Sequential"
        }
        
        if options.preprocessText {
            description += ", Preprocess"
        }
        
        if options.useAdaptiveBatching {
            description += ", Adaptive"
        }
        
        description += ", \(options.memoryThresholdMB)MB thresh"
        
        return description
    }
}

// MARK: - Helper Extensions

extension ExtractionMetrics {
    /// Convert metrics to a dictionary representation
    func asDictionary() -> [String: Any] {
        return [
            "totalProcessingTime": executionTime,
            "peakMemoryUsage": peakMemoryUsage,
            "pagesProcessed": pagesProcessed,
            "charactersExtracted": charactersExtracted,
            "cacheHitRatio": cacheHitRatio,
            "usedParallelProcessing": usedParallelProcessing,
            "usedTextPreprocessing": usedTextPreprocessing,
            "extractionRetries": extractionRetries,
            "memoryOptimizationTriggered": memoryOptimizationTriggered
        ]
    }
} 