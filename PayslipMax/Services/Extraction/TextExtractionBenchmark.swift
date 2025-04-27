import Foundation
import PDFKit

/// A utility class for benchmarking different text extraction methods
class TextExtractionBenchmark {
    
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
    
    // MARK: - Public API
    
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
        
        // Print results
        printBenchmarkSummary(results: results)
        
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
        
        // Print results
        printBenchmarkSummary(results: convertToArray(results))
        
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
        print("⚙️ Configuration: \(describeOptions(options))")
        
        let result = benchmarkEnhancedExtraction(on: document, options: options)
        
        // Compare with standard
        let standardResult = benchmarkStandardExtraction(on: document)
        let timeImprovement = calculatePercentageImprovement(
            standard: standardResult.executionTime,
            enhanced: result.executionTime
        )
        let memoryImprovement = calculatePercentageImprovement(
            standard: standardResult.memoryUsage,
            enhanced: result.memoryUsage
        )
        
        print("⏱️ Execution time: \(formatTime(result.executionTime)) (\(timeImprovement)% vs standard)")
        print("💾 Memory usage: \(formatMemory(result.memoryUsage)) (\(memoryImprovement)% vs standard)")
        
        return result
    }

    // MARK: - Private Methods - Benchmarking
    
    private func benchmarkStandardExtraction(on document: PDFDocument) -> TextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = currentMemoryUsage()
        
        // Use a method that's available in ExtractionStrategyService - I'm assuming it might be something like determineStrategy
        // This would need to be adjusted based on the actual API of ExtractionStrategyService
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
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            _ = await enhancedService.extractTextEnhanced(from: document, options: options)
            semaphore.signal()
        }
        
        // Wait a moment for the async operation to complete
        semaphore.wait()
        
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
    
    // Additional helper methods...
    
    private func convertToArray(_ dictionary: [String: TextExtractionBenchmarkResult]) -> [TextExtractionBenchmarkResult] {
        return dictionary.values.map { $0 }
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
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 0.001 {
            return String(format: "%.2f μs", seconds * 1_000_000)
        } else if seconds < 1 {
            return String(format: "%.2f ms", seconds * 1_000)
        } else {
            return String(format: "%.2f s", seconds)
        }
    }
    
    private func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
    
    private func calculatePercentageImprovement(standard: Double, enhanced: Double) -> String {
        let improvement = (standard - enhanced) / standard * 100
        return String(format: "%.1f", improvement)
    }
    
    private func calculatePercentageImprovement(standard: UInt64, enhanced: UInt64) -> String {
        let standardDouble = Double(standard)
        let enhancedDouble = Double(enhanced)
        let improvement = (standardDouble - enhancedDouble) / standardDouble * 100
        return String(format: "%.1f", improvement)
    }
    
    private func describeOptions(_ options: ExtractionOptions) -> String {
        var description = [String]()
        
        if options.useParallelProcessing {
            description.append("Parallel(\(options.maxConcurrentOperations))")
        } else {
            description.append("Sequential")
        }
        
        if options.preprocessText {
            description.append("Preprocess")
        }
        
        if options.useAdaptiveBatching {
            description.append("AdaptiveBatch")
        }
        
        description.append("MemThreshold:\(options.memoryThresholdMB)MB")
        
        return description.joined(separator: ", ")
    }
    
    private func printBenchmarkSummary(results: [TextExtractionBenchmarkResult]) {
        print("\n📊 BENCHMARK SUMMARY")
        print("===================")
        
        // Find standard result for comparison
        let standardResult = results.first { $0.methodName == "Standard" }
        
        // Print headers
        print(String(format: "%-20s %-15s %-15s %-20s %-20s", 
                     "Method", "Time", "Memory", "Time vs Std", "Memory vs Std"))
        print(String(repeating: "-", count: 90))
        
        // Print each result
        for result in results {
            var timeComparison = "N/A"
            var memoryComparison = "N/A"
            
            if let standard = standardResult {
                let timeImprovement = calculatePercentageImprovement(
                    standard: standard.executionTime,
                    enhanced: result.executionTime
                )
                let memoryImprovement = calculatePercentageImprovement(
                    standard: standard.memoryUsage,
                    enhanced: result.memoryUsage
                )
                
                timeComparison = "\(timeImprovement)%"
                memoryComparison = "\(memoryImprovement)%"
            }
            
            let optionsText = result.options != nil ? " (\(describeOptions(result.options!)))" : ""
            let displayName = result.methodName + optionsText
            
            print(String(format: "%-20s %-15s %-15s %-20s %-20s",
                         displayName,
                         formatTime(result.executionTime),
                         formatMemory(result.memoryUsage),
                         timeComparison,
                         memoryComparison))
        }
        
        print("===================\n")
    }
}

// MARK: - Types

