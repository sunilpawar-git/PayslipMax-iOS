import Foundation
import PDFKit
import Combine

/// Protocol for PDF streaming processor service
protocol StreamingPDFProcessorProtocol {
    /// Process a PDF document with streaming page-by-page processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - callback: Optional callback to receive progress updates during processing
    /// - Returns: The processed text from the entire document
    func processDocumentStreaming(_ document: PDFDocument, callback: ((Double, String) -> Void)?) async -> String
    
    /// Process a PDF document page range with streaming page-by-page processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - range: The range of pages to process
    ///   - callback: Optional callback to receive progress updates during processing
    /// - Returns: The processed text from the specified pages
    func processDocumentRangeStreaming(_ document: PDFDocument, range: Range<Int>, callback: ((Double, String) -> Void)?) async -> String
    
    /// Get memory usage metrics for the processor
    /// - Returns: Dictionary containing memory usage statistics
    func getMemoryMetrics() -> [String: UInt64]
}

/// Protocol for receiving memory usage updates
protocol StreamingPDFProcessorDelegate: AnyObject {
    /// Called when memory usage is updated during processing
    /// - Parameters:
    ///   - memoryUsage: Current memory usage in bytes
    ///   - delta: Change in memory usage since the last update
    ///   - pageIndex: Current page being processed
    ///   - totalPages: Total number of pages in the document
    func streamingProcessor(didUpdateMemoryUsage memoryUsage: UInt64, delta: UInt64, pageIndex: Int, totalPages: Int)
    
    /// Called when a page has completed processing
    /// - Parameters:
    ///   - pageIndex: Index of the page that was processed
    ///   - pageText: Extracted text from the page
    ///   - totalPages: Total number of pages in the document
    func streamingProcessor(didProcessPage pageIndex: Int, pageText: String, totalPages: Int)
}

/// Service for memory-efficient PDF processing using a streaming approach
class StreamingPDFProcessor: StreamingPDFProcessorProtocol {
    // MARK: - Properties
    
    /// Current memory usage in bytes
    private var currentMemoryUsage: UInt64 = 0
    
    /// Peak memory usage in bytes
    private var peakMemoryUsage: UInt64 = 0
    
    /// Change in memory usage from baseline
    private var memoryDelta: UInt64 = 0
    
    /// Baseline memory usage before processing
    private var baselineMemoryUsage: UInt64 = 0
    
    /// Memory usage history for analysis
    private var memoryHistory: [(pageIndex: Int, usage: UInt64)] = []
    
    /// Text extraction service for getting text from PDF pages
    private let textExtractionService: PDFTextExtractionServiceProtocol
    
    /// Delegate for receiving processing updates
    weak var delegate: StreamingPDFProcessorDelegate?
    
    /// Page processing batch size (number of pages to process in one batch)
    private let pageProcessingBatchSize: Int
    
    /// Threshold for triggering memory cleanup (in bytes)
    private let memoryCleanupThreshold: UInt64
    
    // MARK: - Initialization
    
    /// Initializes a streaming PDF processor with custom parameters
    /// - Parameters:
    ///   - textExtractionService: The service for extracting text from PDFs
    ///   - pageProcessingBatchSize: Number of pages to process in one batch
    ///   - memoryCleanupThreshold: Memory threshold in MB for triggering cleanup
    init(
        textExtractionService: PDFTextExtractionServiceProtocol? = nil,
        pageProcessingBatchSize: Int = 5,
        memoryCleanupThreshold: UInt64 = 50 * 1024 * 1024 // 50 MB
    ) {
        self.textExtractionService = textExtractionService ?? PDFTextExtractionService()
        self.pageProcessingBatchSize = pageProcessingBatchSize
        self.memoryCleanupThreshold = memoryCleanupThreshold
        self.baselineMemoryUsage = getCurrentMemoryUsage()
    }
    
    // MARK: - Public Methods
    
