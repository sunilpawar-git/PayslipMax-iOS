import Foundation
import PDFKit

/// Async-first coordinator for PDF processing operations.
/// This replaces the DispatchSemaphore usage in ModularPDFExtractor.swift and related services.
/// 
/// Follows the coordinator pattern established in Phase 2B refactoring.
@MainActor
class AsyncPDFProcessingCoordinator: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var isProcessing = false
    @Published private(set) var processingProgress: Double = 0.0
    @Published private(set) var lastError: Error?
    
    private let textExtractor: AsyncTextExtractor
    private let streamingExtractor: AsyncStreamingExtractor
    
    // MARK: - Initialization
    
    init(
        textExtractor: AsyncTextExtractor = AsyncTextExtractor(),
        streamingExtractor: AsyncStreamingExtractor = AsyncStreamingExtractor()
    ) {
        self.textExtractor = textExtractor
        self.streamingExtractor = streamingExtractor
    }
    
    // MARK: - Public Methods
    
    /// Processes a PDF document asynchronously using structured concurrency.
    /// This replaces the DispatchSemaphore-based processing in ModularPDFExtractor.
    func processPDF(data: Data) async throws -> PDFProcessingResult {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            lastError = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
                processingProgress = 1.0
            }
        }
        
        do {
            // ✅ CLEAN: Use structured concurrency for parallel processing
            async let extractedText = textExtractor.extractText(from: data) { progress in
                Task { @MainActor in
                    self.processingProgress = progress * 0.5
                }
            }
            
            async let streamingResult = streamingExtractor.streamText(from: data) { progress in
                Task { @MainActor in
                    self.processingProgress = 0.5 + (progress * 0.5)
                }
            }
            
            let text = try await extractedText
            let streamingData = try await streamingResult
            
            return PDFProcessingResult(
                extractedText: text,
                streamingData: streamingData,
                metadata: createMetadata(from: data)
            )
            
        } catch {
            await MainActor.run {
                lastError = error
            }
            throw error
        }
    }
    
    /// Processes multiple PDFs concurrently with controlled concurrency.
    func processPDFs(_ dataArray: [Data], maxConcurrency: Int = 3) async throws -> [PDFProcessingResult] {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
                processingProgress = 1.0
            }
        }
        
        // ✅ CLEAN: Structured concurrency with controlled parallelism
        return try await withThrowingTaskGroup(of: (Int, PDFProcessingResult).self) { group in
            var results: [PDFProcessingResult?] = Array(repeating: nil, count: dataArray.count)
            let semaphore = AsyncSemaphore(value: maxConcurrency)
            
            for (index, data) in dataArray.enumerated() {
                group.addTask {
                    await semaphore.wait()
                    
                    do {
                        let result = try await self.processPDF(data: data)
                        
                        Task { @MainActor in
                            self.processingProgress = Double(index + 1) / Double(dataArray.count)
                        }
                        
                        await semaphore.signal()
                        return (index, result)
                    } catch {
                        await semaphore.signal()
                        throw error
                    }
                }
            }
            
            for try await (index, result) in group {
                results[index] = result
            }
            
            return results.compactMap { $0 }
        }
    }
    
    // MARK: - Private Methods
    
    private func createMetadata(from data: Data) -> PDFMetadata {
        return PDFMetadata(
            size: data.count,
            processedAt: Date(),
            version: "async-1.0"
        )
    }
}

// MARK: - Supporting Types

/// Result of PDF processing operations
struct PDFProcessingResult {
    let extractedText: String
    let streamingData: StreamingTextData
    let metadata: PDFMetadata
}

/// Metadata about processed PDF
struct PDFMetadata {
    let size: Int
    let processedAt: Date
    let version: String
}

/// Async-first text extractor that replaces DispatchSemaphore usage
class AsyncTextExtractor {
    
    /// Extracts text from PDF data asynchronously with progress reporting
    func extractText(
        from data: Data, 
        progressCallback: @Sendable @escaping (Double) -> Void = { _ in }
    ) async throws -> String {
        
        guard let document = PDFDocument(data: data) else {
            throw AsyncPDFError.invalidPDFData
        }
        
        let pageCount = document.pageCount
        var extractedText = ""
        
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // ✅ CLEAN: Use Task.yield() instead of blocking operations
            await Task.yield()
            
            if let pageText = page.string {
                extractedText += pageText + "\n"
            }
            
            // Report progress
            let progress = Double(pageIndex + 1) / Double(pageCount)
            progressCallback(progress)
        }
        
        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Async-first streaming extractor
class AsyncStreamingExtractor {
    
    /// Streams text data asynchronously
    func streamText(
        from data: Data,
        progressCallback: @Sendable @escaping (Double) -> Void = { _ in }
    ) async throws -> StreamingTextData {
        
        // Simulate streaming processing with async operations
        let chunks = stride(from: 0, to: data.count, by: 1024).map { startIndex in
            let endIndex = min(startIndex + 1024, data.count)
            return data.subdata(in: startIndex..<endIndex)
        }
        
        var processedChunks: [String] = []
        
        for (index, chunk) in chunks.enumerated() {
            // ✅ CLEAN: Non-blocking async processing
            await Task.yield()
            
            // Process chunk (simplified for example)
            let chunkString = String(data: chunk, encoding: .utf8) ?? ""
            processedChunks.append(chunkString)
            
            let progress = Double(index + 1) / Double(chunks.count)
            progressCallback(progress)
        }
        
        return StreamingTextData(chunks: processedChunks)
    }
}

/// Streaming text data structure
struct StreamingTextData {
    let chunks: [String]
    
    var combinedText: String {
        chunks.joined()
    }
}

/// Custom async semaphore for controlled concurrency
actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            value += 1
        }
    }
}

/// Errors for async PDF processing
enum AsyncPDFError: Error, LocalizedError {
    case invalidPDFData
    case processingFailed(underlying: Error)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidPDFData:
            return "Invalid PDF data provided"
        case .processingFailed(let error):
            return "PDF processing failed: \(error.localizedDescription)"
        case .cancelled:
            return "PDF processing was cancelled"
        }
    }
} 