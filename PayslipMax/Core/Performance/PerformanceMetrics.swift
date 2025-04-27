import Foundation
import SwiftUI
import Combine
import QuartzCore

/// Manages performance metrics tracking throughout the application
class PerformanceMetrics: ObservableObject {
    // MARK: - Singleton Access
    
    /// Shared instance for app-wide performance tracking
    static let shared = PerformanceMetrics()
    
    // MARK: - Published Properties
    
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
    
    /// Memory usage thresholds in bytes
    struct MemoryThresholds {
        /// Warning threshold (75% of available memory)
        static let warning: UInt64 = 1024 * 1024 * 200 // 200MB
        
        /// Critical threshold (90% of available memory)
        static let critical: UInt64 = 1024 * 1024 * 300 // 300MB
    }
    
    // MARK: - Private Properties
    
    /// Frame timing data
    private var frameTimestamps: [TimeInterval] = []
    
    /// Maximum number of frame timestamps to keep
    private let maxFrameSamples = 60
    
    /// Timer for periodic measurements
    private var monitorTimer: Timer?
    
    /// Display link for frame timing
    private var displayLink: CADisplayLink?
    
    /// Whether metrics collection is enabled
    private var isEnabled: Bool = false
    
    /// Cancellables bag
    private var cancellables = Set<AnyCancellable>()
    
    /// History of memory usage measurements
    private(set) var memoryHistory: [(timestamp: Date, usage: UInt64)] = []
    
    /// History of CPU usage measurements
    private(set) var cpuHistory: [(timestamp: Date, usage: Double)] = []
    
    /// Maximum samples to keep in history
    private let maxHistorySamples = 100
    
    /// Indicates if continuous monitoring is active
    private(set) var isMonitoring = false
    
    /// Frame counter for fps calculation
    private var frameCount = 0
    
    /// Last timestamp for fps calculation
    private var lastTimestamp: CFTimeInterval = 0
    
    // MARK: - Initialization
    
    private init() {
        // Private initialization to enforce singleton
    }
    
    // MARK: - Public API
    
    /// Starts performance monitoring
    func startMonitoring() {
        guard !isEnabled else { return }
        isEnabled = true
        
        setupDisplayLink()
        startMemoryMonitoring()
        startCPUMonitoring()
        
        print("[PerformanceMetrics] Monitoring started")
    }
    
    /// Stops performance monitoring
    func stopMonitoring() {
        isEnabled = false
        
        displayLink?.invalidate()
        displayLink = nil
        monitorTimer?.invalidate()
        monitorTimer = nil
        
        print("[PerformanceMetrics] Monitoring stopped")
    }
    
    /// Records the time to first render for a specified view
    /// - Parameters:
    ///   - viewName: The name of the view
    ///   - timeInterval: The time interval in milliseconds
    func recordTimeToFirstRender(for viewName: String, timeInterval: TimeInterval) {
        timeToFirstRender[viewName] = timeInterval
    }
    
    /// Records a view redraw
    /// - Parameter viewName: The name of the view that was redrawn
    func recordViewRedraw(for viewName: String) {
        viewRedrawCounts[viewName, default: 0] += 1
    }
    
    /// Resets all collected performance metrics to their initial state.
    func resetMetrics() {
        frameTimestamps.removeAll()
        currentFPS = 0
        averageFPS = 0
        memoryUsage = 0
        cpuUsage = 0
        timeToFirstRender.removeAll()
        viewRedrawCounts.removeAll()
        memoryHistory.removeAll()
        cpuHistory.removeAll()
    }
    
