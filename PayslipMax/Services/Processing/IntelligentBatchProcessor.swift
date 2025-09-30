import Foundation
import Combine

/// Intelligent batch processor that optimizes batch sizes and concurrency based on system resources and workload patterns
final class IntelligentBatchProcessor {

    // MARK: - Properties

    private var currentBatchSize = BatchConfig.defaultBatchSize
    private var currentConcurrency = 4
    private var adaptationCounter = 0
    private var batchMetrics = BatchProcessingMetrics()
    private var recentPerformance: [BatchPerformanceData] = []
    private var memoryMonitor = BatchMemoryPressureMonitor()
    private var adaptiveStrategy = AdaptiveProcessingStrategy()

    @Published private(set) var metrics = BatchProcessingMetrics()
    @Published private(set) var isProcessing = false

    // MARK: - Initialization

    init() {
        setupMemoryPressureMonitoring()
    }

    // MARK: - Batch Processing

    /// Process items in intelligent batches with adaptive sizing and concurrency
    func processBatch<T, U>(
        items: [T],
        processor: @escaping (T) async throws -> U
    ) async throws -> [U] {
        guard !items.isEmpty else { return [] }

        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        var results: [U] = []
        results.reserveCapacity(items.count)

        let batches = createOptimizedBatches(from: items)

        for batch in batches {
            let batchResults = try await processSingleBatch(batch, processor: processor)
            results.append(contentsOf: batchResults)
        }

        return results
    }

    /// Process a collection with intelligent memory management and progress tracking
    func processWithProgressTracking<T, U>(
        items: [T],
        processor: @escaping (T) async throws -> U,
        progressHandler: @escaping (Double) -> Void = { _ in }
    ) async throws -> [U] {
        let totalItems = items.count
        var completedItems = 0
        var results: [U] = []

        let batches = createOptimizedBatches(from: items)

        for batch in batches {
            let batchResults = try await processSingleBatch(batch, processor: processor)
            results.append(contentsOf: batchResults)

            completedItems += batch.count
            let progress = Double(completedItems) / Double(totalItems)
            progressHandler(progress)
        }

        return results
    }

    // MARK: - Batch Optimization

    private func createOptimizedBatches<T>(from items: [T]) -> [[T]] {
        let memoryPressure = memoryMonitor.getCurrentMemoryPressure()
        let optimizedBatchSize = determineOptimalBatchSize(memoryPressure: memoryPressure)

        var batches: [[T]] = []
        var currentIndex = 0

        while currentIndex < items.count {
            let remainingItems = items.count - currentIndex
            let batchSize = min(optimizedBatchSize, remainingItems)
            let endIndex = currentIndex + batchSize

            let batch = Array(items[currentIndex..<endIndex])
            batches.append(batch)
            currentIndex = endIndex
        }

        return batches
    }

    private func processSingleBatch<T, U>(
        _ batch: [T],
        processor: @escaping (T) async throws -> U
    ) async throws -> [U] {
        let startTime = Date()
        let memoryBefore = getCurrentMemoryUsage()
        let memoryPressure = memoryMonitor.getCurrentMemoryPressure()

        let concurrency = determineOptimalConcurrency(memoryPressure: memoryPressure)

        // Process batch with controlled concurrency
        let results = try await processWithControlledConcurrency(
            batch,
            concurrency: concurrency,
            processor: processor
        )

        // Record performance metrics
        let executionTime = Date().timeIntervalSince(startTime)
        let memoryAfter = getCurrentMemoryUsage()
        let successRate = Double(results.count) / Double(batch.count)

        let performance = BatchPerformanceData(
            batchSize: batch.count,
            concurrency: concurrency,
            executionTime: executionTime,
            successRate: successRate,
            memoryPeak: memoryAfter - memoryBefore,
            timestamp: startTime
        )

        await updateMetrics(performance)

        // Adapt strategy based on performance
        adaptiveStrategy.recordPerformance(performance)
        adaptationCounter += 1

        if adaptationCounter >= BatchConfig.adaptationThreshold {
            adaptBatchParameters(memoryPressure: memoryPressure)
            adaptationCounter = 0
        }

        return results
    }