    /// Process a PDF document with streaming page-by-page processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - callback: Optional callback to receive progress updates during processing
    /// - Returns: The processed text from the entire document
    func processDocumentStreaming(_ document: PDFDocument, callback: ((Double, String) -> Void)?) async -> String {
        return await processDocumentRangeStreaming(document, range: 0..<document.pageCount, callback: callback)
    }
    
    /// Process a PDF document page range with streaming page-by-page processing
    /// - Parameters:
    ///   - document: The PDF document to process
    ///   - range: The range of pages to process
    ///   - callback: Optional callback to receive progress updates during processing
    /// - Returns: The processed text from the specified pages
    func processDocumentRangeStreaming(_ document: PDFDocument, range: Range<Int>, callback: ((Double, String) -> Void)?) async -> String {
        guard document.pageCount > 0, !range.isEmpty else {
            print("[StreamingPDFProcessor] Document has no pages or invalid range")
            return ""
        }
        
        // Validate range
        let validatedRange = validatePageRange(range, pageCount: document.pageCount)
        let totalPagesToProcess = validatedRange.count
        
        print("[StreamingPDFProcessor] Processing \(totalPagesToProcess) pages using streaming")
        
        // Reset memory metrics
        resetMemoryMetrics()
        
        var fullText = ""
        var batchResults: [String] = []
        var currentBatchSize = 0
        
        // Process pages in batches
        for pageIndex in validatedRange {
            autoreleasepool {
                // Process one page
                if let pageText = processPage(at: pageIndex, in: document) {
                    batchResults.append(pageText)
                    currentBatchSize += 1
                    
                    // Calculate progress
                    let progress = Double(pageIndex - validatedRange.lowerBound + 1) / Double(totalPagesToProcess)
                    
                    // Report progress through callback
                    callback?(progress, pageText)
                    
                    // Report to delegate
                    delegate?.streamingProcessor(didProcessPage: pageIndex, pageText: pageText, totalPages: document.pageCount)
                    
                    // Update memory metrics
                    updateMemoryMetrics(pageIndex: pageIndex, totalPages: document.pageCount)
                }
                
                // If we reached the batch size or this is the last page, process the batch
                if currentBatchSize >= pageProcessingBatchSize || pageIndex == validatedRange.upperBound - 1 {
                    // Add the batch results to full text
                    let batchText = batchResults.joined(separator: "\n\n")
                    fullText += batchText
                    
                    // Clear batch results to free memory
                    batchResults.removeAll()
                    currentBatchSize = 0
                    
                    // Force memory cleanup if needed
                    cleanupMemoryIfNeeded()
                }
            }
        }
        
        print("[StreamingPDFProcessor] Processing complete. Peak memory: \(formatMemory(peakMemoryUsage))")
        return fullText
    }
    
    /// Get memory usage metrics for the processor
    /// - Returns: Dictionary containing memory usage statistics
    func getMemoryMetrics() -> [String: UInt64] {
        return [
            "current": currentMemoryUsage,
            "peak": peakMemoryUsage,
            "baseline": baselineMemoryUsage,
            "delta": memoryDelta
        ]
    }
    
    // MARK: - Private Methods
    
    /// Process a single page from the document
    /// - Parameters:
    ///   - pageIndex: Index of the page to process
    ///   - document: The PDF document containing the page
    /// - Returns: The extracted text from the page
    private func processPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount,
              let _ = document.page(at: pageIndex) else {
            print("[StreamingPDFProcessor] Invalid page index: \(pageIndex)")
            return nil
        }
        
