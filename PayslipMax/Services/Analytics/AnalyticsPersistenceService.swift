import Foundation

/// Protocol for analytics data persistence
protocol AnalyticsPersistenceProtocol {
    /// Load analytics data from persistent storage
    func loadAnalyticsData() async throws -> [String: [ExtractionEvent]]

    /// Save analytics data to persistent storage
    func saveAnalyticsData(_ data: [String: [ExtractionEvent]]) async throws

    /// Load pattern test data from persistent storage
    func loadPatternTestData() async throws -> [String: [PatternTestEvent]]

    /// Save pattern test data to persistent storage
    func savePatternTestData(_ data: [String: [PatternTestEvent]]) async throws
}

/// Default implementation using UserDefaults
class UserDefaultsAnalyticsPersistence: AnalyticsPersistenceProtocol {
    private let analyticsStoreKey = "extractionAnalyticsData.v2"
    private let patternTestStoreKey = "patternTestAnalyticsData.v2"

    func loadAnalyticsData() async throws -> [String: [ExtractionEvent]] {
        guard let data = UserDefaults.standard.data(forKey: analyticsStoreKey) else {
            return [:]
        }

        let decoder = JSONDecoder()
        return try decoder.decode([String: [ExtractionEvent]].self, from: data)
    }

    func saveAnalyticsData(_ data: [String: [ExtractionEvent]]) async throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        UserDefaults.standard.set(encodedData, forKey: analyticsStoreKey)
    }

    func loadPatternTestData() async throws -> [String: [PatternTestEvent]] {
        guard let data = UserDefaults.standard.data(forKey: patternTestStoreKey) else {
            return [:]
        }

        let decoder = JSONDecoder()
        return try decoder.decode([String: [PatternTestEvent]].self, from: data)
    }

    func savePatternTestData(_ data: [String: [PatternTestEvent]]) async throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(data)
        UserDefaults.standard.set(encodedData, forKey: patternTestStoreKey)
    }
}
