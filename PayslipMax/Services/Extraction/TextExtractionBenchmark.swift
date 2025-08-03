import Foundation
import PDFKit

/// A utility class for benchmarking different text extraction methods.
///
/// This coordinator orchestrates benchmark execution and result formatting
/// by delegating to specialized services while providing a unified interface
/// for text extraction performance analysis.
class TextExtractionBenchmark {
    
    // MARK: - Properties
    
    /// The execution engine responsible for running benchmarks
    private let executionEngine: BenchmarkExecutionEngineProtocol
    
    /// The formatter responsible for displaying results
    private let resultFormatter: BenchmarkResultFormatterProtocol
    
    // MARK: - Initialization
    
    /// Initializes the benchmark coordinator with default services
    init() {
        self.executionEngine = BenchmarkExecutionEngine()
        self.resultFormatter = BenchmarkResultFormatter()
    }
    
    /// Initializes the benchmark coordinator with injected dependencies
    /// - Parameters:
    ///   - executionEngine: The benchmark execution engine
    ///   - resultFormatter: The result formatter
    init(executionEngine: BenchmarkExecutionEngineProtocol, resultFormatter: BenchmarkResultFormatterProtocol) {
        self.executionEngine = executionEngine
        self.resultFormatter = resultFormatter
    }
    
    // MARK: - Public API
    
    /// Runs a comprehensive benchmark of all extraction methods on the given PDF document
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each method
    func runComprehensiveBenchmark(on document: PDFDocument) async -> [TextExtractionBenchmarkResult] {
        let results = await executionEngine.runComprehensiveBenchmark(on: document)
        
        // Print results using the formatter
        resultFormatter.printBenchmarkSummary(results: results)
        
        return results
    }
    
    /// Benchmarks all preset configurations of enhanced extraction
    /// - Parameter document: The PDF document to benchmark
    /// - Returns: A dictionary containing benchmark results for each preset
    func benchmarkPresets(on document: PDFDocument) -> [String: TextExtractionBenchmarkResult] {
        let results = executionEngine.benchmarkPresets(on: document)
        
        // Print results using the formatter
        resultFormatter.printBenchmarkSummary(results: resultFormatter.convertToArray(results))
        
        return results
    }
    
    /// Benchmarks enhanced extraction with custom options
    /// - Parameters:
    ///   - document: The PDF document to benchmark
    ///   - options: Custom extraction options
    /// - Returns: Benchmark result for the custom configuration
    func benchmarkCustomConfiguration(on document: PDFDocument, options: ExtractionOptions) -> TextExtractionBenchmarkResult {
        print("⚙️ Configuration: \(resultFormatter.describeOptions(options))")
        
        let result = executionEngine.benchmarkCustomConfiguration(on: document, options: options)
        
        // Compare with standard if available
        let standardResults = executionEngine.benchmarkPresets(on: document)
        if let standardResult = standardResults["Standard"] {
            let timeImprovement = resultFormatter.calculatePercentageImprovement(
            standard: standardResult.executionTime,
            enhanced: result.executionTime
        )
            let memoryImprovement = resultFormatter.calculatePercentageImprovement(
            standard: standardResult.memoryUsage,
            enhanced: result.memoryUsage
        )
        
            print("⏱️ Execution time: \(resultFormatter.formatTime(result.executionTime)) (\(timeImprovement)% vs standard)")
            print("💾 Memory usage: \(resultFormatter.formatMemory(result.memoryUsage)) (\(memoryImprovement)% vs standard)")
        }
        
        return result
    }

    // MARK: - Convenience Methods
    
    /// Formats a time interval for display
    /// - Parameter seconds: Time interval in seconds
    /// - Returns: Formatted time string
    func formatTime(_ seconds: TimeInterval) -> String {
        return resultFormatter.formatTime(seconds)
    }
    
    /// Formats memory usage for display
    /// - Parameter bytes: Memory usage in bytes
    /// - Returns: Formatted memory string
    func formatMemory(_ bytes: UInt64) -> String {
        return resultFormatter.formatMemory(bytes)
    }
    
    /// Calculates percentage improvement between two values
    /// - Parameters:
    ///   - standard: The baseline value
    ///   - enhanced: The comparison value
    /// - Returns: Formatted percentage improvement string
    func calculatePercentageImprovement(standard: Double, enhanced: Double) -> String {
        return resultFormatter.calculatePercentageImprovement(standard: standard, enhanced: enhanced)
    }
    
    /// Describes extraction options in a human-readable format
    /// - Parameter options: The extraction options to describe
    /// - Returns: Human-readable description of the options
    func describeOptions(_ options: ExtractionOptions) -> String {
        return resultFormatter.describeOptions(options)
    }
    
    /// Prints a formatted benchmark summary table
    /// - Parameter results: Array of benchmark results to display
    func printBenchmarkSummary(results: [TextExtractionBenchmarkResult]) {
        resultFormatter.printBenchmarkSummary(results: results)
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