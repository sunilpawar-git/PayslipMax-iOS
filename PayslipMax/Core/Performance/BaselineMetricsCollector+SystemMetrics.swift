import Foundation

// MARK: - Memory Usage & Processing Efficiency Metrics

extension BaselineMetricsCollector {

    func collectMemoryUsageMetrics() async -> MemoryUsageMetrics {
        let initialMemory = getCurrentMemoryUsage()
        let _: [MemoryMeasurement] = []

        var memoryMeasurements: [MemoryMeasurement] = []
        let measurementDuration: TimeInterval = 10.0
        let measurementInterval = configuration.memoryMeasurementInterval

        let startTime = CFAbsoluteTimeGetCurrent()
        var currentTime = startTime

        while (currentTime - startTime) < measurementDuration {
            let memoryUsage = getCurrentMemoryUsage()
            let measurement = MemoryMeasurement(
                timestamp: Date(),
                residentSize: memoryUsage.resident,
                virtualSize: memoryUsage.virtual,
                peakResident: memoryUsage.peak
            )
            memoryMeasurements.append(measurement)

            try? await Task.sleep(nanoseconds: UInt64(measurementInterval * 1_000_000_000))
            currentTime = CFAbsoluteTimeGetCurrent()
        }

        return MemoryUsageMetrics(
            initialMemoryUsage: initialMemory,
            measurements: memoryMeasurements,
            peakMemoryUsage: memoryMeasurements.map(\.residentSize).max() ?? 0,
            averageMemoryUsage: memoryMeasurements.map(\.residentSize).reduce(0, +) / UInt64(memoryMeasurements.count),
            memoryVariability: calculateMemoryVariability(memoryMeasurements)
        )
    }

    func collectProcessingEfficiencyMetrics(testDocuments: [Data]) async throws -> ProcessingEfficiencyMetrics {
        let redundancyMetrics = try await measureProcessingRedundancy(testDocuments: testDocuments)
        let resourceMetrics = await measureResourceUtilization()
        let concurrencyMetrics = try await measureConcurrencyEfficiency(testDocuments: testDocuments)

        return ProcessingEfficiencyMetrics(
            redundancyPercentage: redundancyMetrics.redundancyPercentage,
            duplicateOperations: redundancyMetrics.duplicateOperations,
            resourceUtilization: resourceMetrics,
            concurrencyEfficiency: concurrencyMetrics,
            bottleneckIdentification: identifyProcessingBottlenecks(redundancyMetrics, resourceMetrics)
        )
    }

    func getCurrentMemoryUsage() -> (resident: UInt64, virtual: UInt64, peak: UInt64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return (
                resident: UInt64(info.resident_size),
                virtual: UInt64(info.virtual_size),
                peak: UInt64(info.resident_size_max)
            )
        }
        return (0, 0, 0)
    }
}
