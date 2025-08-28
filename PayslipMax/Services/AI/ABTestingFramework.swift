import Foundation
import SwiftData
import Combine

/// Protocol for A/B testing functionality
public protocol ABTestingFrameworkProtocol {
    func registerTest(_ test: ABTest) async throws
    func getTestVariant(for userId: String, testName: String) async -> ABTestVariant?
    func recordTestResult(_ result: ABTestResult) async throws
    func getTestResults(for testName: String) async throws -> [ABTestResult]
    func getActiveTests() async -> [ABTest]
    func endTest(_ testName: String) async throws
}

/// A/B testing framework for parser improvements
/// Enables data-driven optimization of parsing algorithms
@MainActor
public class ABTestingFramework: ABTestingFrameworkProtocol, ObservableObject {

    // MARK: - Properties

    private let testStore: ABTestStore
    private let variantSelector: VariantSelector
    private let resultAnalyzer: ResultAnalyzer
    private let privacyManager: PrivacyPreservingLearningManagerProtocol?

    @Published public var activeTests: [ABTest] = []
    @Published public var testResults: [String: [ABTestResult]] = [:]

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        testStore: ABTestStore? = nil,
        variantSelector: VariantSelector? = nil,
        resultAnalyzer: ResultAnalyzer? = nil,
        privacyManager: PrivacyPreservingLearningManagerProtocol? = nil
    ) {
        self.testStore = testStore ?? ABTestStore()
        self.variantSelector = variantSelector ?? VariantSelector()
        self.resultAnalyzer = resultAnalyzer ?? ResultAnalyzer()
        self.privacyManager = privacyManager

        Task {
            await loadActiveTests()
        }
    }

    // MARK: - Public Methods

    /// Register a new A/B test
    public func registerTest(_ test: ABTest) async throws {
        print("[ABTestingFramework] Registering test: \(test.name)")

        try await testStore.saveTest(test)
        await loadActiveTests()

        print("[ABTestingFramework] Test registered successfully")
    }

    /// Get test variant for a user
    public func getTestVariant(for userId: String, testName: String) async -> ABTestVariant? {
        guard let test = await getTest(by: testName) else {
            return nil
        }

        // Apply privacy-preserving user identification
        let anonymizedUserId = await anonymizeUserId(userId)

        return await variantSelector.selectVariant(for: anonymizedUserId, test: test)
    }

    /// Record test result
    public func recordTestResult(_ result: ABTestResult) async throws {
        print("[ABTestingFramework] Recording result for test: \(result.testName), variant: \(result.variantName)")

        // Store result securely
        try await testStore.saveResult(result)

        // Update cached results
        if testResults[result.testName] == nil {
            testResults[result.testName] = []
        }
        testResults[result.testName]?.append(result)

        // Analyze results for early stopping or winner determination
        await analyzeTestResults(result.testName)

        print("[ABTestingFramework] Result recorded successfully")
    }

    /// Get test results for a specific test
    public func getTestResults(for testName: String) async throws -> [ABTestResult] {
        return try await testStore.getResults(for: testName)
    }

    /// Get all active tests
    public func getActiveTests() async -> [ABTest] {
        return await testStore.getActiveTests()
    }

    /// End a test and determine winner
    public func endTest(_ testName: String) async throws {
        print("[ABTestingFramework] Ending test: \(testName)")

        guard var test = await getTest(by: testName) else {
            throw ABTestingError.testNotFound(testName)
        }

        // Analyze final results
        let results = try await getTestResults(for: testName)
        let winner = await resultAnalyzer.determineWinner(from: results, test: test)

        // Update test with winner
        test.winner = winner
        test.status = .completed
        test.endDate = Date()

        try await testStore.updateTest(test)
        await loadActiveTests()

        print("[ABTestingFramework] Test ended. Winner: \(winner?.name ?? "No winner")")
    }

    // MARK: - Private Methods

    /// Load active tests from storage
    private func loadActiveTests() async {
        let tests = await testStore.getActiveTests()
        await MainActor.run {
            self.activeTests = tests
        }
    }

    /// Get test by name
    private func getTest(by name: String) async -> ABTest? {
        return await testStore.getTest(by: name)
    }

    /// Anonymize user ID for privacy
    private func anonymizeUserId(_ userId: String) async -> String {
        guard let privacyManager = privacyManager else {
            return userId // Fallback if no privacy manager
        }

        do {
            // Create a dummy correction to use the anonymizeCorrection method
            let dummyCorrection = UserCorrection(
                fieldName: "userId",
                originalValue: userId,
                correctedValue: userId,
                documentType: .corporate,
                parserUsed: "ABTestingFramework",
                timestamp: Date(),
                confidenceImpact: 0.0,
                totalExtractions: 1
            )

            let anonymizedCorrection = try await privacyManager.anonymizeCorrection(dummyCorrection)
            return anonymizedCorrection.originalValue // Return the anonymized value
        } catch {
            print("[ABTestingFramework] Error anonymizing user ID: \(error)")
            return userId
        }
    }

    /// Analyze test results for insights
    private func analyzeTestResults(_ testName: String) async {
        guard let results = testResults[testName], !results.isEmpty else {
            return
        }

        // Perform statistical analysis
        let analysis = await resultAnalyzer.analyzeResults(results)

        // Check for early stopping conditions
        if await shouldStopTestEarly(analysis, testName: testName) {
            Task {
                try? await endTest(testName)
            }
        }
    }

    /// Determine if test should stop early
    private func shouldStopTestEarly(_ analysis: ABTestAnalysis, testName: String) async -> Bool {
        guard let test = await getTest(by: testName) else {
            return false
        }

        // Stop if we have statistical significance and clear winner
        return analysis.confidence > 0.95 &&
               analysis.recommendedSampleSize <= analysis.totalSamples &&
               abs(analysis.effectSize) > test.minimumEffectSize
    }
}

