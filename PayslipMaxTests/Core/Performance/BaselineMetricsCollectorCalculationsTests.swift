import XCTest
@testable import PayslipMax

/// Unit tests for the pure calculation helpers in BaselineMetricsCollector.
/// These cover the contracts extracted into BaselineMetricsCollector+Calculations.swift.
/// All functions under test are deterministic with no async/external dependencies.
@MainActor
final class BaselineMetricsCollectorCalculationsTests: XCTestCase {

    // MARK: - Properties

    private var sut: BaselineMetricsCollector!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = BaselineMetricsCollector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - calculateAverageProcessingTime

    func test_calculateAverageProcessingTime_withEmptyDict_returnsZero() {
        let result = sut.calculateAverageProcessingTime([:])
        XCTAssertEqual(result, 0, "Empty input must return 0")
    }

    func test_calculateAverageProcessingTime_withSingleEntry_returnsAverage() {
        let input = ["systemA": [0.1, 0.3, 0.5]]
        let result = sut.calculateAverageProcessingTime(input)
        XCTAssertEqual(result, 0.3, accuracy: 0.001)
    }

    func test_calculateAverageProcessingTime_withMultipleEntries_returnsGlobalAverage() {
        let input = ["a": [1.0, 3.0], "b": [2.0, 4.0]]
        let result = sut.calculateAverageProcessingTime(input)
        XCTAssertEqual(result, 2.5, accuracy: 0.001, "Average of [1,3,2,4] should be 2.5")
    }

    func test_calculateAverageProcessingTime_withSingleValueEntries_returnsCorrectAverage() {
        let input = ["x": [10.0], "y": [20.0], "z": [30.0]]
        let result = sut.calculateAverageProcessingTime(input)
        XCTAssertEqual(result, 20.0, accuracy: 0.001)
    }

    // MARK: - calculateProcessingDistribution

    func test_calculateProcessingDistribution_withEmptyDict_returnsEmpty() {
        let result = sut.calculateProcessingDistribution([:])
        XCTAssertTrue(result.isEmpty)
    }

    func test_calculateProcessingDistribution_withEntries_returnsPerKeyAverages() {
        let input = ["systemA": [1.0, 3.0], "systemB": [2.0, 4.0]]
        let result = sut.calculateProcessingDistribution(input)
        XCTAssertEqual(result["systemA"] ?? -1, 2.0, accuracy: 0.001)
        XCTAssertEqual(result["systemB"] ?? -1, 3.0, accuracy: 0.001)
    }

    func test_calculateProcessingDistribution_withEmptyArray_returnsZeroForKey() {
        let input = ["system": [Double]()]
        let result = sut.calculateProcessingDistribution(input)
        XCTAssertEqual(result["system"] ?? -1, 0, "Empty time array must produce 0 average")
    }

    // MARK: - calculateOverallHitRate

    func test_calculateOverallHitRate_withEmptyDict_returnsZero() {
        let result = sut.calculateOverallHitRate([:])
        XCTAssertEqual(result, 0)
    }

    func test_calculateOverallHitRate_withSingleEntry_returnsItsHitRate() {
        let metrics = Self.makeCache(hitRate: 0.75, totalOperations: 100)
        let result = sut.calculateOverallHitRate(["cache": metrics])
        XCTAssertEqual(result, 0.75, accuracy: 0.001)
    }

    func test_calculateOverallHitRate_withMultipleEntries_returnsWeightedAverage() {
        let cacheA = Self.makeCache(hitRate: 1.0, totalOperations: 100)
        let cacheB = Self.makeCache(hitRate: 0.0, totalOperations: 100)
        let result = sut.calculateOverallHitRate(["a": cacheA, "b": cacheB])
        XCTAssertEqual(result, 0.5, accuracy: 0.001, "Equal-weight caches with rates 1.0 and 0.0 should average 0.5")
    }

    // MARK: - calculateCacheMemoryDistribution

    func test_calculateCacheMemoryDistribution_returnsCorrectMemoryValues() {
        let cache = Self.makeCache(memoryUsage: 50 * 1024 * 1024)
        let result = sut.calculateCacheMemoryDistribution(["testCache": cache])
        XCTAssertEqual(result["testCache"], 50 * 1024 * 1024)
    }

    func test_calculateCacheMemoryDistribution_withMultipleEntries_mapsCorrectly() {
        let caches = [
            "a": Self.makeCache(memoryUsage: 1_000),
            "b": Self.makeCache(memoryUsage: 2_000)
        ]
        let result = sut.calculateCacheMemoryDistribution(caches)
        XCTAssertEqual(result["a"], 1_000)
        XCTAssertEqual(result["b"], 2_000)
    }

    // MARK: - calculateCacheOperationDistribution

