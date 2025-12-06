//
//  DualSectionPerformanceMonitor.swift
//  PayslipMax
//
//  Created for Phase 6: Performance Optimization & Validation
//  Monitors dual-section processing performance with intelligent caching
//

import Foundation

/// Performance metrics for dual-section processing operations
struct DualSectionPerformanceMetrics {
    let processingTime: TimeInterval
    let componentsProcessed: Int
    let cacheHitRate: Double
    let memoryUsage: Int64  // Changed from UInt64 to handle negative deltas
    let classificationCount: Int
    let sectionAnalysisCount: Int
}

/// Performance thresholds for dual-section processing
struct PerformanceThresholds {
    let maxProcessingTimePerComponent: TimeInterval = 0.001 // 1ms per component
    let maxMemoryUsageIncrease: Double = 0.30 // 30% increase max
    let minCacheHitRate: Double = 0.70 // 70% cache hit rate minimum
    let maxTotalProcessingTime: TimeInterval = 0.50 // 500ms total
}

/// Protocol for dual-section performance monitoring capabilities
protocol DualSectionPerformanceMonitorProtocol {
    /// Starts performance monitoring for a processing session
    /// - Parameter sessionId: Unique identifier for the processing session
    func startMonitoring(sessionId: String)

    /// Records a component processing operation
    /// - Parameters:
    ///   - sessionId: The processing session identifier
    ///   - componentKey: The component being processed
    ///   - wasFromCache: Whether the result came from cache
    ///   - processingTime: Time taken for this operation
    func recordComponentProcessing(sessionId: String, componentKey: String, wasFromCache: Bool, processingTime: TimeInterval)

    /// Ends monitoring and returns performance metrics
    /// - Parameter sessionId: The processing session identifier
    /// - Returns: Complete performance metrics for the session
    func endMonitoring(sessionId: String) -> DualSectionPerformanceMetrics?

    /// Gets current performance status
    /// - Parameter sessionId: The processing session identifier
    /// - Returns: Current performance metrics
    func getCurrentMetrics(sessionId: String) -> DualSectionPerformanceMetrics?

    /// Checks if performance is within acceptable thresholds
    /// - Parameter metrics: The metrics to validate
    /// - Returns: True if performance is acceptable
    func isPerformanceAcceptable(_ metrics: DualSectionPerformanceMetrics) -> Bool
}

/// Performance monitor for dual-section processing operations
/// Tracks cache efficiency, processing times, and memory usage
final class DualSectionPerformanceMonitor: DualSectionPerformanceMonitorProtocol {

    // MARK: - Properties

    /// Active monitoring sessions
    private var activeSessions: [String: MonitoringSession] = [:]

    /// Performance thresholds for validation
    private let thresholds = PerformanceThresholds()

    /// Queue for thread-safe operations
    private let queue = DispatchQueue(label: "performance.monitor.queue", qos: .utility)

    // MARK: - Private Types

    /// Internal monitoring session data
    private struct MonitoringSession {
        let startTime: Date
        var componentsProcessed: Int = 0
        var cacheHits: Int = 0
        var totalOperations: Int = 0
        var classificationCount: Int = 0
        var sectionAnalysisCount: Int = 0
        let startMemory: UInt64

        init() {
            self.startTime = Date()
            self.startMemory = DualSectionPerformanceMonitor.getCurrentMemoryUsage()
        }
    }

    // MARK: - Public Methods

