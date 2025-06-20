import Foundation
import PDFKit

/// Async-first text extraction benchmark service that eliminates DispatchSemaphore usage.
/// This replaces the synchronous TextExtractionBenchmark for new async workflows.
/// 
/// Follows the single responsibility principle established in Phase 2B refactoring.
class AsyncTextExtractionBenchmark {
    
    // MARK: - Properties
    
    private let enhancedService: EnhancedTextExtractionService
    
    // MARK: - Initialization
    
    init(enhancedService: EnhancedTextExtractionService = EnhancedTextExtractionService()) {
        self.enhancedService = enhancedService
    }
    
    // MARK: - Public Async Methods
    
    /// Runs comprehensive benchmarks asynchronously
    func runBenchmarks(on document: PDFDocument) async -> [AsyncTextExtractionBenchmarkResult] {
        print("🚀 Starting Async Text Extraction Benchmarks")
        print("============================================")
        
        var results: [AsyncTextExtractionBenchmarkResult] = []
        
        // ✅ CLEAN: Use structured concurrency for parallel benchmarks
        async let standardResult = benchmarkStandardExtraction(on: document)
        async let enhancedResult = benchmarkEnhancedExtraction(on: document)
        async let parallelResult = benchmarkParallelExtraction(on: document)
        async let optimizedResult = benchmarkOptimizedExtraction(on: document)
        
        // Collect all results
        do {
            let allResults = try await [
                standardResult,
                enhancedResult,
                parallelResult,
                optimizedResult
            ]
            
            results.append(contentsOf: allResults)
            
        } catch {
            print("❌ Benchmark error: \(error)")
        }
        
        // Print summary
        await printBenchmarkSummary(results: results)
        
        return results
    }
    