    func test_calculateCacheOperationDistribution_returnsCorrectCounts() {
        let cache = Self.makeCache(totalOperations: 500)
        let result = sut.calculateCacheOperationDistribution(["cache": cache])
        XCTAssertEqual(result["cache"], 500)
    }

    // MARK: - calculateMemoryVariability

    func test_calculateMemoryVariability_withSingleMeasurement_returnsZero() {
        let measurements = [Self.makeMeasurement(resident: 100_000)]
        let result = sut.calculateMemoryVariability(measurements)
        XCTAssertEqual(result, 0, "Single measurement has no variability")
    }

    func test_calculateMemoryVariability_withIdenticalMeasurements_returnsZero() {
        let measurements = [
            Self.makeMeasurement(resident: 100_000),
            Self.makeMeasurement(resident: 100_000),
            Self.makeMeasurement(resident: 100_000)
        ]
        let result = sut.calculateMemoryVariability(measurements)
        XCTAssertEqual(result, 0, accuracy: 0.001, "Identical measurements must have zero variability")
    }

    func test_calculateMemoryVariability_withVaryingMeasurements_returnsPositiveValue() {
        let measurements = [
            Self.makeMeasurement(resident: 100_000),
            Self.makeMeasurement(resident: 200_000),
            Self.makeMeasurement(resident: 300_000)
        ]
        let result = sut.calculateMemoryVariability(measurements)
        XCTAssertGreaterThan(result, 0, "Varying measurements must produce positive coefficient of variation")
    }

    func test_calculateMemoryVariability_withEmptyArray_returnsZero() {
        let result = sut.calculateMemoryVariability([])
        XCTAssertEqual(result, 0)
    }

    // MARK: - identifyProcessingBottlenecks

    func test_identifyProcessingBottlenecks_withNoIssues_returnsEmpty() {
        let redundancy = RedundancyMetrics(
            redundancyPercentage: 10,
            duplicateOperations: 1,
            uniqueOperations: 10,
            totalOperations: 11
        )
        let result = sut.identifyProcessingBottlenecks(redundancy, 0.5)
        XCTAssertTrue(result.isEmpty, "No bottlenecks expected when metrics are within thresholds")
    }

    func test_identifyProcessingBottlenecks_withHighRedundancy_identifiesBottleneck() {
        let redundancy = RedundancyMetrics(
            redundancyPercentage: 35,
            duplicateOperations: 35,
            uniqueOperations: 65,
            totalOperations: 100
        )
        let result = sut.identifyProcessingBottlenecks(redundancy, 0.5)
        XCTAssertTrue(result.contains { $0.contains("redundancy") }, "High redundancy must be flagged")
    }

    func test_identifyProcessingBottlenecks_withHighResourceUsage_identifiesBottleneck() {
        let redundancy = RedundancyMetrics(
            redundancyPercentage: 5,
            duplicateOperations: 1,
            uniqueOperations: 20,
            totalOperations: 21
        )
        let result = sut.identifyProcessingBottlenecks(redundancy, 0.85)
        XCTAssertTrue(result.contains { $0.contains("resource utilization") }, "High resource usage must be flagged")
    }

    func test_identifyProcessingBottlenecks_withMoreDuplicatesThanUnique_identifiesBottleneck() {
        let redundancy = RedundancyMetrics(
            redundancyPercentage: 10,
            duplicateOperations: 50,
            uniqueOperations: 10,
            totalOperations: 60
        )
        let result = sut.identifyProcessingBottlenecks(redundancy, 0.3)
        XCTAssertTrue(
            result.contains { $0.contains("duplicate") },
            "More duplicates than unique operations must be flagged"
        )
    }

    func test_identifyProcessingBottlenecks_withAllIssues_identifiesAllBottlenecks() {
        let redundancy = RedundancyMetrics(
            redundancyPercentage: 50,
            duplicateOperations: 100,
            uniqueOperations: 10,
            totalOperations: 110
        )
        let result = sut.identifyProcessingBottlenecks(redundancy, 0.9)
        XCTAssertGreaterThanOrEqual(result.count, 2, "Multiple issues should produce multiple bottleneck descriptions")
    }

    // MARK: - Factory Helpers

    private static func makeCache(
        hitRate: Double = 0.75,
        totalOperations: Int = 1_000,
        memoryUsage: UInt64 = 50 * 1024 * 1024
    ) -> CacheEffectivenessMetrics {
        CacheEffectivenessMetrics(
            hitRate: hitRate,
            missRate: 1 - hitRate,
            totalOperations: totalOperations,
            memoryUsage: memoryUsage,
            evictionRate: 0.1,
            averageResponseTime: 0.002
        )
    }

    private static func makeMeasurement(resident: UInt64) -> MemoryMeasurement {
        MemoryMeasurement(
            timestamp: Date(),
            residentSize: resident,
            virtualSize: resident * 2,
            peakResident: resident
        )
    }
}