// MARK: - Supporting Classes

/// Store for A/B tests and results
public class ABTestStore {
    private var tests: [String: ABTest] = [:]
    private var results: [String: [ABTestResult]] = [:]

    public func saveTest(_ test: ABTest) async throws {
        tests[test.name] = test
    }

    public func getTest(by name: String) async -> ABTest? {
        return tests[name]
    }

    public func getActiveTests() async -> [ABTest] {
        return tests.values.filter { $0.status == .active }
    }

    public func saveResult(_ result: ABTestResult) async throws {
        if results[result.testName] == nil {
            results[result.testName] = []
        }
        results[result.testName]?.append(result)
    }

    public func getResults(for testName: String) async throws -> [ABTestResult] {
        return results[testName] ?? []
    }

    public func updateTest(_ test: ABTest) async throws {
        tests[test.name] = test
    }
}

/// Variant selector using consistent hashing
public class VariantSelector {
    public func selectVariant(for userId: String, test: ABTest) async -> ABTestVariant? {
        let hash = userId.hashValue
        let variantIndex = abs(hash) % test.variants.count
        return test.variants[variantIndex]
    }
}

/// Result analyzer for statistical analysis
public class ResultAnalyzer {
    public func analyzeResults(_ results: [ABTestResult]) async -> ABTestAnalysis {
        let variantGroups = Dictionary(grouping: results) { $0.variantName }

        var variantMetrics: [String: ABTestMetrics] = [:]

        for (variantName, variantResults) in variantGroups {
            let successRate = Double(variantResults.filter { $0.success }.count) / Double(variantResults.count)
            let avgProcessingTime = variantResults.map { $0.processingTime }.reduce(0, +) / Double(variantResults.count)
            let avgAccuracy = variantResults.map { $0.accuracy }.reduce(0, +) / Double(variantResults.count)

            variantMetrics[variantName] = ABTestMetrics(
                sampleSize: variantResults.count,
                successRate: successRate,
                avgProcessingTime: avgProcessingTime,
                avgAccuracy: avgAccuracy,
                standardDeviation: calculateStandardDeviation(variantResults.map { $0.accuracy })
            )
        }

        // Calculate statistical significance (simplified)
        let confidence = calculateConfidence(variantMetrics)
        let effectSize = calculateEffectSize(variantMetrics)
        let recommendedSampleSize = calculateRecommendedSampleSize(variantMetrics)

        return ABTestAnalysis(
            variantMetrics: variantMetrics,
            confidence: confidence,
            effectSize: effectSize,
            recommendedSampleSize: recommendedSampleSize,
            totalSamples: results.count,
            analysisDate: Date()
        )
    }

    public func determineWinner(from results: [ABTestResult], test: ABTest) async -> ABTestVariant? {
        let analysis = await analyzeResults(results)

        // Find variant with best performance
        let bestVariant = analysis.variantMetrics.max { (lhs, rhs) in
            let lhsScore = lhs.value.successRate * lhs.value.avgAccuracy / lhs.value.avgProcessingTime
            let rhsScore = rhs.value.successRate * rhs.value.avgAccuracy / rhs.value.avgProcessingTime
            return lhsScore < rhsScore
        }

        return test.variants.first { $0.name == bestVariant?.key }
    }

    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func calculateConfidence(_ metrics: [String: ABTestMetrics]) -> Double {
        // Simplified confidence calculation
        guard metrics.count >= 2 else { return 0.0 }

        let values = metrics.values.map { $0.successRate }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)

