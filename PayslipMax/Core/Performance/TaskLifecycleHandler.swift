import Foundation
import Combine

/// Handles task lifecycle events, cleanup, and dependency validation
@MainActor
public class TaskLifecycleHandler {
    
    // MARK: - Properties
    
    private let taskStorage: TaskStorage
    private var taskPublisher: PassthroughSubject<TaskEvent, Never>
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(taskStorage: TaskStorage, taskPublisher: PassthroughSubject<TaskEvent, Never>) {
        self.taskStorage = taskStorage
        self.taskPublisher = taskPublisher
        setupEventHandling()
    }
    
    // MARK: - Task Registration
    
    /// Register a task with the coordinator
    /// - Parameter task: The task to register
    /// - Returns: The task identifier
    public func register(task: any ManagedTask) async throws -> TaskIdentifier {
        let id = task.id
        
        // Check for circular dependencies
        if let cycle = await detectCircularDependency(for: task) {
            throw TaskCoordinatorError.circularDependency(ids: cycle)
        }
        
        try await taskStorage.registerTask(id, task: task)
        taskPublisher.send(.registered(id))
        
        return id
    }
    
    /// Create and register a new background task
    /// - Parameters:
    ///   - name: Name of the task
    ///   - category: Category of the task
    ///   - priority: Priority of the task
    ///   - dependencies: Other tasks that must complete before this one starts
    ///   - isUserInitiated: Whether the task was directly initiated by the user
    ///   - operation: The async operation to perform
    /// - Returns: The task identifier
    public func createTask<T>(
        name: String,
        category: TaskCategory = .general,
        priority: TaskPriority = .medium,
        dependencies: [TaskIdentifier] = [],
        isUserInitiated: Bool = false,
        operation: @escaping (@escaping (Double, String) -> Void) async throws -> T
    ) async throws -> TaskIdentifier {
        let id = TaskIdentifier(name: name, category: category, isUserInitiated: isUserInitiated)
        let task = BackgroundTask(
            id: id,
            priority: priority,
            dependencies: dependencies,
            operation: operation
        )
        
        _ = try await register(task: task)
        return id
    }
    
    // MARK: - Task Cleanup
    
    /// Clean up completed or failed tasks
    public func cleanupTasks() async {
        let tasksToRemove = await taskStorage.getTasksToCleanup()
        
        for id in tasksToRemove {
            await taskStorage.removeTask(id)
        }
    }
    
    /// Clean up tasks older than a specified time interval
    /// - Parameter timeInterval: The maximum age for tasks before cleanup
    public func cleanupOldTasks(olderThan timeInterval: TimeInterval) async {
        let allTasks = await taskStorage.getAllTasks()
        let currentTime = Date().timeIntervalSince1970
        
        for (id, task) in allTasks {
            if task.status.isTerminal {
                // For now, we don't have creation time tracking
                // This would need to be added to the task protocol
                // Clean up immediately if terminal
                await taskStorage.removeTask(id)
            }
        }
    }
    
    // MARK: - Task Queries
    
    /// Get all currently registered tasks
    /// - Returns: Dictionary of task IDs to tasks
    public func getAllTasks() async -> [TaskIdentifier: any ManagedTask] {
        return await taskStorage.getAllTasks()
    }
    
    /// Get all tasks in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Dictionary of task IDs to tasks
    public func getTasks(in category: TaskCategory) async -> [TaskIdentifier: any ManagedTask] {
        return await taskStorage.getTasksInCategory(category)
    }
    
    /// Get tasks by status
    /// - Parameter status: The status to filter by
    /// - Returns: Array of tasks with the specified status
    public func getTasks(withStatus status: TaskStatus) async -> [any ManagedTask] {
        let allTasks = await taskStorage.getAllTasks()
        return allTasks.values.filter { task in
            switch (task.status, status) {
            case (.pending, .pending), (.running, .running), (.paused, .paused),
                 (.cancelled, .cancelled), (.completed, .completed):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    /// Get task statistics
    public func getTaskStatistics() async -> TaskStatistics {
        let allTasks = await taskStorage.getAllTasks()
        
        var statusCounts: [String: Int] = [:]
        var categoryCounts: [TaskCategory: Int] = [:]
        var priorityCounts: [TaskPriority: Int] = [:]
        
        for (_, task) in allTasks {
            // Count by status
            let statusKey = statusKey(for: task.status)
            statusCounts[statusKey, default: 0] += 1
            
            // Count by category
            categoryCounts[task.id.category, default: 0] += 1
            
            // Count by priority
            priorityCounts[task.priority, default: 0] += 1
        }
        
        return TaskStatistics(
            totalTasks: allTasks.count,
            statusCounts: statusCounts,
            categoryCounts: categoryCounts,
            priorityCounts: priorityCounts
        )
    }
    
    // MARK: - Dependency Management
    
    /// Detect circular dependencies in a task
    /// - Parameter task: The task to check
    /// - Returns: Array of task IDs forming a cycle, or nil if no cycle found
    private func detectCircularDependency(for task: any ManagedTask) async -> [TaskIdentifier]? {
        var visited = Set<TaskIdentifier>()
        var path = [TaskIdentifier]()
        
        func dfs(_ currentId: TaskIdentifier) async -> [TaskIdentifier]? {
            if path.contains(currentId) {
                return path.suffix(from: path.firstIndex(of: currentId)!) + [currentId]
            }
            
            if visited.contains(currentId) {
                return nil
            }
            
            visited.insert(currentId)
            path.append(currentId)
            
            if let currentTask = await taskStorage.getTask(currentId) {
                for dependencyId in currentTask.dependencies {
                    if let cycle = await dfs(dependencyId) {
                        return cycle
                    }
                }
            }
            
            path.removeLast()
            return nil
        }
        
        return await dfs(task.id)
    }
    
    // MARK: - Private Methods
    
    /// Set up event handling for task lifecycle events
    private func setupEventHandling() {
        // Monitor task completion events for automatic cleanup
        taskPublisher
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.handleTaskEvent(event)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle task lifecycle events
    /// - Parameter event: The task event to handle
    private func handleTaskEvent(_ event: TaskEvent) async {
        switch event {
        case .completed(let id), .failed(let id, _), .cancelled(let id):
            // Schedule cleanup after a delay to allow result retrieval
            Task {
                try? await Task.sleep(for: .seconds(60)) // 1 minute delay
                await self.taskStorage.removeTask(id)
            }
        default:
            break
        }
    }
    
    /// Get a string key for a task status
    /// - Parameter status: The task status
    /// - Returns: A string representation of the status
    private func statusKey(for status: TaskStatus) -> String {
        switch status {
        case .pending:
            return "pending"
        case .running:
            return "running"
        case .paused:
            return "paused"
        case .cancelled:
            return "cancelled"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        }
    }
}

// MARK: - Task Statistics

/// Statistics about registered tasks
public struct TaskStatistics {
    public let totalTasks: Int
    public let statusCounts: [String: Int]
    public let categoryCounts: [TaskCategory: Int]
    public let priorityCounts: [TaskPriority: Int]
    
    public var pendingTasks: Int { statusCounts["pending"] ?? 0 }
    public var runningTasks: Int { statusCounts["running"] ?? 0 }
    public var completedTasks: Int { statusCounts["completed"] ?? 0 }
    public var failedTasks: Int { statusCounts["failed"] ?? 0 }
    public var cancelledTasks: Int { statusCounts["cancelled"] ?? 0 }
}