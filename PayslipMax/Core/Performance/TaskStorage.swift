import Foundation

/// Thread-safe storage for background tasks using an actor
public actor TaskStorage {
    
    // MARK: - Properties
    
    private var tasks: [TaskIdentifier: any ManagedTask] = [:]
    
    // MARK: - Task Management
    
    /// Get a task by its identifier
    /// - Parameter id: The task identifier
    /// - Returns: The task if found, nil otherwise
    public func getTask(_ id: TaskIdentifier) -> (any ManagedTask)? {
        return tasks[id]
    }
    
    /// Register a new task
    /// - Parameters:
    ///   - id: The task identifier
    ///   - task: The task to register
    /// - Throws: TaskCoordinatorError if task is already registered
    public func registerTask(_ id: TaskIdentifier, task: any ManagedTask) throws {
        if tasks[id] != nil {
            throw TaskCoordinatorError.taskAlreadyRegistered(id: id)
        }
        tasks[id] = task
    }
    
    /// Remove a task by its identifier
    /// - Parameter id: The task identifier
    public func removeTask(_ id: TaskIdentifier) {
        tasks.removeValue(forKey: id)
    }
    
    /// Get all registered tasks
    /// - Returns: Dictionary of task IDs to tasks
    public func getAllTasks() -> [TaskIdentifier: any ManagedTask] {
        return tasks
    }
    
    /// Get all tasks in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Dictionary of task IDs to tasks in the specified category
    public func getTasksInCategory(_ category: TaskCategory) -> [TaskIdentifier: any ManagedTask] {
        return tasks.filter { $0.key.category == category }
    }
    
    /// Get task identifiers that are ready for cleanup (completed, cancelled, or failed)
    /// - Returns: Array of task identifiers ready for cleanup
    public func getTasksToCleanup() -> [TaskIdentifier] {
        return tasks.filter { _, task in
            switch task.status {
            case .completed, .cancelled, .failed:
                return true
            default:
                return false
            }
        }.map { $0.key }
    }
    
    /// Get the count of tasks in each status
    /// - Returns: Dictionary mapping status strings to counts
    public func getTaskStatusCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        for (_, task) in tasks {
            let statusKey: String
            switch task.status {
            case .pending:
                statusKey = "pending"
            case .running:
                statusKey = "running"
            case .paused:
                statusKey = "paused"
            case .cancelled:
                statusKey = "cancelled"
            case .completed:
                statusKey = "completed"
            case .failed:
                statusKey = "failed"
            }
            counts[statusKey, default: 0] += 1
        }
        
        return counts
    }
    
    /// Check if a task exists
    /// - Parameter id: The task identifier
    /// - Returns: True if the task exists
    public func taskExists(_ id: TaskIdentifier) -> Bool {
        return tasks[id] != nil
    }
    
    /// Get the total number of registered tasks
    public var taskCount: Int {
        return tasks.count
    }
    
    /// Clear all tasks (for testing/cleanup)
    public func removeAllTasks() {
        tasks.removeAll()
    }
}