import Foundation

// MARK: - Batch Processing Types and Models

/// Configuration for batch processing optimization
struct BatchConfig {
    static let minBatchSize = 1
    static let maxBatchSize = 20
    static let defaultBatchSize = 5
    static let adaptationThreshold = 10 // Number of batches before adaptation
    static let concurrencyRange = 2...8
}

/// Performance tracking for individual batch execution
struct BatchPerformanceData {
    let batchSize: Int
    let concurrency: Int
    let executionTime: TimeInterval
    let successRate: Double
    let memoryPeak: UInt64
    let timestamp: Date
    
    var efficiency: Double {
        return successRate * (1.0 / max(0.1, executionTime)) * (Double(batchSize) / 10.0)
    }
}

/// Comprehensive metrics for batch processing operations
struct BatchProcessingMetrics {
    var totalBatches: Int = 0
    var successfulBatches: Int = 0
    var totalExecutionTime: TimeInterval = 0
    var averageBatchSize: Double = 0
    var peakMemoryUsage: UInt64 = 0
    var averageConcurrency: Double = 0
    
    var successRate: Double {
        return totalBatches > 0 ? Double(successfulBatches) / Double(totalBatches) : 0.0
    }
    
    var averageExecutionTime: TimeInterval {
        return totalBatches > 0 ? totalExecutionTime / Double(totalBatches) : 0.0
    }
    
    mutating func recordBatch(_ performance: BatchPerformanceData) {
        totalBatches += 1
        if performance.successRate > 0.8 {
            successfulBatches += 1
        }
        totalExecutionTime += performance.executionTime
        averageBatchSize = (averageBatchSize * Double(totalBatches - 1) + Double(performance.batchSize)) / Double(totalBatches)
        peakMemoryUsage = max(peakMemoryUsage, performance.memoryPeak)
        averageConcurrency = (averageConcurrency * Double(totalBatches - 1) + Double(performance.concurrency)) / Double(totalBatches)
    }
}

/// Memory pressure monitoring for adaptive batch sizing
struct BatchMemoryPressureMonitor {
    private var lastMemoryCheck = Date()
    private let checkInterval: TimeInterval = 1.0
    
    mutating func getCurrentMemoryPressure() -> MemoryPressureLevel {
        let now = Date()
        guard now.timeIntervalSince(lastMemoryCheck) >= checkInterval else {
            return .normal
        }
        lastMemoryCheck = now
        
        let memoryInfo = ProcessInfo.processInfo.physicalMemory
        let usedMemory = getUsedMemory()
        let pressure = Double(usedMemory) / Double(memoryInfo)
        
        if pressure > 0.9 {
            return .critical
        } else if pressure > 0.7 {
            return .high
        } else if pressure > 0.5 {
            return .moderate
        } else {
            return .normal
        }
    }
    
    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

/// Memory pressure levels for adaptive processing
enum MemoryPressureLevel {
    case normal
    case moderate
    case high
    case critical
    
    var batchSizeMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .moderate: return 0.8
        case .high: return 0.6
        case .critical: return 0.4
        }
    }
    
    var concurrencyMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .moderate: return 0.8
        case .high: return 0.6
        case .critical: return 0.5
        }
    }
}

/// Adaptive processing strategy based on performance history
struct AdaptiveProcessingStrategy {
    private var recentPerformance: [BatchPerformanceData] = []
    private let maxHistorySize = 20
    
    mutating func recordPerformance(_ performance: BatchPerformanceData) {
        recentPerformance.append(performance)
        if recentPerformance.count > maxHistorySize {
            recentPerformance.removeFirst()
        }
    }
    
    func recommendBatchSize(currentSize: Int, memoryPressure: MemoryPressureLevel) -> Int {
        let baseRecommendation = analyzeOptimalBatchSize()
        let pressureAdjusted = Int(Double(baseRecommendation) * memoryPressure.batchSizeMultiplier)
        return max(BatchConfig.minBatchSize, min(BatchConfig.maxBatchSize, pressureAdjusted))
    }
    
    func recommendConcurrency(current: Int, memoryPressure: MemoryPressureLevel) -> Int {
        let baseRecommendation = analyzeOptimalConcurrency()
        let pressureAdjusted = Int(Double(baseRecommendation) * memoryPressure.concurrencyMultiplier)
        return max(BatchConfig.concurrencyRange.lowerBound, min(BatchConfig.concurrencyRange.upperBound, pressureAdjusted))
    }
    
    private func analyzeOptimalBatchSize() -> Int {
        guard !recentPerformance.isEmpty else { return BatchConfig.defaultBatchSize }
        
        let avgEfficiency = recentPerformance.map { $0.efficiency }.reduce(0, +) / Double(recentPerformance.count)
        let lastPerformance = recentPerformance.last!
        
        if avgEfficiency > 0.8 && lastPerformance.executionTime < 2.0 {
            return min(BatchConfig.maxBatchSize, lastPerformance.batchSize + 1)
        } else if avgEfficiency < 0.4 || lastPerformance.executionTime > 5.0 {
            return max(BatchConfig.minBatchSize, lastPerformance.batchSize - 1)
        } else {
            return lastPerformance.batchSize
        }
    }
    
    private func analyzeOptimalConcurrency() -> Int {
        guard !recentPerformance.isEmpty else { return 4 }
        
        let avgEfficiency = recentPerformance.map { $0.efficiency }.reduce(0, +) / Double(recentPerformance.count)
        let lastPerformance = recentPerformance.last!
        
        if avgEfficiency > 0.7 {
            return min(BatchConfig.concurrencyRange.upperBound, lastPerformance.concurrency + 1)
        } else if avgEfficiency < 0.4 {
            return max(BatchConfig.concurrencyRange.lowerBound, lastPerformance.concurrency - 1)
        } else {
            return lastPerformance.concurrency
        }
    }
}
