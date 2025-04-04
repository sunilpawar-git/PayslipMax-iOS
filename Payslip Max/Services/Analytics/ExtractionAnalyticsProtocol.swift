import Foundation

/// Protocol defining methods for tracking extraction analytics
protocol ExtractionAnalyticsProtocol {
    /// Record a successful extraction using a specific pattern
    /// - Parameters:
    ///   - patternKey: The key of the pattern used for extraction
    ///   - extractionTime: The time taken for extraction in seconds
    func recordSuccessfulExtraction(patternKey: String, extractionTime: TimeInterval) async
    
    /// Record a failed extraction using a specific pattern
    /// - Parameters:
    ///   - patternKey: The key of the pattern used for extraction
    ///   - extractionTime: The time taken for extraction in seconds
    ///   - errorType: Optional error type describing the failure reason
    func recordFailedExtraction(patternKey: String, extractionTime: TimeInterval, errorType: String?) async
    
    /// Get performance data for all patterns
    /// - Returns: Array of pattern performance data
    func getPatternPerformanceData() async -> [PatternPerformance]
    
    /// Get performance data for a specific pattern
    /// - Parameter key: The pattern key to get performance for
    /// - Returns: Performance data if available, nil otherwise
    func getPatternPerformance(forKey key: String) async -> PatternPerformance?
    
    /// Record feedback about extraction accuracy
    /// - Parameters:
    ///   - patternKey: The key of the pattern used for extraction
    ///   - isAccurate: Whether the extraction result was accurate
    ///   - userCorrection: Optional user-provided correction
    func recordExtractionFeedback(patternKey: String, isAccurate: Bool, userCorrection: String?) async
    
    /// Reset analytics data (primarily for testing)
    func resetAnalytics() async
}

/// Type of extraction event for analytics
enum ExtractionEventType: String, Codable, Sendable {
    case success
    case failure
    case feedback
}

/// Performance metrics for a pattern
struct PatternPerformance: Codable, Sendable {
    /// Pattern identifier
    let patternKey: String
    
    /// Success rate (0.0-1.0)
    let successRate: Double
    
    /// Number of times the pattern has been used for extraction
    let extractionCount: Int
    
    /// Average time taken for extraction
    let averageExtractionTime: TimeInterval
    
    /// Date when the pattern was last used
    let lastUsed: Date?
    
    /// Rate of user-reported accuracy (0.0-1.0)
    let userAccuracyRate: Double
} 