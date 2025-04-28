import Foundation
import PDFKit

/// Utility class for benchmarking PDF processing performance
class PDFBenchmarkingTools {
    // MARK: - Properties
    
    /// Shared instance for benchmarking
    static let shared = PDFBenchmarkingTools()
    
    /// Records of past benchmarks
    private var benchmarkRecords: [PDFBenchmarkingTools.BenchmarkRecord] = []
    
    // MARK: - Benchmarking Methods
    
    /// Run a comprehensive benchmark on a PDF document with different extraction strategies.
    /// Runs asynchronously and returns the results.
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: An array of benchmark results for different strategies.
    func runComprehensiveBenchmark(on document: PDFDocument) async -> [PDFBenchmarkingTools.BenchmarkResult] {
        var results: [PDFBenchmarkingTools.BenchmarkResult] = []
        
        // Standard extraction benchmark (now async)
        let standardResult = await self.benchmarkStandardExtraction(document)
        results.append(standardResult)
        
        // Optimized extraction benchmark with different strategies
        let optimizedService = OptimizedTextExtractionService()
        
        for strategy in PDFExtractionStrategy.allCases {
            // Benchmark strategy (now requires await)
            let strategyResult = await self.benchmarkStrategy(strategy, on: document, using: optimizedService)
            results.append(strategyResult)
        }
        
        // Streaming extraction benchmark (assuming it should be async)
        let streamingResult = await self.benchmarkStreamingExtraction(document)
        results.append(streamingResult)
        
        // Store benchmark record
        let record = PDFBenchmarkingTools.BenchmarkRecord(
            documentInfo: self.getDocumentInfo(document),
            results: results,
            timestamp: Date()
        )
        self.benchmarkRecords.append(record)
        
        return results
    }
    
