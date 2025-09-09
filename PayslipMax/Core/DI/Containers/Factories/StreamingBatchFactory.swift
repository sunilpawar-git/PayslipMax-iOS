import Foundation
import PDFKit

/// Factory for streaming batch processing services.
/// Handles memory-efficient PDF processing with adaptive batching and resource monitoring.
@MainActor
class StreamingBatchFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Streaming Batch Processing Services

    /// Creates a streaming batch coordinator for memory-efficient PDF processing
    func makeStreamingBatchCoordinator() -> StreamingBatchCoordinator {
        return StreamingBatchCoordinator(
            pressureMonitor: makeResourcePressureMonitor(),
            batchProcessor: makeStreamingBatchProcessor(),
            configurationCalculator: makeBatchConfigurationCalculator(),
            progressTracker: makeBatchProgressTracker()
        )
    }

    /// Creates a streaming batch processor for executing page batches
    func makeStreamingBatchProcessor() -> StreamingBatchProcessor {
        return StreamingBatchProcessor(
            memoryExtractor: makeMemoryOptimizedExtractor(),
            cacheManager: makeAdaptiveCacheManager()
        )
    }

    /// Creates a batch configuration calculator for adaptive settings
    func makeBatchConfigurationCalculator() -> BatchConfigurationCalculator {
        return BatchConfigurationCalculator(
            pressureMonitor: makeResourcePressureMonitor()
        )
    }

    /// Creates a batch progress tracker for monitoring and reporting
    func makeBatchProgressTracker() -> BatchProgressTracker {
        return BatchProgressTracker()
    }

    /// Creates a resource pressure monitor for memory management
    func makeResourcePressureMonitor() -> ResourcePressureMonitor {
        return ResourcePressureMonitor()
    }

    /// Creates a memory optimized extractor for text processing
    func makeMemoryOptimizedExtractor() -> MemoryOptimizedExtractor {
        return MemoryOptimizedExtractor()
    }

    /// Creates an adaptive cache manager for result caching
    func makeAdaptiveCacheManager() -> AdaptiveCacheManager {
        return AdaptiveCacheManager()
    }
}
