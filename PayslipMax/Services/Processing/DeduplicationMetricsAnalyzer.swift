import Foundation

/// Analyzes deduplication metrics to provide insights and trend analysis
@MainActor
final class DeduplicationMetricsAnalyzer {
    
    // MARK: - Configuration
    
    private struct AnalyzerConfig {
        static let trendCalculationMinPoints = 5
        static let significantChangeThreshold = 10.0 // 10% change
        static let reliabilityThreshold = 0.8 // 80% confidence
    }
    
    // MARK: - Properties
    
    /// Historical metrics storage
    private var metricsHistory: [Date: DeduplicationMetrics] = [:]
    
    /// Performance baseline
    private var baseline: PerformanceBaseline?
    
    /// Alert thresholds
    private let alertThresholds: AlertThresholds
    
    // MARK: - Initialization
    
    init(alertThresholds: AlertThresholds = AlertThresholds()) {
        self.alertThresholds = alertThresholds
    }
    
    // MARK: - Public Interface
    
    /// Add metrics data point for analysis
    func addMetricsDataPoint(_ metrics: DeduplicationMetrics) {
        metricsHistory[metrics.lastUpdated] = metrics
        pruneOldMetrics()
    }
    
    /// Set performance baseline
    func setBaseline(_ baseline: PerformanceBaseline) {
        self.baseline = baseline
    }
    
    /// Calculate trends from historical data
    func calculateTrends(window: Int = 7) -> MetricsTrends {
        let windowStart = Calendar.current.date(byAdding: .day, value: -window, to: Date()) ?? Date()
        let recentMetrics = metricsHistory.filter { $0.key >= windowStart }.values.sorted { $0.lastUpdated < $1.lastUpdated }
        
        guard recentMetrics.count >= AnalyzerConfig.trendCalculationMinPoints else {
            return MetricsTrends(trendWindow: window, isReliable: false)
        }
        
        return MetricsTrends(
            cacheHitRateTrend: calculateTrend(recentMetrics.map { $0.cacheHitRate }),
            redundancyReductionTrend: calculateTrend(recentMetrics.map { $0.redundancyReduction }),
            processingTimeTrend: calculateTrend(recentMetrics.map { $0.averageProcessingTime }),
            memoryUsageTrend: calculateTrend(recentMetrics.map { Double($0.currentMemoryUsage) }),
            trendWindow: window,
            lastCalculated: Date(),
            isReliable: true
        )
    }
    
    /// Generate performance improvement summary
    func generateImprovementSummary(currentMetrics: DeduplicationMetrics) -> PerformanceImprovementSummary? {
        guard let baseline = baseline, baseline.isValid else { return nil }
        
        let processingTimeImprovement = calculateImprovement(
            baseline: baseline.baselineProcessingTime,
            current: currentMetrics.averageProcessingTime
        )
        
        let memoryUsageImprovement = calculateImprovement(
            baseline: Double(baseline.baselineMemoryUsage),
            current: Double(currentMetrics.currentMemoryUsage)
        )
        
        let cacheEffectivenessImprovement = calculateImprovement(
            baseline: baseline.baselineCacheHitRate,
            current: currentMetrics.cacheHitRate,
            higherIsBetter: true
        )
        
        let overallImprovement = (processingTimeImprovement + memoryUsageImprovement + cacheEffectivenessImprovement) / 3.0
        
        return PerformanceImprovementSummary(
            overallImprovement: overallImprovement,
            processingTimeImprovement: processingTimeImprovement,
            memoryUsageImprovement: memoryUsageImprovement,
            cacheEffectivenessImprovement: cacheEffectivenessImprovement,
            redundancyReductionAchievement: currentMetrics.redundancyReduction,
            generatedAt: Date()
        )
    }
    
