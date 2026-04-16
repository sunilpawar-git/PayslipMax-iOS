import Foundation
import PDFKit

/// Comprehensive baseline metrics collector for parsing system performance
///
/// This service establishes performance baselines for the parsing system unification process.
/// It measures current performance across all parsing systems and cache implementations
/// to enable accurate regression detection during the consolidation process.
@MainActor
final class BaselineMetricsCollector {

    // MARK: - Configuration

    /// Metrics collection configuration
    struct Configuration {
        let sampleSize: Int
        let timeoutInterval: TimeInterval
        let memoryMeasurementInterval: TimeInterval

        static let `default` = Configuration(
            sampleSize: 10,
            timeoutInterval: 30.0,
            memoryMeasurementInterval: 0.1
        )
    }

    // MARK: - Properties

    let configuration: Configuration

    /// Storage for collected baseline metrics
    private var collectedMetrics: [BaselineSnapshot] = []

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Baseline Collection

    /// Collect comprehensive baseline metrics across all parsing systems
    /// - Parameter testDocuments: Array of test document data for consistent measurement
    /// - Returns: Aggregated baseline metrics
    func collectBaselineMetrics(testDocuments: [Data]) async throws -> BaselineSnapshot {
        print("🔍 Starting baseline metrics collection with \(testDocuments.count) test documents")

        let startTime = CFAbsoluteTimeGetCurrent()

        // Collect parsing system performance
        let parsingMetrics = try await collectParsingSystemMetrics(testDocuments: testDocuments)

        // Collect cache system effectiveness
        let cacheMetrics = await collectCacheSystemMetrics()

        // Collect memory usage patterns
        let memoryMetrics = await collectMemoryUsageMetrics()

        // Collect processing efficiency metrics
        let processingMetrics = try await collectProcessingEfficiencyMetrics(testDocuments: testDocuments)

        let collectionTime = CFAbsoluteTimeGetCurrent() - startTime

        let baseline = BaselineSnapshot(
            timestamp: Date(),
            collectionDuration: collectionTime,
            parsingMetrics: parsingMetrics,
            cacheMetrics: cacheMetrics,
            memoryMetrics: memoryMetrics,
            processingMetrics: processingMetrics,
            testDocumentCount: testDocuments.count,
            systemInfo: SystemInfo.current()
        )

        collectedMetrics.append(baseline)
        print("✅ Baseline metrics collection completed in \(String(format: "%.2f", collectionTime))s")

        return baseline
    }

    // MARK: - Parsing System Metrics

    private func collectParsingSystemMetrics(testDocuments: [Data]) async throws -> ParsingSystemMetrics {
        print("📊 Collecting parsing system performance metrics...")

        var allTelemetry: [ParserTelemetry] = []
        var processingTimes: [String: [TimeInterval]] = [:]
        var successRates: [String: Double] = [:]
        var memoryUsagePeaks: [String: UInt64] = [:]

        // Test each parsing system with each document
        let parsingSystems = await identifyParsingSystems()

        for system in parsingSystems {
            print("Testing parsing system: \(system.name)")

            var systemTelemetry: [ParserTelemetry] = []
            var systemTimes: [TimeInterval] = []
            var successCount = 0
            var peakMemory: UInt64 = 0

            for (index, documentData) in testDocuments.enumerated() {
                do {
                    let metrics = try await measureParsingPerformance(
                        system: system,
                        documentData: documentData,
                        documentIndex: index
                    )

                    systemTelemetry.append(metrics.telemetry)
                    systemTimes.append(metrics.processingTime)

                    if metrics.telemetry.success {
                        successCount += 1
                    }

                    if let memoryUsage = metrics.telemetry.memoryUsage, UInt64(memoryUsage) > peakMemory {
                        peakMemory = UInt64(memoryUsage)
                    }

                } catch {
                    print("Failed to measure \(system.name) with document \(index): \(error.localizedDescription)")

                    // Record failure telemetry
                    let failureTelemetry = ParserTelemetry(
                        parserName: system.name,
                        processingTime: 0,
                        success: false,
                        errorMessage: error.localizedDescription
                    )
                    systemTelemetry.append(failureTelemetry)
                }
            }

            allTelemetry.append(contentsOf: systemTelemetry)
            processingTimes[system.name] = systemTimes
            successRates[system.name] = Double(successCount) / Double(testDocuments.count)
            memoryUsagePeaks[system.name] = peakMemory
        }

        return ParsingSystemMetrics(
            systemCount: parsingSystems.count,
            totalProcessingTime: processingTimes.values.flatMap { $0 }.reduce(0, +),
            averageProcessingTime: calculateAverageProcessingTime(processingTimes),
            successRates: successRates,
            memoryUsagePeaks: memoryUsagePeaks,
            telemetryData: allTelemetry,
            documentProcessingDistribution: calculateProcessingDistribution(processingTimes)
        )
    }

    // MARK: - Cache System Metrics

    private func collectCacheSystemMetrics() async -> CacheSystemMetrics {
        print("🗄️ Collecting cache system effectiveness metrics...")

        let cacheManagers = await identifyCacheSystems()
        var cacheEffectiveness: [String: CacheEffectivenessMetrics] = [:]
        var totalMemoryUsage: UInt64 = 0
        var totalCacheOperations = 0

        for cacheManager in cacheManagers {
            let effectiveness = await measureCacheEffectiveness(cacheManager)
            cacheEffectiveness[cacheManager.name] = effectiveness
            totalMemoryUsage += effectiveness.memoryUsage
            totalCacheOperations += effectiveness.totalOperations
        }

        return CacheSystemMetrics(
            cacheSystemCount: cacheManagers.count,
            overallHitRate: calculateOverallHitRate(cacheEffectiveness),
            totalMemoryUsage: totalMemoryUsage,
            cacheEffectiveness: cacheEffectiveness,
            memoryDistribution: calculateCacheMemoryDistribution(cacheEffectiveness),
            operationDistribution: calculateCacheOperationDistribution(cacheEffectiveness)
        )
    }

    // MARK: - Helper Methods

    private func identifyParsingSystems() async -> [ParsingSystemInfo] {
        return [
            ParsingSystemInfo(name: "ModularPayslipProcessingPipeline", type: .unified),
            ParsingSystemInfo(name: "UnifiedPDFParsingCoordinator", type: .unified)
        ]
    }

    private func identifyCacheSystems() async -> [CacheSystemInfo] {
        return [
            CacheSystemInfo(name: "PDFProcessingCache", type: .multiLevel),
            CacheSystemInfo(name: "AdaptiveCacheManager", type: .lruPressureAware),
            CacheSystemInfo(name: "OptimizedProcessingPipeline", type: .processingCache),
            CacheSystemInfo(name: "PDFDocumentCache", type: .documentCache),
            CacheSystemInfo(name: "EnhancedMemoryManager", type: .memoryManagement),
            CacheSystemInfo(name: "LargePDFStreamingProcessor", type: .streamingCache)
        ]
    }
}
