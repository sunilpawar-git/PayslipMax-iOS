import Foundation

/// Options for configuring the text extraction process
struct ExtractionOptions {
    /// Whether to use parallel processing for non-sequential pages
    var useParallelProcessing: Bool = true
    
    /// Maximum number of concurrent operations for parallel processing
    var maxConcurrentOperations: Int = 4
    
    /// Whether to preprocess text for better quality
    var preprocessText: Bool = true
    
    /// Whether to use adaptive batching based on page characteristics
    var useAdaptiveBatching: Bool = true
    
    /// Maximum batch size in bytes
    var maxBatchSize: Int = 5 * 1024 * 1024 // 5MB
    
    /// Whether to collect detailed performance metrics
    var collectDetailedMetrics: Bool = true
    
    /// Whether to use the cache
    var useCache: Bool = true
    
    /// Memory threshold in MB for triggering memory optimization
    var memoryThresholdMB: Int = 200
    
    /// Default extraction options
    static var `default`: ExtractionOptions {
        return ExtractionOptions()
    }
    
    /// Options optimized for speed
    ///
    /// This preset is ideal for:
    /// - Real-time processing requirements
    /// - High-quality source documents
    /// - Situations where speed is prioritized over extraction accuracy
    /// - Documents without complex layouts or tables
    ///
    /// It maximizes throughput by disabling preprocessing and increasing concurrency,
    /// potentially at the cost of reduced extraction quality for complex documents.
    static var speed: ExtractionOptions {
        var options = ExtractionOptions()
        options.preprocessText = false
        options.maxConcurrentOperations = 8
        return options
    }
    
    /// Options optimized for quality
    ///
    /// This preset is ideal for:
    /// - Complex documents with tables or formatted content
    /// - Low-quality scans or documents with artifacts
    /// - Situations where extraction accuracy is critical
    /// - Financial or legal documents requiring precise extraction
    ///
    /// It ensures maximum extraction quality by enabling preprocessing and
    /// using sequential processing for more consistent results, at the cost of speed.
    static var quality: ExtractionOptions {
        var options = ExtractionOptions()
        options.preprocessText = true
        options.useParallelProcessing = false
        return options
    }
    
    /// Options optimized for memory efficiency
    ///
    /// This preset is ideal for:
    /// - Very large documents (100+ pages)
    /// - Devices with limited memory
    /// - Background processing where memory pressure is a concern
    /// - Processing multiple documents simultaneously
    ///
    /// It minimizes memory usage through sequential processing and aggressive
    /// batching, making it possible to process large documents on memory-constrained devices.
    static var memoryEfficient: ExtractionOptions {
        var options = ExtractionOptions()
        options.useParallelProcessing = false
        options.useAdaptiveBatching = true
        options.memoryThresholdMB = 100
        return options
    }
}

/// Performance metrics for the extraction process
struct ExtractionMetrics {
    /// Total execution time in seconds
    var executionTime: TimeInterval = 0
    
    /// Peak memory usage in bytes
    var peakMemoryUsage: UInt64 = 0
    
    /// Number of pages processed
    var pagesProcessed: Int = 0
    
    /// Number of characters extracted
    var charactersExtracted: Int = 0
    
    /// Processing time per page in seconds
    var processingTimePerPage: [Int: TimeInterval] = [:]
    
    /// Memory usage per page in bytes
    var memoryUsagePerPage: [Int: UInt64] = [:]
    
    /// Cache hit ratio (0.0-1.0)
    var cacheHitRatio: Double = 0.0
    
    /// Whether parallel processing was used
    var usedParallelProcessing: Bool = false
    
    /// Whether text preprocessing was used
    var usedTextPreprocessing: Bool = false
    
    /// Number of extraction retries due to errors
    var extractionRetries: Int = 0
    
    /// Whether memory optimization was triggered
    var memoryOptimizationTriggered: Bool = false
}

// Note: Extensions for ExtractionMetrics are provided in ExtractorProfiler.swift to avoid redeclaration 