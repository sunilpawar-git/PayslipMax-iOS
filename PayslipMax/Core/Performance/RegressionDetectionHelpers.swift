import Foundation

// MARK: - Regression Detection Helper Methods

extension PerformanceRegressionDetector {
    
    // MARK: - Parsing System Regression Detection
    
    func detectParsingRegressions(
        baseline: ParsingSystemMetrics,
        current: ParsingSystemMetrics
    ) -> [ParsingRegression] {
        var regressions: [ParsingRegression] = []
        
        // Check overall processing time regression
        let timeIncrease = (current.averageProcessingTime - baseline.averageProcessingTime) / baseline.averageProcessingTime
        if timeIncrease > thresholds.processingTimeIncrease {
            regressions.append(ParsingRegression(
                type: .processingTimeIncrease,
                system: "Overall",
                baselineValue: baseline.averageProcessingTime,
                currentValue: current.averageProcessingTime,
                percentageChange: timeIncrease * 100,
                severity: calculateSeverity(timeIncrease, threshold: thresholds.processingTimeIncrease)
            ))
        }
        
        // Check success rate regressions for each system
        for (systemName, baselineSuccessRate) in baseline.successRates {
            if let currentSuccessRate = current.successRates[systemName] {
                let successDecrease = (baselineSuccessRate - currentSuccessRate) / baselineSuccessRate
                if successDecrease > thresholds.successRateDecrease {
                    regressions.append(ParsingRegression(
                        type: .successRateDecrease,
                        system: systemName,
                        baselineValue: baselineSuccessRate,
                        currentValue: currentSuccessRate,
                        percentageChange: successDecrease * 100,
                        severity: calculateSeverity(successDecrease, threshold: thresholds.successRateDecrease)
                    ))
                }
            }
        }
        
        // Check memory usage regressions for each system
        for (systemName, baselineMemory) in baseline.memoryUsagePeaks {
            if let currentMemory = current.memoryUsagePeaks[systemName] {
                let memoryIncrease = Double(currentMemory - baselineMemory) / Double(baselineMemory)
                if memoryIncrease > thresholds.memoryUsageIncrease {
                    regressions.append(ParsingRegression(
                        type: .memoryUsageIncrease,
                        system: systemName,
                        baselineValue: Double(baselineMemory),
                        currentValue: Double(currentMemory),
                        percentageChange: memoryIncrease * 100,
                        severity: calculateSeverity(memoryIncrease, threshold: thresholds.memoryUsageIncrease)
                    ))
                }
            }
        }
        
        return regressions
    }
    
    // MARK: - Cache System Regression Detection
    
    func detectCacheRegressions(
        baseline: CacheSystemMetrics,
        current: CacheSystemMetrics
    ) -> [CacheRegression] {
        var regressions: [CacheRegression] = []
        
        // Check overall hit rate regression
        let hitRateDecrease = (baseline.overallHitRate - current.overallHitRate) / baseline.overallHitRate
        if hitRateDecrease > thresholds.cacheHitRateDecrease {
            regressions.append(CacheRegression(
                type: .hitRateDecrease,
                cacheSystem: "Overall",
                baselineValue: baseline.overallHitRate,
                currentValue: current.overallHitRate,
                percentageChange: hitRateDecrease * 100,
                severity: calculateSeverity(hitRateDecrease, threshold: thresholds.cacheHitRateDecrease)
            ))
        }
        
        // Check individual cache system regressions
        for (cacheName, baselineMetrics) in baseline.cacheEffectiveness {
            if let currentMetrics = current.cacheEffectiveness[cacheName] {
                let hitRateDecrease = (baselineMetrics.hitRate - currentMetrics.hitRate) / baselineMetrics.hitRate
                if hitRateDecrease > thresholds.cacheHitRateDecrease {
                    regressions.append(CacheRegression(
                        type: .hitRateDecrease,
                        cacheSystem: cacheName,
                        baselineValue: baselineMetrics.hitRate,
                        currentValue: currentMetrics.hitRate,
                        percentageChange: hitRateDecrease * 100,
                        severity: calculateSeverity(hitRateDecrease, threshold: thresholds.cacheHitRateDecrease)
                    ))
                }
                
                // Check memory usage increase
                let memoryIncrease = Double(currentMetrics.memoryUsage - baselineMetrics.memoryUsage) / Double(baselineMetrics.memoryUsage)
                if memoryIncrease > thresholds.memoryUsageIncrease {
                    regressions.append(CacheRegression(
                        type: .memoryUsageIncrease,
                        cacheSystem: cacheName,
                        baselineValue: Double(baselineMetrics.memoryUsage),
                        currentValue: Double(currentMetrics.memoryUsage),
                        percentageChange: memoryIncrease * 100,
                        severity: calculateSeverity(memoryIncrease, threshold: thresholds.memoryUsageIncrease)
                    ))
                }
            }
        }
        
        return regressions
    }
    
