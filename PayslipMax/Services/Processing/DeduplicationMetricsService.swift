import Foundation
import Combine

/// Simplified service for monitoring and analyzing deduplication effectiveness
/// Coordinates metrics collection, analysis, and reporting for processing efficiency optimization
@MainActor
final class DeduplicationMetricsServiceSimplified: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentMetrics = DeduplicationMetrics()
    @Published private(set) var historicalTrends = MetricsTrends()
    @Published private(set) var performanceBaseline = PerformanceBaseline()
    @Published private(set) var alerts: [DeduplicationPerformanceAlert] = []
    @Published private(set) var insights: [MetricsInsight] = []
    
    // MARK: - Dependencies
    
    private let collector: DeduplicationMetricsCollector
    private let analyzer: DeduplicationMetricsAnalyzer
    private let persistenceManager: MetricsPersistenceManager
    
    // MARK: - Configuration
    
    private struct ServiceConfig {
        static let alertCheckInterval: TimeInterval = 300.0 // 5 minutes
        static let insightUpdateInterval: TimeInterval = 600.0 // 10 minutes
        static let trendsUpdateInterval: TimeInterval = 3600.0 // 1 hour
    }
    
    // MARK: - Properties
    
    private var alertTimer: Timer?
    private var insightTimer: Timer?
    private var trendsTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(collector: DeduplicationMetricsCollector? = nil,
         analyzer: DeduplicationMetricsAnalyzer? = nil,
         persistenceManager: MetricsPersistenceManager? = nil) {
        
        self.collector = collector ?? DeduplicationMetricsCollector()
        self.analyzer = analyzer ?? DeduplicationMetricsAnalyzer()
        self.persistenceManager = persistenceManager ?? MetricsPersistenceManager()
        
        setupMetricsService()
        loadPersistedData()
    }
    
    deinit {
        alertTimer?.invalidate()
        insightTimer?.invalidate()
        trendsTimer?.invalidate()
        // Note: Cannot call async from deinit, metrics will be saved on next launch
    }
    
    // MARK: - Public Interface
    
    /// Record cache hit
    func recordCacheHit() {
        collector.recordCacheHit()
        updateCurrentMetrics()
    }
    
    /// Record cache miss
    func recordCacheMiss() {
        collector.recordCacheMiss()
        updateCurrentMetrics()
    }
    
    /// Record operation coalescing
    func recordOperationCoalescing(savedOperations: Int = 1) {
        collector.recordOperationCoalescing(savedOperations: savedOperations)
        updateCurrentMetrics()
    }
    
    /// Record result sharing
    func recordResultSharing(sharedCount: Int = 1) {
        collector.recordResultSharing(sharedCount: sharedCount)
        updateCurrentMetrics()
    }
    
    /// Record semantic fingerprint match
    func recordSemanticMatch() {
        collector.recordSemanticMatch()
        updateCurrentMetrics()
    }
    
    /// Record document processing
    func recordDocumentProcessing(processingTime: TimeInterval) {
        collector.recordDocumentProcessing(processingTime: processingTime)
        updateCurrentMetrics()
    }
    
    /// Record processing time saved through deduplication
    func recordTimeSaved(_ timeSaved: TimeInterval) {
        collector.recordTimeSaved(timeSaved)
        updateCurrentMetrics()
    }
    
    /// Record memory saved through deduplication
    func recordMemorySaved(_ bytesSaved: Int64) {
        collector.recordMemorySaved(bytesSaved)
        updateCurrentMetrics()
    }
    
    /// Record processing error
    func recordError() {
        collector.recordError()
        updateCurrentMetrics()
    }
    
    /// Set performance baseline
    func setBaseline(_ baseline: PerformanceBaseline) {
        self.performanceBaseline = baseline
        analyzer.setBaseline(baseline)
        persistenceManager.saveBaseline(baseline)
    }
    
    /// Generate performance improvement summary
    func generateImprovementSummary() -> PerformanceImprovementSummary? {
        return analyzer.generateImprovementSummary(currentMetrics: currentMetrics)
    }
    
    /// Reset metrics for new session
    func resetMetrics() {
        collector.resetMetrics()
        alerts.removeAll()
        insights.removeAll()
        updateCurrentMetrics()
    }
    
    /// Force update all analytics
    func updateAnalytics() {
        updateTrends()
        updateAlerts()
        updateInsights()
    }
    
    // MARK: - Private Methods
    
    private func setupMetricsService() {
        // Setup collector delegate
        collector.addDelegate(self)
        
        // Setup periodic updates
        setupPeriodicUpdates()
    }
    
    private func setupPeriodicUpdates() {
        // Alert checking
        alertTimer = Timer.scheduledTimer(withTimeInterval: ServiceConfig.alertCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAlerts()
            }
        }
        
        // Insight updates
        insightTimer = Timer.scheduledTimer(withTimeInterval: ServiceConfig.insightUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateInsights()
            }
        }
        
        // Trends calculation
        trendsTimer = Timer.scheduledTimer(withTimeInterval: ServiceConfig.trendsUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTrends()
            }
        }
    }
    
    private func updateCurrentMetrics() {
        currentMetrics = collector.getCurrentMetrics()
    }
    
    private func updateTrends() {
        analyzer.addMetricsDataPoint(currentMetrics)
        historicalTrends = analyzer.calculateTrends()
    }
    
    private func updateAlerts() {
        alerts = analyzer.checkAlerts(currentMetrics: currentMetrics)
    }
    
    private func updateInsights() {
        insights = analyzer.getInsights(currentMetrics: currentMetrics)
    }
    
    private func loadPersistedData() {
        performanceBaseline = persistenceManager.loadBaseline() ?? PerformanceBaseline()
        if performanceBaseline.isValid {
            analyzer.setBaseline(performanceBaseline)
        }
    }
    
    private func saveMetrics() {
        persistenceManager.saveMetrics(currentMetrics)
        persistenceManager.saveBaseline(performanceBaseline)
    }
}

