import Foundation

/// Monitors parser performance for A/B testing
/// Tracks metrics for Universal vs Legacy parser comparison
final class ParserPerformanceMonitor {

    // MARK: - Singleton

    static let shared = ParserPerformanceMonitor()

    // MARK: - Types

    struct PerformanceMetrics {
        let processingTime: TimeInterval
        let componentsExtracted: Int
        let credits: Double
        let debits: Double
        let parserType: String
        let timestamp: Date

        var description: String {
            """
            Parser: \(parserType)
            Time: \(String(format: "%.2f", processingTime * 1000))ms
            Components: \(componentsExtracted)
            Credits: ₹\(String(format: "%.2f", credits))
            Debits: ₹\(String(format: "%.2f", debits))
            """
        }
    }

    // MARK: - Properties

    /// Stored metrics for analysis
    private var metrics: [PerformanceMetrics] = []

    /// Thread-safe access queue
    private let queue = DispatchQueue(label: "com.payslipmax.parsermonitor", attributes: .concurrent)

    /// Maximum metrics to store (prevent memory bloat)
    private let maxMetricsCount = 1000

    // MARK: - Initialization

    private init() {
        print("[ParserPerformanceMonitor] Initialized")
    }

    // MARK: - Public Methods

    /// Records performance metrics for a parsing operation
    /// - Parameter metrics: The metrics to record
    func recordMetrics(_ metrics: PerformanceMetrics) {
        queue.async(flags: .barrier) {
            self.metrics.append(metrics)

            // Prevent memory bloat
            if self.metrics.count > self.maxMetricsCount {
                self.metrics.removeFirst(self.metrics.count - self.maxMetricsCount)
            }
        }

        // Log to console for debugging
        print("""

        ═══════════════════════════════════════════════
        [ParserPerformanceMonitor] \(metrics.parserType):
        ───────────────────────────────────────────────
        ⏱ Time: \(String(format: "%.2f", metrics.processingTime * 1000))ms
        📦 Components: \(metrics.componentsExtracted)
        💰 Credits: ₹\(String(format: "%.2f", metrics.credits))
        💸 Debits: ₹\(String(format: "%.2f", metrics.debits))
        🕐 Timestamp: \(DateFormatter.localizedString(from: metrics.timestamp, dateStyle: .short, timeStyle: .medium))
        ═══════════════════════════════════════════════

        """)
    }

    /// Gets average processing time for a specific parser type
    /// - Parameter parserType: The parser type to analyze
    /// - Returns: Average processing time in seconds
    func getAverageProcessingTime(for parserType: String) -> TimeInterval {
        var totalTime: TimeInterval = 0
        var count = 0

        queue.sync {
            let filtered = metrics.filter { $0.parserType == parserType }
            count = filtered.count
            totalTime = filtered.reduce(0) { $0 + $1.processingTime }
        }

        guard count > 0 else { return 0 }
        return totalTime / Double(count)
    }

    /// Gets average component count for a specific parser type
    /// - Parameter parserType: The parser type to analyze
    /// - Returns: Average number of components extracted
    func getAverageComponentCount(for parserType: String) -> Double {
        var totalComponents = 0
        var count = 0

        queue.sync {
            let filtered = metrics.filter { $0.parserType == parserType }
            count = filtered.count
            totalComponents = filtered.reduce(0) { $0 + $1.componentsExtracted }
        }

        guard count > 0 else { return 0 }
        return Double(totalComponents) / Double(count)
    }

    /// Gets all metrics for a specific parser type
    /// - Parameter parserType: The parser type
    /// - Returns: Array of metrics
    func getMetrics(for parserType: String) -> [PerformanceMetrics] {
        var result: [PerformanceMetrics] = []
        queue.sync {
            result = metrics.filter { $0.parserType == parserType }
        }
        return result
    }

    /// Gets comparison statistics between two parser types
    /// - Parameters:
    ///   - parserType1: First parser type
    ///   - parserType2: Second parser type
    /// - Returns: Comparison summary string
    func getComparisonSummary(parserType1: String, parserType2: String) -> String {
        let time1 = getAverageProcessingTime(for: parserType1)
        let time2 = getAverageProcessingTime(for: parserType2)
        let components1 = getAverageComponentCount(for: parserType1)
        let components2 = getAverageComponentCount(for: parserType2)

        let count1 = getMetrics(for: parserType1).count
        let count2 = getMetrics(for: parserType2).count

        let timeDiff = ((time1 - time2) / time2) * 100
        let componentsDiff = ((components1 - components2) / components2) * 100

        return """

        ╔═══════════════════════════════════════════════════╗
        ║         PARSER PERFORMANCE COMPARISON             ║
        ╠═══════════════════════════════════════════════════╣
        ║ \(parserType1.padding(toLength: 24, withPad: " ", startingAt: 0)) vs \(parserType2.padding(toLength: 24, withPad: " ", startingAt: 0)) ║
        ║───────────────────────────────────────────────────║
        ║ PROCESSING TIME:                                  ║
        ║   \(parserType1): \(String(format: "%.2f", time1 * 1000))ms (n=\(count1))          ║
        ║   \(parserType2): \(String(format: "%.2f", time2 * 1000))ms (n=\(count2))          ║
        ║   Difference: \(String(format: "%+.1f", timeDiff))%                  ║
        ║───────────────────────────────────────────────────║
        ║ COMPONENTS EXTRACTED:                             ║
        ║   \(parserType1): \(String(format: "%.1f", components1)) avg              ║
        ║   \(parserType2): \(String(format: "%.1f", components2)) avg              ║
        ║   Difference: \(String(format: "%+.1f", componentsDiff))%                  ║
        ╚═══════════════════════════════════════════════════╝

        """
    }

    /// Clears all stored metrics
    func clearMetrics() {
        queue.async(flags: .barrier) {
            self.metrics.removeAll()
        }
        print("[ParserPerformanceMonitor] All metrics cleared")
    }

    /// Gets total metrics count
    /// - Returns: Total number of stored metrics
    func getTotalMetricsCount() -> Int {
        var count = 0
        queue.sync {
            count = metrics.count
        }
        return count
    }

    /// Exports metrics to JSON for analysis
    /// - Returns: JSON string representation of metrics
    func exportMetricsAsJSON() -> String? {
        var metricsData: [[String: Any]] = []

        queue.sync {
            metricsData = metrics.map { metric in
                [
                    "parserType": metric.parserType,
                    "processingTime": metric.processingTime * 1000, // in ms
                    "componentsExtracted": metric.componentsExtracted,
                    "credits": metric.credits,
                    "debits": metric.debits,
                    "timestamp": ISO8601DateFormatter().string(from: metric.timestamp)
                ]
            }
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: metricsData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }
}
