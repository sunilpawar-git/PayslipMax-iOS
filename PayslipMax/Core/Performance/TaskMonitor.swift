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
    
    /// The coordinator wrapper being monitored
    private var taskCoordinatorWrapper: TaskCoordinatorWrapper
    
    /// Task history for analytics and debugging
    internal var taskHistory: [String: TaskHistoryEntry] = [:]
    internal let historyLock = NSLock()
    
    /// Maximum number of task history entries to keep
    internal let maxHistoryEntries = 100
    
    /// Publisher for monitoring events
    internal let eventPublisher = PassthroughSubject<MonitoringEvent, Never>()
    
    /// Cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Periodic task that cleans up old history entries
    private var cleanupTask: Task<Void, Never>?
    
    /// Flag to indicate if monitoring is currently enabled
    private var isMonitoringEnabled = true
    
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
    
    // MARK: - Private Methods
    
    /// Set up subscriptions to the coordinator wrapper's events
    private func setupSubscriptions() {
        taskCoordinatorWrapper.publisher
            .sink { [weak self] enhancedEvent in
                guard let self = self, self.isMonitoringEnabled else { return }
                
                self.processEnhancedEvent(enhancedEvent)
            }
            .store(in: &cancellables)
    }
    
    /// Process an enhanced event from the coordinator wrapper
    private func processEnhancedEvent(_ enhancedEvent: TaskCoordinatorWrapper.EnhancedTaskEvent) {
        switch enhancedEvent.baseEvent {
        case .registered(let id):
            recordTaskCreation(id, metadata: enhancedEvent.metadata)
            
        case .started(let id):
            recordTaskStart(id, metadata: enhancedEvent.metadata)
            
        case .progressed(let id, let progress, let message):
            recordTaskProgress(id, progress: progress, message: message, metadata: enhancedEvent.metadata)
            
        case .completed(let id):
            recordTaskCompletion(id, metadata: enhancedEvent.metadata)
            
        case .failed(let id, let error):
            recordTaskFailure(id, error: error, metadata: enhancedEvent.metadata)
            
        case .cancelled(let id):
            recordTaskCancellation(id, metadata: enhancedEvent.metadata)
            
        case .queued(_, _):
            // No specific handling needed for queued events in the monitor
            break
            
        case .throttled(let currentCount, let maxAllowed):
            // Log throttling events but don't take any specific action
            print("Task throttled: \(currentCount)/\(maxAllowed) tasks running")
        }
    }
    
    
    /// Set up periodic cleanup of task history
    private func setupPeriodicCleanup() {
        cleanupTask = Task {
            while !Task.isCancelled && isMonitoringEnabled {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hour in nanoseconds
                await cleanupOldTaskHistory()
            }
        }
    }
    
    /// Clean up old task history entries
    private func cleanupOldTaskHistory() async {
        await withCheckedContinuation { continuation in
            // Schedule a task on the main actor to access the isolated properties
            Task { @MainActor in
                // Calculate cutoff time (24 hours ago)
                let cutoffTime = Date().addingTimeInterval(-24 * 60 * 60)
                
                // Get the keys to remove
                var keysToRemove = [String]()
                
                // Use withLock for safe locking in async context
                self.historyLock.withLock {
                    for (key, entry) in self.taskHistory {
                        if let completedAt = entry.metrics.completedAt, completedAt < cutoffTime {
                            keysToRemove.append(key)
                        }
                    }
                    
                    // Remove the keys
                    for key in keysToRemove {
                        self.taskHistory.removeValue(forKey: key)
                    }
                }
                
                let count = keysToRemove.count
                
                if count > 0 {
                    self.logger.log("Cleaned up \(count) old task history entries")
                }
                
                continuation.resume()
            }
        }
    }
} 