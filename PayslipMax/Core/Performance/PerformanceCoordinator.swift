//
//  PerformanceCoordinator.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Coordinates all performance monitoring components
//

import Foundation
import Combine

/// Coordinates all performance monitoring components and provides unified interface
final class PerformanceCoordinator: PerformanceCoordinatorProtocol, ObservableObject {
    // MARK: - Component Properties

    /// FPS monitor
    let fpsMonitor: FPSMonitorProtocol

    /// Memory monitor
    let memoryMonitor: MemoryMonitorProtocol

    /// CPU monitor
    let cpuMonitor: CPUMonitorProtocol

    /// Performance reporter
    let reporter: PerformanceReporterProtocol

    // MARK: - Published Properties (Unified Interface)

    /// Current frames per second
    @Published var currentFPS: Double = 0

    /// Average frames per second
    @Published var averageFPS: Double = 0

    /// Current memory usage in bytes
    @Published var memoryUsage: UInt64 = 0

    /// CPU usage percentage (0-100)
    @Published var cpuUsage: Double = 0

    // MARK: - Private Properties

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Whether monitoring is active
    private var isMonitoring = false

    // MARK: - Initialization

    /// Initializes the coordinator with monitoring components
    /// - Parameters:
    ///   - fpsMonitor: FPS monitoring component
    ///   - memoryMonitor: Memory monitoring component
    ///   - cpuMonitor: CPU monitoring component
    ///   - reporter: Performance reporting component
    init(
        fpsMonitor: FPSMonitorProtocol,
        memoryMonitor: MemoryMonitorProtocol,
        cpuMonitor: CPUMonitorProtocol,
        reporter: PerformanceReporterProtocol
    ) {
        self.fpsMonitor = fpsMonitor
        self.memoryMonitor = memoryMonitor
        self.cpuMonitor = cpuMonitor
        self.reporter = reporter

        setupBindings()
    }

    /// Convenience initializer with default implementations
    convenience init() {
        self.init(
            fpsMonitor: PerformanceFPSMonitor(),
            memoryMonitor: PerformanceMemoryMonitor(),
            cpuMonitor: PerformanceCPUMonitor(),
            reporter: PerformanceReporter()
        )
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public API

    /// Starts all performance monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }

        fpsMonitor.startMonitoring()
        memoryMonitor.startMonitoring()
        cpuMonitor.startMonitoring()

        isMonitoring = true
        print("[PerformanceCoordinator] Monitoring started")
    }

    /// Stops all performance monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }

        fpsMonitor.stopMonitoring()
        memoryMonitor.stopMonitoring()
        cpuMonitor.stopMonitoring()

        isMonitoring = false
        print("[PerformanceCoordinator] Monitoring stopped")
    }

    /// Captures all current metrics
    func captureMetrics() {
        memoryMonitor.captureMemoryUsage()
        cpuMonitor.captureCPUUsage()
    }

    /// Resets all metrics
    func resetAllMetrics() {
        fpsMonitor.resetMetrics()
        memoryMonitor.resetMetrics()
        cpuMonitor.resetMetrics()
        reporter.resetMetrics()
    }

    /// Generates comprehensive performance report
    func generateComprehensiveReport() -> String {
        let averageMemory = memoryMonitor.calculateAverageMemory()
        let peakMemory = memoryMonitor.calculatePeakMemory()
        let averageCPU = cpuMonitor.calculateAverageCPU()

        return (reporter as? PerformanceReporter)?.generateDetailedReport(
            currentFPS: currentFPS,
            averageFPS: averageFPS,
            currentMemory: memoryUsage,
            averageMemory: averageMemory,
            peakMemory: peakMemory,
            currentCPU: cpuUsage,
            averageCPU: averageCPU
        ) ?? reporter.generatePerformanceReport()
    }

    // MARK: - Private Methods

    /// Sets up Combine bindings to sync published properties
    private func setupBindings() {
        // FPS bindings
        fpsMonitor.fpsPublisher
            .assign(to: &$currentFPS)

        // Memory bindings
        memoryMonitor.memoryUsagePublisher
            .assign(to: &$memoryUsage)

        // CPU bindings
        cpuMonitor.cpuUsagePublisher
            .assign(to: &$cpuUsage)

        // Note: We would need to create a way to get averageFPS from the FPS monitor
        // For now, we'll use a simple approach
        fpsMonitor.fpsPublisher
            .sink { [weak self] _ in
                // In a real implementation, we'd get the average from the monitor
                self?.averageFPS = self?.fpsMonitor.averageFPS ?? 0
            }
            .store(in: &cancellables)
    }

    // MARK: - Legacy API Compatibility

    /// Records the time to first render for a specified view
    /// - Parameters:
    ///   - viewName: The name of the view
    ///   - timeInterval: The time interval in milliseconds
    func recordTimeToFirstRender(for viewName: String, timeInterval: TimeInterval) {
        reporter.recordTimeToFirstRender(for: viewName, timeInterval: timeInterval)
    }

    /// Records a view redraw
    /// - Parameter viewName: The name of the view that was redrawn
    func recordViewRedraw(for viewName: String) {
        reporter.recordViewRedraw(for: viewName)
    }

    /// Gets concise performance report
    func getPerformanceReport() -> String {
        return generateComprehensiveReport()
    }
}