        // Use the text extraction service to extract text from the page
        return textExtractionService.extractTextFromPage(at: pageIndex, in: document)
    }
    
    /// Validates the page range to ensure it's within the document bounds
    /// - Parameters:
    ///   - range: The requested page range
    ///   - pageCount: Total number of pages in the document
    /// - Returns: A valid page range within document bounds
    private func validatePageRange(_ range: Range<Int>, pageCount: Int) -> Range<Int> {
        let lowerBound = max(0, range.lowerBound)
        let upperBound = min(pageCount, range.upperBound)
        return lowerBound..<upperBound
    }
    
    /// Updates memory metrics after processing a page
    /// - Parameters:
    ///   - pageIndex: Index of the page that was processed
    ///   - totalPages: Total number of pages in the document
    private func updateMemoryMetrics(pageIndex: Int, totalPages: Int) {
        // Get current memory usage
        let previousMemoryUsage = currentMemoryUsage
        currentMemoryUsage = getCurrentMemoryUsage()
        
        // Update peak memory usage
        if currentMemoryUsage > peakMemoryUsage {
            peakMemoryUsage = currentMemoryUsage
        }
        
        // Calculate memory delta from previous reading
        let delta = currentMemoryUsage > previousMemoryUsage ? 
                    currentMemoryUsage - previousMemoryUsage : 
                    previousMemoryUsage - currentMemoryUsage
        
        memoryDelta = currentMemoryUsage > baselineMemoryUsage ? 
                       currentMemoryUsage - baselineMemoryUsage : 0
        
        // Record memory history
        memoryHistory.append((pageIndex: pageIndex, usage: currentMemoryUsage))
        
        // Report memory usage through delegate
        delegate?.streamingProcessor(
            didUpdateMemoryUsage: currentMemoryUsage,
            delta: delta,
            pageIndex: pageIndex,
            totalPages: totalPages
        )
        
        // Print memory usage
        print("[StreamingPDFProcessor] Memory after page \(pageIndex + 1)/\(totalPages): \(formatMemory(currentMemoryUsage)) (Δ\(formatMemory(delta)))")
    }
    
    /// Resets memory metrics before processing a document
    private func resetMemoryMetrics() {
        baselineMemoryUsage = getCurrentMemoryUsage()
        currentMemoryUsage = baselineMemoryUsage
        peakMemoryUsage = baselineMemoryUsage
        memoryDelta = 0
        memoryHistory.removeAll()
        
        print("[StreamingPDFProcessor] Baseline memory: \(formatMemory(baselineMemoryUsage))")
    }
    
    /// Cleans up memory if it exceeds the threshold
    private func cleanupMemoryIfNeeded() {
        if memoryDelta > memoryCleanupThreshold {
            print("[StreamingPDFProcessor] Memory usage exceeded threshold, performing cleanup")
            
            // Suggest garbage collection by creating and releasing a large object
            autoreleasepool {
                _ = [UInt8](repeating: 0, count: 1)
            }
            
            // Update memory metrics after cleanup
            let previousUsage = currentMemoryUsage
            currentMemoryUsage = getCurrentMemoryUsage()
            
            print("[StreamingPDFProcessor] Memory after cleanup: \(formatMemory(currentMemoryUsage)) (saved: \(formatMemory(previousUsage - currentMemoryUsage)))")
        }
    }
    
    /// Gets the current memory usage of the app
    /// - Returns: Current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        // Simplified memory usage reporting that works on iOS
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
            print("[StreamingPDFProcessor] Error getting memory usage: \(result)")
            return 0
        }
    }
    
    /// Formats memory size in human-readable format
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted memory size string
    private func formatMemory(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.2f KB", kb)
        }
    }
}

// MARK: - Extensions

/// Extension for adding streaming processing capability to PDFDocument
extension PDFDocument {
    /// Processes the document using a streaming processor
    /// - Parameters:
    ///   - processor: The streaming processor to use
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: The processed text
    func processWithStreaming(
        using processor: StreamingPDFProcessor = StreamingPDFProcessor(),
        progressCallback: ((Double, String) -> Void)? = nil
    ) async -> String {
        return await processor.processDocumentStreaming(self, callback: progressCallback)
    }
} 