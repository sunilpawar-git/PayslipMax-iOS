import Foundation

/// Protocol for analytics storage operations
protocol AnalyticsStorageProtocol {
    /// Add an event for a specific pattern key
    func addEvent(_ event: ExtractionEvent, forKey key: String) async

    /// Add a pattern test event for a specific pattern ID
    func addPatternTestEvent(_ event: PatternTestEvent, forPatternID patternID: String) async

    /// Get events for a specific pattern key
    func getEvents(forKey key: String) async -> [ExtractionEvent]?

    /// Get pattern test events for a specific pattern ID
    func getPatternTestEvents(forPatternID patternID: String) async -> [PatternTestEvent]?

    /// Get the full analytics cache
    func getAnalyticsCache() async -> [String: [ExtractionEvent]]

    /// Get the full pattern test cache
    func getPatternTestCache() async -> [String: [PatternTestEvent]]

    /// Set the analytics cache
    func setAnalyticsCache(_ cache: [String: [ExtractionEvent]]) async

    /// Set the pattern test cache
    func setPatternTestCache(_ cache: [String: [PatternTestEvent]]) async

    /// Reset all data
    func resetData() async
}

/// Actor for thread-safe access to analytics data
actor AnalyticsStore: AnalyticsStorageProtocol {
    /// Analytics data cache
    private var analyticsCache: [String: [ExtractionEvent]] = [:]

    /// Pattern test data cache
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
