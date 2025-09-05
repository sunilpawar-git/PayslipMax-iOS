import Foundation

/// Performance regression detection system for parsing system unification
/// 
/// This service monitors performance during the parsing system unification process
/// and detects regressions against established baselines. It provides early warning
/// of performance issues and enables quick rollback decisions.
@MainActor
final class PerformanceRegressionDetector {
    
    // MARK: - Configuration
    
    /// Regression detection thresholds
    struct RegressionThresholds {
        let processingTimeIncrease: Double = 0.20  // 20% slower is a regression
        let memoryUsageIncrease: Double = 0.25     // 25% more memory is a regression
        let cacheHitRateDecrease: Double = 0.15    // 15% lower hit rate is a regression
        let successRateDecrease: Double = 0.05     // 5% lower success rate is a regression
        let redundancyIncrease: Double = 0.30      // 30% more redundancy is a regression
        
        static let `default` = RegressionThresholds()
        static let strict = RegressionThresholds()
    }
    
    // MARK: - Properties
    
    internal let thresholds: RegressionThresholds
    private var baselineSnapshot: BaselineSnapshot?
    private var regressionHistory: [RegressionAnalysis] = []
    
    // MARK: - Initialization
    
    init(thresholds: RegressionThresholds = .default) {
        self.thresholds = thresholds
    }
    
    // MARK: - Baseline Management
    
    /// Set the baseline snapshot for regression detection
    /// - Parameter baseline: The baseline metrics to compare against
    func setBaseline(_ baseline: BaselineSnapshot) {
        self.baselineSnapshot = baseline
        print("📊 Baseline established for regression detection")
        print("Baseline: \(baseline.generateSummaryReport())")
    }
    
    /// Detect regressions by comparing current metrics to baseline
    /// - Parameter currentMetrics: Current performance metrics
    /// - Returns: Regression analysis results
    func detectRegressions(currentMetrics: BaselineSnapshot) throws -> RegressionAnalysis {
        guard let baseline = baselineSnapshot else {
            throw RegressionDetectionError.noBaselineSet
        }
        
        print("🔍 Analyzing performance for regressions...")
        
        let analysis = RegressionAnalysis(
            timestamp: Date(),
            baselineTimestamp: baseline.timestamp,
            currentMetrics: currentMetrics,
            baselineMetrics: baseline,
            parsingRegressions: detectParsingRegressions(baseline: baseline.parsingMetrics, current: currentMetrics.parsingMetrics),
            cacheRegressions: detectCacheRegressions(baseline: baseline.cacheMetrics, current: currentMetrics.cacheMetrics),
            memoryRegressions: detectMemoryRegressions(baseline: baseline.memoryMetrics, current: currentMetrics.memoryMetrics),
            efficiencyRegressions: detectEfficiencyRegressions(baseline: baseline.processingMetrics, current: currentMetrics.processingMetrics),
            overallSeverity: .none // Will be calculated
        )
        
        // Calculate overall severity
        let updatedAnalysis = calculateOverallSeverity(analysis)
        regressionHistory.append(updatedAnalysis)
        
        // Log results
        logRegressionResults(updatedAnalysis)
        
        return updatedAnalysis
    }
    
    
    // MARK: - Helper Methods
    
    func calculateSeverity(_ change: Double, threshold: Double) -> RegressionSeverity {
        if change > threshold * 3 {
            return .critical
        } else if change > threshold * 2 {
            return .high
        } else if change > threshold {
            return .medium
        } else {
            return .low
        }
    }
    
}

// MARK: - Error Types

enum RegressionDetectionError: Error {
    case noBaselineSet
    case insufficientData
    case invalidComparison
}