    /// Runs comparative benchmarks with different configurations
    func runComparativeBenchmarks(on documents: [PDFDocument]) async -> AsyncBenchmarkReport {
        let startTime = Date()
        
        var allResults: [AsyncTextExtractionBenchmarkResult] = []
        
        // ✅ CLEAN: Process documents concurrently with controlled parallelism
        let maxConcurrency = min(documents.count, 3)
        
        await withTaskGroup(of: [AsyncTextExtractionBenchmarkResult].self) { group in
            let semaphore = AsyncSemaphore(value: maxConcurrency)
            
            for (index, document) in documents.enumerated() {
                group.addTask {
                    await semaphore.wait()
                    defer {
                        Task { await semaphore.signal() }
                    }
                    
                    return await self.runBenchmarks(on: document)
                }
            }
            
            for await results in group {
                allResults.append(contentsOf: results)
            }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        return AsyncBenchmarkReport(
            results: allResults,
            totalTime: totalTime,
            documentCount: documents.count,
            averageTimePerDocument: totalTime / Double(documents.count)
        )
    }
    
    // MARK: - Private Benchmark Methods
    
    /// Benchmarks standard extraction
    private func benchmarkStandardExtraction(on document: PDFDocument) async -> AsyncTextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = await currentMemoryUsage()
        
        // ✅ CLEAN: Direct async call - no semaphores!
        _ = await extractTextStandard(from: document)
        
        let endTime = Date()
        let endMemory = await currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return AsyncTextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: UInt64(max(0, memoryUsage)),
            methodName: "Standard",
            options: nil as ExtractionOptions?
        )
    }
    
    /// Benchmarks enhanced extraction
    private func benchmarkEnhancedExtraction(on document: PDFDocument) async -> AsyncTextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = await currentMemoryUsage()
        
        let options = ExtractionOptions(
            useParallelProcessing: false,
            maxConcurrentOperations: 1,
            preprocessText: true,
            useAdaptiveBatching: false,
            useCache: true,
            memoryThresholdMB: 50
        )
        
        // ✅ CLEAN: Direct async call - no semaphores!
        _ = await enhancedService.extractTextEnhanced(from: document, options: options)
        
        let endTime = Date()
        let endMemory = await currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return AsyncTextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: UInt64(max(0, memoryUsage)),
            methodName: "Enhanced",
            options: options
        )
    }
    
    /// Benchmarks parallel extraction
    private func benchmarkParallelExtraction(on document: PDFDocument) async -> AsyncTextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = await currentMemoryUsage()
        
        let options = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 4,
            preprocessText: true,
            useAdaptiveBatching: true,
            useCache: true,
            memoryThresholdMB: 100
        )
        
        // ✅ CLEAN: Direct async call - no semaphores!
        _ = await enhancedService.extractTextEnhanced(from: document, options: options)
        
        let endTime = Date()
        let endMemory = await currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return AsyncTextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: UInt64(max(0, memoryUsage)),
            methodName: "Parallel",
            options: options
        )
    }
    
    /// Benchmarks optimized extraction
    private func benchmarkOptimizedExtraction(on document: PDFDocument) async -> AsyncTextExtractionBenchmarkResult {
        let startTime = Date()
        let startMemory = await currentMemoryUsage()
        
        let options = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 2,
            preprocessText: false,
            useAdaptiveBatching: true,
            useCache: false,
            memoryThresholdMB: 200
        )
        
        // ✅ CLEAN: Direct async call - no semaphores!
        _ = await enhancedService.extractTextEnhanced(from: document, options: options)
        
        let endTime = Date()
        let endMemory = await currentMemoryUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        let memoryUsage = endMemory - startMemory
        
        return AsyncTextExtractionBenchmarkResult(
            executionTime: executionTime,
            memoryUsage: UInt64(max(0, memoryUsage)),
            methodName: "Optimized",
            options: options
        )
    }
    
    // MARK: - Helper Methods
    
    /// Standard text extraction method
    private func extractTextStandard(from document: PDFDocument) async -> String {
        var result = ""
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // ✅ CLEAN: Use Task.yield() for cooperative cancellation
            await Task.yield()
            
            if let pageText = page.string {
                result += pageText + "\n"
            }
        }
        
        return result
    }
    
    /// Gets current memory usage asynchronously
    private func currentMemoryUsage() async -> Int64 {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
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
                
                let memoryUsage = kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
                continuation.resume(returning: memoryUsage)
            }
        }
    }
    
    /// Formats time for display
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 0.001 {
            return String(format: "%.2f μs", seconds * 1_000_000)
        } else if seconds < 1 {
            return String(format: "%.2f ms", seconds * 1_000)
        } else {
            return String(format: "%.2f s", seconds)
        }
    }
    
    /// Formats memory for display
    private func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
    
    /// Calculates percentage improvement
    private func calculatePercentageImprovement(standard: Double, enhanced: Double) -> String {
        let improvement = (standard - enhanced) / standard * 100
        return String(format: "%.1f", improvement)
    }
    
    /// Prints benchmark summary
    private func printBenchmarkSummary(results: [AsyncTextExtractionBenchmarkResult]) async {
        print("\n📊 ASYNC BENCHMARK SUMMARY")
        print("==========================")
        
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
                    standard: Double(standard.memoryUsage),
                    enhanced: Double(result.memoryUsage)
                )
                
                timeComparison = "\(timeImprovement)%"
                memoryComparison = "\(memoryImprovement)%"
            }
            
            print(String(format: "%-20s %-15s %-15s %-20s %-20s",
                         result.methodName,
                         formatTime(result.executionTime),
                         formatMemory(result.memoryUsage),
                         timeComparison,
                         memoryComparison))
        }
        
        print("==========================\n")
    }
}

// MARK: - Supporting Types

/// Result of an async benchmark test
struct AsyncTextExtractionBenchmarkResult {
    /// Execution time in seconds
    let executionTime: TimeInterval
    
    /// Memory usage in bytes
    let memoryUsage: UInt64
    
    /// Name of the extraction method
    let methodName: String
    
    /// Extraction options used (if applicable)
    let options: ExtractionOptions?
}

/// Comprehensive benchmark report
struct AsyncBenchmarkReport {
    let results: [AsyncTextExtractionBenchmarkResult]
    let totalTime: TimeInterval
    let documentCount: Int
    let averageTimePerDocument: TimeInterval
    
    /// Performance summary
    var summary: String {
        return """
        📈 BENCHMARK REPORT SUMMARY
        ===========================
        Total Documents: \(documentCount)
        Total Time: \(String(format: "%.2f", totalTime))s
        Average Time/Document: \(String(format: "%.2f", averageTimePerDocument))s
        Total Tests: \(results.count)
        """
    }
}

// Note: ExtractionOptions and EnhancedTextExtractionService are defined in EnhancedTextExtractionService.swift

// Note: AsyncSemaphore is defined in AsyncPDFProcessingCoordinator.swift 