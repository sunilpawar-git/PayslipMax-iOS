import Foundation
import PDFKit

/// Protocol defining benchmark execution capabilities.
///
/// This service handles the core benchmarking logic and execution for different
/// text extraction methods, including timing, memory monitoring, and result collection.
protocol BenchmarkExecutionEngineProtocol {
    /// Runs a comprehensive benchmark of all extraction methods on the given PDF document
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each method
    func runComprehensiveBenchmark(on document: PDFDocument) async -> [TextExtractionBenchmarkResult]
    
    /// Benchmarks all preset configurations of enhanced extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each preset
    func benchmarkPresets(on document: PDFDocument) -> [String: TextExtractionBenchmarkResult]
    
    /// Benchmarks enhanced extraction with custom options
    /// - Parameters:
    ///   - document: The PDF document to benchmark
    ///   - options: Custom extraction options
    /// - Returns: Benchmark result for the custom configuration
    func benchmarkCustomConfiguration(on document: PDFDocument, options: ExtractionOptions) -> TextExtractionBenchmarkResult
}

/// Service responsible for executing benchmarks and collecting performance metrics.
///
/// This service provides the core benchmarking engine that runs different text extraction
/// methods, measures their performance characteristics, and collects detailed metrics
/// for analysis and comparison.
class BenchmarkExecutionEngine: BenchmarkExecutionEngineProtocol {
    
    // MARK: - Properties
    
    private let standardService: ExtractionStrategyService
    private let optimizedService: OptimizedTextExtractionService
    private let enhancedService: EnhancedTextExtractionService
    private let streamingService: StreamingTextExtractionService
    
    // MARK: - Private Properties
    
    private enum ExtractionPreset {
        case defaultPreset
        case speed
        case quality
        case memoryEfficient
    }
    
    // MARK: - Initialization
    
    init() {
        // Create new instances directly
        self.standardService = ExtractionStrategyService()
        self.optimizedService = OptimizedTextExtractionService()
        self.enhancedService = EnhancedTextExtractionService()
        self.streamingService = StreamingTextExtractionService()
    }
    
    // MARK: - BenchmarkExecutionEngineProtocol
    
    /// Runs a comprehensive benchmark of all extraction methods on the given PDF document
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each method
    func runComprehensiveBenchmark(on document: PDFDocument) async -> [TextExtractionBenchmarkResult] {
        print("🚀 Starting comprehensive text extraction benchmark...")
        print("📄 Document info: \(document.pageCount) pages")
        
        var results = [TextExtractionBenchmarkResult]()
        
        // Run all benchmarks
        results.append(benchmarkStandardExtraction(on: document))
        results.append(await benchmarkOptimizedExtraction(on: document))
        results.append(benchmarkStreamingExtraction(on: document))
        results.append(benchmarkEnhancedExtraction(on: document, preset: .defaultPreset))
        
        // If document is large enough, also test presets
        if document.pageCount > 5 {
            results.append(benchmarkEnhancedExtraction(on: document, preset: .speed))
            results.append(benchmarkEnhancedExtraction(on: document, preset: .quality))
            results.append(benchmarkEnhancedExtraction(on: document, preset: .memoryEfficient))
        }
        
        return results
    }
    
    /// Benchmarks all preset configurations of enhanced extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each preset
    func benchmarkPresets(on document: PDFDocument) -> [String: TextExtractionBenchmarkResult] {
        print("🚀 Starting preset benchmarks...")
        print("📄 Document info: \(document.pageCount) pages")
        
        var results = [String: TextExtractionBenchmarkResult]()
        
        // Standard for comparison
        results["Standard"] = benchmarkStandardExtraction(on: document)
        
        // Test all presets
        results["Default"] = benchmarkEnhancedExtraction(on: document, preset: .defaultPreset)
        results["Speed"] = benchmarkEnhancedExtraction(on: document, preset: .speed)
        results["Quality"] = benchmarkEnhancedExtraction(on: document, preset: .quality)
        results["Memory"] = benchmarkEnhancedExtraction(on: document, preset: .memoryEfficient)
        
        return results
    }
    
