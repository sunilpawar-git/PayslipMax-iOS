import Foundation
import UIKit

/// Enhanced memory manager for Phase 4 optimization
/// Provides comprehensive memory monitoring, pressure handling, and optimization strategies
class EnhancedMemoryManager: ObservableObject {
    
    // MARK: - Configuration
    
    /// Memory thresholds for different pressure levels
    struct MemoryThresholds {
        static let normal: UInt64 = 150 * 1024 * 1024    // 150MB
        static let warning: UInt64 = 250 * 1024 * 1024   // 250MB
        static let critical: UInt64 = 400 * 1024 * 1024  // 400MB
        static let emergency: UInt64 = 500 * 1024 * 1024 // 500MB
    }
    
    enum MemoryPressureLevel: Int, CaseIterable {
        case normal = 0
        case warning = 1
        case critical = 2
        case emergency = 3
        
        var description: String {
            switch self {
            case .normal: return "Normal"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .emergency: return "Emergency"
            }
        }
        
        var shouldOptimizeOperations: Bool {
            return self.rawValue >= MemoryPressureLevel.warning.rawValue
        }
        
        var shouldReduceConcurrency: Bool {
            return self.rawValue >= MemoryPressureLevel.critical.rawValue
        }
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var currentPressureLevel: MemoryPressureLevel = .normal
    @Published private(set) var currentMemoryUsage: UInt64 = 0
    @Published private(set) var availableMemoryPercentage: Double = 1.0
    @Published private(set) var recommendedConcurrency: Int = 4
    
    // MARK: - Private Properties
    
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 0.5 // More frequent monitoring
    private var memoryHistory: [UInt64] = []
    private let maxHistorySize = 60 // Keep 30 seconds of history
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
        setupMemoryWarningNotifications()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        stopMonitoring()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMemoryStatus()
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Memory Status Updates
    
    private func updateMemoryStatus() {
        let memoryUsage = getCurrentMemoryUsage()
        let pressureLevel = calculatePressureLevel(for: memoryUsage)
        let availablePercentage = calculateAvailableMemoryPercentage(current: memoryUsage)
        let concurrency = calculateRecommendedConcurrency(for: pressureLevel)
        
        updateMemoryHistory(memoryUsage)
        
        DispatchQueue.main.async {
            self.currentMemoryUsage = memoryUsage
            self.currentPressureLevel = pressureLevel
            self.availableMemoryPercentage = availablePercentage
            self.recommendedConcurrency = concurrency
        }
        
        // Trigger optimization if needed
        if pressureLevel.shouldOptimizeOperations {
            triggerMemoryOptimization(level: pressureLevel)
        }
    }
    
    private func calculatePressureLevel(for memoryUsage: UInt64) -> MemoryPressureLevel {
        switch memoryUsage {
        case 0..<MemoryThresholds.normal:
            return .normal
        case MemoryThresholds.normal..<MemoryThresholds.warning:
            return .warning
        case MemoryThresholds.warning..<MemoryThresholds.critical:
            return .critical
        default:
            return .emergency
        }
    }
    
    private func calculateAvailableMemoryPercentage(current: UInt64) -> Double {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedPercentage = Double(current) / Double(totalMemory)
        return max(0.0, min(1.0, 1.0 - usedPercentage))
    }
    
    private func calculateRecommendedConcurrency(for level: MemoryPressureLevel) -> Int {
        switch level {
        case .normal:
            return 4
        case .warning:
            return 3
        case .critical:
            return 2
        case .emergency:
            return 1
        }
    }
    
    private func updateMemoryHistory(_ memoryUsage: UInt64) {
        memoryHistory.append(memoryUsage)
        
        if memoryHistory.count > maxHistorySize {
            memoryHistory.removeFirst()
        }
    }
    
    // MARK: - Memory Information
    
    private func getCurrentMemoryUsage() -> UInt64 {
        return MemoryUtils.getCurrentMemoryUsage()
    }
    
    // MARK: - Memory Optimization
    
    private func triggerMemoryOptimization(level: MemoryPressureLevel) {
        NotificationCenter.default.post(
            name: .memoryPressureDetected,
            object: self,
            userInfo: ["level": level]
        )
        
        switch level {
        case .warning:
            optimizeForWarningLevel()
        case .critical:
            optimizeForCriticalLevel()
        case .emergency:
            optimizeForEmergencyLevel()
        case .normal:
            break
        }
    }
    
    private func optimizeForWarningLevel() {
        // Clear non-essential caches
        URLCache.shared.removeAllCachedResponses()
        
        // Suggest garbage collection
        DispatchQueue.global(qos: .utility).async {
            // Allow system to perform cleanup
            autoreleasepool {}
        }
    }
    
    private func optimizeForCriticalLevel() {
        optimizeForWarningLevel()
        
        // More aggressive cache clearing
        NotificationCenter.default.post(name: .shouldClearCaches, object: self)
        
        // Reduce image cache sizes
        let cache = URLCache.shared
        cache.memoryCapacity = cache.memoryCapacity / 2
    }
    
    private func optimizeForEmergencyLevel() {
        optimizeForCriticalLevel()
        
        // Emergency memory cleanup
        NotificationCenter.default.post(name: .emergencyMemoryCleanup, object: self)
        
        // Disable non-essential operations
        NotificationCenter.default.post(name: .disableNonEssentialOperations, object: self)
    }
    
    // MARK: - Memory Warning Notifications
    
    private func setupMemoryWarningNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // System memory warning received - immediate action required
        triggerMemoryOptimization(level: .emergency)
    }
    
    // MARK: - Public Interface
    
    /// Check if current memory pressure requires operation throttling
    func shouldThrottleOperations() -> Bool {
        return currentPressureLevel.shouldOptimizeOperations
    }
    
    /// Check if concurrency should be reduced
    func shouldReduceConcurrency() -> Bool {
        return currentPressureLevel.shouldReduceConcurrency
    }
    
    /// Get memory usage trend (increasing/decreasing/stable)
    func getMemoryTrend() -> MemoryTrend {
        guard memoryHistory.count >= 5 else { return .stable }
        
        let recent = Array(memoryHistory.suffix(5))
        let average = recent.reduce(0, +) / UInt64(recent.count)
        let current = recent.last ?? 0
        
        let threshold: UInt64 = 10 * 1024 * 1024 // 10MB threshold
        
        if current > average + threshold {
            return .increasing
        } else if current < average - threshold {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    enum MemoryTrend {
        case increasing
        case decreasing
        case stable
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
    static let shouldClearCaches = Notification.Name("shouldClearCaches")
    static let emergencyMemoryCleanup = Notification.Name("emergencyMemoryCleanup")
    static let disableNonEssentialOperations = Notification.Name("disableNonEssentialOperations")
}
