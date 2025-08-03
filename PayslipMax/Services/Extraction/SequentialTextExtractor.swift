import Foundation
import PDFKit
import Combine

// Import data models from Phase 1
// Note: TextExtractionModels provides ExtractionOptions and ExtractionMetrics

/// Specialized text extractor for sequential processing of PDF documents
///
/// This extractor handles sequential text extraction processing pages one by one,
/// providing memory-efficient processing ideal for large documents or memory-constrained devices.
/// It follows the single responsibility principle by focusing solely on sequential extraction logic.
///
/// ## Key Features:
/// - Memory-efficient page-by-page processing
/// - Detailed per-page metrics collection
/// - Autoreleasepool memory management
/// - Progress tracking integration
/// - Text preprocessing support
class SequentialTextExtractor {
    
    // MARK: - Dependencies
    
    /// Text preprocessing service
    private let textPreprocessor: TextPreprocessor
    
    /// Progress reporting subject
    private let progressSubject: PassthroughSubject<(pageIndex: Int, progress: Double), Never>
    
    /// Memory manager for tracking usage
    private let memoryManager: ExtractionMemoryManager
    
    // MARK: - Initialization
    
    /// Initialize the sequential extractor with dependencies
    /// - Parameters:
    ///   - textPreprocessor: Text preprocessing service
    ///   - progressSubject: Progress reporting subject
    ///   - memoryManager: Memory management service
    init(
        textPreprocessor: TextPreprocessor,
        progressSubject: PassthroughSubject<(pageIndex: Int, progress: Double), Never>,
        memoryManager: ExtractionMemoryManager
    ) {
        self.textPreprocessor = textPreprocessor
        self.progressSubject = progressSubject
        self.memoryManager = memoryManager
    }
    
    // MARK: - Sequential Extraction
    
    /// Extracts text from all pages of a document sequentially.
    ///
    /// This method processes pages one by one in their original order. It's suitable for scenarios
    /// where parallel processing might consume too much memory or where sequential processing is required.
    /// Text preprocessing is applied if specified in the options.
    /// Detailed performance metrics (time and memory per page) are collected and updated in the `metrics` parameter.
    /// Progress is reported via the `progressSubject`.
    /// Uses an `autoreleasepool` for each page to help manage memory during sequential processing.
    ///
    /// **Performance Characteristics:**
    /// - **Speed**: Slower than parallel processing, especially for multi-page documents
    /// - **Memory Usage**: Much lower memory usage as only one page is processed at a time
    /// - **CPU Usage**: Lower, typically uses a single core effectively
    /// - **Ideal For**: Memory-constrained devices or very large documents
    ///
    /// **Implementation Details:**
    /// The sequential approach processes each page in order, using an autoreleasepool to
    /// help manage memory by releasing resources after each page is processed. This method
    /// collects detailed metrics about processing time and memory usage per page.
    ///
    /// - Parameters:
    ///   - document: The `PDFDocument` to process.
    ///   - options: `ExtractionOptions` configuring the process (e.g., `preprocessText`).
    ///   - metrics: An `inout ExtractionMetrics` instance to be updated with per-page and overall metrics.
    /// - Returns: A single string containing the text from all pages, concatenated in order, separated by double newlines.
    func extractTextSequential(from document: PDFDocument, options: ExtractionOptions, metrics: inout ExtractionMetrics) async -> String {
        print("[SequentialTextExtractor] Using sequential processing")
        
        var combinedText = ""
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            let startTime = Date()
            let startMemory = memoryManager.getCurrentMemoryUsage()
            
            // Use autorelease pool to manage memory
            autoreleasepool {
                // Extract text from page
                let page = document.page(at: pageIndex)!
                let pageText = page.string ?? ""
                
                // Apply preprocessing if enabled
                let finalText = options.preprocessText ? textPreprocessor.preprocessText(pageText) : pageText
                
                // Add to combined text
                combinedText += finalText
                if pageIndex < pageCount - 1 {
                    combinedText += "\n\n"
                }
                
                // Calculate metrics
                let endTime = Date()
                let endMemory = memoryManager.getCurrentMemoryUsage()
                let processingTime = endTime.timeIntervalSince(startTime)
                let memoryUsage = endMemory > startMemory ? endMemory - startMemory : 0
                
                metrics.processingTimePerPage[pageIndex] = processingTime
                metrics.memoryUsagePerPage[pageIndex] = memoryUsage
                
                // Report progress
                let progress = Double(pageIndex + 1) / Double(pageCount)
                progressSubject.send((pageIndex: pageIndex, progress: progress))
            }
        }
        
        return combinedText
    }
}

