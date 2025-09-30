import Foundation

/// Protocol for performance metrics tracking and monitoring
protocol PerformanceMetricsProtocol: ObservableObject {
    /// Current frames per second
    var currentFPS: Double { get }

    /// Average frames per second
    var averageFPS: Double { get }

    /// Current memory usage in bytes
    var memoryUsage: UInt64 { get }

    /// Time to first render in milliseconds
    var timeToFirstRender: [String: TimeInterval] { get }

    /// View redraw counts
    var viewRedrawCounts: [String: Int] { get }

    /// CPU usage percentage (0-100)
    var cpuUsage: Double { get }

    /// Starts performance monitoring
    func startMonitoring()

    /// Stops performance monitoring
    func stopMonitoring()

    /// Records a view render event
    /// - Parameters:
    ///   - viewName: The name of the view
    ///   - renderTime: Time taken to render in milliseconds
    func recordViewRender(viewName: String, renderTime: TimeInterval)

    /// Records memory usage at a point in time
    func recordMemoryUsage()

    /// Gets performance statistics for a time period
    /// - Parameter timeRange: The time range to analyze
    /// - Returns: Performance statistics
    func getPerformanceStats(for timeRange: TimeInterval) -> PerformanceStats

    /// Resets all performance metrics
    func resetMetrics()
}

/// Structure for performance statistics
struct PerformanceStats {
    let averageFPS: Double
    let peakMemoryUsage: UInt64
    let totalViewRenders: Int
    let averageRenderTime: TimeInterval
}