    /// Benchmark standard text extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: Benchmark result for standard extraction
    func benchmarkStandardExtraction(_ document: PDFDocument) async -> PDFBenchmarkingTools.BenchmarkResult {
        let service = TextExtractionService()
        
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Extract text (now async)
        let text = await service.extractText(from: document)
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "Standard",
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Benchmark streaming text extraction (now async)
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: Benchmark result for streaming extraction
    func benchmarkStreamingExtraction(_ document: PDFDocument) async -> PDFBenchmarkingTools.BenchmarkResult {
        let processor = StreamingPDFProcessor()
        
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Process the document using the async streaming method directly
        let text = await processor.processDocumentStreaming(document) { _, _ in }
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "Streaming",
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Benchmark a specific extraction strategy (now async)
    /// - Parameters:
    ///   - strategy: The strategy to benchmark
    ///   - document: The PDF document to process
    ///   - service: The optimized extraction service
    /// - Returns: Benchmark result for the strategy
    func benchmarkStrategy(_ strategy: PDFExtractionStrategy, on document: PDFDocument, using service: OptimizedTextExtractionService) async -> PDFBenchmarkingTools.BenchmarkResult {
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Extract text using specified strategy (now requires await)
        let text = await service.extractText(from: document, using: strategy)
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return PDFBenchmarkingTools.BenchmarkResult(
            strategyName: strategy.rawValue,
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Get historical benchmark records
    /// - Returns: Array of benchmark records
    func getBenchmarkHistory() -> [PDFBenchmarkingTools.BenchmarkRecord] {
        return benchmarkRecords
    }
    
    /// Export benchmark results to JSON
    /// - Returns: JSON data representation of benchmark records
    func exportBenchmarksToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(benchmarkRecords)
        } catch {
            print("[PDFBenchmarkingTools] Error encoding benchmark records: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get current memory usage
    /// - Returns: Current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<natural_t>.size)
        
        let result = withUnsafeMutablePointer(to: &taskInfo) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { (rawPtr) -> kern_return_t in
                return task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), rawPtr, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return UInt64(taskInfo.phys_footprint)
        } else {
            print("[PDFBenchmarkingTools] Error getting memory usage: \(result)")
            return 0
        }
    }
    
    /// Get document information for benchmarking context
    /// - Parameter document: The PDF document
    /// - Returns: Document information
    private func getDocumentInfo(_ document: PDFDocument) -> PDFBenchmarkingTools.DocumentInfo {
        return PDFBenchmarkingTools.DocumentInfo(
            pageCount: document.pageCount,
            fileSize: document.dataRepresentation()?.count ?? 0,
            hasText: document.string?.isEmpty == false
        )
    }
}

// MARK: - Model Structures

extension PDFBenchmarkingTools {
    /// Structure representing a benchmark result
    struct BenchmarkResult: Codable {
        /// Name of the strategy being benchmarked
        let strategyName: String
        
        /// Execution time in seconds
        let executionTime: TimeInterval
        
        /// Memory usage in bytes
        let memoryUsage: Int64
        
        /// Size of the output text
        let outputSize: Int
        
        /// Whether the extraction was successful
        let success: Bool
    }
    
    /// Structure representing a text extraction benchmark result with additional metrics
    struct TextExtractionBenchmarkResult: Codable {
        /// Base benchmark results
        let baseResult: BenchmarkResult
        
        /// Text quality score (0-100)
        let textQualityScore: Double
        
        /// Structure preservation score (0-100)
        let structurePreservationScore: Double
        
        /// Accuracy of text order (0-100)
        let textOrderAccuracy: Double
        
        /// Character error rate (lower is better)
        let characterErrorRate: Double
        
        init(baseResult: BenchmarkResult, 
             textQualityScore: Double = 0, 
             structurePreservationScore: Double = 0,
             textOrderAccuracy: Double = 0,
             characterErrorRate: Double = 0) {
            self.baseResult = baseResult
            self.textQualityScore = textQualityScore
            self.structurePreservationScore = structurePreservationScore
            self.textOrderAccuracy = textOrderAccuracy
            self.characterErrorRate = characterErrorRate
        }
        
        /// Convenience initializer to create from a BenchmarkResult
        init(from benchmarkResult: BenchmarkResult) {
            self.init(baseResult: benchmarkResult)
        }
    }

    /// Structure representing a benchmark record with context
    struct BenchmarkRecord: Codable {
        /// Information about the document being benchmarked
        let documentInfo: DocumentInfo
        
        /// Results of different benchmark strategies
        let results: [BenchmarkResult]
        
        /// When the benchmark was performed
        let timestamp: Date
    }

    /// Structure for document information
    struct DocumentInfo: Codable {
        /// Number of pages in the document
        let pageCount: Int
        
        /// Size of the document in bytes
        let fileSize: Int
        
        /// Whether the document contains text
        let hasText: Bool
    }
}

// MARK: - Extensions

/// Make PDFExtractionStrategy conform to CaseIterable for benchmarking all strategies
extension PDFExtractionStrategy: CaseIterable {
    static var allCases: [PDFExtractionStrategy] {
        return [.standard, .vision, .layoutAware, .fastText]
    }
}

/// Extension to provide a human-readable performance summary
extension PDFBenchmarkingTools.BenchmarkResult {
    /// Get a human-readable summary of the benchmark result
    /// - Returns: Formatted summary string
    func getSummary() -> String {
        let timeFormatted = String(format: "%.3f sec", executionTime)
        let memoryFormatted = formatMemorySize(memoryUsage)
        
        return "\(strategyName): \(timeFormatted), \(memoryFormatted), \(outputSize) chars"
    }
    
    /// Format memory size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string
    private func formatMemorySize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
}

/// Extension to provide a human-readable performance summary for text extraction benchmark
extension PDFBenchmarkingTools.TextExtractionBenchmarkResult {
    /// Get a human-readable summary of the text extraction benchmark result
    /// - Returns: Formatted summary string
    func getSummary() -> String {
        let baseSummary = baseResult.getSummary()
        let qualitySummary = String(format: "Quality: %.1f%%, Structure: %.1f%%, Order: %.1f%%, CER: %.2f%%",
                                   textQualityScore, structurePreservationScore, textOrderAccuracy, characterErrorRate * 100)
        
        return "\(baseSummary) | \(qualitySummary)"
    }
    
    /// Get the base benchmark result
    var strategyName: String { baseResult.strategyName }
    var executionTime: TimeInterval { baseResult.executionTime }
    var memoryUsage: Int64 { baseResult.memoryUsage }
    var outputSize: Int { baseResult.outputSize }
    var success: Bool { baseResult.success }
} 