/// Comprehensive memory manager for extraction operations
///
/// This service handles all memory-related operations for text extraction, including:
/// - Memory usage tracking and monitoring
/// - Memory requirement estimation
/// - Memory optimization decisions
/// - Human-readable memory formatting
/// 
/// Extracted from EnhancedTextExtractionService as part of Phase 3 refactoring.
class ExtractionMemoryManager {
    
    // MARK: - Memory Tracking
    
    /// Retrieves the current resident memory usage of the application task using Mach task info.
    ///
    /// This provides a snapshot of the physical memory currently occupied by the app.
    /// It's used for monitoring memory usage during extraction, especially in the sequential processing path.
    /// The implementation uses the Mach task_info API to obtain accurate memory information directly
    /// from the operating system, providing a reliable way to track memory consumption.
    ///
    /// **Implementation Details:**
    /// This method calls the low-level Mach kernel API to get the `resident_size` from `mach_task_basic_info`,
    /// which represents the actual physical RAM the process is currently using (not including compressed or
    /// swapped memory).
    ///
    /// - Returns: The resident memory size in bytes, or 0 if the information cannot be retrieved.
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            withUnsafeMutablePointer(to: &count) { countPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    task_info_t(OpaquePointer(infoPtr)),
                    countPtr
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    // MARK: - Memory Estimation
    
    /// Estimates the potential memory requirement for processing a given PDF document.
    ///
    /// This method uses a heuristic approach to predict the memory needed for processing a document.
    /// It samples the first few pages to estimate the average memory requirement per page, then
    /// extrapolates for the entire document. This prediction helps determine if memory optimization
    /// techniques should be activated.
    ///
    /// **Estimation Approach:**
    /// 1. Samples text content from the first few pages (up to 5)
    /// 2. Calculates average memory needed per page based on text content size
    /// 3. Extrapolates to the full document based on page count
    /// 4. Adds a fixed overhead for processing structures and temporary objects
    ///
    /// **Memory Characteristics:**
    /// - Text-heavy pages typically require more memory than image-heavy pages
    /// - Unicode characters take 2 bytes each in memory
    /// - Additional overhead is needed for processing structures and temporary objects
    /// - A fixed 50MB overhead is added to account for processing infrastructure
    ///
    /// This estimate is conservative and generally overestimates rather than underestimates
    /// memory requirements to avoid memory-related crashes.
    ///
    /// - Parameter document: The `PDFDocument` to estimate memory requirements for.
    /// - Returns: An estimated memory requirement in bytes.
    func estimateMemoryRequirement(for document: PDFDocument) -> UInt64 {
        // Basic heuristic: estimate based on page count and size
        let pageCount = document.pageCount
        let averagePageSize: UInt64 = 1_000_000 // 1MB per page as base estimate
        
        // Sample a few pages to refine the estimate
        var totalSize: UInt64 = 0
        let sampleSize = min(pageCount, 5)
        
        for i in 0..<sampleSize {
            if let page = document.page(at: i), let pageText = page.string {
                totalSize += UInt64(pageText.count * 2) // Unicode chars are 2 bytes
            } else {
                totalSize += averagePageSize
            }
        }
        
        let avgSampleSize = sampleSize > 0 ? totalSize / UInt64(sampleSize) : averagePageSize
        let estimatedSize = avgSampleSize * UInt64(pageCount)
        
        // Add overhead for processing
        let overhead: UInt64 = 50_000_000 // 50MB overhead
        return estimatedSize + overhead
    }
    
    // MARK: - Memory Optimization
    
    /// Determines if memory optimization should be used based on estimated requirements and threshold.
    ///
    /// - Parameters:
    ///   - document: The PDF document to analyze
    ///   - thresholdMB: Memory threshold in megabytes
    /// - Returns: True if memory optimization should be enabled
    func shouldUseMemoryOptimization(for document: PDFDocument, thresholdMB: Int) -> Bool {
        let estimatedMemoryRequirement = estimateMemoryRequirement(for: document)
        return estimatedMemoryRequirement > UInt64(thresholdMB * 1024 * 1024)
    }
    
    // MARK: - Memory Formatting
    
    /// Formats a memory size (given in bytes) into a human-readable string (KB or MB).
    ///
    /// Uses KB for sizes less than 1024 KB, otherwise uses MB. Formats to two decimal places.
    /// This helper method improves logging readability by converting raw byte counts into 
    /// more human-friendly units.
    ///
    /// - Parameter bytes: The memory size in bytes.
    /// - Returns: A formatted string representation (e.g., "123.45 KB", "1.23 MB").
    func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.2f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
} 