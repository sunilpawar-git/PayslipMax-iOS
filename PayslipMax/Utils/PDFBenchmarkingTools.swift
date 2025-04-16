import Foundation
import PDFKit

/// Utility class for benchmarking PDF processing performance
class PDFBenchmarkingTools {
    // MARK: - Properties
    
    /// Shared instance for benchmarking
    static let shared = PDFBenchmarkingTools()
    
    /// Records of past benchmarks
    private var benchmarkRecords: [BenchmarkRecord] = []
    
    // MARK: - Benchmarking Methods
    
    /// Run a comprehensive benchmark on a PDF document with different extraction strategies
    /// - Parameters:
    ///   - document: The PDF document to benchmark
    ///   - completion: Callback with the benchmark results
    func runComprehensiveBenchmark(on document: PDFDocument, completion: @escaping ([BenchmarkResult]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [BenchmarkResult] = []
            
            // Standard extraction benchmark
            let standardResult = self.benchmarkStandardExtraction(document)
            results.append(standardResult)
            
            // Optimized extraction benchmark with different strategies
            let optimizedService = OptimizedTextExtractionService()
            
            for strategy in PDFExtractionStrategy.allCases {
                let strategyResult = self.benchmarkStrategy(strategy, on: document, using: optimizedService)
                results.append(strategyResult)
            }
            
            // Streaming extraction benchmark
            let streamingResult = self.benchmarkStreamingExtraction(document)
            results.append(streamingResult)
            
            // Store benchmark record
            let record = BenchmarkRecord(
                documentInfo: self.getDocumentInfo(document),
                results: results,
                timestamp: Date()
            )
            self.benchmarkRecords.append(record)
            
            // Return results on main thread
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    /// Benchmark standard text extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: Benchmark result for standard extraction
    func benchmarkStandardExtraction(_ document: PDFDocument) -> BenchmarkResult {
        let service = TextExtractionService()
        
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Extract text
        let text = service.extractText(from: document)
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return BenchmarkResult(
            strategyName: "Standard",
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Benchmark streaming text extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: Benchmark result for streaming extraction
    func benchmarkStreamingExtraction(_ document: PDFDocument) -> BenchmarkResult {
        let processor = StreamingPDFProcessor()
        
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Process the document using a synchronous approach for benchmarking
        var text = ""
        
        // Create and run a Task for async processing
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            text = await processor.processDocumentStreaming(document) { _, _ in }
            semaphore.signal()
        }
        
        // Wait for task completion
        semaphore.wait()
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return BenchmarkResult(
            strategyName: "Streaming",
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Benchmark a specific extraction strategy
    /// - Parameters:
    ///   - strategy: The strategy to benchmark
    ///   - document: The PDF document to process
    ///   - service: The optimized extraction service
    /// - Returns: Benchmark result for the strategy
    func benchmarkStrategy(_ strategy: PDFExtractionStrategy, on document: PDFDocument, using service: OptimizedTextExtractionService) -> BenchmarkResult {
        let startTime = Date()
        let startMemory = getCurrentMemoryUsage()
        
        // Extract text using specified strategy
        let text = service.extractText(from: document, using: strategy)
        
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        return BenchmarkResult(
            strategyName: strategy.rawValue,
            executionTime: endTime.timeIntervalSince(startTime),
            memoryUsage: Int64(endMemory - startMemory),
            outputSize: text.count,
            success: !text.isEmpty
        )
    }
    
    /// Get historical benchmark records
    /// - Returns: Array of benchmark records
    func getBenchmarkHistory() -> [BenchmarkRecord] {
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
    private func getDocumentInfo(_ document: PDFDocument) -> DocumentInfo {
        return DocumentInfo(
            pageCount: document.pageCount,
            fileSize: document.dataRepresentation()?.count ?? 0,
            hasText: document.string?.isEmpty == false
        )
    }
}

// MARK: - Model Structures

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

// MARK: - Extensions

/// Make PDFExtractionStrategy conform to CaseIterable for benchmarking all strategies
extension PDFExtractionStrategy: CaseIterable {
    static var allCases: [PDFExtractionStrategy] {
        return [.standard, .vision, .layoutAware, .fastText]
    }
}

/// Extension to provide a human-readable performance summary
extension BenchmarkResult {
    /// Get a human-readable summary of the benchmark result
    /// - Returns: Formatted summary string
    func getSummary() -> String {
        let timeString = String(format: "%.2f seconds", executionTime)
        let memoryString = formatMemory(memoryUsage)
        let outputString = formatTextSize(outputSize)
        
        return """
        Strategy: \(strategyName)
        Time: \(timeString)
        Memory: \(memoryString)
        Output: \(outputString)
        Success: \(success ? "Yes" : "No")
        """
    }
    
    /// Format memory size in human-readable format
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted memory size string
    private func formatMemory(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.2f KB", kb)
        }
    }
    
    /// Format text size in human-readable format
    /// - Parameter charCount: Character count
    /// - Returns: Formatted text size string
    private func formatTextSize(_ charCount: Int) -> String {
        if charCount >= 1000 {
            return String(format: "%.1f K chars", Double(charCount) / 1000.0)
        } else {
            return "\(charCount) chars"
        }
    }
} 