    // MARK: - Memory Regression Detection
    
    func detectMemoryRegressions(
        baseline: MemoryUsageMetrics,
        current: MemoryUsageMetrics
    ) -> [MemoryRegression] {
        var regressions: [MemoryRegression] = []
        
        // Check peak memory usage regression
        let peakMemoryIncrease = Double(current.peakMemoryUsage - baseline.peakMemoryUsage) / Double(baseline.peakMemoryUsage)
        if peakMemoryIncrease > thresholds.memoryUsageIncrease {
            regressions.append(MemoryRegression(
                type: .peakMemoryIncrease,
                baselineValue: Double(baseline.peakMemoryUsage),
                currentValue: Double(current.peakMemoryUsage),
                percentageChange: peakMemoryIncrease * 100,
                severity: calculateSeverity(peakMemoryIncrease, threshold: thresholds.memoryUsageIncrease)
            ))
        }
        
        // Check average memory usage regression
        let avgMemoryIncrease = Double(current.averageMemoryUsage - baseline.averageMemoryUsage) / Double(baseline.averageMemoryUsage)
        if avgMemoryIncrease > thresholds.memoryUsageIncrease {
            regressions.append(MemoryRegression(
                type: .averageMemoryIncrease,
                baselineValue: Double(baseline.averageMemoryUsage),
                currentValue: Double(current.averageMemoryUsage),
                percentageChange: avgMemoryIncrease * 100,
                severity: calculateSeverity(avgMemoryIncrease, threshold: thresholds.memoryUsageIncrease)
            ))
        }
        
        return regressions
    }
    
    // MARK: - Efficiency Regression Detection
    
    func detectEfficiencyRegressions(
        baseline: ProcessingEfficiencyMetrics,
        current: ProcessingEfficiencyMetrics
    ) -> [EfficiencyRegression] {
        var regressions: [EfficiencyRegression] = []
        
        // Check redundancy increase
        let redundancyIncrease = (current.redundancyPercentage - baseline.redundancyPercentage) / baseline.redundancyPercentage
        if redundancyIncrease > thresholds.redundancyIncrease {
            regressions.append(EfficiencyRegression(
                type: .redundancyIncrease,
                baselineValue: baseline.redundancyPercentage,
                currentValue: current.redundancyPercentage,
                percentageChange: redundancyIncrease * 100,
                severity: calculateSeverity(redundancyIncrease, threshold: thresholds.redundancyIncrease)
            ))
        }
        
        return regressions
    }
    
    // MARK: - Analysis Helper Methods
    
    func calculateOverallSeverity(_ analysis: RegressionAnalysis) -> RegressionAnalysis {
        let allSeverities = analysis.parsingRegressions.map(\.severity) +
                           analysis.cacheRegressions.map(\.severity) +
                           analysis.memoryRegressions.map(\.severity) +
                           analysis.efficiencyRegressions.map(\.severity)
        
        let maxSeverity = allSeverities.max() ?? .none
        
        return RegressionAnalysis(
            timestamp: analysis.timestamp,
            baselineTimestamp: analysis.baselineTimestamp,
            currentMetrics: analysis.currentMetrics,
            baselineMetrics: analysis.baselineMetrics,
            parsingRegressions: analysis.parsingRegressions,
            cacheRegressions: analysis.cacheRegressions,
            memoryRegressions: analysis.memoryRegressions,
            efficiencyRegressions: analysis.efficiencyRegressions,
            overallSeverity: maxSeverity
        )
    }
    
    func logRegressionResults(_ analysis: RegressionAnalysis) {
        let totalRegressions = analysis.parsingRegressions.count +
                              analysis.cacheRegressions.count +
                              analysis.memoryRegressions.count +
                              analysis.efficiencyRegressions.count
        
        if totalRegressions == 0 {
            print("✅ No performance regressions detected")
        } else {
            print("⚠️ \(totalRegressions) performance regressions detected - Severity: \(analysis.overallSeverity)")
            
            for regression in analysis.parsingRegressions {
                print("📊 Parsing regression in \(regression.system): \(regression.type) - \(String(format: "%.1f", regression.percentageChange))% change")
            }
            
            for regression in analysis.cacheRegressions {
                print("🗼️ Cache regression in \(regression.cacheSystem): \(regression.type) - \(String(format: "%.1f", regression.percentageChange))% change")
            }
            
            for regression in analysis.memoryRegressions {
                print("🧠 Memory regression: \(regression.type) - \(String(format: "%.1f", regression.percentageChange))% change")
            }
            
            for regression in analysis.efficiencyRegressions {
                print("⚡ Efficiency regression: \(regression.type) - \(String(format: "%.1f", regression.percentageChange))% change")
            }
        }
    }
}
