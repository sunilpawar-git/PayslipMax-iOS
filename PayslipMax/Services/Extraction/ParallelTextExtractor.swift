import Foundation
import PDFKit
import Combine

// Import data models from Phase 1
// Note: TextExtractionModels provides ExtractionOptions and ExtractionMetrics

/// Specialized text extractor for parallel processing of PDF documents
///
/// This extractor handles parallel text extraction from multiple pages simultaneously,
/// providing optimal performance on multi-core devices. It follows the single responsibility
/// principle by focusing solely on parallel extraction logic.
///
/// ## Key Features:
/// - Concurrent page processing using TaskGroup
/// - Configurable concurrency levels
/// - Progress tracking integration
/// - Text preprocessing support
/// - Memory-efficient result collection
class ParallelTextExtractor {
    
    // MARK: - Dependencies
    
    /// Operation queue for parallel processing
    private let extractionQueue: OperationQueue
    
    /// Text preprocessing service
    private let textPreprocessor: TextPreprocessor
    
    /// Progress reporting subject
    private let progressSubject: PassthroughSubject<(pageIndex: Int, progress: Double), Never>
    
    // MARK: - Initialization
    
    /// Initialize the parallel extractor with dependencies
    /// - Parameters:
    ///   - extractionQueue: Operation queue for parallel processing
    ///   - textPreprocessor: Text preprocessing service
    ///   - progressSubject: Progress reporting subject
    init(
        extractionQueue: OperationQueue,
        textPreprocessor: TextPreprocessor,
        progressSubject: PassthroughSubject<(pageIndex: Int, progress: Double), Never>
    ) {
        self.extractionQueue = extractionQueue
        self.textPreprocessor = textPreprocessor
        self.progressSubject = progressSubject
    }
    
    // MARK: - Parallel Extraction
    
    /// Extracts text from all pages of a document in parallel using TaskGroup.
    ///
    /// This method is suitable for documents where page processing order doesn't matter and
    /// parallel execution can provide speed benefits. It divides the work by assigning each page
    /// to a separate task within a `TaskGroup`.
    /// Text preprocessing is applied if specified in the options.
    /// Progress is reported via the `progressSubject`.
    ///
    /// **Performance Characteristics:**
    /// - **Speed**: Fastest method, particularly on multi-core systems
    /// - **Memory Usage**: Highest memory usage as multiple pages are processed simultaneously
    /// - **CPU Usage**: High, utilizes multiple cores effectively
    /// - **Ideal For**: Modern devices with ample resources processing standard business documents
    ///
    /// **Implementation Details:**
    /// The parallel approach creates a task for each page and collects results in a dictionary
    /// keyed by page index. After all tasks complete, results are combined in the correct order.
    /// This approach maximizes throughput at the cost of higher resource usage.
    ///
    /// - Parameters:
    ///   - document: The `PDFDocument` to process.
    ///   - options: `ExtractionOptions` configuring the process (e.g., `maxConcurrentOperations`, `preprocessText`).
    ///   - metrics: An `inout ExtractionMetrics` instance to be updated (although direct updates are minimal here, focus is on return).
    /// - Returns: A single string containing the text from all pages, concatenated in order, separated by double newlines.
    func extractTextParallel(from document: PDFDocument, options: ExtractionOptions, metrics: inout ExtractionMetrics) async -> String {
        print("[ParallelTextExtractor] Using parallel processing with \(options.maxConcurrentOperations) concurrent operations")
        
        // Configure extraction queue using adaptive cap
        let cap = DeviceClass.current.parallelismCap
        extractionQueue.maxConcurrentOperationCount = min(options.maxConcurrentOperations, cap)
        
        // Create a task group for parallel processing
        var pageTexts = [Int: String]()
        let pageCount = document.pageCount
        
        await withTaskGroup(of: (Int, String).self) { group in
            // Add a task for each page
            for pageIndex in 0..<pageCount {
                group.addTask {
                    // Extract text from page
                    let page = document.page(at: pageIndex)!
                    let pageText = page.string ?? ""
                    
                    // Apply preprocessing if enabled
                    let finalText = options.preprocessText ? self.textPreprocessor.preprocessText(pageText) : pageText
                    
                    // Report progress
                    let progress = Double(pageIndex + 1) / Double(pageCount)
                    self.progressSubject.send((pageIndex: pageIndex, progress: progress))
                    
                    return (pageIndex, finalText)
                }
            }
            
            // Collect results
            for await (pageIndex, pageText) in group {
                pageTexts[pageIndex] = pageText
            }
        }
        
        // Combine page texts in correct order
        var combinedText = ""
        for pageIndex in 0..<pageCount {
            if let pageText = pageTexts[pageIndex] {
                combinedText += pageText
                if pageIndex < pageCount - 1 {
                    combinedText += "\n\n"
                }
            }
        }
        
        return combinedText
    }
}

/// Text preprocessing service for extraction operations
class TextPreprocessor {
    
    /// Performs basic text cleaning and normalization on a string.
    ///
    /// Steps include:
    /// 1. Normalizing all newline characters to `\n`.
    /// 2. Removing consecutive duplicate newlines (e.g., `\n\n\n` becomes `\n\n`).
    /// 3. Trimming leading and trailing whitespace and newlines from the entire string.
    ///
    /// - Parameter text: The raw text string to preprocess.
    /// - Returns: The cleaned and normalized text string.
    func preprocessText(_ text: String) -> String {
        // Basic text cleanup
        var processedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // Remove duplicate line breaks
        while processedText.contains("\n\n\n") {
            processedText = processedText.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // Trim whitespace
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
} 