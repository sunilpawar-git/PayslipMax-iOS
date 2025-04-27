import Foundation
import PDFKit

/// Example class demonstrating the usage of the TextExtractionBenchmark
class TextExtractionBenchmarkExample {
    
    /// Demonstrates comprehensive benchmarking of all extraction methods
    func runComprehensiveBenchmarkExample() async {
        guard let pdfURL = Bundle.main.url(forResource: "SampleDocument", withExtension: "pdf"),
              let document = PDFDocument(url: pdfURL) else {
            print("❌ Failed to load sample document")
            return
        }
        
        print("🔬 Running comprehensive benchmark on sample document...")
        let benchmark = TextExtractionBenchmark()
        let results = await benchmark.runComprehensiveBenchmark(on: document)
        
        // Do something with the results if needed
        print("📈 Found \(results.count) benchmark results")
    }
    
    /// Demonstrates benchmarking of all presets
    func runPresetBenchmarkExample() {
        guard let pdfURL = Bundle.main.url(forResource: "LargeDocument", withExtension: "pdf"),
              let document = PDFDocument(url: pdfURL) else {
            print("❌ Failed to load large document")
            return
        }
        
        print("🔬 Running preset benchmark on large document...")
        let benchmark = TextExtractionBenchmark()
        let results = benchmark.benchmarkPresets(on: document)
        
        // Find the best performing preset
        var bestPreset = ""
        var bestTime = Double.infinity
        
        for (name, result) in results {
            if name != "Standard" && result.executionTime < bestTime {
                bestTime = result.executionTime
                bestPreset = name
            }
        }
        
        print("🏆 Best performing preset: \(bestPreset)")
    }
    
    /// Demonstrates benchmarking with custom options
    func runCustomConfigurationExample() {
        guard let pdfURL = Bundle.main.url(forResource: "ComplexDocument", withExtension: "pdf"),
              let document = PDFDocument(url: pdfURL) else {
            print("❌ Failed to load complex document")
            return
        }
        
        print("🔬 Running custom configuration benchmark...")
        
        // Create custom extraction options
        let customOptions = ExtractionOptions(
            useParallelProcessing: true,
            maxConcurrentOperations: 4,
            preprocessText: false,
            useAdaptiveBatching: true,
            maxBatchSize: 2 * 1024 * 1024, // 2MB instead of batchSize parameter
            collectDetailedMetrics: true,
            useCache: true,
            memoryThresholdMB: 100 // Using memoryThresholdMB instead of memoryThreshold
        )
        
        let benchmark = TextExtractionBenchmark()
        let result = benchmark.benchmarkCustomConfiguration(on: document, options: customOptions)
        
        print("📊 Custom configuration result: \(result.executionTime) seconds")
    }
    
    /// Runs all benchmark examples
    func runAllExamples() async {
        print("\n========== EXTRACTION BENCHMARK EXAMPLES ==========\n")
        
        await runComprehensiveBenchmarkExample()
        print("\n---------------------------------------------------\n")
        
        runPresetBenchmarkExample()
        print("\n---------------------------------------------------\n")
        
        runCustomConfigurationExample()
        print("\n========== END OF EXAMPLES ==========\n")
    }
}

// Example usage:
// let example = TextExtractionBenchmarkExample()
// example.runAllExamples() 