        // Use t-distribution approximation for confidence
        return min(0.99, 1.0 - (variance / (variance + 1.0)))
    }

    private func calculateEffectSize(_ metrics: [String: ABTestMetrics]) -> Double {
        guard metrics.count >= 2 else { return 0.0 }

        let sortedMetrics = metrics.values.sorted { $0.successRate > $1.successRate }
        guard let best = sortedMetrics.first, let second = sortedMetrics.dropFirst().first else {
            return 0.0
        }

        return best.successRate - second.successRate
    }

    private func calculateRecommendedSampleSize(_ metrics: [String: ABTestMetrics]) -> Int {
        // Simplified sample size calculation using Cohen's d effect size
        let effectSize = calculateEffectSize(metrics)

        if effectSize <= 0.2 {
            return 1000 // Large effect
        } else if effectSize <= 0.5 {
            return 400 // Medium effect
        } else {
            return 100 // Small effect
        }
    }
}

// MARK: - Supporting Types

/// A/B test definition
public struct ABTest: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let variants: [ABTestVariant]
    public let targetMetric: ABTestMetric
    public let minimumEffectSize: Double
    public let startDate: Date
    public var endDate: Date?
    public var status: ABTestStatus
    public var winner: ABTestVariant?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        variants: [ABTestVariant],
        targetMetric: ABTestMetric,
        minimumEffectSize: Double = 0.05,
        startDate: Date = Date(),
        status: ABTestStatus = .active
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.variants = variants
        self.targetMetric = targetMetric
        self.minimumEffectSize = minimumEffectSize
        self.startDate = startDate
        self.status = status
    }
}

/// A/B test variant
public struct ABTestVariant: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let weight: Double // Percentage of users in this variant
    public let parameters: [String: AnyCodable]

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        weight: Double = 0.5,
        parameters: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.weight = weight
        self.parameters = parameters
    }
}

/// A/B test result
public struct ABTestResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let testName: String
    public let variantName: String
    public let userId: String
    public let timestamp: Date
    public let success: Bool
    public let processingTime: TimeInterval
    public let accuracy: Double
    public let confidence: Double
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        testName: String,
        variantName: String,
        userId: String,
        timestamp: Date = Date(),
        success: Bool,
        processingTime: TimeInterval,
        accuracy: Double,
        confidence: Double,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.testName = testName
        self.variantName = variantName
        self.userId = userId
        self.timestamp = timestamp
        self.success = success
        self.processingTime = processingTime
        self.accuracy = accuracy
        self.confidence = confidence
        self.metadata = metadata
    }
}

/// Test status
public enum ABTestStatus: String, Codable, CaseIterable, Sendable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

/// Test metrics
public enum ABTestMetric: String, Codable, CaseIterable, Sendable {
    case accuracy = "accuracy"
    case processingTime = "processing_time"
    case successRate = "success_rate"
    case userSatisfaction = "user_satisfaction"
}

/// Test metrics data
public struct ABTestMetrics: Codable, Sendable {
    public let sampleSize: Int
    public let successRate: Double
    public let avgProcessingTime: TimeInterval
    public let avgAccuracy: Double
    public let standardDeviation: Double
}

/// Test analysis results
public struct ABTestAnalysis: Codable, Sendable {
    public let variantMetrics: [String: ABTestMetrics]
    public let confidence: Double
    public let effectSize: Double
    public let recommendedSampleSize: Int
    public let totalSamples: Int
    public let analysisDate: Date
}

/// Type-erased codable value
public struct AnyCodable: Codable, Sendable {
    public let value: Sendable

    public init(_ value: Sendable) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(String.self) // Simplified
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: value))
    }
}

/// Errors for A/B testing
public enum ABTestingError: Error, LocalizedError {
    case testNotFound(String)
    case variantNotFound(String)
    case insufficientData
    case analysisFailed(String)

    public var errorDescription: String? {
        switch self {
        case .testNotFound(let testName):
            return "Test not found: \(testName)"
        case .variantNotFound(let variantName):
            return "Variant not found: \(variantName)"
        case .insufficientData:
            return "Insufficient data for analysis"
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        }
    }
}