    /// Gets a concise performance report string.
    /// Includes current/average FPS, memory usage, CPU usage, TTFR, and view redraw counts.
    /// - Returns: A formatted string summarizing key performance metrics.
    func getPerformanceReport() -> String {
        var report = "Performance Report\n"
        report += "================\n"
        report += "FPS: Current: \(String(format: "%.1f", currentFPS)), "
        report += "Average: \(String(format: "%.1f", averageFPS))\n"
        report += "Memory Usage: \(formatMemory(memoryUsage))\n"
        report += "CPU Usage: \(String(format: "%.1f", cpuUsage))%\n"
        
        if !timeToFirstRender.isEmpty {
            report += "\nTime to First Render:\n"
            for (view, time) in timeToFirstRender.sorted(by: { $0.key < $1.key }) {
                report += "- \(view): \(String(format: "%.2f", time * 1000)) ms\n"
            }
        }
        
        if !viewRedrawCounts.isEmpty {
            report += "\nView Redraw Counts:\n"
            for (view, count) in viewRedrawCounts.sorted(by: { $0.value > $1.value }) {
                report += "- \(view): \(count) redraws\n"
            }
        }
        
        return report
    }
    
    /// Starts continuous monitoring of system metrics like memory and CPU usage.
    /// Updates `memoryHistory` and `cpuHistory` periodically.
    /// Also starts FPS monitoring via the display link if not already running.
    /// - Parameter interval: The time interval in seconds between metric capture updates. Defaults to 1.0 second.
    func startMonitoring(interval: TimeInterval = 1.0) {
        guard !isMonitoring else { return }
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.captureMetrics()
        }
        
        startFPSMonitoring()
        
