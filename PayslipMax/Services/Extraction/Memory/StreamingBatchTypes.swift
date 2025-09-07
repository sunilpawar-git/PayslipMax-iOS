import Foundation

/// Supporting types for streaming batch processing
///
/// Following Phase 4B modular pattern: Centralized type definitions
/// Extracted from StreamingBatchCoordinator to maintain 300-line limit

// MARK: - Configuration Types

/// Batch processing configuration
struct BatchConfiguration {
    let maxBatchSize: Int
    let minBatchSize: Int = 1
    let maxConcurrentBatches: Int
    let memoryThreshold: UInt64
    
    init(maxBatchSize: Int = 10, maxConcurrentBatches: Int = 2, memoryThreshold: UInt64 = 200 * 1024 * 1024) {
        self.maxBatchSize = maxBatchSize
        self.maxConcurrentBatches = maxConcurrentBatches
        self.memoryThreshold = memoryThreshold
    }
}

// MARK: - Result Types

/// Processing result for a batch
struct BatchResult {
    let batchIndex: Int
    let pageRange: Range<Int>
    let extractedText: String
    let processingTime: TimeInterval
    let memoryUsed: UInt64
}

// MARK: - Progress Types

/// Progress information for streaming processing
struct ProcessingProgress {
    let completedPages: Int
    let totalPages: Int
    let currentBatch: Int
    let totalBatches: Int
    let estimatedTimeRemaining: TimeInterval
    
    var percentage: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(completedPages) / Double(totalPages)
    }
}

