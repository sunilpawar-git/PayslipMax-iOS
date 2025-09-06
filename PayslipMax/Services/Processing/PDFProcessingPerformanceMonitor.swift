import Foundation

/// Performance monitoring service for PDF processing operations
/// Tracks processing times, success rates, and optimization effectiveness
final class PDFProcessingPerformanceMonitor {
    
    // MARK: - Properties
    
    /// Storage for active processing sessions
    private var activeSessions: [String: ProcessingSession] = [:]
    
    /// Historical performance metrics
    private var performanceHistory: [PerformanceMetric] = []
    
    /// Maximum number of metrics to retain in memory
    private let maxHistorySize: Int = 1000
    
    // MARK: - Public Interface
    
    /// Starts monitoring a processing session
    /// - Parameters:
    ///   - id: Unique identifier for the processing session
    ///   - dataSize: Size of PDF data being processed in bytes
    func startProcessing(id: String, dataSize: Int) {
        let session = ProcessingSession(
            id: id,
            startTime: Date(),
            dataSize: dataSize
        )
        
        activeSessions[id] = session
        print("[PDFProcessingPerformanceMonitor] Started monitoring session: \(id)")
    }
    
    /// Records successful completion of processing
    /// - Parameters:
    ///   - id: Processing session identifier
    ///   - mode: Processing mode used
    func recordSuccess(id: String, mode: PDFProcessingMode) {
        guard let session = activeSessions.removeValue(forKey: id) else {
            print("[PDFProcessingPerformanceMonitor] Warning: No active session found for id: \(id)")
            return
        }
        
        let processingTime = Date().timeIntervalSince(session.startTime)
        let metric = PerformanceMetric(
            sessionId: id,
            processingMode: mode,
            dataSize: session.dataSize,
            processingTime: processingTime,
            success: true,
            timestamp: Date()
        )
        
        addMetric(metric)
        print("[PDFProcessingPerformanceMonitor] Recorded success for \(mode.rawValue): \(String(format: "%.3f", processingTime))s")
    }
    
    /// Records fallback to legacy processing
    /// - Parameters:
    ///   - id: Processing session identifier
    ///   - error: Error that caused fallback
    func recordFallback(id: String, error: Error) {
        guard let session = activeSessions.removeValue(forKey: id) else {
            print("[PDFProcessingPerformanceMonitor] Warning: No active session found for fallback: \(id)")
            return
        }
        
        let processingTime = Date().timeIntervalSince(session.startTime)
        let metric = PerformanceMetric(
            sessionId: id,
            processingMode: .legacy,
            dataSize: session.dataSize,
            processingTime: processingTime,
            success: false,
            timestamp: Date(),
            errorDescription: error.localizedDescription
        )
        
        addMetric(metric)
        print("[PDFProcessingPerformanceMonitor] Recorded fallback: \(error.localizedDescription)")
    }
    
    /// Gets current performance statistics
    /// - Returns: Performance statistics summary
    func getPerformanceStatistics() -> PerformanceStatistics {
        let recentMetrics = getRecentMetrics(hours: 24)
        
        return PerformanceStatistics(
            totalSessions: recentMetrics.count,
            enhancedModeSuccess: calculateSuccessRate(for: .enhanced, in: recentMetrics),
            dualModeSuccess: calculateSuccessRate(for: .dualMode, in: recentMetrics),
            legacyModeUsage: calculateUsageRate(for: .legacy, in: recentMetrics),
            averageProcessingTime: calculateAverageProcessingTime(in: recentMetrics),
            averageDataSize: calculateAverageDataSize(in: recentMetrics)
        )
    }
    
    /// Clears old performance metrics to manage memory usage
    func cleanupOldMetrics() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        performanceHistory.removeAll { $0.timestamp < cutoffDate }
        
        // Also enforce maximum history size
        if performanceHistory.count > maxHistorySize {
            performanceHistory = Array(performanceHistory.suffix(maxHistorySize))
        }
        