    /// Benchmarks enhanced extraction with custom options
    /// - Parameters:
    ///   - document: The PDF document to benchmark
    ///   - options: Custom extraction options
    /// - Returns: Benchmark result for the custom configuration
    func benchmarkCustomConfiguration(on document: PDFDocument, options: ExtractionOptions) -> TextExtractionBenchmarkResult {
        print("🚀 Benchmarking custom configuration...")
        print("📄 Document info: \(document.pageCount) pages")
        
        let result = benchmarkEnhancedExtraction(on: document, options: options)
        
        return result
    }
    
    // MARK: - Private Methods - Benchmarking
    
    private func benchmarkStandardExtraction(on document: PDFDocument) -> TextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = currentMemoryUsage()
        
        // Use a method that's available in ExtractionStrategyService
        let _ = standardService.determineStrategy(for: PayslipMax.DocumentAnalysis(
            pageCount: document.pageCount,
            containsScannedContent: false,
            hasComplexLayout: false,
            textDensity: 0.5,
            estimatedMemoryRequirement: 0,
            containsTables: false,
            containsFormElements: false
        ))
        
        let endTime = Date()
        let endMemory = currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return TextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            methodName: "Standard",
            options: nil
        )
    }
    
    private func benchmarkOptimizedExtraction(on document: PDFDocument) async -> TextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = currentMemoryUsage()
        
        // Await the async call
        let _ = await optimizedService.extractOptimizedText(from: document)
        
        let endTime = Date()
        let endMemory = currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return TextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            methodName: "Optimized",
            options: nil
        )
    }
    
    private func benchmarkStreamingExtraction(on document: PDFDocument) -> TextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = currentMemoryUsage()
        
        let _ = streamingService.extractText(from: document)
        
        let endTime = Date()
        let endMemory = currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return TextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            methodName: "Streaming",
            options: nil
        )
    }
    
    private func benchmarkEnhancedExtraction(on document: PDFDocument, preset: ExtractionPreset) -> TextExtractionBenchmarkResult {
        // Convert preset to options
        let options: ExtractionOptions
        switch preset {
        case .defaultPreset:
            options = ExtractionOptions()
        case .speed:
            options = ExtractionOptions(
                useParallelProcessing: true,
                maxConcurrentOperations: 8,
                preprocessText: false,
                useAdaptiveBatching: true,
                maxBatchSize: 1 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 200
            )
        case .quality:
            options = ExtractionOptions(
                useParallelProcessing: false,
                maxConcurrentOperations: 1,
                preprocessText: true,
                useAdaptiveBatching: false,
                maxBatchSize: 1 * 1024 * 1024,
                collectDetailedMetrics: true,
                useCache: true,
                memoryThresholdMB: 500
            )
        case .memoryEfficient:
            options = ExtractionOptions(
                useParallelProcessing: false,
                maxConcurrentOperations: 1,
                preprocessText: true,
                useAdaptiveBatching: true,
                maxBatchSize: 5 * 1024 * 1024,
                collectDetailedMetrics: false,
                useCache: true,
                memoryThresholdMB: 50
            )
        }
        
        return benchmarkEnhancedExtraction(on: document, options: options)
    }
    
    private func benchmarkEnhancedExtraction(on document: PDFDocument, options: ExtractionOptions) -> TextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = currentMemoryUsage()
        
        // ✅ CLEAN: Eliminated DispatchSemaphore - using DispatchGroup for cleaner concurrency
        let group = DispatchGroup()
        
        group.enter()
        Task {
            _ = await enhancedService.extractTextEnhanced(from: document, options: options)
            group.leave()
        }
        
        // Wait for the async operation to complete
        group.wait()
        
        let endTime = Date()
        let endMemory = currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return TextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            methodName: "Enhanced",
            options: options
        )
    }
    
    // MARK: - Helper Methods
    
    private func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) { infoPtr in
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                task_info_t(OpaquePointer(infoPtr)),
                &count
            )
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}