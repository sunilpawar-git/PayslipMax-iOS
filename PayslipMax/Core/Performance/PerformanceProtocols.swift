//
//  PerformanceProtocols.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Protocols for performance monitoring components
//

import Foundation
import Combine

// MARK: - FPS Monitoring Protocol

/// Protocol for FPS monitoring functionality
protocol FPSMonitorProtocol {
    /// Current frames per second
    var currentFPS: Double { get }

    /// Average frames per second
    var averageFPS: Double { get }

    /// Publisher for FPS updates
    var fpsPublisher: AnyPublisher<Double, Never> { get }

    /// Starts FPS monitoring
    func startMonitoring()

    /// Stops FPS monitoring
    func stopMonitoring()

    /// Resets FPS metrics
    func resetMetrics()
}

// MARK: - Memory Monitoring Protocol

/// Protocol for memory monitoring functionality
protocol MemoryMonitorProtocol {
    /// Current memory usage in bytes
    var currentMemoryUsage: UInt64 { get }

    /// Publisher for memory usage updates
    var memoryUsagePublisher: AnyPublisher<UInt64, Never> { get }

    /// Memory usage history
    var memoryHistory: [(timestamp: Date, usage: UInt64)] { get }

    /// Starts memory monitoring
    func startMonitoring()

    /// Stops memory monitoring
    func stopMonitoring()

    /// Captures current memory usage
    func captureMemoryUsage()

    /// Calculates average memory usage
    func calculateAverageMemory() -> UInt64

    /// Calculates peak memory usage
    func calculatePeakMemory() -> UInt64

    /// Resets memory metrics
    func resetMetrics()
}

// MARK: - CPU Monitoring Protocol

/// Protocol for CPU monitoring functionality
protocol CPUMonitorProtocol {
    /// Current CPU usage percentage
    var currentCPUUsage: Double { get }

    /// Publisher for CPU usage updates
    var cpuUsagePublisher: AnyPublisher<Double, Never> { get }

    /// CPU usage history
    var cpuHistory: [(timestamp: Date, usage: Double)] { get }

    /// Starts CPU monitoring
    func startMonitoring()

    /// Stops CPU monitoring
    func stopMonitoring()

    /// Captures current CPU usage
    func captureCPUUsage()

    /// Calculates average CPU usage
    func calculateAverageCPU() -> Double

    /// Resets CPU metrics
    func resetMetrics()
}

// MARK: - Performance Reporting Protocol

/// Protocol for performance reporting functionality
protocol PerformanceReporterProtocol {
    /// Generates performance report
    func generatePerformanceReport() -> String

    /// Gets concise performance report
    func getConcisePerformanceReport() -> String

    /// Formats memory size to human-readable string
    func formatMemory(_ bytes: UInt64) -> String

    /// Records time to first render for a view
    func recordTimeToFirstRender(for viewName: String, timeInterval: TimeInterval)

    /// Records view redraw
    func recordViewRedraw(for viewName: String)

    /// Gets time to first render metrics
    func getTimeToFirstRender() -> [String: TimeInterval]

    /// Gets view redraw counts
    func getViewRedrawCounts() -> [String: Int]

    /// Resets all reporting metrics
    func resetMetrics()
}

// MARK: - Performance Coordinator Protocol

/// Protocol for coordinating all performance monitoring components
protocol PerformanceCoordinatorProtocol {
    /// FPS monitor
    var fpsMonitor: FPSMonitorProtocol { get }

    /// Memory monitor
    var memoryMonitor: MemoryMonitorProtocol { get }

    /// CPU monitor
    var cpuMonitor: CPUMonitorProtocol { get }

    /// Performance reporter
    var reporter: PerformanceReporterProtocol { get }

    /// Starts all performance monitoring
    func startMonitoring()

    /// Stops all performance monitoring
    func stopMonitoring()

    /// Captures all current metrics
    func captureMetrics()

    /// Resets all metrics
    func resetAllMetrics()
}
