import Foundation
import Combine

/// Resource pressure monitor for adaptive memory management
///
/// Following Phase 4B modular pattern: Focused responsibility for resource monitoring
/// Provides real-time memory pressure detection and adaptive recommendations
class ResourcePressureMonitor: ObservableObject {
    
    // MARK: - Configuration
    
    /// Memory pressure thresholds
    private struct MemoryThresholds {
        static let low: UInt64 = 100 * 1024 * 1024    // 100MB
        static let medium: UInt64 = 200 * 1024 * 1024  // 200MB  
        static let high: UInt64 = 300 * 1024 * 1024    // 300MB
        static let critical: UInt64 = 400 * 1024 * 1024 // 400MB
    }
    
    /// Memory pressure levels
    enum MemoryPressureLevel: Int, CaseIterable {
        case normal = 0
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .low: return "Low Pressure"
            case .medium: return "Medium Pressure"
            case .high: return "High Pressure"
            case .critical: return "Critical Pressure"
            }
        }
        
        var shouldReduceOperations: Bool {
            return self.rawValue >= MemoryPressureLevel.medium.rawValue
        }
    }
    
    // MARK: - Published Properties
    
    /// Current memory pressure level
    @Published private(set) var currentPressureLevel: MemoryPressureLevel = .normal
    
    /// Current memory usage in bytes
    @Published private(set) var currentMemoryUsage: UInt64 = 0
    
    /// Available memory percentage (0.0-1.0)
    @Published private(set) var availableMemoryPercentage: Double = 1.0
    
    // MARK: - Private Properties
    
    /// Timer for periodic monitoring
    private var monitoringTimer: Timer?
    
    /// Monitoring interval in seconds
    private let monitoringInterval: TimeInterval = 1.0
    
    /// Memory usage history for trend analysis
    private var memoryHistory: [UInt64] = []
    private let maxHistorySize = 30 // Keep 30 seconds of history
    
    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize resource pressure monitor
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    /// Start memory pressure monitoring
    func startMonitoring() {
        stopMonitoring() // Ensure no duplicate timers
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMemoryStatus()
        }
    }
    
    /// Stop memory pressure monitoring
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Memory Status Updates
    
    /// Update current memory status
    private func updateMemoryStatus() {
        let memoryUsage = getCurrentMemoryUsage()
        let pressureLevel = calculatePressureLevel(for: memoryUsage)
        let availablePercentage = calculateAvailableMemoryPercentage(current: memoryUsage)
        
        // Update history
        updateMemoryHistory(memoryUsage)
        
        // Update published properties on main thread
        DispatchQueue.main.async {
            self.currentMemoryUsage = memoryUsage
            self.currentPressureLevel = pressureLevel
            self.availableMemoryPercentage = availablePercentage
        }
    }
    
    /// Calculate memory pressure level based on usage
    /// - Parameter memoryUsage: Current memory usage in bytes
    /// - Returns: Calculated pressure level
    private func calculatePressureLevel(for memoryUsage: UInt64) -> MemoryPressureLevel {
        switch memoryUsage {
        case 0..<MemoryThresholds.low:
            return .normal
        case MemoryThresholds.low..<MemoryThresholds.medium:
            return .low
        case MemoryThresholds.medium..<MemoryThresholds.high:
            return .medium
        case MemoryThresholds.high..<MemoryThresholds.critical:
            return .high
        default:
            return .critical
        }
    }
    
    /// Calculate available memory percentage
    /// - Parameter current: Current memory usage
    /// - Returns: Available memory as percentage (0.0-1.0)
    private func calculateAvailableMemoryPercentage(current: UInt64) -> Double {
        let totalMemory = getTotalSystemMemory()
        guard totalMemory > 0 else { return 0.0 }
        
        let usedPercentage = Double(current) / Double(totalMemory)
        return max(0.0, min(1.0, 1.0 - usedPercentage))
    }
    
    /// Update memory usage history
    /// - Parameter memoryUsage: Current memory usage to add
    private func updateMemoryHistory(_ memoryUsage: UInt64) {
        memoryHistory.append(memoryUsage)
        
        // Keep only recent history
        if memoryHistory.count > maxHistorySize {
            memoryHistory.removeFirst()
        }
    }
    
    // MARK: - Memory Information
    
    /// Get current memory usage using shared utility
    /// - Returns: Current memory usage in bytes
    private func getCurrentMemoryUsage() -> UInt64 {
        return MemoryUtils.getCurrentMemoryUsage()
    }
    
    /// Get total system memory (approximation)
    /// - Returns: Total system memory in bytes
    private func getTotalSystemMemory() -> UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }
    
    // MARK: - Pressure Analysis
    
    /// Check if memory pressure requires immediate action
    /// - Returns: True if immediate action is required
    func requiresImmediateAction() -> Bool {
        return currentPressureLevel == .critical
    }
    
    /// Get recommended batch size based on current pressure
    /// - Parameter defaultBatchSize: Default batch size
    /// - Returns: Recommended batch size adjusted for memory pressure
    func getRecommendedBatchSize(default defaultBatchSize: Int) -> Int {
        switch currentPressureLevel {
        case .normal:
            return defaultBatchSize
        case .low:
            return max(1, defaultBatchSize * 3 / 4) // Reduce by 25%
        case .medium:
            return max(1, defaultBatchSize / 2)     // Reduce by 50%
        case .high:
            return max(1, defaultBatchSize / 4)     // Reduce by 75%
        case .critical:
            return 1                                // Minimal batch size
        }
    }
    
    /// Get recommended concurrency level based on current pressure
    /// - Parameter defaultConcurrency: Default concurrency level
    /// - Returns: Recommended concurrency level
    func getRecommendedConcurrency(default defaultConcurrency: Int) -> Int {
        switch currentPressureLevel {
        case .normal:
            return defaultConcurrency
        case .low:
            return max(1, defaultConcurrency * 3 / 4)
        case .medium:
            return max(1, defaultConcurrency / 2)
        case .high, .critical:
            return 1 // Sequential processing only
        }
    }
    
    /// Check if streaming processing is recommended
    /// - Returns: True if streaming is recommended
    func isStreamingRecommended() -> Bool {
        return currentPressureLevel.shouldReduceOperations
    }
    
    /// Get memory trend analysis
    /// - Returns: Tuple indicating if memory is increasing, decreasing, or stable
    func getMemoryTrend() -> (isIncreasing: Bool, isDecreasing: Bool, changeRate: Double) {
        guard memoryHistory.count >= 5 else {
            return (false, false, 0.0)
        }
        
        let recent = Array(memoryHistory.suffix(5))
        let older = Array(memoryHistory.prefix(max(0, memoryHistory.count - 5)).suffix(5))
        
        let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
        let olderAvg = Double(older.reduce(0, +)) / Double(older.count)
        
        let changeRate = (recentAvg - olderAvg) / olderAvg
        let threshold = 0.05 // 5% change threshold
        
        return (
            isIncreasing: changeRate > threshold,
            isDecreasing: changeRate < -threshold,
            changeRate: changeRate
        )
    }
    
    /// Format memory size for display using shared utility
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted string (e.g., "123.45 MB")
    func formatMemorySize(_ bytes: UInt64) -> String {
        return MemoryUtils.formatMemorySize(bytes)
    }
} 