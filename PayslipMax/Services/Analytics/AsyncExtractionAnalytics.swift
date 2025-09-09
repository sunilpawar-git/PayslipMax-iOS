import Foundation

/// Modern async implementation of the ExtractionAnalyticsProtocol
class AsyncExtractionAnalytics: ExtractionAnalyticsProtocol {
    // MARK: - Private Properties

    /// Storage service for analytics data
    private let storage: AnalyticsStorageProtocol

    /// Persistence service for data storage
    private let persistence: AnalyticsPersistenceProtocol

    /// Performance calculator service
    private let performanceCalculator: AnalyticsPerformanceCalculatorProtocol

    // MARK: - Initialization

    init(
        storage: AnalyticsStorageProtocol = AnalyticsStore(),
        persistence: AnalyticsPersistenceProtocol = UserDefaultsAnalyticsPersistence(),
        performanceCalculator: AnalyticsPerformanceCalculatorProtocol = AnalyticsPerformanceCalculator()
    ) {
        self.storage = storage
        self.persistence = persistence
        self.performanceCalculator = performanceCalculator

        Task {
            await loadAnalyticsData()
            await loadPatternTestData()
        }
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

        await storage.addEvent(event, forKey: patternKey)
        await saveAnalyticsData()
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

        await storage.addEvent(event, forKey: patternKey)
        await saveAnalyticsData()
    }
    
    /// Get performance data for all patterns
    func getPatternPerformanceData() async -> [PatternPerformance] {
        let cache = await storage.getAnalyticsCache()

        var performanceData: [PatternPerformance] = []
        for (patternKey, events) in cache {
            let performance = performanceCalculator.calculatePerformance(forEvents: events, patternKey: patternKey)
            performanceData.append(performance)
        }

        return performanceData
    }

    /// Get performance data for a specific pattern
    func getPatternPerformance(forKey key: String) async -> PatternPerformance? {
        let events = await storage.getEvents(forKey: key)
        guard let events = events, !events.isEmpty else {
            return nil
        }

        return performanceCalculator.calculatePerformance(forEvents: events, patternKey: key)
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

        await storage.addEvent(event, forKey: patternKey)
        await saveAnalyticsData()
    }

    /// Record a successful pattern test by pattern ID
    func recordPatternSuccess(patternID: UUID, key: String) async {
        let event = PatternTestEvent(
            patternID: patternID,
            key: key,
            isSuccess: true,
            timestamp: Date()
        )

        let patternIDString = patternID.uuidString
        await storage.addPatternTestEvent(event, forPatternID: patternIDString)
        await savePatternTestData()
    }

    /// Record a failed pattern test by pattern ID
    func recordPatternFailure(patternID: UUID, key: String) async {
        let event = PatternTestEvent(
            patternID: patternID,
            key: key,
            isSuccess: false,
            timestamp: Date()
        )

        let patternIDString = patternID.uuidString
        await storage.addPatternTestEvent(event, forPatternID: patternIDString)
        await savePatternTestData()
    }
    
    /// Get success rate for a specific pattern ID
    func getPatternSuccessRate(patternID: UUID) async -> Double {
        let patternIDString = patternID.uuidString
        let events = await storage.getPatternTestEvents(forPatternID: patternIDString)

        guard let events = events, !events.isEmpty else {
            return 0.0
        }

        let successEvents = events.filter { $0.isSuccess }
        return Double(successEvents.count) / Double(events.count)
    }

    /// Reset analytics data
    func resetAnalytics() async {
        await storage.resetData()
        await saveAnalyticsData()
        await savePatternTestData()
    }

    // MARK: - Private Helper Methods

    /// Load analytics data from persistent storage
    private func loadAnalyticsData() async {
        do {
            let analyticsData = try await persistence.loadAnalyticsData()
            await storage.setAnalyticsCache(analyticsData)
        } catch {
            print("Error loading extraction analytics data: \(error)")
            await storage.resetData()
        }
    }

    /// Save analytics data to persistent storage
    private func saveAnalyticsData() async {
        do {
            let analyticsData = await storage.getAnalyticsCache()
            try await persistence.saveAnalyticsData(analyticsData)
        } catch {
            print("Error saving extraction analytics data: \(error)")
        }
    }

    /// Load pattern test data from persistent storage
    private func loadPatternTestData() async {
        do {
            let patternTestData = try await persistence.loadPatternTestData()
            await storage.setPatternTestCache(patternTestData)
        } catch {
            print("Error loading pattern test data: \(error)")
        }
    }

    /// Save pattern test data to persistent storage
    private func savePatternTestData() async {
        do {
            let patternTestData = await storage.getPatternTestCache()
            try await persistence.savePatternTestData(patternTestData)
        } catch {
            print("Error saving pattern test data: \(error)")
        }
    }
} 