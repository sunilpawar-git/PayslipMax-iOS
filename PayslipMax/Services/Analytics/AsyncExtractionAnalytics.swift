import Foundation

/// Modern async implementation of the ExtractionAnalyticsProtocol
class AsyncExtractionAnalytics: ExtractionAnalyticsProtocol {
    // MARK: - Private Properties
    
    /// UserDefaults key for storing analytics data
    private let analyticsStoreKey = "extractionAnalyticsData.v2"
    
    /// UserDefaults key for storing pattern test data
    private let patternTestStoreKey = "patternTestAnalyticsData.v2"
    
    /// In-memory cache of analytics data
    private var analyticsCache: [String: [ExtractionEvent]] = [:]
    
    /// In-memory cache of pattern test data
    private var patternTestCache: [String: [PatternTestEvent]] = [:]
    
    /// Actor for safe concurrent access to analytics data
    private let store = AnalyticsStore()
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadAnalyticsData()
            await loadPatternTestData()
        }
    }
    
    // MARK: - ExtractionAnalyticsProtocol
    
    /// Record a successful extraction using a specific pattern
    func recordSuccessfulExtraction(patternKey: String, extractionTime: TimeInterval) async {
        let event = ExtractionEvent(
            type: ExtractionEventType.success,
            timestamp: Date(),
            extractionTime: extractionTime,
            errorType: nil as String?,
            userFeedback: nil as ExtractionUserFeedback?
        )
        
        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Record a failed extraction using a specific pattern
    func recordFailedExtraction(patternKey: String, extractionTime: TimeInterval, errorType: String?) async {
        let event = ExtractionEvent(
            type: ExtractionEventType.failure,
            timestamp: Date(),
            extractionTime: extractionTime,
            errorType: errorType,
            userFeedback: nil as ExtractionUserFeedback?
        )

        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Get performance data for all patterns
    func getPatternPerformanceData() async -> [PatternPerformance] {
        let cache = await store.getAnalyticsCache()
        
        var performanceData: [PatternPerformance] = []
        for (patternKey, events) in cache {
            performanceData.append(calculatePerformance(forEvents: events, patternKey: patternKey))
        }
        
        return performanceData
    }
    
    /// Get performance data for a specific pattern
    func getPatternPerformance(forKey key: String) async -> PatternPerformance? {
        let events = await store.getEvents(forKey: key)
        guard let events = events, !events.isEmpty else {
            return nil
        }
        
        return calculatePerformance(forEvents: events, patternKey: key)
    }
    
    /// Record feedback about extraction accuracy
    func recordExtractionFeedback(patternKey: String, isAccurate: Bool, userCorrection: String?) async {
        let event = ExtractionEvent(
            type: ExtractionEventType.feedback,
            timestamp: Date(),
            extractionTime: nil as TimeInterval?,
            errorType: nil as String?,
            userFeedback: ExtractionUserFeedback(isAccurate: isAccurate, correction: userCorrection)
        )

        await recordEvent(event, forPatternKey: patternKey)
    }
    
    /// Record a successful pattern test by pattern ID
    func recordPatternSuccess(patternID: UUID, key: String) async {
        let event = PatternTestEvent(
            patternID: patternID,
            key: key,
            isSuccess: true,
            timestamp: Date()
        )
        
        await recordPatternTestEvent(event)
    }
    
    /// Record a failed pattern test by pattern ID
    func recordPatternFailure(patternID: UUID, key: String) async {
        let event = PatternTestEvent(
            patternID: patternID,
            key: key,
            isSuccess: false,
            timestamp: Date()
        )
        
        await recordPatternTestEvent(event)
    }
    
    /// Get success rate for a specific pattern ID
    func getPatternSuccessRate(patternID: UUID) async -> Double {
        let patternIDString = patternID.uuidString
        let events = await store.getPatternTestEvents(forPatternID: patternIDString)
        
        guard let events = events, !events.isEmpty else {
            return 0.0
        }
        
        let successEvents = events.filter { $0.isSuccess }
        return Double(successEvents.count) / Double(events.count)
    }
    
    /// Reset analytics data
    func resetAnalytics() async {
        await store.resetData()
        await saveAnalyticsData()
        await savePatternTestData()
    }
    
    // MARK: - Private Helper Methods
    
    /// Record an event for a specific pattern
    private func recordEvent(_ event: ExtractionEvent, forPatternKey patternKey: String) async {
        await store.addEvent(event, forKey: patternKey)
        await saveAnalyticsData()
    }
    
    /// Record a pattern test event
    private func recordPatternTestEvent(_ event: PatternTestEvent) async {
        let patternIDString = event.patternID.uuidString
        await store.addPatternTestEvent(event, forPatternID: patternIDString)
        await savePatternTestData()
    }
    
    /// Calculate performance metrics from events
    private func calculatePerformance(forEvents events: [ExtractionEvent], patternKey: String) -> PatternPerformance {
        let extractionEvents = events.filter { $0.type == ExtractionEventType.success || $0.type == ExtractionEventType.failure }
        let successEvents = events.filter { $0.type == ExtractionEventType.success }
        let feedbackEvents = events.filter { $0.type == ExtractionEventType.feedback }
        
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
    private func loadAnalyticsData() async {
        if let data = UserDefaults.standard.data(forKey: analyticsStoreKey) {
            do {
                let decoder = JSONDecoder()
                let analyticsData = try decoder.decode([String: [ExtractionEvent]].self, from: data)
                await store.setAnalyticsCache(analyticsData)
            } catch {
                print("Error loading extraction analytics data: \(error)")
                await store.resetData()
            }
        }
    }
    
    /// Save analytics data to UserDefaults
    private func saveAnalyticsData() async {
        do {
            let encoder = JSONEncoder()
            let analyticsData = await store.getAnalyticsCache()
            let data = try encoder.encode(analyticsData)
            UserDefaults.standard.set(data, forKey: analyticsStoreKey)
        } catch {
            print("Error saving extraction analytics data: \(error)")
        }
    }
    
    /// Load pattern test data from UserDefaults
    private func loadPatternTestData() async {
        if let data = UserDefaults.standard.data(forKey: patternTestStoreKey) {
            do {
                let decoder = JSONDecoder()
                let patternTestData = try decoder.decode([String: [PatternTestEvent]].self, from: data)
                await store.setPatternTestCache(patternTestData)
            } catch {
                print("Error loading pattern test data: \(error)")
            }
        }
    }
    
    /// Save pattern test data to UserDefaults
    private func savePatternTestData() async {
        do {
            let encoder = JSONEncoder()
            let patternTestData = await store.getPatternTestCache()
            let data = try encoder.encode(patternTestData)
            UserDefaults.standard.set(data, forKey: patternTestStoreKey)
        } catch {
            print("Error saving pattern test data: \(error)")
        }
    }
}

// MARK: - AnalyticsStore Actor

/// Actor for thread-safe access to analytics data
private actor AnalyticsStore {
    /// Analytics data
    private var analyticsCache: [String: [ExtractionEvent]] = [:]
    
    /// Pattern test data
    private var patternTestCache: [String: [PatternTestEvent]] = [:]
    
    /// Add an event for a specific pattern key
    func addEvent(_ event: ExtractionEvent, forKey key: String) {
        var events = analyticsCache[key] ?? []
        events.append(event)
        analyticsCache[key] = events
    }
    
    /// Add a pattern test event for a specific pattern ID
    func addPatternTestEvent(_ event: PatternTestEvent, forPatternID patternID: String) {
        var events = patternTestCache[patternID] ?? []
        events.append(event)
        patternTestCache[patternID] = events
    }
    
    /// Get events for a specific pattern key
    func getEvents(forKey key: String) -> [ExtractionEvent]? {
        return analyticsCache[key]
    }
    
    /// Get pattern test events for a specific pattern ID
    func getPatternTestEvents(forPatternID patternID: String) -> [PatternTestEvent]? {
        return patternTestCache[patternID]
    }
    
    /// Get the full analytics cache
    func getAnalyticsCache() -> [String: [ExtractionEvent]] {
        return analyticsCache
    }
    
    /// Get the full pattern test cache
    func getPatternTestCache() -> [String: [PatternTestEvent]] {
        return patternTestCache
    }
    
    /// Set the analytics cache
    func setAnalyticsCache(_ cache: [String: [ExtractionEvent]]) {
        analyticsCache = cache
    }
    
    /// Set the pattern test cache
    func setPatternTestCache(_ cache: [String: [PatternTestEvent]]) {
        patternTestCache = cache
    }
    
    /// Reset all data
    func resetData() {
        analyticsCache = [:]
        patternTestCache = [:]
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
    
    /// Type of error (if applicable)
    let errorType: String?
    
    /// User feedback (if applicable)
    let userFeedback: ExtractionUserFeedback?
}

/// Represents user feedback on extraction
private struct ExtractionUserFeedback: Codable, Sendable {
    /// Whether the extraction was accurate
    let isAccurate: Bool

    /// User-provided correction (if any)
    let correction: String?
}

/// Represents a pattern test event
private struct PatternTestEvent: Codable, Sendable {
    /// ID of the pattern
    let patternID: UUID
    
    /// Key for the pattern
    let key: String
    
    /// Whether the test was successful
    let isSuccess: Bool
    
    /// When the test occurred
    let timestamp: Date
} 