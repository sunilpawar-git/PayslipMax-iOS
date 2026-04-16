import Foundation

// MARK: - BaselineMetricsCollector: Calculation Helpers

/// Pure calculation helpers for aggregating baseline metrics.
/// All functions are deterministic and free of side effects,
/// making them straightforward to unit-test in isolation.
extension BaselineMetricsCollector {

    // MARK: - Processing Time

    func calculateAverageProcessingTime(_ processingTimes: [String: [TimeInterval]]) -> TimeInterval {
        let allTimes = processingTimes.values.flatMap { $0 }
        guard !allTimes.isEmpty else { return 0 }
        return allTimes.reduce(0, +) / Double(allTimes.count)
    }

    func calculateProcessingDistribution(_ processingTimes: [String: [TimeInterval]]) -> [String: TimeInterval] {
        processingTimes.mapValues { times in
            times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        }
    }

    // MARK: - Cache Hit Rate

    func calculateOverallHitRate(_ cacheEffectiveness: [String: CacheEffectivenessMetrics]) -> Double {
        let totalOps = cacheEffectiveness.values.map(\.totalOperations).reduce(0, +)
        guard totalOps > 0 else { return 0 }
        let weighted = cacheEffectiveness.values.reduce(0.0) { sum, metrics in
            sum + (metrics.hitRate * Double(metrics.totalOperations))
        }
        return weighted / Double(totalOps)
    }

    // MARK: - Cache Distribution

    func calculateCacheMemoryDistribution(
        _ cacheEffectiveness: [String: CacheEffectivenessMetrics]
    ) -> [String: UInt64] {
        cacheEffectiveness.mapValues(\.memoryUsage)
    }

    func calculateCacheOperationDistribution(
        _ cacheEffectiveness: [String: CacheEffectivenessMetrics]
    ) -> [String: Int] {
        cacheEffectiveness.mapValues(\.totalOperations)
    }

    // MARK: - Memory Variability

    /// Returns the coefficient of variation (%) of resident memory across measurements.
    func calculateMemoryVariability(_ measurements: [MemoryMeasurement]) -> Double {
        guard measurements.count > 1 else { return 0 }
        let values = measurements.map { Double($0.residentSize) }
        let mean = values.reduce(0, +) / Double(values.count)
        guard mean > 0 else { return 0 }
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return (sqrt(variance) / mean) * 100
    }

    // MARK: - Bottleneck Identification

    func identifyProcessingBottlenecks(
        _ redundancyMetrics: RedundancyMetrics,
        _ resourceMetrics: Double
    ) -> [String] {
        var bottlenecks: [String] = []

        if redundancyMetrics.redundancyPercentage > 30 {
            bottlenecks.append(
                "High processing redundancy (\(String(format: "%.1f", redundancyMetrics.redundancyPercentage))%)"
            )
        }
        if resourceMetrics > 0.8 {
            bottlenecks.append(
                "High resource utilization (\(String(format: "%.1f", resourceMetrics * 100))%)"
            )
        }
        if redundancyMetrics.duplicateOperations > redundancyMetrics.uniqueOperations {
            bottlenecks.append("More duplicate operations than unique operations")
        }

        return bottlenecks
    }
}
