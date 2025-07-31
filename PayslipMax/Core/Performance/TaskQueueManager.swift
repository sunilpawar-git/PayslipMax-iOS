import Foundation
import Combine

/// Manages task queuing, prioritization, and concurrency limits
@MainActor
public class TaskQueueManager {
    
    // MARK: - Properties
    
    private var taskQueue: [TaskIdentifier] = []
    private let queueLock = NSLock()
    private let maxConcurrentTasks: Int
    private var runningTasks = Set<TaskIdentifier>()
    private var taskPublisher: PassthroughSubject<TaskEvent, Never>
    
    // MARK: - Initialization
    
    public init(maxConcurrentTasks: Int = 4, taskPublisher: PassthroughSubject<TaskEvent, Never>) {
        self.maxConcurrentTasks = maxConcurrentTasks
        self.taskPublisher = taskPublisher
    }
    
    // MARK: - Queue Management
    
    /// Add a task to the queue with priority-based insertion
    /// - Parameters:
    ///   - taskId: The task identifier to queue
    ///   - priority: The priority of the task
    public func enqueue(taskId: TaskIdentifier, priority: TaskPriority) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        // Find the correct position to insert based on priority
        let insertIndex = taskQueue.firstIndex { existingId in
            // Compare priorities - higher priority tasks go first
            let existingPriority = getPriority(for: existingId)
            return priority.rawValue > existingPriority.rawValue
        } ?? taskQueue.count
        
        taskQueue.insert(taskId, at: insertIndex)
        taskPublisher.send(.queued(taskId, priority))
    }
    
    /// Remove and return the next task from the queue
    /// - Returns: The next task identifier, or nil if queue is empty
    public func dequeue() -> TaskIdentifier? {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        guard !taskQueue.isEmpty else { return nil }
        return taskQueue.removeFirst()
    }
    
    /// Remove a specific task from the queue
    /// - Parameter taskId: The task identifier to remove
    /// - Returns: True if the task was removed, false if it wasn't in the queue
    public func removeFromQueue(taskId: TaskIdentifier) -> Bool {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if let index = taskQueue.firstIndex(of: taskId) {
            taskQueue.remove(at: index)
            return true
        }
        return false
    }
    
    /// Check if a task is currently in the queue
    /// - Parameter taskId: The task identifier to check
    /// - Returns: True if the task is queued
    public func isQueued(taskId: TaskIdentifier) -> Bool {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        return taskQueue.contains(taskId)
    }
    
    /// Get the current queue length
    public var queueLength: Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        return taskQueue.count
    }
    
    /// Get all queued task identifiers
    public var queuedTasks: [TaskIdentifier] {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        return Array(taskQueue)
    }
    
    // MARK: - Concurrency Management
    
    /// Check if we can start more tasks based on concurrency limits
    public var canStartMoreTasks: Bool {
        return runningTasks.count < maxConcurrentTasks
    }
    
    /// Get the number of currently running tasks
    public var runningTaskCount: Int {
        return runningTasks.count
    }
    
    /// Mark a task as running
    /// - Parameter taskId: The task identifier
    public func markTaskAsRunning(_ taskId: TaskIdentifier) {
        runningTasks.insert(taskId)
    }
    
    /// Mark a task as no longer running
    /// - Parameter taskId: The task identifier
    public func markTaskAsNotRunning(_ taskId: TaskIdentifier) {
        runningTasks.remove(taskId)
    }
    
    /// Check if a task is currently running
    /// - Parameter taskId: The task identifier
    /// - Returns: True if the task is running
    public func isRunning(taskId: TaskIdentifier) -> Bool {
        return runningTasks.contains(taskId)
    }
    
    /// Get all currently running task identifiers
    public var runningTaskIds: Set<TaskIdentifier> {
        return runningTasks
    }
    
    // MARK: - Queue Processing
    
    /// Process the queue and start tasks up to the concurrency limit
    /// - Parameter taskStorage: The task storage to get task details
    public func processQueue(with taskStorage: TaskStorage) async {
        while canStartMoreTasks {
            guard let nextTaskId = dequeue() else { break }
            
            // Check if task still exists
            guard let task = await taskStorage.getTask(nextTaskId) else {
                continue
            }
            
            // Check if dependencies are satisfied
            let dependenciesSatisfied = await checkDependencies(for: task, in: taskStorage)
            
            if dependenciesSatisfied {
                markTaskAsRunning(nextTaskId)
                taskPublisher.send(.started(nextTaskId))
                
                // Start the task in the background
                Task {
                    do {
                        try await task.start()
                        await self.markTaskAsNotRunning(nextTaskId)
                        self.taskPublisher.send(.completed(nextTaskId))
                    } catch {
                        await self.markTaskAsNotRunning(nextTaskId)
                        self.taskPublisher.send(.failed(nextTaskId, error))
                    }
                }
            } else {
                // Re-queue the task to try again later
                enqueue(taskId: nextTaskId, priority: task.priority)
                break // Don't process more tasks until dependencies are resolved
            }
        }
        
        // Check if we're at concurrency limit
        if !canStartMoreTasks {
            taskPublisher.send(.throttled(currentCount: runningTaskCount, maxAllowed: maxConcurrentTasks))
        }
    }
    
    /// Clear all queued tasks
    public func clearQueue() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        taskQueue.removeAll()
    }
    
    /// Get queue statistics
    public func getQueueStatistics() -> QueueStatistics {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        var priorityCounts: [TaskPriority: Int] = [:]
        var categoryCounts: [TaskCategory: Int] = [:]
        
        for taskId in taskQueue {
            let priority = getPriority(for: taskId)
            priorityCounts[priority, default: 0] += 1
            categoryCounts[taskId.category, default: 0] += 1
        }
        
        return QueueStatistics(
            totalQueuedTasks: taskQueue.count,
            runningTasks: runningTasks.count,
            maxConcurrentTasks: maxConcurrentTasks,
            priorityCounts: priorityCounts,
            categoryCounts: categoryCounts
        )
    }
    
    // MARK: - Private Methods
    
    /// Get the priority for a task identifier
    /// - Parameter taskId: The task identifier
    /// - Returns: The task priority
    private func getPriority(for taskId: TaskIdentifier) -> TaskPriority {
        // In a real implementation, this would look up the task priority
        // For now, we'll use the user-initiated flag to determine priority
        return taskId.isUserInitiated ? .userInitiated : .medium
    }
    
    /// Check if all dependencies for a task are satisfied
    /// - Parameters:
    ///   - task: The task to check
    ///   - taskStorage: The task storage
    /// - Returns: True if all dependencies are satisfied
    private func checkDependencies(for task: any ManagedTask, in taskStorage: TaskStorage) async -> Bool {
        for dependencyId in task.dependencies {
            guard let dependencyTask = await taskStorage.getTask(dependencyId) else {
                return false // Dependency not found
            }
            
            // Dependency must be completed
            if case .completed = dependencyTask.status {
                continue
            } else {
                return false
            }
        }
        return true
    }
}

// MARK: - Queue Statistics

/// Statistics about the current queue state
public struct QueueStatistics {
    public let totalQueuedTasks: Int
    public let runningTasks: Int
    public let maxConcurrentTasks: Int
    public let priorityCounts: [TaskPriority: Int]
    public let categoryCounts: [TaskCategory: Int]
    
    public var utilizationPercentage: Double {
        guard maxConcurrentTasks > 0 else { return 0.0 }
        return Double(runningTasks) / Double(maxConcurrentTasks) * 100.0
    }
}