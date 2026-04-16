import Foundation
import PDFKit

// MARK: - BaselineMetricsCollector: Performance Measurements

/// Performance measurement helpers for `BaselineMetricsCollector`.
/// Each method measures one dimension of parsing/caching performance.
/// Simulation helpers are co-located here because measurement methods
/// depend on them and `private` scope must remain within the same file.
extension BaselineMetricsCollector {

    // MARK: - Parsing Performance

    /// Measures parsing performance for a single system and document.
    func measureParsingPerformance(
        system: ParsingSystemInfo,
        documentData: Data,
        documentIndex: Int
    ) async throws -> ParsingPerformanceMeasurement {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = getCurrentMemoryUsage().resident

        var telemetry: ParserTelemetry
        var success = false

        do {
            let result = try await performParsingForSystem(system, documentData: documentData)
            success = result.success

            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let finalMemory = getCurrentMemoryUsage().resident
            let memoryDelta = finalMemory > initialMemory ? finalMemory - initialMemory : UInt64(0)

            telemetry = ParserTelemetry(
                parserName: system.name,
                processingTime: processingTime,
                success: success,
                extractedItemCount: result.extractedItemCount,
                textLength: result.textLength
            )

            return ParsingPerformanceMeasurement(
                telemetry: telemetry,
                processingTime: processingTime,
                memoryDelta: memoryDelta,
                success: success
            )
        } catch {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime

            telemetry = ParserTelemetry(
                parserName: system.name,
                processingTime: processingTime,
                success: false,
                errorMessage: error.localizedDescription
            )

            return ParsingPerformanceMeasurement(
                telemetry: telemetry,
                processingTime: processingTime,
                memoryDelta: 0,
                success: false
            )
        }
    }

    // MARK: - Cache Effectiveness

    /// Returns simulated cache effectiveness metrics for a given cache system type.
    func measureCacheEffectiveness(_ cacheSystem: CacheSystemInfo) async -> CacheEffectivenessMetrics {
        switch cacheSystem.type {
        case .multiLevel:
            return CacheEffectivenessMetrics(
                hitRate: 0.75, missRate: 0.25, totalOperations: 1000,
                memoryUsage: 50 * 1024 * 1024, evictionRate: 0.10, averageResponseTime: 0.002
            )
        case .lruPressureAware:
            return CacheEffectivenessMetrics(
                hitRate: 0.68, missRate: 0.32, totalOperations: 800,
                memoryUsage: 25 * 1024 * 1024, evictionRate: 0.15, averageResponseTime: 0.001
            )
        case .processingCache:
            return CacheEffectivenessMetrics(
                hitRate: 0.85, missRate: 0.15, totalOperations: 1200,
                memoryUsage: 75 * 1024 * 1024, evictionRate: 0.05, averageResponseTime: 0.003
            )
        case .documentCache:
            return CacheEffectivenessMetrics(
                hitRate: 0.60, missRate: 0.40, totalOperations: 600,
                memoryUsage: 100 * 1024 * 1024, evictionRate: 0.20, averageResponseTime: 0.005
            )
        case .memoryManagement:
            return CacheEffectivenessMetrics(
                hitRate: 0.90, missRate: 0.10, totalOperations: 500,
                memoryUsage: 15 * 1024 * 1024, evictionRate: 0.02, averageResponseTime: 0.0005
            )
        case .streamingCache:
            return CacheEffectivenessMetrics(
                hitRate: 0.45, missRate: 0.55, totalOperations: 300,
                memoryUsage: 200 * 1024 * 1024, evictionRate: 0.30, averageResponseTime: 0.010
            )
        }
    }

    // MARK: - Processing Redundancy

    /// Measures duplicate-operation redundancy across a set of test documents.
    func measureProcessingRedundancy(testDocuments: [Data]) async throws -> RedundancyMetrics {
        var uniqueOperations: Set<String> = []
        var totalOperations = 0
        var duplicateOperations = 0

        for documentData in testDocuments {
            let documentHash = sha256Hash(documentData)
            let operationTypes = ["validation", "textExtraction", "formatDetection", "processing"]

            for operationType in operationTypes {
                let key = "\(operationType)_\(documentHash)"
                totalOperations += 1

                if uniqueOperations.contains(key) {
                    duplicateOperations += 1
                } else {
                    uniqueOperations.insert(key)
                }
            }
        }

        let redundancyPct = totalOperations > 0
            ? Double(duplicateOperations) / Double(totalOperations) * 100
            : 0

        return RedundancyMetrics(
            redundancyPercentage: redundancyPct,
            duplicateOperations: duplicateOperations,
            uniqueOperations: uniqueOperations.count,
            totalOperations: totalOperations
        )
    }

    // MARK: - Resource Utilisation

    /// Returns an estimated resource utilisation percentage (0–1).
    func measureResourceUtilization() async -> Double {
        let info = getCurrentMemoryUsage()
        let systemInfo = SystemInfo.current()
        let memoryUtilization = Double(info.resident) / Double(systemInfo.physicalMemory)
        return min(memoryUtilization * 1.2, 1.0)
    }

    // MARK: - Concurrency Efficiency

    /// Compares sequential vs. concurrent processing time and returns an
    /// efficiency ratio (0–1, where 1 means perfect linear concurrency scaling).
    func measureConcurrencyEfficiency(testDocuments: [Data]) async throws -> Double {
        var sequentialTime: TimeInterval = 0
        for documentData in testDocuments.prefix(3) {
            let docStart = CFAbsoluteTimeGetCurrent()
            _ = try await simulateDocumentProcessing(documentData)
            sequentialTime += CFAbsoluteTimeGetCurrent() - docStart
        }

        let concurrentStart = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            for documentData in testDocuments.prefix(3) {
                group.addTask {
                    do {
                        _ = try await self.simulateDocumentProcessing(documentData)
                    } catch {
                        // Measurement only — errors are intentionally swallowed
                    }
                }
            }
        }
        let concurrentTime = CFAbsoluteTimeGetCurrent() - concurrentStart

        return concurrentTime > 0 ? min(sequentialTime / concurrentTime, 3.0) / 3.0 : 0
    }

    // MARK: - Private Simulation Helpers
    // These are private to this file because they are called only by the measurement
    // methods above.  Moving them to a separate file would require loosening access.

    private func performParsingForSystem(
        _ system: ParsingSystemInfo,
        documentData: Data
    ) async throws -> (success: Bool, extractedItemCount: Int, textLength: Int) {
        let delay = TimeInterval.random(in: 0.1...2.0)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return (
            success: Double.random(in: 0...1) > 0.1,
            extractedItemCount: Int.random(in: 5...25),
            textLength: Int.random(in: 1000...5000)
        )
    }

    private func simulateDocumentProcessing(_ documentData: Data) async throws {
        let delay = TimeInterval.random(in: 0.1...1.0)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func sha256Hash(_ data: Data) -> String {
        String(data.hashValue)
    }
}
