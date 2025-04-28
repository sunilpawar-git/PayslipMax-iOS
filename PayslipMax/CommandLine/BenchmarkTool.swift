import Foundation
import PDFKit
// import ArgumentParser - Removed to fix build issues

/// A tool for benchmarking text extraction performance
/// Converted from command-line tool to regular class for iOS compatibility
class BenchmarkTool {
    
    // MARK: - Public Methods
    
    /// Run comprehensive benchmarks
    static func runComprehensiveBenchmark(pdfPath: String, saveResults: Bool = false) async {
        let urlFromString = URL(string: pdfPath)
        let urlFromPath = URL(fileURLWithPath: pdfPath)
        let pdfURL = urlFromString ?? urlFromPath
        
        guard let document = PDFDocument(url: pdfURL) else {
            print("Could not load PDF from \(pdfPath)")
            return
        }
        
        print("📊 Running comprehensive benchmark on \(pdfURL.lastPathComponent)...")
        let benchmark = TextExtractionBenchmark()
        let results = await benchmark.runComprehensiveBenchmark(on: document)
        
        if saveResults {
            saveToCSV(results: results, filename: "comprehensive_benchmark.csv")
        }
        
        print("✅ Benchmark completed with \(results.count) test results")
    }
    
    /// Benchmark extraction presets
    static func benchmarkPresets(pdfPath: String, saveResults: Bool = false) {
        let urlFromString = URL(string: pdfPath)
        let urlFromPath = URL(fileURLWithPath: pdfPath)
        let pdfURL = urlFromString ?? urlFromPath
        
        guard let document = PDFDocument(url: pdfURL) else {
            print("Could not load PDF from \(pdfPath)")
            return
        }
        
        print("📊 Running preset benchmark on \(pdfURL.lastPathComponent)...")
        let benchmark = TextExtractionBenchmark()
        let results = benchmark.benchmarkPresets(on: document)
        
        if saveResults {
            savePresetResultsToCSV(results: results, filename: "preset_benchmark.csv")
        }
        
        print("✅ Benchmark completed with \(results.count) presets tested")
    }
    
    /// Run benchmark with custom extraction options
    static func benchmarkCustomConfiguration(
        pdfPath: String, 
        parallel: Bool = true,
        preprocess: Bool = true,
        adaptiveBatching: Bool = true,
        maxConcurrentOps: Int = 4,
        memoryThresholdMB: Int = 100,
        batchSize: Int = 2
    ) {
        let urlFromString = URL(string: pdfPath)
        let urlFromPath = URL(fileURLWithPath: pdfPath)
        let pdfURL = urlFromString ?? urlFromPath
        
        guard let document = PDFDocument(url: pdfURL) else {
            print("Could not load PDF from \(pdfPath)")
            return
        }
        
        let options = ExtractionOptions(
            useParallelProcessing: parallel,
            maxConcurrentOperations: maxConcurrentOps,
            preprocessText: preprocess,
            useAdaptiveBatching: adaptiveBatching,
            maxBatchSize: batchSize * 1024 * 1024,
            memoryThresholdMB: memoryThresholdMB
        )
        
        print("📊 Running custom benchmark on \(pdfURL.lastPathComponent)...")
        let benchmark = TextExtractionBenchmark()
        let result = benchmark.benchmarkCustomConfiguration(on: document, options: options)
        
        print("⏱️ Execution time: \(String(format: "%.4f", result.executionTime)) seconds")
        print("💾 Memory usage: \(formatMemoryUsage(Int(result.memoryUsage)))")
        print("✅ Custom benchmark completed")
    }
    
    // MARK: - Helper Methods
    
    /// Save benchmark results to a CSV file
    static func saveToCSV(results: [TextExtractionBenchmarkResult], filename: String) {
        let csvHeader = "Method,Execution Time (s),Memory Usage (MB),Options\n"
        var csvContent = csvHeader
        
        for result in results {
            let optionsString = result.options != nil ? optionsToString(result.options!) : "Default"
            let line = "\(result.methodName),\(result.executionTime),\(Double(result.memoryUsage) / 1024.0 / 1024.0),\"\(optionsString)\"\n"
            csvContent.append(line)
        }
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📁 Results saved to \(fileURL.path)")
        } catch {
            print("❌ Failed to save results: \(error.localizedDescription)")
        }
    }
    
    /// Save preset benchmark results to a CSV file
    static func savePresetResultsToCSV(results: [String: TextExtractionBenchmarkResult], filename: String) {
        let csvHeader = "Preset,Execution Time (s),Memory Usage (MB),Options\n"
        var csvContent = csvHeader
        
        for (preset, result) in results {
            let optionsString = result.options != nil ? optionsToString(result.options!) : "Default"
            let line = "\(preset),\(result.executionTime),\(Double(result.memoryUsage) / 1024.0 / 1024.0),\"\(optionsString)\"\n"
            csvContent.append(line)
        }
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📁 Results saved to \(fileURL.path)")
        } catch {
            print("❌ Failed to save results: \(error.localizedDescription)")
        }
    }
    
    /// Convert extraction options to string representation
    private static func optionsToString(_ options: ExtractionOptions) -> String {
        var parts = [String]()
        
        if options.useParallelProcessing {
            parts.append("Parallel:\(options.maxConcurrentOperations)")
        } else {
            parts.append("Sequential")
        }
        
        if options.preprocessText {
            parts.append("Preprocess")
        }
        
        if options.useAdaptiveBatching {
            parts.append("AdaptiveBatching")
        }
        
        parts.append("MemThreshold:\(options.memoryThresholdMB)MB")
        
        return parts.joined(separator: ", ")
    }
    
    /// Format memory usage to a human-readable string
    static func formatMemoryUsage(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        return String(format: "%.2f MB", mb)
    }
}

// Usage example:
// BenchmarkTool.main() 