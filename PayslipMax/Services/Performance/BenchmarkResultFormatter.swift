import Foundation

/// Protocol defining benchmark result formatting capabilities.
///
/// This service handles the formatting and display of benchmark results,
/// including time and memory calculations, percentage comparisons, and
/// tabular output formatting.
protocol BenchmarkResultFormatterProtocol {
    /// Formats a time interval for display
    /// - Parameter seconds: Time interval in seconds
    /// - Returns: Formatted time string (e.g., "1.23 ms", "2.45 s")
    func formatTime(_ seconds: TimeInterval) -> String
    
    /// Formats memory usage for display
    /// - Parameter bytes: Memory usage in bytes
    /// - Returns: Formatted memory string (e.g., "1.23 KB", "4.56 MB")
    func formatMemory(_ bytes: UInt64) -> String
    
    /// Calculates percentage improvement between two values
    /// - Parameters:
    ///   - standard: The baseline value
    ///   - enhanced: The comparison value
    /// - Returns: Formatted percentage improvement string
    func calculatePercentageImprovement(standard: Double, enhanced: Double) -> String
    
    /// Calculates percentage improvement between two memory values
    /// - Parameters:
    ///   - standard: The baseline memory value
    ///   - enhanced: The comparison memory value
    /// - Returns: Formatted percentage improvement string
    func calculatePercentageImprovement(standard: UInt64, enhanced: UInt64) -> String
    
    /// Describes extraction options in a human-readable format
    /// - Parameter options: The extraction options to describe
    /// - Returns: Human-readable description of the options
    func describeOptions(_ options: ExtractionOptions) -> String
    
    /// Prints a formatted benchmark summary table
    /// - Parameter results: Array of benchmark results to display
    func printBenchmarkSummary(results: [TextExtractionBenchmarkResult])
    
    /// Converts a dictionary of results to an array
    /// - Parameter dictionary: Dictionary of benchmark results
    /// - Returns: Array of benchmark results
    func convertToArray(_ dictionary: [String: TextExtractionBenchmarkResult]) -> [TextExtractionBenchmarkResult]
}

/// Service responsible for formatting and displaying benchmark results.
///
/// This service provides comprehensive formatting capabilities for benchmark data,
/// including time and memory formatting, percentage calculations, and tabular
/// output generation for easy comparison of different extraction methods.
class BenchmarkResultFormatter: BenchmarkResultFormatterProtocol {
    
    // MARK: - BenchmarkResultFormatterProtocol
    
    /// Formats a time interval for display
    /// - Parameter seconds: Time interval in seconds
    /// - Returns: Formatted time string (e.g., "1.23 ms", "2.45 s")
    func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 0.001 {
            return String(format: "%.2f μs", seconds * 1_000_000)
        } else if seconds < 1 {
            return String(format: "%.2f ms", seconds * 1_000)
        } else {
            return String(format: "%.2f s", seconds)
        }
    }
    
    /// Formats memory usage for display
    /// - Parameter bytes: Memory usage in bytes
    /// - Returns: Formatted memory string (e.g., "1.23 KB", "4.56 MB")
    func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
    
    /// Calculates percentage improvement between two values
    /// - Parameters:
    ///   - standard: The baseline value
    ///   - enhanced: The comparison value
    /// - Returns: Formatted percentage improvement string
    func calculatePercentageImprovement(standard: Double, enhanced: Double) -> String {
        let improvement = (standard - enhanced) / standard * 100
        return String(format: "%.1f", improvement)
    }
    
    /// Calculates percentage improvement between two memory values
    /// - Parameters:
    ///   - standard: The baseline memory value
    ///   - enhanced: The comparison memory value
    /// - Returns: Formatted percentage improvement string
    func calculatePercentageImprovement(standard: UInt64, enhanced: UInt64) -> String {
        let standardDouble = Double(standard)
        let enhancedDouble = Double(enhanced)
        let improvement = (standardDouble - enhancedDouble) / standardDouble * 100
        return String(format: "%.1f", improvement)
    }
    
    /// Describes extraction options in a human-readable format
    /// - Parameter options: The extraction options to describe
    /// - Returns: Human-readable description of the options
    func describeOptions(_ options: ExtractionOptions) -> String {
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
    
    /// Prints a formatted benchmark summary table
    /// - Parameter results: Array of benchmark results to display
    func printBenchmarkSummary(results: [TextExtractionBenchmarkResult]) {
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
    
    /// Converts a dictionary of results to an array
    /// - Parameter dictionary: Dictionary of benchmark results
    /// - Returns: Array of benchmark results
    func convertToArray(_ dictionary: [String: TextExtractionBenchmarkResult]) -> [TextExtractionBenchmarkResult] {
        return dictionary.values.map { $0 }
    }
}