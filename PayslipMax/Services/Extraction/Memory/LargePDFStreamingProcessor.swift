import Foundation
@preconcurrency import PDFKit

/// Enhanced streaming processor for large PDF files (>10MB)
/// Implements memory-efficient processing with adaptive batch sizing and pressure monitoring
@MainActor
class LargePDFStreamingProcessor: ObservableObject {
    
    // MARK: - Configuration
    
    private struct ProcessingConfig {
        static let largeFileThreshold: Int = 10 * 1024 * 1024 // 10MB
        static let defaultBatchSize = 3 // Default pages per batch
        static let maxBatchSize = 8     // Maximum pages per batch
        static let minBatchSize = 1     // Minimum pages per batch for memory pressure
    }
    
    // MARK: - Dependencies
    
    private let memoryManager: EnhancedMemoryManager
    private let adaptiveCache: AdaptiveCacheManager
    
    // MARK: - Processing State
    
    @Published private(set) var isProcessing = false
    @Published private(set) var processingProgress: Double = 0.0
    @Published private(set) var currentBatchSize = ProcessingConfig.defaultBatchSize
    
    // MARK: - Initialization
    
    init(memoryManager: EnhancedMemoryManager = EnhancedMemoryManager(),
         adaptiveCache: AdaptiveCacheManager = AdaptiveCacheManager()) {
        self.memoryManager = memoryManager
        self.adaptiveCache = adaptiveCache
        setupMemoryPressureHandling()
    }
    
    // MARK: - Public Interface
    
    /// Process large PDF with memory-efficient streaming
    func processLargePDF(data: Data, progressCallback: @escaping (Double) -> Void) async throws -> String {
        guard data.count >= ProcessingConfig.largeFileThreshold else {
            // Use regular processing for smaller files
            return try await processRegularPDF(data: data)
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        guard let document = PDFDocument(data: data) else {
            throw LargePDFProcessingError.invalidDocument
        }
        
        let pageCount = document.pageCount
        let batches = createAdaptiveBatches(pageCount: pageCount)
        var extractedText = ""
        
        for (batchIndex, batch) in batches.enumerated() {
            // Check memory pressure before each batch
            if memoryManager.shouldThrottleOperations() {
                // Wait for memory to stabilize
                try await waitForMemoryRecovery()
                
                // Adjust batch size if needed
                currentBatchSize = calculateOptimalBatchSize()
            }
            
            // Process batch with memory monitoring
            let batchText = try await processBatchWithMemoryMonitoring(
                document: document,
                pageRange: batch,
                batchIndex: batchIndex
            )
            
            extractedText += batchText + "\n"
            
            // Update progress
            let progress = Double(batchIndex + 1) / Double(batches.count)
            DispatchQueue.main.async {
                self.processingProgress = progress
                progressCallback(progress)
            }
            
            // Brief pause to allow system cleanup
            if batchIndex < batches.count - 1 {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
        }
        
        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Batch Processing
    
    private func createAdaptiveBatches(pageCount: Int) -> [Range<Int>] {
        var batches: [Range<Int>] = []
        var currentIndex = 0
        
        while currentIndex < pageCount {
            let batchSize = calculateOptimalBatchSize()
            let endIndex = min(currentIndex + batchSize, pageCount)
            batches.append(currentIndex..<endIndex)
            currentIndex = endIndex
        }
        
        return batches
    }
    
    private func calculateOptimalBatchSize() -> Int {
        let memoryLevel = memoryManager.currentPressureLevel
        let recommendedConcurrency = memoryManager.recommendedConcurrency
        
        switch memoryLevel {
        case .normal:
            return min(ProcessingConfig.maxBatchSize, recommendedConcurrency * 2)
        case .warning:
            return min(ProcessingConfig.defaultBatchSize, recommendedConcurrency)
        case .critical:
            return ProcessingConfig.minBatchSize
        case .emergency:
            return ProcessingConfig.minBatchSize
        }
    }
    
    private func processBatchWithMemoryMonitoring(
        document: PDFDocument,
        pageRange: Range<Int>,
        batchIndex: Int
    ) async throws -> String {
        
        let startMemory = memoryManager.currentMemoryUsage
        var batchText = ""
        
        // Extract pages data before async processing to avoid Sendable issues
        var pageTexts: [(Int, String)] = []
        for pageIndex in pageRange {
            if let page = document.page(at: pageIndex), let pageText = page.string {
                pageTexts.append((pageIndex, pageText))
            }
        }
        
        // Use autorelease pool for automatic memory cleanup
        try await withUnsafeThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    for (_, pageText) in pageTexts {
                        // Extract text with memory-efficient preprocessing
                        let processedText = MemoryUtils.preprocessTextMemoryEfficient(pageText)
                        batchText += processedText + "\n"
                        
                        // Check memory growth during batch processing
                        let currentMemory = MemoryUtils.getCurrentMemoryUsage()
                        let memoryGrowth = currentMemory > startMemory ? currentMemory - startMemory : 0
                        
                        // If memory growth is excessive, yield control
                        if memoryGrowth > 50 * 1024 * 1024 { // 50MB growth
                            Thread.sleep(forTimeInterval: 0.001) // 1ms yield
                        }
                    }
                    continuation.resume(returning: ())
                }
            }
        }
        
        return batchText
    }
    
    // MARK: - Memory Recovery
    
    private func waitForMemoryRecovery() async throws {
        let maxWaitTime: TimeInterval = 5.0 // Maximum 5 seconds
        let checkInterval: TimeInterval = 0.1 // Check every 100ms
        let startTime = Date()
        
        while memoryManager.shouldThrottleOperations() {
            if Date().timeIntervalSince(startTime) > maxWaitTime {
                // If memory doesn't recover, proceed with reduced batch size
                currentBatchSize = ProcessingConfig.minBatchSize
                break
            }
            
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    private func setupMemoryPressureHandling() {
        NotificationCenter.default.addObserver(
            forName: .memoryPressureDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleMemoryPressure(notification)
            }
        }
    }
    
    @MainActor private func handleMemoryPressure(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? EnhancedMemoryManager.MemoryPressureLevel else {
            return
        }
        
        switch level {
        case .warning:
            currentBatchSize = max(ProcessingConfig.minBatchSize, currentBatchSize - 1)
        case .critical, .emergency:
            currentBatchSize = ProcessingConfig.minBatchSize
            // Clear processing cache
            adaptiveCache.clearCache()
        case .normal:
            // Gradually increase batch size if memory allows
            currentBatchSize = min(ProcessingConfig.defaultBatchSize, currentBatchSize + 1)
        }
    }
    
    // MARK: - Fallback Processing
    
    private func processRegularPDF(data: Data) async throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw LargePDFProcessingError.invalidDocument
        }
        
        var extractedText = ""
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            autoreleasepool {
                if let page = document.page(at: pageIndex),
                   let pageText = page.string {
                    let processedText = MemoryUtils.preprocessTextMemoryEfficient(pageText)
                    extractedText += processedText + "\n"
                }
            }
        }
        
        return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Types

enum LargePDFProcessingError: Error, LocalizedError {
    case invalidDocument
    case memoryPressureTimeout
    case processingInterrupted
    
    var errorDescription: String? {
        switch self {
        case .invalidDocument:
            return "Invalid PDF document"
        case .memoryPressureTimeout:
            return "Processing timeout due to memory pressure"
        case .processingInterrupted:
            return "Processing was interrupted"
        }
    }
}
