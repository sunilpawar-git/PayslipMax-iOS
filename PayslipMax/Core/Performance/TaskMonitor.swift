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
    private let taskCoordinatorWrapper: TaskCoordinatorWrapper
    
    /// Task history for analytics and debugging
    private var taskHistory: [String: TaskHistoryEntry] = [:]
    private let historyLock = NSLock()
    
    /// Maximum number of task history entries to keep
    private let maxHistoryEntries = 100
    
    /// Publisher for monitoring events
    private let eventPublisher = PassthroughSubject<MonitoringEvent, Never>()
    
    /// Cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Periodic task that cleans up old history entries
    private var cleanupTask: Task<Void, Never>?
    
    /// Flag to indicate if monitoring is currently enabled
    private var isMonitoringEnabled = true
    
    // MARK: - Task History
    
    /// Entry in the task history for analytics and debugging
    public struct TaskHistoryEntry {
        /// Basic information about the task
        public struct TaskInfo {
            public let id: String
            public let name: String
            public let category: String
            public let priority: Int
            public let createdAt: Date
        }
        
        /// Metrics about the task execution
        public struct TaskMetrics {
            public var startedAt: Date?
            public var completedAt: Date?
            public var status: String
            public var duration: TimeInterval?
            public var progressUpdates: Int
            public var peakMemoryUsage: Int?
            public var averageCPUUsage: Double?
        }
        
        /// Basic information about the task
        public let info: TaskInfo
        
        /// Metrics about the task execution
        public var metrics: TaskMetrics
        
        /// Progress history (in 10% increments)
        public var progressHistory: [(progress: Double, message: String, timestamp: Date)]
        
        /// Error information if the task failed
        public var error: TaskErrorInfo?
        
        /// Detailed diagnostics
        public var diagnostics: [String: String]
        
        /// Create a new task history entry
        init(id: TaskIdentifier) {
            self.info = TaskInfo(
                id: id.description,
                name: id.name,
                category: id.category.rawValue,
                priority: 0, // Will be updated later
                createdAt: Date()
            )
            
            self.metrics = TaskMetrics(
                startedAt: nil,
                completedAt: nil,
                status: "Created",
                duration: nil,
                progressUpdates: 0,
                peakMemoryUsage: nil,
                averageCPUUsage: nil
            )
            
            self.progressHistory = []
            self.error = nil
            self.diagnostics = [:]
        }
    }
    
    /// Information about a task error
    public struct TaskErrorInfo {
        public let message: String
        public let errorType: String
        public let timestamp: Date
        
        init(error: Error, timestamp: Date = Date()) {
            self.message = error.localizedDescription
            self.errorType = String(describing: type(of: error))
            self.timestamp = timestamp
        }
    }
    
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
    public init(taskCoordinatorWrapper: TaskCoordinatorWrapper = .shared) {
        self.taskCoordinatorWrapper = taskCoordinatorWrapper
        setupSubscriptions()
        startMonitoring()
        logger.log("TaskMonitor initialized")
    }
    
    deinit {
        // When deinitializing in a non-main actor context, 
        // we can't directly call the isolated method
        Task { @MainActor in
            self.stopMonitoring()
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
    
    /// Record the creation of a new task
    private func recordTaskCreation(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        // Create a new history entry
        let entry = TaskHistoryEntry(id: id)
        
        // We can't directly mutate the TaskInfo struct since it's a let property
        // Commenting out the priority handling for now
        // _ = metadata["priority"] // Acknowledge the variable to avoid 'unused' warning
        
        taskHistory[id.description] = entry
        
        // Publish monitoring event
        eventPublisher.send(.taskCreated(id))
        
        // Trim history if needed
        if taskHistory.count > maxHistoryEntries {
            // Remove the oldest entry
            let oldestKey = taskHistory.keys.sorted { lhs, rhs in
                guard let lhsDate = taskHistory[lhs]?.info.createdAt,
                      let rhsDate = taskHistory[rhs]?.info.createdAt else {
                    return false
                }
                return lhsDate < rhsDate
            }.first
            
            if let oldestKey = oldestKey {
                taskHistory.removeValue(forKey: oldestKey)
            }
        }
    }
    
    /// Record the start of a task
    private func recordTaskStart(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let startTime = metadata["startTime"] as? Date ?? Date()
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.startedAt = startTime
            updatedMetrics.status = "Running"
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            eventPublisher.send(.taskStarted(id))
        }
    }
    
    /// Record progress update for a task
    private func recordTaskProgress(_ id: TaskIdentifier, progress: Double, message: String, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let timestamp = metadata["timestamp"] as? Date ?? Date()
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.progressUpdates += 1
            entry.metrics = updatedMetrics
            
            // Only record progress at 10% increments to avoid excessive history
            if entry.progressHistory.isEmpty || 
               abs(progress - entry.progressHistory.last!.progress) >= 0.1 ||
               progress >= 0.99 {
                entry.progressHistory.append((progress: progress, message: message, timestamp: timestamp))
            }
            
            taskHistory[id.description] = entry
        }
    }
    
    /// Record the completion of a task
    private func recordTaskCompletion(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Completed"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            if let duration = duration {
                eventPublisher.send(.taskCompleted(id, duration: duration))
            } else {
                eventPublisher.send(.taskCompleted(id, duration: 0))
            }
        }
    }
    
    /// Record the failure of a task
    private func recordTaskFailure(_ id: TaskIdentifier, error: Error, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Failed: \(error.localizedDescription)"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            // Record error information
            entry.error = TaskErrorInfo(error: error)
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            if let duration = duration {
                eventPublisher.send(.taskFailed(id, error: error, duration: duration))
            } else {
                eventPublisher.send(.taskFailed(id, error: error, duration: 0))
            }
        }
    }
    
    /// Record the cancellation of a task
    private func recordTaskCancellation(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Cancelled"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            eventPublisher.send(.taskCancelled(id, duration: duration))
        }
    }
    
    /// Set up periodic cleanup of task history
    private func setupPeriodicCleanup() {
        cleanupTask = Task {
            while !Task.isCancelled && isMonitoringEnabled {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000) // 1 hour in nanoseconds
                await cleanupOldHistoryEntries()
            }
        }
    }
    
    /// Clean up old history entries
    private func cleanupOldHistoryEntries() async {
        await withCheckedContinuation { continuation in
            // Since we're using @unchecked Sendable, we can use self directly
            DispatchQueue.global().async {
                // Keep entries for 24 hours
                let cutoffTime = Date().addingTimeInterval(-86400)
                
                // Get the keys to remove
                var keysToRemove = [String]()
                
                self.historyLock.lock()
                
                for (key, entry) in self.taskHistory {
                    if let completedAt = entry.metrics.completedAt, completedAt < cutoffTime {
                        keysToRemove.append(key)
                    }
                }
                
                // Remove the keys
                for key in keysToRemove {
                    self.taskHistory.removeValue(forKey: key)
                }
                
                let count = keysToRemove.count
                
                self.historyLock.unlock()
                
                if count > 0 {
                    self.logger.log("Cleaned up \(count) old task history entries")
                }
                
                continuation.resume()
            }
        }
    }
} 