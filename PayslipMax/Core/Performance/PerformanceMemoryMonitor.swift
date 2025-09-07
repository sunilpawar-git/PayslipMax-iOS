//
//  PerformanceMemoryMonitor.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Handles memory usage monitoring and calculation
//

import Foundation
import Combine

/// Monitors memory usage and manages memory-related performance metrics
final class PerformanceMemoryMonitor: MemoryMonitorProtocol {
    // MARK: - Published Properties

    /// Current memory usage in bytes
    @Published private(set) var currentMemoryUsage: UInt64 = 0

    /// Publisher for memory usage updates
    var memoryUsagePublisher: AnyPublisher<UInt64, Never> {
        $currentMemoryUsage.eraseToAnyPublisher()
    }

    /// Memory usage history
    private(set) var memoryHistory: [(timestamp: Date, usage: UInt64)] = []

    // MARK: - Private Properties

    /// Maximum samples to keep in history
    private let maxHistorySamples = 100

    /// Timer for periodic measurements
    private var monitorTimer: Timer?

    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()

    /// Whether monitoring is active
    private var isMonitoring = false

    // MARK: - Memory Thresholds

    /// Memory usage thresholds in bytes
    struct MemoryThresholds {
        /// Warning threshold (75% of available memory)
        static let warning: UInt64 = 1024 * 1024 * 200 // 200MB

        /// Critical threshold (90% of available memory)
        static let critical: UInt64 = 1024 * 1024 * 300 // 300MB
    }

    // MARK: - Initialization

    init() {
        // Initialization handled in startMonitoring
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public API

    /// Starts memory monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }

        setupMemoryMonitoring()
        isMonitoring = true
    }

    /// Stops memory monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }

        monitorTimer?.invalidate()
        monitorTimer = nil
        cancellables.removeAll()
        isMonitoring = false
    }

    /// Captures current memory usage
    func captureMemoryUsage() {
        let timestamp = Date()
        let memory = currentMemoryUsage

        memoryHistory.append((timestamp: timestamp, usage: memory))

        // Trim history if it exceeds max size
        if memoryHistory.count > maxHistorySamples {
            memoryHistory.removeFirst(memoryHistory.count - maxHistorySamples)
        }

        // Check memory thresholds
        checkMemoryThresholds(memory)
    }

    /// Calculates average memory usage
    func calculateAverageMemory() -> UInt64 {
        guard !memoryHistory.isEmpty else { return 0 }

        let total = memoryHistory.reduce(0) { $0 + $1.usage }
        return total / UInt64(memoryHistory.count)
    }

    /// Calculates peak memory usage
    func calculatePeakMemory() -> UInt64 {
        return memoryHistory.map { $0.usage }.max() ?? 0
    }

    /// Resets memory metrics
    func resetMetrics() {
        currentMemoryUsage = 0
        memoryHistory.removeAll()
    }

    // MARK: - Private Methods

    /// Sets up memory usage monitoring
    private func setupMemoryMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
    }

    /// Updates memory usage information
    private func updateMemoryUsage() {
        currentMemoryUsage = getCurrentMemoryUsage()
        captureMemoryUsage()
    }

    /// Gets current memory usage
    /// - Returns: Memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)

        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            withUnsafeMutablePointer(to: &count) { countPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    task_info_t(OpaquePointer(infoPtr)),
                    countPtr
                )
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    /// Checks if memory usage exceeds defined thresholds
    /// - Parameter memory: Current memory usage in bytes
    private func checkMemoryThresholds(_ memory: UInt64) {
        if memory >= MemoryThresholds.critical {
            print("⚠️ CRITICAL: Memory usage exceeds critical threshold: \(formatMemory(memory))")
        } else if memory >= MemoryThresholds.warning {
            print("⚠️ WARNING: Memory usage exceeds warning threshold: \(formatMemory(memory))")
        }
    }

    /// Formats memory size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