        isMonitoring = true
    }
    
    /// Captures a single snapshot of current metrics (memory, CPU) and adds it to the history.
    /// Also checks memory usage against defined warning and critical thresholds.
    func captureMetrics() {
        let timestamp = Date()
        let memory = memoryUsage
        let cpu = cpuUsage
        
        memoryHistory.append((timestamp: timestamp, usage: memory))
        cpuHistory.append((timestamp: timestamp, usage: cpu))
        
        // Trim histories if they exceed max size
        if memoryHistory.count > maxHistorySamples {
            memoryHistory.removeFirst(memoryHistory.count - maxHistorySamples)
        }
        
        if cpuHistory.count > maxHistorySamples {
            cpuHistory.removeFirst(cpuHistory.count - maxHistorySamples)
        }
        
        // Check if memory usage is in warning or critical state
        checkMemoryThresholds(memory)
    }
    
    /// Generates a detailed performance report including current, average, and peak metrics.
    /// Provides insights into memory usage, CPU usage, and UI performance (FPS).
    /// - Returns: A formatted string containing a detailed performance analysis.
    func generatePerformanceReport() -> String {
        let currentMemory = formatMemory(memoryUsage)
        let averageMemory = calculateAverageMemory()
        let peakMemory = calculatePeakMemory()
        let averageCPU = calculateAverageCPU()
        
        var report = "Performance Report\n"
        report += "=================\n\n"
        
        report += "Memory Usage:\n"
        report += "  Current: \(currentMemory)\n"
        report += "  Average: \(formatMemory(averageMemory))\n"
        report += "  Peak: \(formatMemory(peakMemory))\n\n"
        
        report += "CPU Usage:\n"
        report += "  Current: \(String(format: "%.1f", cpuUsage))%\n"
        report += "  Average: \(String(format: "%.1f", averageCPU))%\n\n"
        
        report += "UI Performance:\n"
        report += "  FPS: \(String(format: "%.1f", currentFPS))\n"
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// Sets up display link for frame timing
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    /// Handles display link firing
    @objc private func displayLinkFired() {
        let timestamp = CACurrentMediaTime()
        frameTimestamps.append(timestamp)
        
        // Keep only recent frames
        if frameTimestamps.count > maxFrameSamples {
            frameTimestamps.removeFirst(frameTimestamps.count - maxFrameSamples)
        }
        
        // Calculate FPS
        calculateFPS()
    }
    
    /// Calculates frames per second
    private func calculateFPS() {
        guard frameTimestamps.count >= 2 else { return }
        
        let count = Double(frameTimestamps.count)
        let timeInterval = frameTimestamps.last! - frameTimestamps.first!
        
        if timeInterval > 0 {
            currentFPS = (count - 1) / timeInterval
            
            // Update average FPS with slight weight toward recent values
            if averageFPS == 0 {
                averageFPS = currentFPS
            } else {
                averageFPS = averageFPS * 0.95 + currentFPS * 0.05
            }
        }
    }
    
    /// Starts memory usage monitoring
    private func startMemoryMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
    }
    
    /// Updates memory usage information
    private func updateMemoryUsage() {
        memoryUsage = currentMemoryUsage()
    }
    
    /// Starts CPU usage monitoring
    private func startCPUMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCPUUsage()
            }
            .store(in: &cancellables)
    }
    
    /// Updates CPU usage information
    private func updateCPUUsage() {
        cpuUsage = currentCPUUsage()
    }
    
    /// Gets current memory usage
    /// - Returns: Memory usage in bytes
    private func currentMemoryUsage() -> UInt64 {
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
    
    /// Gets current CPU usage
    /// - Returns: CPU usage percentage (0-100)
    private func currentCPUUsage() -> Double {
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
    
    /// Formats memory size to human-readable string
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Starts monitoring FPS
    private func startFPSMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = CFAbsoluteTimeGetCurrent()
        frameCount = 0
    }
    
    /// Stops monitoring FPS
    private func stopFPSMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    /// Display link callback for FPS calculation
    @objc private func displayLinkTick(link: CADisplayLink) {
        frameCount += 1
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - lastTimestamp
        
        if elapsedTime >= 1.0 {
            currentFPS = Double(frameCount) / elapsedTime
            frameCount = 0
            lastTimestamp = currentTime
        }
    }
    
    /// Calculates the average memory usage from history
    /// - Returns: Average memory usage in bytes
    private func calculateAverageMemory() -> UInt64 {
        guard !memoryHistory.isEmpty else { return 0 }
        
        let total = memoryHistory.reduce(0) { $0 + $1.usage }
        return total / UInt64(memoryHistory.count)
    }
    
    /// Calculates the peak memory usage from history
    /// - Returns: Peak memory usage in bytes
    private func calculatePeakMemory() -> UInt64 {
        return memoryHistory.map { $0.usage }.max() ?? 0
    }
    
    /// Calculates the average CPU usage from history
    /// - Returns: Average CPU usage as a percentage
    private func calculateAverageCPU() -> Double {
        guard !cpuHistory.isEmpty else { return 0 }
        
        let total = cpuHistory.reduce(0.0) { $0 + $1.usage }
        return total / Double(cpuHistory.count)
    }
    
    /// Checks if memory usage exceeds defined thresholds
    /// - Parameter memory: Current memory usage in bytes
    private func checkMemoryThresholds(_ memory: UInt64) {
        if memory >= MemoryThresholds.critical {
            // In a real app, we would log this critical event or take action
            print("⚠️ CRITICAL: Memory usage exceeds critical threshold: \(formatMemory(memory))")
        } else if memory >= MemoryThresholds.warning {
            // In a real app, we might log this warning
            print("⚠️ WARNING: Memory usage exceeds warning threshold: \(formatMemory(memory))")
        }
    }
}

// MARK: - View Extension for Performance Tracking

extension View {
    /// Tracks render time for this view
    /// - Parameter name: The name of the view to track
    /// - Returns: A modified view with performance tracking
    func trackRenderTime(name: String) -> some View {
        let startTime = CFAbsoluteTimeGetCurrent()
        return self.onAppear {
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            PerformanceMetrics.shared.recordTimeToFirstRender(for: name, timeInterval: renderTime)
        }
        .onChange(of: 0) { _, _ in
            // This never triggers, but forces SwiftUI to evaluate the view
        }
    }
    
    /// Tracks redraws of this view
    /// - Parameter name: The name of the view to track
    /// - Returns: A modified view with redraw tracking
    func trackRedraws(name: String) -> some View {
        return self.modifier(RedrawTracker(viewName: name))
    }
}

/// Tracks view redraws
struct RedrawTracker: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                PerformanceMetrics.shared.recordViewRedraw(for: viewName)
            }
            .id(UUID()) // Forces a new identity each time, capturing redraws
    }
} 