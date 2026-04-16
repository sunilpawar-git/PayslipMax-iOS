import Foundation
import Combine
// import os.log

/// Simple custom logger to avoid os.log issues
private class SimpleLogger {
    let category: String
    
    init(category: String = "Default") {
        self.category = category
    }
    
    func log(_ message: String) {
        print("[\(category)] \(message)")
    }
}

/// Monitors and records metrics about tasks managed by the BackgroundTaskCoordinator
@MainActor
public class TaskMonitor: @unchecked Sendable {
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = TaskMonitor()
    
    // MARK: - Properties
    
    /// Logger for tracking operations
    private let logger = SimpleLogger(category: "TaskMonitor")

    /// Internal logging entry point for extensions
    func logMessage(_ message: String) {
        logger.log(message)
    }
    
    /// The coordinator wrapper being monitored
    var taskCoordinatorWrapper: TaskCoordinatorWrapper
    
    /// Task history for analytics and debugging
    internal var taskHistory: [String: TaskHistoryEntry] = [:]
    internal let historyLock = NSLock()
    
    /// Maximum number of task history entries to keep
    internal let maxHistoryEntries = 100
    
    /// Publisher for monitoring events
    internal let eventPublisher = PassthroughSubject<MonitoringEvent, Never>()
    
    /// Cancellables for subscriptions
    var cancellables = Set<AnyCancellable>()
    
    /// Periodic task that cleans up old history entries
    var cleanupTask: Task<Void, Never>?
    
    /// Flag to indicate if monitoring is currently enabled
    var isMonitoringEnabled = true
    
    // MARK: - Task History
    
    
    // MARK: - Monitoring Events
    
    /// Events published by the monitor
    public enum MonitoringEvent {
        case taskCreated(TaskIdentifier)
        case taskStarted(TaskIdentifier)
        case taskCompleted(TaskIdentifier, duration: TimeInterval)
        case taskFailed(TaskIdentifier, error: Error, duration: TimeInterval)
        case taskCancelled(TaskIdentifier, duration: TimeInterval?)
        case systemOverloaded(cpuUsage: Double, memoryUsage: Int)
        case monitoringStarted
        case monitoringStopped
    }
    
    /// Publisher for monitoring events
    public var publisher: AnyPublisher<MonitoringEvent, Never> {
        return eventPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initialize with the default coordinator wrapper or a custom one for testing
    public init(taskCoordinatorWrapper: TaskCoordinatorWrapper? = nil) {
        // Initialize stored properties first
        if let wrapper = taskCoordinatorWrapper {
            self.taskCoordinatorWrapper = wrapper
        } else {
            // ✅ ASYNC-FIRST: Use MainActor.assumeIsolated for synchronous access to isolated property
            // This is cleaner than DispatchGroup and follows Swift 6 best practices
            self.taskCoordinatorWrapper = MainActor.assumeIsolated {
                return TaskCoordinatorWrapper.shared
            }
        }
        
        // Only after properties are initialized, start setup
        Task { @MainActor in
            self.setupSubscriptions()
            self.startMonitoring()
            self.logger.log("TaskMonitor initialized - async migration complete")
        }
    }
    
    deinit {
        // When deinitializing in a non-main actor context, 
        // we can't directly call the isolated method
        
        // Create a local reference to the method to avoid capturing self
        let stopMonitoringMethod = stopMonitoring
        
        Task { 
            await MainActor.run {
                stopMonitoringMethod()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring tasks
    public func startMonitoring() {
        guard !isMonitoringEnabled else { return }
        
        isMonitoringEnabled = true
        setupPeriodicCleanup()
        eventPublisher.send(.monitoringStarted)
        logger.log("Task monitoring started")
    }
    
    /// Stop monitoring tasks
    public func stopMonitoring() {
        guard isMonitoringEnabled else { return }
        
        isMonitoringEnabled = false
        cleanupTask?.cancel()
        cleanupTask = nil
        eventPublisher.send(.monitoringStopped)
        logger.log("Task monitoring stopped")
    }
    
    /// Get a snapshot of the current task history
    public func getTaskHistorySnapshot() -> [String: TaskHistoryEntry] {
        historyLock.lock()
        defer { historyLock.unlock() }
        return taskHistory
    }
    
    /// Get a summary of task performance metrics
    public func getTaskPerformanceMetrics() -> [String: Any] {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        var totalDuration: TimeInterval = 0
        var completedTasks = 0
        var failedTasks = 0
        var cancelledTasks = 0
        var averageDuration: TimeInterval = 0
        
        for (_, entry) in taskHistory {
            if let duration = entry.metrics.duration {
                totalDuration += duration
                
                if entry.metrics.status == "Completed" {
                    completedTasks += 1
                } else if entry.metrics.status.starts(with: "Failed") {
                    failedTasks += 1
                } else if entry.metrics.status == "Cancelled" {
                    cancelledTasks += 1
                }
            }
        }
        
        let totalTasks = completedTasks + failedTasks + cancelledTasks
        if totalTasks > 0 {
            averageDuration = totalDuration / Double(totalTasks)
        }
        
        return [
            "totalTasks": taskHistory.count,
            "completedTasks": completedTasks,
            "failedTasks": failedTasks,
            "cancelledTasks": cancelledTasks,
            "averageDuration": averageDuration,
            "successRate": totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
        ]
    }
    
    /// Clear task history
    public func clearTaskHistory() {
        historyLock.lock()
        taskHistory.removeAll()
        historyLock.unlock()
        logger.log("Task history cleared")
    }
    
    /// Register a custom diagnostic for a task
    public func addDiagnostic(for taskId: TaskIdentifier, key: String, value: String) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[taskId.description] {
            entry.diagnostics[key] = value
            taskHistory[taskId.description] = entry
        }
    }
}
