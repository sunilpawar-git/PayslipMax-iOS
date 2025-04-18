import Foundation
import PDFKit

/// A command-line utility to run the ExtractorProfiler on a given PDF document
class ExtractorProfilerRunner {
    private let profiler = ExtractorProfiler()
    private let analysisService = DocumentAnalysisService()
    private let formatter = ByteCountFormatter()
    
    init() {
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
    }
    
    /// Run the profiler on a given PDF document
    /// - Parameter pdfPath: The file path to the PDF document
    func runProfiler(on pdfPath: String) async {
        print("🔍 Running ExtractorProfiler on: \(pdfPath)")
        
        let fileURL = URL(fileURLWithPath: pdfPath)
        guard let document = PDFDocument(url: fileURL) else {
            print("❌ Error: Could not load PDF document at path: \(pdfPath)")
            return
        }
        
        print("📄 Document loaded: \(document.pageCount) pages")
        
        // Analyze document
        print("\n📊 Analyzing document characteristics...")
        
        let analysis: DocumentAnalysis
        do {
            analysis = try analysisService.analyzeDocument(document)
        } catch {
            print("❌ Error analyzing document: \(error.localizedDescription)")
            return
        }
        
        printDocumentAnalysis(analysis)
        
        // Run profiling tests
        print("\n⏱️ Running extraction benchmarks...")
        
        // Standard extraction
        print("\n🔹 Standard Extraction:")
        let standardResult = await profiler.profileStandardExtraction(on: document)
        printProfilerResult(standardResult)
        
        // Optimized extraction
        print("\n🔹 Optimized Extraction:")
        let optimizedResult = await profiler.profileOptimizedExtraction(on: document)
        printProfilerResult(optimizedResult)
        
        // Enhanced extraction - speed preset
        print("\n🔹 Enhanced Extraction (Speed):")
        let enhancedSpeedResult = await profiler.profileEnhancedExtraction(on: document, preset: .speed)
        printProfilerResult(enhancedSpeedResult)
        
        // Enhanced extraction - quality preset
        print("\n🔹 Enhanced Extraction (Quality):")
        let enhancedQualityResult = await profiler.profileEnhancedExtraction(on: document, preset: .quality)
        printProfilerResult(enhancedQualityResult)
        
        // Enhanced extraction - memory efficient preset
        print("\n🔹 Enhanced Extraction (Memory Efficient):")
        let enhancedMemoryResult = await profiler.profileEnhancedExtraction(on: document, preset: .memoryEfficient)
        printProfilerResult(enhancedMemoryResult)
        
        // Custom extraction options
        print("\n🔹 Enhanced Extraction (Custom):")
        var customOptions = ExtractionOptions()
        customOptions.useParallelProcessing = true
        customOptions.maxConcurrentOperations = 2
        customOptions.preprocessText = true
        customOptions.useAdaptiveBatching = true
        customOptions.maxBatchSize = 1_048_576 // 1MB
        customOptions.memoryThresholdMB = 200
        customOptions.collectDetailedMetrics = true
        
        let customResult = await profiler.profileEnhancedExtraction(on: document, options: customOptions)
        printProfilerResult(customResult)
        
        // Summary
        print("\n📋 Extraction Summary:")
        let results = [standardResult, optimizedResult, enhancedSpeedResult, 
                      enhancedQualityResult, enhancedMemoryResult, customResult]
        
        let fastest = results.min { $0.extractionTime < $1.extractionTime }
        let mostEfficient = results.min { $0.peakMemoryUsage < $1.peakMemoryUsage }
        
        if let fastest = fastest {
            print("⚡ Fastest method: \(fastest.strategyName) - \(String(format: "%.2f", fastest.extractionTime))s")
        }
        
        if let mostEfficient = mostEfficient {
            print("💾 Most memory efficient: \(mostEfficient.strategyName) - \(formatter.string(fromByteCount: Int64(mostEfficient.peakMemoryUsage)))")
        }
    }
    
    /// Print the document analysis results
    /// - Parameter analysis: The document analysis to print
    private func printDocumentAnalysis(_ analysis: DocumentAnalysis) {
        print("   - Pages: \(analysis.pageCount)")
        print("   - Contains scanned content: \(analysis.containsScannedContent ? "Yes" : "No")")
        print("   - Has complex layout: \(analysis.hasComplexLayout ? "Yes" : "No")")
        print("   - Text density: \(String(format: "%.2f", analysis.textDensity))")
        print("   - Is large document: \(analysis.isLargeDocument ? "Yes" : "No")")
        print("   - Contains tables: \(analysis.containsTables ? "Yes" : "No")")
        print("   - Recommended extraction strategies: \(analysis.recommendedExtractionStrategies.map { String(describing: $0) }.joined(separator: ", "))")
    }
    
    /// Print the profiler result in a readable format
    /// - Parameter result: The profiler result to print
    private func printProfilerResult(_ result: ProfilerResult) {
        print("   - Extraction time: \(String(format: "%.2f", result.extractionTime))s")
        print("   - Characters extracted: \(result.characterCount)")
        print("   - Speed: \(String(format: "%.2f", result.charactersPerSecond)) chars/s, \(String(format: "%.2f", result.pagesPerSecond)) pages/s")
        print("   - Peak memory usage: \(formatter.string(fromByteCount: Int64(result.peakMemoryUsage)))")
        
        if let metrics = result.detailedMetrics {
            print("   - Detailed metrics:")
            for (key, value) in metrics {
                if let timeValue = value as? TimeInterval {
                    print("     • \(key): \(String(format: "%.4f", timeValue))s")
                } else {
                    print("     • \(key): \(value)")
                }
            }
        }
    }
}

// Main entry point
struct ExtractorProfilerApp {
    static func main() async {
        let runner = ExtractorProfilerRunner()
        
        // Default sample path - modify this to test with different documents
        let samplePath = "/Users/sunil/Desktop/PayslipMax-iOS/PayslipMax/Resources/SamplePayslip.pdf"
        
        // Get command line argument if provided
        let arguments = CommandLine.arguments
        let pdfPath = arguments.count > 1 ? arguments[1] : samplePath
        
        await runner.runProfiler(on: pdfPath)
    }
} 