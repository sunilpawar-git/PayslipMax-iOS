import Foundation

/// Default implementation of the ExtractionAnalyticsProtocol
@available(*, deprecated, message: "Use AsyncExtractionAnalytics instead")
class DefaultExtractionAnalytics: ExtractionAnalyticsProtocol, @unchecked Sendable {
    // MARK: - Private Properties
    
    /// UserDefaults key for storing analytics data
    private let analyticsStoreKey = "extractionAnalyticsData"
    
    /// In-memory cache of analytics data
    private var analyticsCache: [String: [ExtractionEvent]] = [:]
    
    /// Queue for synchronizing access to analytics data
    private let analyticsQueue = DispatchQueue(label: "com.payslipmax.extractionAnalytics", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        loadAnalyticsData()
    }
    
    // MARK: - ExtractionAnalyticsProtocol
    
    /// Record a successful extraction using a specific pattern
    func recordSuccessfulExtraction(patternKey: String, extractionTime: TimeInterval) async {
        let event = ExtractionEvent(
            type: .success,
            timestamp: Date(),
            extractionTime: extractionTime,
            errorType: nil,
            userFeedback: nil
        )
        
        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Record a failed extraction using a specific pattern
    func recordFailedExtraction(patternKey: String, extractionTime: TimeInterval, errorType: String?) async {
        let event = ExtractionEvent(
            type: .failure,
            timestamp: Date(),
            extractionTime: extractionTime,
            errorType: errorType,
            userFeedback: nil
        )
        
        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Get performance data for all patterns
    func getPatternPerformanceData() async -> [PatternPerformance] {
        // Use a synchronous function to avoid the warning about no async operations
        let performanceData = analyticsQueue.sync {
            var performanceData: [PatternPerformance] = []
            
            for (patternKey, events) in analyticsCache {
                performanceData.append(calculatePerformance(forEvents: events, patternKey: patternKey))
            }
            
            return performanceData
        }
        
        return performanceData
    }
    
    /// Get performance data for a specific pattern
    func getPatternPerformance(forKey key: String) async -> PatternPerformance? {
        // Use a synchronous function to avoid the warning about no async operations
        let performance = analyticsQueue.sync { () -> PatternPerformance? in
            guard let events = analyticsCache[key] else {
                return nil
            }
            
            return calculatePerformance(forEvents: events, patternKey: key)
        }
        
        return performance
    }
    
    /// Record feedback about extraction accuracy
    func recordExtractionFeedback(patternKey: String, isAccurate: Bool, userCorrection: String?) async {
        let event = ExtractionEvent(
            type: .feedback,
            timestamp: Date(),
            extractionTime: nil,
            errorType: nil,
            userFeedback: UserFeedback(isAccurate: isAccurate, correction: userCorrection)
        )
        
        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Reset analytics data for testing purposes
    func resetAnalytics() async {
        // Use Task to properly execute the async operation
        Task {
            analyticsQueue.async(flags: .barrier) {
                // Create a local copy to avoid accessing self
                let cache = [String: [ExtractionEvent]]()
                UserDefaults.standard.removeObject(forKey: self.analyticsStoreKey)
                
                // Use a synchronous update after the async operation
                self.analyticsCache = cache
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Record an event for a specific pattern
    private func recordEvent(_ event: ExtractionEvent, forPatternKey patternKey: String) async {
        // Use Task to properly execute the async operation
        Task {
            // Initialize events array before using it in closures
            var eventsToUpdate: [ExtractionEvent] = []
            
            // First get the current events synchronously
            analyticsQueue.sync {
                eventsToUpdate = self.analyticsCache[patternKey] ?? []
                eventsToUpdate.append(event)
            }
            
            // Then update with a barrier
            analyticsQueue.async(flags: .barrier) {
                self.analyticsCache[patternKey] = eventsToUpdate
                self.saveAnalyticsData()
            }
        }
    }
    
    /// Calculate performance metrics from events
    private func calculatePerformance(forEvents events: [ExtractionEvent], patternKey: String) -> PatternPerformance {
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
    
    /// Load analytics data from UserDefaults
    private func loadAnalyticsData() {
        analyticsQueue.async(flags: .barrier) {
            if let data = UserDefaults.standard.data(forKey: self.analyticsStoreKey) {
                do {
                    let decoder = JSONDecoder()
                    let analyticsData = try decoder.decode([String: [ExtractionEvent]].self, from: data)
                    self.analyticsCache = analyticsData
                } catch {
                    print("Error loading extraction analytics data: \(error)")
                    self.analyticsCache = [:]
                }
            }
        }
    }
    
    /// Save analytics data to UserDefaults
    private func saveAnalyticsData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(analyticsCache)
            UserDefaults.standard.set(data, forKey: analyticsStoreKey)
        } catch {
            print("Error saving extraction analytics data: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// Represents an extraction event for analytics
private struct ExtractionEvent: Codable, Sendable {
    /// Type of event
    let type: ExtractionEventType
    
    /// When the event occurred
    let timestamp: Date
    
    /// Time taken for extraction (if applicable)
    let extractionTime: TimeInterval?
    
    /// Error type for failures (if applicable)
    let errorType: String?
    
    /// User feedback (if applicable)
    let userFeedback: UserFeedback?
    
    /// Coding keys
    enum CodingKeys: String, CodingKey {
        case type, timestamp, extractionTime, errorType, userFeedback
    }
    
    /// Encode event
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(extractionTime, forKey: .extractionTime)
        try container.encodeIfPresent(errorType, forKey: .errorType)
        try container.encodeIfPresent(userFeedback, forKey: .userFeedback)
    }
    
    /// Decode event
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeRawValue = try container.decode(String.self, forKey: .type)
        type = ExtractionEventType(rawValue: typeRawValue) ?? .failure
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        extractionTime = try container.decodeIfPresent(TimeInterval.self, forKey: .extractionTime)
        errorType = try container.decodeIfPresent(String.self, forKey: .errorType)
        userFeedback = try container.decodeIfPresent(UserFeedback.self, forKey: .userFeedback)
    }
    
    /// Initialize with values
    init(type: ExtractionEventType, timestamp: Date, extractionTime: TimeInterval?, errorType: String?, userFeedback: UserFeedback?) {
        self.type = type
        self.timestamp = timestamp
        self.extractionTime = extractionTime
        self.errorType = errorType
        self.userFeedback = userFeedback
    }
}

/// Represents user feedback on extraction accuracy
private struct UserFeedback: Codable, Sendable {
    /// Whether the extraction was accurate
    let isAccurate: Bool
    
    /// User-provided correction (if not accurate)
    let correction: String?
} 