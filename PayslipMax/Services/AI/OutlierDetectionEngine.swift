import Foundation

/// Engine responsible for outlier detection in financial data
public class OutlierDetectionEngine {

    // MARK: - Public Methods

    /// Detect outlier values in financial data
    func detectOutliers(
        amounts: [String: Double],
        format: LiteRTDocumentFormatType
    ) async throws -> OutlierDetectionResult {

        var outliers: [String: OutlierAnalysis] = [:]
        var totalRisk: Double = 0
        var maxRisk: OutlierRiskLevel = .low

        for (component, value) in amounts {
            if let expectedRange = getExpectedRange(for: component, format: format) {
                let zScore = calculateZScore(value: value, expectedRange: expectedRange)
                let riskLevel = determineOutlierRisk(zScore: zScore)

                if riskLevel != .low {
                    let analysis = OutlierAnalysis(
                        value: value,
                        zScore: zScore,
                        riskLevel: riskLevel,
                        expectedRange: expectedRange,
                        explanation: generateOutlierExplanation(
                            component: component,
                            value: value,
                            range: expectedRange
                        )
                    )
                    outliers[component] = analysis
                    totalRisk += riskLevel.numericValue()
                    
                    // Track the maximum individual risk level
                    if riskLevel.numericValue() > maxRisk.numericValue() {
                        maxRisk = riskLevel
                    }
                }
            }
        }

        let overallRisk = determineOverallRisk(totalRisk: totalRisk, outlierCount: outliers.count, maxRisk: maxRisk)
        let confidence = calculateOutlierConfidence(outliers: outliers, totalComponents: amounts.count)

        return OutlierDetectionResult(
            outliers: outliers,
            overallRisk: overallRisk,
            confidence: confidence
        )
    }

    // MARK: - Private Methods

    /// Get expected range for a component based on format
    private func getExpectedRange(for component: String, format: LiteRTDocumentFormatType) -> ClosedRange<Double>? {
        // Use military constraints as default, can be extended for other formats
        let knownRange = MilitaryPayConstraints.ranges[component]

        // If component is not in known ranges, use dynamic range based on typical military pay values
        if knownRange == nil {
            // For unknown components, assume typical military pay component range
            // This allows outlier detection even for unrecognized components
            return 1_000...100_000 // Typical range for military pay components
        }

        return knownRange
    }

    /// Calculate Z-score for outlier detection
    private func calculateZScore(value: Double, expectedRange: ClosedRange<Double>) -> Double {
        let mean = (expectedRange.lowerBound + expectedRange.upperBound) / 2
        let stdDev = (expectedRange.upperBound - expectedRange.lowerBound) / 6 // Approximation
        return abs(value - mean) / stdDev
    }

    /// Determine outlier risk level from Z-score
    private func determineOutlierRisk(zScore: Double) -> OutlierRiskLevel {
        switch zScore {
        case 0..<2: return .low
        case 2..<3: return .medium
        case 3..<4: return .high
        default: return .extreme
        }
    }

    /// Generate explanation for outlier
    private func generateOutlierExplanation(component: String, value: Double, range: ClosedRange<Double>) -> String {
        return "\(component) value \(value) is outside typical range \(range.lowerBound)-\(range.upperBound)"
    }

    /// Determine overall risk from individual risks
    private func determineOverallRisk(totalRisk: Double, outlierCount: Int, maxRisk: OutlierRiskLevel) -> OutlierRiskLevel {
        // If no outliers, risk is low
        guard outlierCount > 0 else { return .low }
        
        // If any individual component has extreme risk, overall should be extreme
        if maxRisk == .extreme {
            return .extreme
        }
        
        // Use average risk for overall assessment
        let averageRisk = totalRisk / Double(outlierCount)
        
        switch averageRisk {
        case 0..<1.5: return .low
        case 1.5..<2.5: return .medium
        case 2.5..<3.5: return .high
        default: return .extreme
        }
    }

    /// Calculate confidence for outlier detection
    private func calculateOutlierConfidence(outliers: [String: OutlierAnalysis], totalComponents: Int) -> Double {
        let outlierRatio = Double(outliers.count) / Double(totalComponents)
        return 1.0 - outlierRatio
    }
}
