import Foundation
import Combine

/// A priority queue for background tasks that manages execution based on priority levels
public class TaskPriorityQueue {
    /// A task entry in the priority queue
    private struct QueuedTask {
        let task: any ManagedTask
        let addedTime: Date
        
        init(task: any ManagedTask) {
            self.task = task
            self.addedTime = Date()
        }
    }
    
    /// Maximum number of concurrent tasks that can be executed
    private let maxConcurrentTasks: Int
    
    /// Queue for tasks waiting to be executed
    private var queue: [QueuedTask] = []
    
    /// Currently running tasks
    private var runningTasks: Set<TaskIdentifier> = []
    
    /// Lock for thread-safe queue operations
    private let queueLock = NSLock()
    
    /// Publisher for priority queue events
    private let eventSubject = PassthroughSubject<QueueEvent, Never>()
    
    /// Events that can be published by the queue
    public enum QueueEvent {
        case taskQueued(TaskIdentifier, TaskPriority)
        case taskStarted(TaskIdentifier)
        case taskCompleted(TaskIdentifier)
        case queueThrottled(currentCount: Int, maxAllowed: Int)
    }
    
    /// Publisher for queue events
    public var publisher: AnyPublisher<QueueEvent, Never> {
        return eventSubject.eraseToAnyPublisher()
    }
    
    /// Initializes a new priority queue with configurable concurrency limits
    /// - Parameter maxConcurrentTasks: Maximum number of tasks that can run concurrently
    public init(maxConcurrentTasks: Int = 4) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    /// Add a task to the priority queue
    /// - Parameter task: The task to add
    public func enqueue(task: any ManagedTask) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        // Add the task to the queue
        let queuedTask = QueuedTask(task: task)
        queue.append(queuedTask)
        
        // Sort the queue based on priority (higher priority first)
        // If priorities are equal, sort by added time (FIFO)
        queue.sort { first, second in
            if first.task.priority == second.task.priority {
                return first.addedTime < second.addedTime
            }
            return first.task.priority > second.task.priority
        }
        
        eventSubject.send(.taskQueued(task.id, task.priority))
        
        // Try to start tasks if possible
        tryStartNextTasks()
    }
    
    /// Attempt to start next tasks if under the concurrency limit
    private func tryStartNextTasks() {
        // This method is called with the lock already acquired
        
        // Check if we can run more tasks
        if runningTasks.count >= maxConcurrentTasks {
            eventSubject.send(.queueThrottled(currentCount: runningTasks.count, maxAllowed: maxConcurrentTasks))
            return
        }
        
        // Find tasks that are ready to run (all dependencies completed)
        let tasksToStart = findReadyTasks()
        
        // Start each ready task
        for queuedTask in tasksToStart {
            let task = queuedTask.task
            
            // Remove from queue
            if let index = queue.firstIndex(where: { $0.task.id == task.id }) {
                queue.remove(at: index)
            }
            
            // Add to running tasks
            runningTasks.insert(task.id)
            
            // Start the task
            eventSubject.send(.taskStarted(task.id))
            
            // Start the task asynchronously
            Task {
                do {
                    try await task.start()
                } catch {
                    // Task completed or failed, but we're done with it
                }
                
                // When task is done, remove it from running tasks
                await withTaskCancellationHandler {
                    withLock(self.queueLock) {
                        runningTasks.remove(task.id)
                        eventSubject.send(.taskCompleted(task.id))
                        
                        // Try to start more tasks
                        tryStartNextTasks()
                    }
                } onCancel: {
                    // Handle cancellation if needed
                }
            }
            
            // Check if we've hit the concurrency limit
            if runningTasks.count >= maxConcurrentTasks {
                break
            }
        }
    }
    
    /// Find tasks that are ready to run (all dependencies satisfied)
    /// This assumes the lock is held while calling
    private func findReadyTasks() -> [QueuedTask] {
        return queue.filter { queuedTask in
            // Check if all dependencies are satisfied
            let dependencies = queuedTask.task.dependencies
            
            // A task is ready if it has no dependencies or all dependencies are completed
            // We consider a dependency satisfied if it's not in the queue or running
            return dependencies.allSatisfy { dependencyId in
                // Check if dependency is not in the queue and not running
                let inQueue = queue.contains { $0.task.id == dependencyId }
                let isRunning = runningTasks.contains(dependencyId)
                
                return !inQueue && !isRunning
            }
        }
    }
    
    /// Get the current number of tasks in the queue
    public var queuedTaskCount: Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        return queue.count
    }
    
    /// Get the current number of running tasks
    public var runningTaskCount: Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        return runningTasks.count
    }
    
    /// Get all queued task identifiers
    public var queuedTaskIds: [TaskIdentifier] {
        queueLock.lock()
        defer { queueLock.unlock() }
        return queue.map { $0.task.id }
    }
    
    /// Get all running task identifiers
    public var runningTaskIds: [TaskIdentifier] {
        queueLock.lock()
        defer { queueLock.unlock() }
        return Array(runningTasks)
    }
    
    /// Cancel all queued tasks and return the number of tasks canceled
    @discardableResult
    public func cancelAllQueuedTasks() -> Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let taskCount = queue.count
        queue.removeAll()
        return taskCount
    }
    
    /// Helper function to safely use NSLock in async contexts
    private func withLock<T>(_ lock: NSLock, operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
} 