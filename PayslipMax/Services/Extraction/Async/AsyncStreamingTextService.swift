import Foundation
import PDFKit

/// Async-first protocol for streaming text extraction
protocol AsyncStreamingTextExtractionServiceProtocol {
    /// Extract text from a PDF document using streaming processing
    func extractText(from document: PDFDocument) async -> String

    /// Extract text from a PDF document with progress updates
    func extractText(from document: PDFDocument, progressHandler: @Sendable @escaping (Double, String) -> Void) async -> String
}

/// Async-first service that provides streaming-based text extraction from PDF documents.
/// This eliminates the DispatchSemaphore usage from StreamingTextExtractionService.
///
/// Follows the single responsibility principle established in Phase 2B refactoring.
class AsyncStreamingTextService: AsyncStreamingTextExtractionServiceProtocol {

    // MARK: - Properties

    private let processor: AsyncStreamingPDFProcessor
    private let options: StreamingProcessingOptions

    // MARK: - Initialization

    /// Initialize a new async streaming text extraction service
    init(
        processor: AsyncStreamingPDFProcessor? = nil,
        options: StreamingProcessingOptions? = nil
    ) {
        self.processor = processor ?? AsyncStreamingPDFProcessor()
        self.options = options ?? StreamingProcessingOptions()
    }

    // MARK: - Public Async API

    /// Extract text from a PDF document using streaming processing
    func extractText(from document: PDFDocument) async -> String {
        return await extractText(from: document) { _, _ in }
    }

    /// Extract text from a PDF document with progress updates
    func extractText(from document: PDFDocument, progressHandler: @Sendable @escaping (Double, String) -> Void) async -> String {
        // ✅ CLEAN: Direct async call - no semaphores!
        return await processor.processDocumentStreaming(document) { progress, page in
            progressHandler(progress, "Processing page \(page)")
        }
    }
}

/// Async-first streaming PDF processor that eliminates blocking operations
class AsyncStreamingPDFProcessor {

    // MARK: - Properties

    private let options: StreamingProcessingOptions

    // MARK: - Initialization

    init(options: StreamingProcessingOptions = StreamingProcessingOptions()) {
        self.options = options
    }

    // MARK: - Public Methods

    /// Process a document in a streaming manner with async operations
    func processDocumentStreaming(
        _ document: PDFDocument,
        progressHandler: @Sendable @escaping (Double, String) -> Void
    ) async -> String {

        var result = ""
        let pageCount = document.pageCount

        guard pageCount > 0 else { return result }

        // Process pages in batches for memory efficiency
        let batchSize = options.batchSize

        for batchStart in stride(from: 0, to: pageCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, pageCount)

            // Process batch of pages
            var batchText = ""

            for pageIndex in batchStart..<batchEnd {
                guard let page = document.page(at: pageIndex) else { continue }

                // ✅ CLEAN: Use Task.yield() for cooperative cancellation
                await Task.yield()

                if let pageText = page.string {
                    if options.preprocessText {
                        batchText += preprocessText(pageText) + "\n"
                    } else {
                        batchText += pageText + "\n"
                    }
                }

                // Report progress for each page
                let progress = Double(pageIndex + 1) / Double(pageCount)
                progressHandler(progress, "page \(pageIndex + 1)")

                // Check memory usage and yield if necessary
                if await shouldYieldForMemory() {
                    await Task.yield()
                }
            }

            result += batchText

            // Report batch completion
            let batchProgress = Double(batchEnd) / Double(pageCount)
            progressHandler(batchProgress, "Completed batch \(batchStart)-\(batchEnd)")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Process multiple documents concurrently with controlled memory usage
    func processDocumentsConcurrently(
        _ documents: [PDFDocument],
        maxConcurrency: Int = 2
    ) async -> [String] {

        // ✅ CLEAN: Use Swift's native concurrency limiting with TaskGroup
        return await withTaskGroup(of: (Int, String).self, returning: [String].self) { group in
            var results: [String?] = Array(repeating: nil, count: documents.count)
            var activeTaskCount = 0
            var documentIndex = 0

            // Process documents with controlled concurrency using native Swift patterns
            while documentIndex < documents.count || activeTaskCount > 0 {
                // Add new tasks up to concurrency limit
                while activeTaskCount < maxConcurrency && documentIndex < documents.count {
                    let currentIndex = documentIndex
                    let currentDocument = documents[documentIndex]

                    group.addTask {
                        let text = await self.processDocumentStreaming(currentDocument) { _, _ in }
                        return (currentIndex, text)
                    }

                    activeTaskCount += 1
                    documentIndex += 1
                }

                // Wait for at least one task to complete
                if let (index, text) = await group.next() {
                    results[index] = text
                    activeTaskCount -= 1
                }
            }

            return results.compactMap { $0 }
        }
    }

    // MARK: - Private Methods

    /// Preprocesses text to improve quality
    private func preprocessText(_ text: String) -> String {
        // Basic text preprocessing
        var processed = text

        // Remove excessive whitespace
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Normalize line breaks
        processed = processed.replacingOccurrences(of: "\\r\\n|\\r", with: "\n", options: .regularExpression)

        // Remove empty lines
        processed = processed.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")

        return processed
    }

    /// Checks if we should yield due to memory pressure
    private func shouldYieldForMemory() async -> Bool {
        let memoryUsage = await getCurrentMemoryUsage()
        return memoryUsage > options.memoryThreshold
    }

    /// Gets current memory usage
    private func getCurrentMemoryUsage() async -> Int64 {
        // Simplified memory check
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) { infoPtr in
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                task_info_t(OpaquePointer(infoPtr)),
                &count
            )
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// Note: StreamingProcessingOptions is defined in StreamingTextExtractionService.swift
// AsyncSemaphore has been replaced with Swift's native concurrency control patterns
