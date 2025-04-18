import Foundation
import PDFKit

/// A utility for benchmarking PDF processing pipelines
class PipelineBenchmark {
    // MARK: - Benchmark Results
    
    /// Stores the results of a processing pipeline benchmark
    struct BenchmarkResult: Equatable, Identifiable {
        /// Unique identifier for the benchmark result
        let id = UUID()
        
        /// Name of the benchmark test
        let testName: String
        
        /// Total execution time in seconds
        let executionTime: TimeInterval
        
        /// Memory usage peak during execution (in bytes)
        let peakMemoryUsage: UInt64
        
        /// Pages processed per second
        let pagesPerSecond: Double
        
        /// Bytes processed per second
        let bytesPerSecond: Double
        
        /// PDF document attributes
        let documentInfo: PDFDocumentInfo
        
        /// Additional metrics reported
        var additionalMetrics: [String: String] = [:]
        
        /// Timestamp when the benchmark was performed
        let timestamp = Date()
    }
    
    /// Stores information about a PDF document
    struct PDFDocumentInfo: Equatable {
        /// The file size in bytes
        let fileSize: UInt64
        
        /// Number of pages in the document
        let pageCount: Int
        
        /// Document title if available
        let title: String?
        
        /// Whether the document contains scanned content
        let hasScannedContent: Bool
        
        /// Whether the document has complex layout
        let hasComplexLayout: Bool
        
        /// Text density level
        let textDensity: Double
    }
    
    // MARK: - Benchmark Storage
    
    /// Singleton instance
    static let shared = PipelineBenchmark()
    
    /// Storage for benchmark results
    private(set) var benchmarkHistory: [BenchmarkResult] = []
    
    /// Maximum number of benchmark results to keep in history
    private let maxHistorySize = 100
    
    // MARK: - Public API
    
