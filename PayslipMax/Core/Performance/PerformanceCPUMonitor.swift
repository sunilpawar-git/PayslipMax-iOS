//
//  PerformanceCPUMonitor.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Handles CPU usage monitoring and calculation
//

import Foundation
import Combine

/// Monitors CPU usage and manages CPU-related performance metrics
final class PerformanceCPUMonitor: CPUMonitorProtocol {
    // MARK: - Published Properties

    /// Current CPU usage percentage
    @Published private(set) var currentCPUUsage: Double = 0

    /// Publisher for CPU usage updates
    var cpuUsagePublisher: AnyPublisher<Double, Never> {
        $currentCPUUsage.eraseToAnyPublisher()
    }

    /// CPU usage history
    private(set) var cpuHistory: [(timestamp: Date, usage: Double)] = []

    // MARK: - Private Properties

    /// Maximum samples to keep in history
    private let maxHistorySamples = 100

    /// Timer for periodic measurements
    private var monitorTimer: Timer?

    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()

    /// Whether monitoring is active
    private var isMonitoring = false

    // MARK: - Initialization

    init() {
        // Initialization handled in startMonitoring
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public API

    /// Starts CPU monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }

        setupCPUMonitoring()
        isMonitoring = true
    }

    /// Stops CPU monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }

        monitorTimer?.invalidate()
        monitorTimer = nil
        cancellables.removeAll()
        isMonitoring = false
    }

    /// Captures current CPU usage
    func captureCPUUsage() {
        let timestamp = Date()
        let cpu = currentCPUUsage

        cpuHistory.append((timestamp: timestamp, usage: cpu))

        // Trim history if it exceeds max size
        if cpuHistory.count > maxHistorySamples {
            cpuHistory.removeFirst(cpuHistory.count - maxHistorySamples)
        }
    }

    /// Calculates average CPU usage
    func calculateAverageCPU() -> Double {
        guard !cpuHistory.isEmpty else { return 0 }

        let total = cpuHistory.reduce(0.0) { $0 + $1.usage }
        return total / Double(cpuHistory.count)
    }

    /// Resets CPU metrics
    func resetMetrics() {
        currentCPUUsage = 0
        cpuHistory.removeAll()
    }

    // MARK: - Private Methods

    /// Sets up CPU usage monitoring
    private func setupCPUMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCPUUsage()
            }
            .store(in: &cancellables)
    }

    /// Updates CPU usage information
    private func updateCPUUsage() {
        currentCPUUsage = getCurrentCPUUsage()
        captureCPUUsage()
    }

    /// Gets current CPU usage
    /// - Returns: CPU usage percentage (0-100)
    private func getCurrentCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        let threadResult = task_threads(mach_task_self_, &threadList, &threadCount)

        if threadResult == KERN_SUCCESS, let threadList = threadList {
            for index in 0..<Int(threadCount) {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size)
                let threadInfoPtr = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                        UnsafeMutablePointer<integer_t>($0)
                    }
                }

                let infoResult = thread_info(threadList[index], thread_flavor_t(THREAD_BASIC_INFO), threadInfoPtr, &threadInfoCount)

                if infoResult == KERN_SUCCESS {
                    let flags = threadInfo.flags

                    if (Int32(flags) & TH_FLAGS_IDLE) == 0 {
                        totalUsageOfCPU = (totalUsageOfCPU + (Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0))
                    }
                }
            }

            // Free the memory allocated for threadList
            vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(threadList).pointee), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride))
        }

        return min(totalUsageOfCPU, 100.0)
    }
}