// MARK: - DeduplicationMetricsDelegate

extension DeduplicationMetricsServiceSimplified: DeduplicationMetricsDelegate {
    func metricsDidUpdate(_ metrics: DeduplicationMetrics) async {
        await MainActor.run {
            currentMetrics = metrics
        }
    }
}

// MARK: - Metrics Persistence Manager

/// Handles persistence of metrics data
@MainActor
final class MetricsPersistenceManager {
    
    private let fileManager = FileManager.default
    
    private lazy var metricsStorageURL: URL = {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("DeduplicationMetrics")
    }()
    
    private lazy var baselineStorageURL: URL = {
        return metricsStorageURL.appendingPathComponent("baseline.json")
    }()
    
    private lazy var currentMetricsURL: URL = {
        return metricsStorageURL.appendingPathComponent("current.json")
    }()
    
    init() {
        ensureDirectoryExists()
    }
    
    func saveMetrics(_ metrics: DeduplicationMetrics) {
        do {
            let data = try JSONEncoder().encode(metrics)
            try data.write(to: currentMetricsURL)
        } catch {
            print("Failed to save metrics: \(error)")
        }
    }
    
    func loadMetrics() -> DeduplicationMetrics? {
        do {
            let data = try Data(contentsOf: currentMetricsURL)
            return try JSONDecoder().decode(DeduplicationMetrics.self, from: data)
        } catch {
            return nil
        }
    }
    
    func saveBaseline(_ baseline: PerformanceBaseline) {
        do {
            let data = try JSONEncoder().encode(baseline)
            try data.write(to: baselineStorageURL)
        } catch {
            print("Failed to save baseline: \(error)")
        }
    }
    
    func loadBaseline() -> PerformanceBaseline? {
        do {
            let data = try Data(contentsOf: baselineStorageURL)
            return try JSONDecoder().decode(PerformanceBaseline.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func ensureDirectoryExists() {
        do {
            try fileManager.createDirectory(at: metricsStorageURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to create metrics directory: \(error)")
        }
    }
}
