import Foundation

/// Protocol for calculating analytics performance metrics
protocol AnalyticsPerformanceCalculatorProtocol {
    /// Calculate performance metrics from events
    func calculatePerformance(forEvents events: [ExtractionEvent], patternKey: String) -> PatternPerformance
}

/// Implementation of performance calculator
class AnalyticsPerformanceCalculator: AnalyticsPerformanceCalculatorProtocol {
    func calculatePerformance(forEvents events: [ExtractionEvent], patternKey: String) -> PatternPerformance {
        let extractionEvents = events.filter { $0.type == .success || $0.type == .failure }
        let successEvents = events.filter { $0.type == .success }
        let feedbackEvents = events.filter { $0.type == .feedback }

        // Calculate success rate
        let successRate = extractionEvents.isEmpty ? 0.0 : Double(successEvents.count) / Double(extractionEvents.count)

        // Calculate average extraction time
        let validExtractionTimes = extractionEvents.compactMap { $0.extractionTime }
        let averageExtractionTime = validExtractionTimes.isEmpty ? 0.0 : validExtractionTimes.reduce(0, +) / Double(validExtractionTimes.count)

        // Calculate user accuracy rate
        let accurateFeedback = feedbackEvents.filter { $0.userFeedback?.isAccurate == true }.count
        let userAccuracyRate = feedbackEvents.isEmpty ? 1.0 : Double(accurateFeedback) / Double(feedbackEvents.count)

        // Find last used date
        let lastUsed = events.map { $0.timestamp }.max()

        return PatternPerformance(
            patternKey: patternKey,
            successRate: successRate,
            extractionCount: extractionEvents.count,
            averageExtractionTime: averageExtractionTime,
            lastUsed: lastUsed,
            userAccuracyRate: userAccuracyRate
        )
    }
}