    private func processWithControlledConcurrency<T, U>(
        _ items: [T],
        concurrency: Int,
        processor: @escaping (T) async throws -> U
    ) async throws -> [U] {
        // ✅ CLEAN: Use Swift's native concurrency limiting with TaskGroup
        return try await withThrowingTaskGroup(of: (Int, U).self, returning: [U].self) { group in
            var results: [U?] = Array(repeating: nil, count: items.count)
            var activeTaskCount = 0
            var itemIndex = 0

            // Process items with controlled concurrency using native Swift patterns
            while itemIndex < items.count || activeTaskCount > 0 {
                // Add new tasks up to concurrency limit
                while activeTaskCount < concurrency && itemIndex < items.count {
                    let currentIndex = itemIndex
                    let currentItem = items[itemIndex]

                    group.addTask {
                        let result = try await processor(currentItem)
                        return (currentIndex, result)
                    }

                    activeTaskCount += 1
                    itemIndex += 1
                }

                // Wait for at least one task to complete
                if let (index, result) = try await group.next() {
                    results[index] = result
                    activeTaskCount -= 1
                }
            }

            return results.compactMap { $0 }
        }
    }

    // MARK: - Adaptive Parameters

    private func determineOptimalBatchSize(memoryPressure: MemoryPressureLevel) -> Int {
        return adaptiveStrategy.recommendBatchSize(
            currentSize: currentBatchSize,
            memoryPressure: memoryPressure
        )
    }

    private func determineOptimalConcurrency(memoryPressure: MemoryPressureLevel) -> Int {
        return adaptiveStrategy.recommendConcurrency(
            current: currentConcurrency,
            memoryPressure: memoryPressure
        )
    }

    private func adaptBatchParameters(memoryPressure: MemoryPressureLevel) {
        currentBatchSize = determineOptimalBatchSize(memoryPressure: memoryPressure)
        currentConcurrency = determineOptimalConcurrency(memoryPressure: memoryPressure)
    }

    // MARK: - Performance Monitoring

    private func updateMetrics(_ performance: BatchPerformanceData) async {
        await MainActor.run {
            batchMetrics.recordBatch(performance)
            metrics = batchMetrics
        }

        recentPerformance.append(performance)
        if recentPerformance.count > 20 {
            recentPerformance.removeFirst()
        }
    }

    func getDetailedMetrics() async -> BatchProcessingMetrics {
        return await MainActor.run { metrics }
    }

    // MARK: - Memory Management

    private func setupMemoryPressureMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                let pressure = self.memoryMonitor.getCurrentMemoryPressure()
                await self.handleMemoryPressure(pressure)
            }
        }
    }

    private func handleMemoryPressure(_ pressure: MemoryPressureLevel) async {
        switch pressure {
        case .critical:
            // Reduce batch size and concurrency aggressively
            currentBatchSize = max(1, Int(Double(currentBatchSize) * 0.5))
            currentConcurrency = max(1, Int(Double(currentConcurrency) * 0.5))

        case .high:
            // Moderate reduction
            currentBatchSize = max(2, Int(Double(currentBatchSize) * 0.7))
            currentConcurrency = max(2, Int(Double(currentConcurrency) * 0.7))

        case .moderate:
            // Slight reduction
            currentBatchSize = max(3, Int(Double(currentBatchSize) * 0.85))
            currentConcurrency = max(2, Int(Double(currentConcurrency) * 0.85))

        case .normal:
            // Allow parameters to be optimized normally
            break
        }
    }

    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    // MARK: - Configuration

    func configureBatchSize(_ size: Int) {
        currentBatchSize = max(BatchConfig.minBatchSize, min(BatchConfig.maxBatchSize, size))
    }

    func configureConcurrency(_ concurrency: Int) {
        currentConcurrency = max(BatchConfig.concurrencyRange.lowerBound, min(BatchConfig.concurrencyRange.upperBound, concurrency))
    }

    func resetToDefaults() {
        currentBatchSize = BatchConfig.defaultBatchSize
        currentConcurrency = 4
        adaptationCounter = 0
        recentPerformance.removeAll()
        adaptiveStrategy = AdaptiveProcessingStrategy()
    }
}
