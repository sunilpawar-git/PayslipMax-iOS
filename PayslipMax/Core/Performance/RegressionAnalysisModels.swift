import Foundation

// MARK: - Regression Analysis Models

/// Complete regression analysis results
struct RegressionAnalysis {
    let timestamp: Date
    let baselineTimestamp: Date
    let currentMetrics: BaselineSnapshot
    let baselineMetrics: BaselineSnapshot
    let parsingRegressions: [ParsingRegression]
    let cacheRegressions: [CacheRegression]
    let memoryRegressions: [MemoryRegression]
    let efficiencyRegressions: [EfficiencyRegression]
    let overallSeverity: RegressionSeverity
    
    /// Total number of regressions detected
    var totalRegressions: Int {
        parsingRegressions.count + cacheRegressions.count + 
        memoryRegressions.count + efficiencyRegressions.count
    }
    
    /// Check if any critical regressions were detected
    var hasCriticalRegressions: Bool {
        overallSeverity == .critical
    }
    
    /// Generate regression report
    func generateReport() -> String {
        var report = """
        🚨 REGRESSION ANALYSIS REPORT
        Analysis Time: \(timestamp.formatted())
        Baseline: \(baselineTimestamp.formatted())
        Overall Severity: \(overallSeverity)
        Total Regressions: \(totalRegressions)
        
        """
        
        if !parsingRegressions.isEmpty {
            report += "📊 PARSING REGRESSIONS (\(parsingRegressions.count)):\n"
            for regression in parsingRegressions {
                report += "  • \(regression.system): \(regression.type) (\(String(format: "%.1f", regression.percentageChange))% \(regression.severity))\n"
            }
            report += "\n"
        }
        
        if !cacheRegressions.isEmpty {
            report += "🗄️ CACHE REGRESSIONS (\(cacheRegressions.count)):\n"
            for regression in cacheRegressions {
                report += "  • \(regression.cacheSystem): \(regression.type) (\(String(format: "%.1f", regression.percentageChange))% \(regression.severity))\n"
            }
            report += "\n"
        }
        
        if !memoryRegressions.isEmpty {
            report += "🧠 MEMORY REGRESSIONS (\(memoryRegressions.count)):\n"
            for regression in memoryRegressions {
                report += "  • \(regression.type) (\(String(format: "%.1f", regression.percentageChange))% \(regression.severity))\n"
            }
            report += "\n"
        }
        
        if !efficiencyRegressions.isEmpty {
            report += "⚡ EFFICIENCY REGRESSIONS (\(efficiencyRegressions.count)):\n"
            for regression in efficiencyRegressions {
                report += "  • \(regression.type) (\(String(format: "%.1f", regression.percentageChange))% \(regression.severity))\n"
            }
            report += "\n"
        }
        
        if totalRegressions == 0 {
            report += "✅ NO REGRESSIONS DETECTED - Performance maintained or improved!\n"
        }
        
        return report
    }
}

// MARK: - Regression Severity

enum RegressionSeverity: String, CaseIterable, Comparable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    static func < (lhs: RegressionSeverity, rhs: RegressionSeverity) -> Bool {
        let order: [RegressionSeverity] = [.none, .low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Parsing Regressions

struct ParsingRegression {
    let type: ParsingRegressionType
    let system: String
    let baselineValue: Double
    let currentValue: Double
    let percentageChange: Double
    let severity: RegressionSeverity
}

enum ParsingRegressionType: String {
    case processingTimeIncrease = "Processing Time Increase"
    case successRateDecrease = "Success Rate Decrease"
    case memoryUsageIncrease = "Memory Usage Increase"
    case accuracyDecrease = "Accuracy Decrease"
    case throughputDecrease = "Throughput Decrease"
}

// MARK: - Cache Regressions

struct CacheRegression {
    let type: CacheRegressionType
    let cacheSystem: String
    let baselineValue: Double
    let currentValue: Double
    let percentageChange: Double
    let severity: RegressionSeverity
}

enum CacheRegressionType: String {
    case hitRateDecrease = "Hit Rate Decrease"
    case memoryUsageIncrease = "Memory Usage Increase"
    case responseTimeIncrease = "Response Time Increase"
    case evictionRateIncrease = "Eviction Rate Increase"
    case missRateIncrease = "Miss Rate Increase"
}

// MARK: - Memory Regressions

struct MemoryRegression {
    let type: MemoryRegressionType
    let baselineValue: Double
    let currentValue: Double
    let percentageChange: Double
    let severity: RegressionSeverity
}

enum MemoryRegressionType: String {
    case peakMemoryIncrease = "Peak Memory Increase"
    case averageMemoryIncrease = "Average Memory Increase"
    case memoryVariabilityIncrease = "Memory Variability Increase"
    case memoryLeakDetected = "Memory Leak Detected"
    case pressureThresholdExceeded = "Pressure Threshold Exceeded"
}

// MARK: - Efficiency Regressions

struct EfficiencyRegression {
    let type: EfficiencyRegressionType
    let baselineValue: Double
    let currentValue: Double
    let percentageChange: Double
    let severity: RegressionSeverity
}

enum EfficiencyRegressionType: String {
    case redundancyIncrease = "Redundancy Increase"
    case resourceUtilizationDecrease = "Resource Utilization Decrease"
    case concurrencyEfficiencyDecrease = "Concurrency Efficiency Decrease"
    case bottleneckIntroduced = "Bottleneck Introduced"
    case operationOverheadIncrease = "Operation Overhead Increase"
}

// MARK: - Regression Action Recommendations

enum RegressionActionRecommendation {
    case continueWithCaution
    case investigateIssue
    case rollbackChanges
    case emergencyRollback
    
    static func recommendation(for severity: RegressionSeverity, regressionCount: Int) -> RegressionActionRecommendation {
        switch severity {
        case .none:
            return .continueWithCaution
        case .low:
            return regressionCount > 5 ? .investigateIssue : .continueWithCaution
        case .medium:
            return regressionCount > 3 ? .rollbackChanges : .investigateIssue
        case .high:
            return .rollbackChanges
        case .critical:
            return .emergencyRollback
        }
    }
    
    var description: String {
        switch self {
        case .continueWithCaution:
            return "Continue with implementation but monitor closely"
        case .investigateIssue:
            return "Investigate the root cause before proceeding"
        case .rollbackChanges:
            return "Consider rolling back recent changes"
        case .emergencyRollback:
            return "Emergency rollback required - critical performance impact"
        }
    }
}

// MARK: - Performance Trend Analysis

struct PerformanceTrend {
    let metric: String
    let values: [Double]
    let timestamps: [Date]
    let trendDirection: TrendDirection
    let volatility: Double
    
    enum TrendDirection {
        case improving
        case stable
        case degrading
        case volatile
    }
}

// MARK: - Baseline Comparison Summary

struct BaselineComparisonSummary {
    let metric: String
    let baselineValue: Double
    let currentValue: Double
    let change: Double
    let changePercentage: Double
    let isRegression: Bool
    let severity: RegressionSeverity
    
    var changeDescription: String {
        let direction = change >= 0 ? "increased" : "decreased"
        return "\(metric) \(direction) by \(String(format: "%.1f", abs(changePercentage)))%"
    }
}

// MARK: - Performance Alert

struct PerformanceAlert {
    let timestamp: Date
    let severity: RegressionSeverity
    let title: String
    let description: String
    let affectedSystems: [String]
    let recommendedAction: RegressionActionRecommendation
    let alertId: UUID = UUID()
    
    var isActionRequired: Bool {
        severity.rawValue != "None" && severity.rawValue != "Low"
    }
}