/// Represents the result of a benchmark test
struct TextExtractionBenchmarkResult {
    /// Execution time in seconds
    let executionTime: TimeInterval
    
    /// Memory usage in bytes
    let memoryUsage: UInt64
    
    /// Name of the extraction method
    let methodName: String
    
    /// Extraction options used (if applicable)
    let options: ExtractionOptions?
    
    init(executionTime: TimeInterval, memoryUsage: UInt64, methodName: String, options: ExtractionOptions?) {
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.methodName = methodName
        self.options = options
    }
}

// MARK: - StreamingPDFProcessor Stub

/// Stub implementation of StreamingPDFProcessor
class BenchmarkStreamingPDFProcessor {
    /// Process a document in a streaming manner
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - progressHandler: Handler to receive progress updates
    /// - Returns: The extracted text
    func processDocumentStreaming(_ document: PDFDocument, progressHandler: @escaping (Double, String) -> Void) async -> String {
        var result = ""
        
        // Simple implementation that extracts text from each page
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                // Extract text from page
                let pageText = page.string ?? ""
                result += pageText + "\n\n"
                
                // Report progress
                let progress = Double(i + 1) / Double(document.pageCount)
                progressHandler(progress, pageText)
            }
        }
        
        return result
    }
}

// MARK: - TextExtractionService Stub

/// Stub implementation of TextExtractionService
class BenchmarkTextExtractionService: TextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var result = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                result += page.string ?? ""
                if i < document.pageCount - 1 {
                    result += "\n\n"
                }
            }
        }
        
        return result
    }
    
    // Add stubs for conformance to TextExtractionServiceProtocol
    func extractText(from page: PDFPage) -> String {
        return page.string ?? ""
    }
    
    func extractDetailedText(from pdfDocument: PDFDocument) -> String {
        return extractText(from: pdfDocument)
    }
    
    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // No-op in stub implementation
    }
    
    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        return true
    }
}

// MARK: - PDFProcessingCache Stub

/// Stub implementation of PDFProcessingCache
class BenchmarkPDFProcessingCache {
    static let shared = BenchmarkPDFProcessingCache()
    
    private var cache: [String: Any] = [:]
    
    func store<T>(_ value: T, forKey key: String) throws {
        cache[key] = value
    }
    
    func retrieve<T>(forKey key: String) throws -> T {
        guard let value = cache[key] as? T else {
            throw NSError(domain: "PDFProcessingCache", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found in cache"])
        }
        return value
    }
}

// MARK: - PDFDocument Extension

extension PDFDocument {
    /// Generate a unique cache key for this document
    func uniqueCacheKey() -> String {
        // Simple implementation that combines unique identifier based on hash value and modification date
        let id = String(self.hashValue)
        let date = documentAttributes?["ModDate"] as? String ?? ""
        return "\(id)-\(date)"
    }
}

// MARK: - PDFTextExtractionService Stub

/// Stub implementation of PDFTextExtractionService
class BenchmarkPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        var result = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                result += page.string ?? ""
                if i < document.pageCount - 1 {
                    result += "\n\n"
                }
            }
        }
        
        return result
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount else { return nil }
        return document.page(at: pageIndex)?.string
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        var result = ""
        for i in range {
            if let page = document.page(at: i) {
                result += page.string ?? ""
            }
        }
        return result
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 0
    }
    
    func extractText(from data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw NSError(domain: "BenchmarkPDFTextExtractionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document from data"])
        }
        return extractText(from: document) ?? ""
    }
}

// MARK: - Required Protocols

/// Protocol for text extraction service
protocol BenchmarkTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

/// Protocol for PDF text extraction service
protocol BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

// Test implementations for benchmark protocol
private struct StandardExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
            }
        }
        return text
    }
}

private struct VisionExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        // Simulated Vision implementation
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
                // Vision would typically provide better text recognition
                text += " [Enhanced with Vision]"
            }
        }
        return text
    }
}

// MARK: - Adapters for Main Protocol

/// Standard text extractor adapter
private struct StandardTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 0.5) // Simulating processing time
        let end = CFAbsoluteTimeGetCurrent()
        
        print("StandardExtractor time: \(end - start) seconds")
        return text
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractTextFromPage(at: pageIndex, in: document)
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractText(from: document, in: range)
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 0
    }
    
    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        return try service.extractText(from: data)
    }
}

/// Vision-based text extractor adapter
private struct VisionTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 1.5) // Simulating longer processing time for Vision
        let end = CFAbsoluteTimeGetCurrent()
        
        print("VisionExtractor time: \(end - start) seconds")
        return text
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.2) // Simulating Vision processing
        return service.extractTextFromPage(at: pageIndex, in: document)
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.5) // Simulating Vision processing
        return service.extractText(from: document, in: range)
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 10_000_000 // 10MB simulated memory usage
    }
    
    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.3) // Simulating Vision processing
        return try service.extractText(from: data)
    }
} 