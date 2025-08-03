import Foundation
import Combine

/// Coordinates background tasks with dependencies, prioritization, and progress reporting
@MainActor
public class BackgroundTaskCoordinator {
    public static let shared = BackgroundTaskCoordinator()
    
    // MARK: - Components
    
    private let taskStorage = TaskStorage()
    private var taskPublisher = PassthroughSubject<TaskEvent, Never>()
    private let taskExecutionCoordinator: TaskExecutionCoordinator
    private let taskQueueManager: TaskQueueManager
    private let taskLifecycleHandler: TaskLifecycleHandler
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init(maxConcurrentTasks: Int = 4) {
        // Initialize specialized coordinators
        self.taskExecutionCoordinator = TaskExecutionCoordinator(
            taskStorage: taskStorage,
            taskPublisher: taskPublisher
        )
        
        self.taskQueueManager = TaskQueueManager(
            maxConcurrentTasks: maxConcurrentTasks,
            taskPublisher: taskPublisher
        )
        
        self.taskLifecycleHandler = TaskLifecycleHandler(
            taskStorage: taskStorage,
            taskPublisher: taskPublisher
        )
        
        setupSubscriptions()
    }
    
    // MARK: - Events
    
    /// Publisher for task events
    public var publisher: AnyPublisher<TaskEvent, Never> {
        return taskPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Task Management
    
    /// Register a task with the coordinator
    /// - Parameter task: The task to register
    /// - Returns: The task identifier
    public func register(task: any ManagedTask) async throws -> TaskIdentifier {
        return try await taskLifecycleHandler.register(task: task)
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
        return try await taskLifecycleHandler.createTask(
            name: name,
            category: category,
            priority: priority,
            dependencies: dependencies,
            isUserInitiated: isUserInitiated,
            operation: operation
        )
    }
    
    // MARK: - Task Execution
    
    /// Start a registered task
    /// - Parameter id: The ID of the task to start
    /// - Returns: The result of the task
    public func startTask<T>(id: TaskIdentifier) async throws -> T {
        return try await taskExecutionCoordinator.startTask(id: id)
    }
    
    /// Wait for a task to complete
    /// - Parameter id: The ID of the task to wait for
    public func waitForTask(id: TaskIdentifier) async throws {
        try await taskExecutionCoordinator.waitForTask(id: id)
    }
    
    /// Cancel a task
    /// - Parameter id: The ID of the task to cancel
    public func cancelTask(id: TaskIdentifier) async {
        await taskExecutionCoordinator.cancelTask(id: id)
    }
    
    /// Cancel all tasks in a specific category
    /// - Parameter category: The category of tasks to cancel
    public func cancelAllTasks(in category: TaskCategory? = nil) async {
        await taskExecutionCoordinator.cancelAllTasks(in: category)
    }
    
    // MARK: - Progress Tracking
    
    /// Returns a publisher that emits the aggregated progress for a task and its dependencies.
    /// The progress is calculated as a weighted average with equal weights assigned to each task.
    /// - Parameter taskId: The ID of the main task
    /// - Returns: A publisher emitting the aggregated progress
    public func aggregatedProgressPublisher(for taskId: TaskIdentifier) -> AnyPublisher<Double, Never> {
        return taskExecutionCoordinator.aggregatedProgressPublisher(for: taskId)
    }
    
    // MARK: - Task Queries
    
    /// Get all currently running tasks
    /// - Returns: Dictionary of task IDs to tasks
    public func getAllTasks() async -> [TaskIdentifier: any ManagedTask] {
        return await taskLifecycleHandler.getAllTasks()
    }
    
    /// Get all tasks in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Dictionary of task IDs to tasks
    public func getTasks(in category: TaskCategory) async -> [TaskIdentifier: any ManagedTask] {
        return await taskLifecycleHandler.getTasks(in: category)
    }
    
    /// Get task statistics
    public func getTaskStatistics() async -> TaskStatistics {
        return await taskLifecycleHandler.getTaskStatistics()
    }
    
    /// Get queue statistics
    public func getQueueStatistics() -> QueueStatistics {
        return taskQueueManager.getQueueStatistics()
    }
    
    // MARK: - Cleanup
    
    /// Clean up completed or failed tasks
    public func cleanupTasks() async {
        await taskLifecycleHandler.cleanupTasks()
    }
    
    /// Clean up tasks older than a specified time interval
    /// - Parameter timeInterval: The maximum age for tasks before cleanup
    public func cleanupOldTasks(olderThan timeInterval: TimeInterval) async {
        await taskLifecycleHandler.cleanupOldTasks(olderThan: timeInterval)
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Set up periodic queue processing
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.taskQueueManager.processQueue(with: self.taskStorage)
                }
            }
            .store(in: &cancellables)
    }
}