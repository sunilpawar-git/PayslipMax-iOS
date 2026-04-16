import Foundation

@MainActor
final class MetricsPersistenceManager {

    private let fileManager = FileManager.default
    private let logCategory = "MetricsPersistence"

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
            Logger.error("Failed to save metrics: \(error.localizedDescription)", category: logCategory)
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
            Logger.error("Failed to save baseline: \(error.localizedDescription)", category: logCategory)
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
            Logger.error("Failed to create metrics directory: \(error.localizedDescription)", category: logCategory)
        }
    }
}
