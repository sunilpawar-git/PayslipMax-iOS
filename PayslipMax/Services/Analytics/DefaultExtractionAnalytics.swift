import Foundation

/// Default implementation of the ExtractionAnalyticsProtocol
@available(*, deprecated, message: "Use AsyncExtractionAnalytics instead")
class DefaultExtractionAnalytics: ExtractionAnalyticsProtocol, @unchecked Sendable {
    // MARK: - Private Properties
    
    /// UserDefaults key for storing analytics data
    private let analyticsStoreKey = "extractionAnalyticsData"
    
    /// UserDefaults key for storing pattern test data
    private let patternTestStoreKey = "patternTestAnalyticsData"
    
    /// In-memory cache of analytics data
    private var analyticsCache: [String: [ExtractionEvent]] = [:]
    
    /// In-memory cache of pattern test data
    private var patternTestCache: [String: [PatternTestEvent]] = [:]
    
    /// Queue for synchronizing access to analytics data
    private let analyticsQueue = DispatchQueue(label: "com.payslipmax.extractionAnalytics", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        loadAnalyticsData()
        loadPatternTestData()
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
        
        return analyticsQueue.sync {
            guard let events = patternTestCache[patternIDString], !events.isEmpty else {
                return 0.0
            }
            
            let successEvents = events.filter { $0.isSuccess }
            return Double(successEvents.count) / Double(events.count)
        }
    }
    
    /// Reset analytics data for testing purposes
    func resetAnalytics() async {
        // Use Task to properly execute the async operation
        Task {
            analyticsQueue.async(flags: .barrier) {
                // Create a local copy to avoid accessing self
                let cache = [String: [ExtractionEvent]]()
                let patternCache = [String: [PatternTestEvent]]()
                
                UserDefaults.standard.removeObject(forKey: self.analyticsStoreKey)
                UserDefaults.standard.removeObject(forKey: self.patternTestStoreKey)
                
                // Use a synchronous update after the async operation
                self.analyticsCache = cache
                self.patternTestCache = patternCache
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
    
    /// Record a pattern test event
    private func recordPatternTestEvent(_ event: PatternTestEvent) async {
        Task {
            let patternIDString = event.patternID.uuidString
            var eventsToUpdate: [PatternTestEvent] = []
            
            analyticsQueue.sync {
                eventsToUpdate = self.patternTestCache[patternIDString] ?? []
                eventsToUpdate.append(event)
            }
            
            analyticsQueue.async(flags: .barrier) {
                self.patternTestCache[patternIDString] = eventsToUpdate
                self.savePatternTestData()
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
    
    /// Load pattern test data from UserDefaults
    private func loadPatternTestData() {
        analyticsQueue.async(flags: .barrier) {
            if let data = UserDefaults.standard.data(forKey: self.patternTestStoreKey) {
                do {
                    let decoder = JSONDecoder()
                    let patternTestData = try decoder.decode([String: [PatternTestEvent]].self, from: data)
                    self.patternTestCache = patternTestData
                } catch {
                    print("Error loading pattern test data: \(error)")
                    self.patternTestCache = [:]
                }
            }
        }
    }
    
    /// Save pattern test data to UserDefaults
    private func savePatternTestData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(patternTestCache)
            UserDefaults.standard.set(data, forKey: patternTestStoreKey)
        } catch {
            print("Error saving pattern test data: \(error)")
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
    
    /// Type of error (if applicable)
    let errorType: String?
    
    /// User feedback (if applicable)
    let userFeedback: UserFeedback?
}

/// Represents user feedback on extraction
private struct UserFeedback: Codable, Sendable {
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