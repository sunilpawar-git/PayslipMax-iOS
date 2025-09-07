import Foundation
import SwiftUI
import Combine

/// Manages performance metrics tracking throughout the application using coordinator pattern
class PerformanceMetrics: ObservableObject {
    // MARK: - Singleton Access (Legacy Compatibility)
    
    /// Shared instance for app-wide performance tracking
    static let shared = PerformanceMetrics()
    
    // MARK: - Coordinator

    /// Performance coordinator that manages all monitoring components
    private let coordinator: PerformanceCoordinator

    // MARK: - Published Properties (Delegated to Coordinator)
    
    /// Current frames per second
    @Published private(set) var currentFPS: Double = 0
    
    /// Average frames per second
    @Published private(set) var averageFPS: Double = 0
    
    /// Current memory usage in bytes
    @Published private(set) var memoryUsage: UInt64 = 0
    
    /// Time to first render in milliseconds
    @Published private(set) var timeToFirstRender: [String: TimeInterval] = [:]
    
    /// View redraw counts
    @Published private(set) var viewRedrawCounts: [String: Int] = [:]
    
    /// CPU usage percentage (0-100)
    @Published private(set) var cpuUsage: Double = 0
    
    /// Memory usage thresholds in bytes (Legacy compatibility)
    struct MemoryThresholds {
        /// Warning threshold (75% of available memory)
        static let warning: UInt64 = 1024 * 1024 * 200 // 200MB
        
        /// Critical threshold (90% of available memory)
        static let critical: UInt64 = 1024 * 1024 * 300 // 300MB
    }
    
    // MARK: - Legacy Properties (Maintained for compatibility)
    
    /// History of memory usage measurements
    private(set) var memoryHistory: [(timestamp: Date, usage: UInt64)] = []
    
    /// History of CPU usage measurements
    private(set) var cpuHistory: [(timestamp: Date, usage: Double)] = []
    
    /// Indicates if continuous monitoring is active
    private(set) var isMonitoring = false
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default coordinator
        self.coordinator = PerformanceCoordinator()
        setupCoordinatorBindings()
    }

    /// Initializes with a custom coordinator (for dependency injection)
    /// - Parameter coordinator: Performance coordinator to use
    init(coordinator: PerformanceCoordinator) {
        self.coordinator = coordinator
        setupCoordinatorBindings()
    }

    // MARK: - Private Methods

    /// Sets up bindings to sync coordinator properties with published properties
    private func setupCoordinatorBindings() {
        // Bind coordinator properties to our published properties
        coordinator.$currentFPS
            .assign(to: &$currentFPS)

        coordinator.$averageFPS
            .assign(to: &$averageFPS)

        coordinator.$memoryUsage
            .assign(to: &$memoryUsage)

        coordinator.$cpuUsage
            .assign(to: &$cpuUsage)

        // Update legacy properties for backward compatibility
        coordinator.memoryMonitor.memoryUsagePublisher
            .sink { [weak self] _ in
                self?.memoryHistory = self?.coordinator.memoryMonitor.memoryHistory ?? []
            }
            .store(in: &cancellables)

        coordinator.cpuMonitor.cpuUsagePublisher
            .sink { [weak self] _ in
                self?.cpuHistory = self?.coordinator.cpuMonitor.cpuHistory ?? []
            }
            .store(in: &cancellables)
    }

    /// Cancellables bag for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public API (Delegated to Coordinator)
    
    /// Starts performance monitoring
    func startMonitoring() {
        coordinator.startMonitoring()
        isMonitoring = true
    }
    
    /// Stops performance monitoring
    func stopMonitoring() {
        coordinator.stopMonitoring()
        isMonitoring = false
    }
    
    /// Records the time to first render for a specified view
    /// - Parameters:
    ///   - viewName: The name of the view
    ///   - timeInterval: The time interval in milliseconds
    func recordTimeToFirstRender(for viewName: String, timeInterval: TimeInterval) {
        coordinator.recordTimeToFirstRender(for: viewName, timeInterval: timeInterval)
        timeToFirstRender[viewName] = timeInterval
    }
    
    /// Records a view redraw
    /// - Parameter viewName: The name of the view that was redrawn
    func recordViewRedraw(for viewName: String) {
        coordinator.recordViewRedraw(for: viewName)
        viewRedrawCounts[viewName, default: 0] += 1
    }
    
    /// Resets all collected performance metrics to their initial state.
    func resetMetrics() {
        coordinator.resetAllMetrics()
        timeToFirstRender.removeAll()
        viewRedrawCounts.removeAll()
        memoryHistory.removeAll()
        cpuHistory.removeAll()
    }
    
    /// Gets a concise performance report string.
    /// Includes current/average FPS, memory usage, CPU usage, TTFR, and view redraw counts.
    /// - Returns: A formatted string summarizing key performance metrics.
    func getPerformanceReport() -> String {
        return coordinator.getPerformanceReport()
    }
    
    /// Starts continuous monitoring of system metrics like memory and CPU usage.
    /// Updates `memoryHistory` and `cpuHistory` periodically.
    /// Also starts FPS monitoring via the display link if not already running.
    /// - Parameter interval: The time interval in seconds between metric capture updates. Defaults to 1.0 second.
    func startMonitoring(interval: TimeInterval = 1.0) {
        // This method is kept for backward compatibility
        // The coordinator handles the actual monitoring
        coordinator.startMonitoring()
        isMonitoring = true
    }
    
    /// Captures a single snapshot of current metrics (memory, CPU) and adds it to the history.
    /// Also checks memory usage against defined warning and critical thresholds.
    func captureMetrics() {
        coordinator.captureMetrics()
    }
    
    /// Generates a detailed performance report including current, average, and peak metrics.
    /// Provides insights into memory usage, CPU usage, and UI performance (FPS).
    /// - Returns: A formatted string containing a detailed performance analysis.
    func generatePerformanceReport() -> String {
        return coordinator.generateComprehensiveReport()
    }
} 