    /// Runs a benchmark on the provided PDF document using the specified processing task
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - testName: Name of the benchmark test
    ///   - task: The processing task to execute and benchmark
    /// - Returns: Benchmark result
    func runBenchmark(
        on document: PDFDocument,
        testName: String,
        task: @escaping (PDFDocument) async throws -> Any
    ) async -> BenchmarkResult {
        // Collect document info
        let documentInfo = collectDocumentInfo(from: document)
        
        // Initialize metrics
        let startMemory = PerformanceMetrics.shared.memoryUsage
        var peakMemory = startMemory
        
        // Start monitoring
        let monitorTask = Task {
            while !Task.isCancelled {
                let currentMemory = PerformanceMetrics.shared.memoryUsage
                peakMemory = max(peakMemory, currentMemory)
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
        
        // Measure execution time
        let startTime = CACurrentMediaTime()
        
        do {
            _ = try await task(document)
        } catch {
            print("Benchmark failed with error: \(error.localizedDescription)")
        }
        
        let endTime = CACurrentMediaTime()
        let executionTime = endTime - startTime
        
        // Cancel the monitor task
        monitorTask.cancel()
        
        // Calculate metrics
        let pagesPerSecond = documentInfo.pageCount > 0 && executionTime > 0 ? 
            Double(documentInfo.pageCount) / executionTime : 0
        
        let bytesPerSecond = documentInfo.fileSize > 0 && executionTime > 0 ? 
            Double(documentInfo.fileSize) / executionTime : 0
        
        // Create and store result
        let result = BenchmarkResult(
            testName: testName,
            executionTime: executionTime,
            peakMemoryUsage: peakMemory,
            pagesPerSecond: pagesPerSecond,
            bytesPerSecond: bytesPerSecond,
            documentInfo: documentInfo
        )
        
        storeBenchmarkResult(result)
        
        return result
    }
    
    /// Gets results for a specific test name
    /// - Parameter testName: The name of the test to filter by
    /// - Returns: Array of matching benchmark results
    func results(for testName: String) -> [BenchmarkResult] {
        return benchmarkHistory.filter { $0.testName == testName }
    }
    
    /// Generates a performance report comparing before and after results
    /// - Parameters:
    ///   - before: The baseline benchmark results
    ///   - after: The optimized benchmark results
    /// - Returns: A formatted report string
    func generateComparisonReport(before: BenchmarkResult, after: BenchmarkResult) -> String {
        let executionImprovement = calculateImprovement(
            before: before.executionTime,
            after: after.executionTime,
            lowerIsBetter: true
        )
        
        let memoryImprovement = calculateImprovement(
            before: Double(before.peakMemoryUsage),
            after: Double(after.peakMemoryUsage),
            lowerIsBetter: true
        )
        
        let pagesPerSecImprovement = calculateImprovement(
            before: before.pagesPerSecond,
            after: after.pagesPerSecond,
            lowerIsBetter: false
        )
        
        let bytesPerSecImprovement = calculateImprovement(
            before: before.bytesPerSecond,
            after: after.bytesPerSecond,
            lowerIsBetter: false
        )
        
        var report = "Performance Optimization Report\n"
        report += "==============================\n\n"
        report += "Test: \(before.testName) → \(after.testName)\n"
        report += "Document: \(formatFileSize(before.documentInfo.fileSize)), \(before.documentInfo.pageCount) pages\n\n"
        
        report += "Execution Time: \(String(format: "%.2f", before.executionTime))s → \(String(format: "%.2f", after.executionTime))s \(formatChange(executionImprovement))\n"
        report += "Peak Memory: \(formatFileSize(before.peakMemoryUsage)) → \(formatFileSize(after.peakMemoryUsage)) \(formatChange(memoryImprovement))\n"
        report += "Pages/Second: \(String(format: "%.2f", before.pagesPerSecond)) → \(String(format: "%.2f", after.pagesPerSecond)) \(formatChange(pagesPerSecImprovement))\n"
        report += "MB/Second: \(String(format: "%.2f", before.bytesPerSecond / (1024 * 1024))) → \(String(format: "%.2f", after.bytesPerSecond / (1024 * 1024))) \(formatChange(bytesPerSecImprovement))\n\n"
        
        report += "Overall Improvement: \(String(format: "%.1f", (executionImprovement + memoryImprovement + pagesPerSecImprovement) / 3))%\n"
        
        return report
    }
    
    /// Clears all benchmark history
    func clearHistory() {
        benchmarkHistory.removeAll()
    }
    
    // MARK: - Private Helpers
    
    /// Collects information about the PDF document
    private func collectDocumentInfo(from document: PDFDocument) -> PDFDocumentInfo {
        let fileSize = getDocumentFileSize(document)
        let pageCount = document.pageCount
        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        
        // These would ideally come from DocumentAnalysisService but simplified for this example
        let hasScannedContent = estimateHasScannedContent(document)
        let hasComplexLayout = estimateHasComplexLayout(document)
        let textDensity = estimateTextDensity(document)
        
        return PDFDocumentInfo(
            fileSize: fileSize,
            pageCount: pageCount,
            title: title,
            hasScannedContent: hasScannedContent,
            hasComplexLayout: hasComplexLayout,
            textDensity: textDensity
        )
    }
    
    /// Estimates if a document has scanned content based on a simple heuristic
    private func estimateHasScannedContent(_ document: PDFDocument) -> Bool {
        // Simplified check - in reality would use DocumentAnalysisService
        guard let page = document.page(at: 0),
              let text = page.string else {
            return true // If we can't extract text, likely scanned
        }
        
        // If text is very short compared to page size, likely scanned
        let pageRect = page.bounds(for: .mediaBox)
        let pageArea = pageRect.width * pageRect.height
        return Double(text.count) / pageArea < 0.01
    }
    
    /// Estimates if a document has complex layout
    private func estimateHasComplexLayout(_ document: PDFDocument) -> Bool {
        // Simplified check - would use DocumentAnalysisService in production
        guard let page = document.page(at: 0) else { return false }
        
        // Check if document has annotations, which might indicate forms
        let annotations = page.annotations
        if !annotations.isEmpty {
            return true
        }
        
        return false
    }
    
    /// Estimates text density in the document
    private func estimateTextDensity(_ document: PDFDocument) -> Double {
        var totalChars = 0
        var totalArea: CGFloat = 0
        
        for i in 0..<min(document.pageCount, 3) {
            guard let page = document.page(at: i) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            totalArea += pageRect.width * pageRect.height
            
            if let text = page.string {
                totalChars += text.count
            }
        }
        
        return totalArea > 0 ? Double(totalChars) / Double(totalArea) : 0
    }
    
    /// Gets the file size of a PDF document
    private func getDocumentFileSize(_ document: PDFDocument) -> UInt64 {
        guard let documentURL = document.documentURL else { return 0 }
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: documentURL.path)
            if let fileSize = fileAttributes[.size] as? UInt64 {
                return fileSize
            }
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    /// Calculates the percentage improvement between two values
    private func calculateImprovement(before: Double, after: Double, lowerIsBetter: Bool) -> Double {
        guard before > 0 else { return 0 }
        
        let rawImprovement = (after - before) / before * 100
        
        // Invert the sign if lower values are better
        return lowerIsBetter ? -rawImprovement : rawImprovement
    }
    
    /// Formats a percentage change as a string
    private func formatChange(_ percentChange: Double) -> String {
        let prefix = percentChange >= 0 ? "+" : ""
        return "(\(prefix)\(String(format: "%.1f", percentChange))%)"
    }
    
    /// Formats a file size in bytes to a human-readable string
    private func formatFileSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Stores a benchmark result in history, maintaining size limits
    private func storeBenchmarkResult(_ result: BenchmarkResult) {
        benchmarkHistory.append(result)
        
        // Maintain history size limit
        if benchmarkHistory.count > maxHistorySize {
            benchmarkHistory.removeFirst(benchmarkHistory.count - maxHistorySize)
        }
    }
} 