    /// Check for performance alerts
    func checkAlerts(currentMetrics: DeduplicationMetrics) -> [DeduplicationPerformanceAlert] {
        var alerts: [DeduplicationPerformanceAlert] = []
        
        // Check redundancy reduction
        if currentMetrics.redundancyReduction < alertThresholds.redundancyReductionBelow {
            let current = String(format: "%.1f", currentMetrics.redundancyReduction)
            let threshold = String(format: "%.1f", alertThresholds.redundancyReductionBelow)
            alerts.append(DeduplicationPerformanceAlert(
                type: .redundancyReductionLow,
                message: "Redundancy reduction (\(current)%) is below threshold (\(threshold)%)",
                severity: .warning,
                timestamp: Date()
            ))
        }

        // Check cache hit rate
        if currentMetrics.cacheHitRate < alertThresholds.cacheHitRateBelow {
            let current = String(format: "%.1f", currentMetrics.cacheHitRate)
            let threshold = String(format: "%.1f", alertThresholds.cacheHitRateBelow)
            alerts.append(DeduplicationPerformanceAlert(
                type: .cacheHitRateLow,
                message: "Cache hit rate (\(current)%) is below threshold (\(threshold)%)",
                severity: .warning,
                timestamp: Date()
            ))
        }

        // Check processing time
        if currentMetrics.averageProcessingTime > alertThresholds.processingTimeAbove {
            let current = String(format: "%.2f", currentMetrics.averageProcessingTime)
            let threshold = String(format: "%.2f", alertThresholds.processingTimeAbove)
            alerts.append(DeduplicationPerformanceAlert(
                type: .processingTimeHigh,
                message: "Average processing time (\(current)s) exceeds threshold (\(threshold)s)",
                severity: .critical,
                timestamp: Date()
            ))
        }
        
        // Check memory usage against baseline
        if let baseline = baseline, baseline.isValid {
            let memoryMultiplier = Double(currentMetrics.currentMemoryUsage) / Double(baseline.baselineMemoryUsage)
            if memoryMultiplier > alertThresholds.memoryUsageMultiplier {
                alerts.append(DeduplicationPerformanceAlert(
                    type: .memoryUsageHigh,
                    message: "Memory usage is \(String(format: "%.1f", memoryMultiplier))x baseline (threshold: \(String(format: "%.1f", alertThresholds.memoryUsageMultiplier))x)",
                    severity: .critical,
                    timestamp: Date()
                ))
            }
        }
        
        return alerts
    }
    
    /// Get metrics insights
    func getInsights(currentMetrics: DeduplicationMetrics) -> [MetricsInsight] {
        var insights: [MetricsInsight] = []
        
        // Cache effectiveness insight
        if currentMetrics.cacheHitRate > 90.0 {
            insights.append(MetricsInsight(
                title: "Excellent Cache Performance",
                description: "Cache hit rate of \(String(format: "%.1f", currentMetrics.cacheHitRate))% indicates optimal cache utilization",
                type: .positive
            ))
        } else if currentMetrics.cacheHitRate < 50.0 {
            insights.append(MetricsInsight(
                title: "Cache Optimization Opportunity",
                description: "Cache hit rate of \(String(format: "%.1f", currentMetrics.cacheHitRate))% suggests room for cache strategy improvement",
                type: .improvement
            ))
        }
        
        // Deduplication effectiveness insight
        if currentMetrics.redundancyReduction > 40.0 {
            insights.append(MetricsInsight(
                title: "High Deduplication Efficiency",
                description: "Reducing \(String(format: "%.1f", currentMetrics.redundancyReduction))% of redundant operations through smart deduplication",
                type: .positive
            ))
        }
        
        // Processing efficiency insight
        if currentMetrics.processingEfficiency > 0.8 {
            insights.append(MetricsInsight(
                title: "Optimal Processing Performance",
                description: "Processing efficiency of \(String(format: "%.1f", currentMetrics.processingEfficiency * 100))% indicates well-optimized pipeline",
                type: .positive
            ))
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        
        let n = Double(values.count)
        let sumX = (1...values.count).reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(1...values.count, values).map { Double($0.0) * $0.1 }.reduce(0, +)
        let sumX2 = (1...values.count).map { Double($0 * $0) }.reduce(0, +)
        
        let slope = (n * sumXY - Double(sumX) * sumY) / (n * sumX2 - Double(sumX) * Double(sumX))
        return slope
    }
    
    private func calculateImprovement(baseline: Double, current: Double, higherIsBetter: Bool = false) -> Double {
        guard baseline > 0 else { return 0.0 }
        
        let change = ((current - baseline) / baseline) * 100.0
        return higherIsBetter ? change : -change
    }
    
    private func pruneOldMetrics() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        metricsHistory = metricsHistory.filter { $0.key >= cutoffDate }
    }
}

// MARK: - Supporting Types

/// Performance alert types
enum PerformanceAlertType: String, CaseIterable, Codable {
    case redundancyReductionLow = "redundancy_reduction_low"
    case cacheHitRateLow = "cache_hit_rate_low"
    case processingTimeHigh = "processing_time_high"
    case memoryUsageHigh = "memory_usage_high"
}

/// Performance alert severity
enum AlertSeverity: String, CaseIterable, Codable {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

/// Performance alert for deduplication metrics
struct DeduplicationPerformanceAlert: Codable, Equatable {
    let type: PerformanceAlertType
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
}

/// Metrics insight types
enum DeduplicationInsightType: String, CaseIterable, Codable {
    case positive = "positive"
    case improvement = "improvement"
    case warning = "warning"
}

/// Metrics insight
struct MetricsInsight: Codable, Equatable {
    let title: String
    let description: String
    let type: DeduplicationInsightType
}