    /// Starts performance monitoring for a processing session
    func startMonitoring(sessionId: String) {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.activeSessions[sessionId] = MonitoringSession()
            print("[DualSectionPerformanceMonitor] Started monitoring session: \(sessionId)")
        }
    }

    /// Records a component processing operation
    func recordComponentProcessing(sessionId: String, componentKey: String, wasFromCache: Bool, processingTime: TimeInterval) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard var session = self.activeSessions[sessionId] else { return }

            session.componentsProcessed += 1
            session.totalOperations += 1

            if wasFromCache {
                session.cacheHits += 1
            }

            // Record classification vs section analysis
            if componentKey.contains("CLASSIFICATION") {
                session.classificationCount += 1
            } else if componentKey.contains("SECTION") {
                session.sectionAnalysisCount += 1
            }

            self.activeSessions[sessionId] = session

            // Log performance warnings if thresholds exceeded
            if processingTime > self.thresholds.maxProcessingTimePerComponent {
                print("[DualSectionPerformanceMonitor] ⚠️ Slow component processing: \(componentKey) took \(String(format: "%.3f", processingTime * 1000))ms")
            }
        }
    }

    /// Ends monitoring and returns performance metrics
    func endMonitoring(sessionId: String) -> DualSectionPerformanceMetrics? {
        return queue.sync { [weak self] in
            guard let self = self else { return nil }
            guard let session = self.activeSessions.removeValue(forKey: sessionId) else { return nil }

            let endTime = Date()
            let totalTime = endTime.timeIntervalSince(session.startTime)
            let currentMemory = Self.getCurrentMemoryUsage()
            let cacheHitRate = session.totalOperations > 0 ? Double(session.cacheHits) / Double(session.totalOperations) : 0.0

            let metrics = DualSectionPerformanceMetrics(
                processingTime: totalTime,
                componentsProcessed: session.componentsProcessed,
                cacheHitRate: cacheHitRate,
                memoryUsage: Int64(currentMemory) - Int64(session.startMemory),
                classificationCount: session.classificationCount,
                sectionAnalysisCount: session.sectionAnalysisCount
            )

            print("[DualSectionPerformanceMonitor] Session \(sessionId) completed:")
            print("  - Processing time: \(String(format: "%.3f", totalTime * 1000))ms")
            print("  - Components processed: \(session.componentsProcessed)")
            print("  - Cache hit rate: \(String(format: "%.1f", cacheHitRate * 100))%")
            print("  - Memory delta: \(metrics.memoryUsage) bytes")

            return metrics
        }
    }

    /// Gets current performance metrics for active session
    func getCurrentMetrics(sessionId: String) -> DualSectionPerformanceMetrics? {
        return queue.sync { [weak self] in
            guard let self = self else { return nil }
            guard let session = self.activeSessions[sessionId] else { return nil }

            let currentTime = Date()
            let elapsedTime = currentTime.timeIntervalSince(session.startTime)
            let currentMemory = Self.getCurrentMemoryUsage()
            let cacheHitRate = session.totalOperations > 0 ? Double(session.cacheHits) / Double(session.totalOperations) : 0.0

            return DualSectionPerformanceMetrics(
                processingTime: elapsedTime,
                componentsProcessed: session.componentsProcessed,
                cacheHitRate: cacheHitRate,
                memoryUsage: Int64(currentMemory) - Int64(session.startMemory),
                classificationCount: session.classificationCount,
                sectionAnalysisCount: session.sectionAnalysisCount
            )
        }
    }

    /// Checks if performance is within acceptable thresholds
    func isPerformanceAcceptable(_ metrics: DualSectionPerformanceMetrics) -> Bool {
        let avgTimePerComponent = metrics.componentsProcessed > 0 ?
            metrics.processingTime / Double(metrics.componentsProcessed) : 0.0

        let performanceIssues = [
            avgTimePerComponent > thresholds.maxProcessingTimePerComponent,
            metrics.processingTime > thresholds.maxTotalProcessingTime,
            metrics.cacheHitRate < thresholds.minCacheHitRate && metrics.componentsProcessed > 10
        ]

        let isAcceptable = !performanceIssues.contains(true)

        if !isAcceptable {
            print("[DualSectionPerformanceMonitor] ⚠️ Performance thresholds exceeded:")
            if avgTimePerComponent > thresholds.maxProcessingTimePerComponent {
                print("  - Avg time per component: \(String(format: "%.3f", avgTimePerComponent * 1000))ms (max: \(String(format: "%.3f", thresholds.maxProcessingTimePerComponent * 1000))ms)")
            }
            if metrics.processingTime > thresholds.maxTotalProcessingTime {
                print("  - Total processing time: \(String(format: "%.3f", metrics.processingTime * 1000))ms (max: \(String(format: "%.3f", thresholds.maxTotalProcessingTime * 1000))ms)")
            }
            if metrics.cacheHitRate < thresholds.minCacheHitRate && metrics.componentsProcessed > 10 {
                print("  - Cache hit rate: \(String(format: "%.1f", metrics.cacheHitRate * 100))% (min: \(String(format: "%.1f", thresholds.minCacheHitRate * 100))%)")
            }
        }

        return isAcceptable
    }

    // MARK: - Private Methods

    /// Gets current memory usage in bytes
    private static func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        }

        return 0
    }
}

// MARK: - Shared Instance

extension DualSectionPerformanceMonitor {
    /// Shared performance monitor instance
    static let shared = DualSectionPerformanceMonitor()
}
