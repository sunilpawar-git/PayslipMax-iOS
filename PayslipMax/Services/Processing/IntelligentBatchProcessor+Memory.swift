import Foundation

extension IntelligentBatchProcessor {

    // MARK: - Memory Management

    func setupMemoryPressureMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                let pressure = self.memoryMonitor.getCurrentMemoryPressure()
                await self.handleMemoryPressure(pressure)
            }
        }
    }

    func handleMemoryPressure(_ pressure: MemoryPressureLevel) async {
        switch pressure {
        case .critical:
            currentBatchSize = max(1, Int(Double(currentBatchSize) * 0.5))
            currentConcurrency = max(1, Int(Double(currentConcurrency) * 0.5))

        case .high:
            currentBatchSize = max(2, Int(Double(currentBatchSize) * 0.7))
            currentConcurrency = max(2, Int(Double(currentConcurrency) * 0.7))

        case .moderate:
            currentBatchSize = max(3, Int(Double(currentBatchSize) * 0.85))
            currentConcurrency = max(2, Int(Double(currentConcurrency) * 0.85))

        case .normal:
            break
        }
    }

    func getCurrentMemoryUsage() -> UInt64 {
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