        print("[PDFProcessingPerformanceMonitor] Cleaned up old metrics, retained \(performanceHistory.count) entries")
    }
    
    // MARK: - Private Implementation
    
    /// Adds a performance metric to the history
    /// - Parameter metric: Performance metric to add
    private func addMetric(_ metric: PerformanceMetric) {
        performanceHistory.append(metric)
        
        // Periodically clean up old metrics
        if performanceHistory.count % 100 == 0 {
            cleanupOldMetrics()
        }
    }
    
    /// Gets metrics from recent time period
    /// - Parameter hours: Number of hours to look back
    /// - Returns: Array of recent metrics
    private func getRecentMetrics(hours: Int) -> [PerformanceMetric] {
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        return performanceHistory.filter { $0.timestamp >= cutoffDate }
    }
    
    /// Calculates success rate for a specific processing mode
    /// - Parameters:
    ///   - mode: Processing mode to analyze
    ///   - metrics: Metrics to analyze
    /// - Returns: Success rate as percentage (0.0 to 100.0)
    private func calculateSuccessRate(for mode: PDFProcessingMode, in metrics: [PerformanceMetric]) -> Double {
        let modeMetrics = metrics.filter { $0.processingMode == mode }
        guard !modeMetrics.isEmpty else { return 0.0 }
        
        let successCount = modeMetrics.filter { $0.success }.count
        return (Double(successCount) / Double(modeMetrics.count)) * 100.0
    }
    
    /// Calculates usage rate for a specific processing mode
    /// - Parameters:
    ///   - mode: Processing mode to analyze
    ///   - metrics: Metrics to analyze
    /// - Returns: Usage rate as percentage (0.0 to 100.0)
    private func calculateUsageRate(for mode: PDFProcessingMode, in metrics: [PerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0.0 }
        
        let modeCount = metrics.filter { $0.processingMode == mode }.count
        return (Double(modeCount) / Double(metrics.count)) * 100.0
    }
    
    /// Calculates average processing time from metrics
    /// - Parameter metrics: Metrics to analyze
    /// - Returns: Average processing time in seconds
    private func calculateAverageProcessingTime(in metrics: [PerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0.0 }
        
        let totalTime = metrics.reduce(0.0) { $0 + $1.processingTime }
        return totalTime / Double(metrics.count)
    }
    
    /// Calculates average data size from metrics
    /// - Parameter metrics: Metrics to analyze
    /// - Returns: Average data size in bytes
    private func calculateAverageDataSize(in metrics: [PerformanceMetric]) -> Int {
        guard !metrics.isEmpty else { return 0 }
        
        let totalSize = metrics.reduce(0) { $0 + $1.dataSize }
        return totalSize / metrics.count
    }
}

// MARK: - Supporting Types

/// Represents an active processing session
private struct ProcessingSession {
    let id: String
    let startTime: Date
    let dataSize: Int
}

/// Represents a completed performance metric
struct PerformanceMetric {
    let sessionId: String
    let processingMode: PDFProcessingMode
    let dataSize: Int
    let processingTime: TimeInterval
    let success: Bool
    let timestamp: Date
    let errorDescription: String?
    
    init(
        sessionId: String,
        processingMode: PDFProcessingMode,
        dataSize: Int,
        processingTime: TimeInterval,
        success: Bool,
        timestamp: Date,
        errorDescription: String? = nil
    ) {
        self.sessionId = sessionId
        self.processingMode = processingMode
        self.dataSize = dataSize
        self.processingTime = processingTime
        self.success = success
        self.timestamp = timestamp
        self.errorDescription = errorDescription
    }
}

/// Performance statistics summary
struct PerformanceStatistics {
    let totalSessions: Int
    let enhancedModeSuccess: Double
    let dualModeSuccess: Double
    let legacyModeUsage: Double
    let averageProcessingTime: Double
    let averageDataSize: Int
    
    /// Formatted description of performance statistics
    var description: String {
        return """
        Performance Statistics (24h):
        - Total Sessions: \(totalSessions)
        - Enhanced Mode Success: \(String(format: "%.1f", enhancedModeSuccess))%
        - Dual Mode Success: \(String(format: "%.1f", dualModeSuccess))%
        - Legacy Mode Usage: \(String(format: "%.1f", legacyModeUsage))%
        - Average Processing Time: \(String(format: "%.3f", averageProcessingTime))s
        - Average Data Size: \(averageDataSize) bytes
        """
    }
}
