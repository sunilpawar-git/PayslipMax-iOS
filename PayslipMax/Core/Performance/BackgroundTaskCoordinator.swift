import Foundation
import Combine

/// Represents a unique identifier for a background task
public struct TaskIdentifier: Hashable, Equatable, CustomStringConvertible {
    private let id: UUID
    public let name: String
    public let category: TaskCategory
    public let isUserInitiated: Bool // Flag for user-initiated tasks
    
    public init(name: String, category: TaskCategory = .general, isUserInitiated: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isUserInitiated = isUserInitiated
    }
    
    public var description: String {
        let userTag = isUserInitiated ? "[UI]" : "[BG]"
        return "\(userTag)\(category.rawValue).\(name).\(id.uuidString.prefix(8))"
    }
}

/// Categories for different types of background tasks
public enum TaskCategory: String, CaseIterable {
    case parsing = "Parsing"
    case processing = "Processing"
    case networking = "Networking"
    case fileIO = "FileIO"
    case general = "General"
}

/// Priority levels for background tasks
public enum TaskPriority: Int, Comparable {
    case low = 0
    case medium = 5
    case high = 10
    case userInitiated = 15
    
    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Status of a background task
public enum TaskStatus: Hashable {
    case pending
    case running
    case paused
    case cancelled
    case completed
    case failed(Error)
    
    var isTerminal: Bool {
        switch self {
        case .completed, .cancelled, .failed:
            return true
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .pending:
            hasher.combine(0)
        case .running:
            hasher.combine(1)
        case .paused:
            hasher.combine(2)
        case .cancelled:
            hasher.combine(3)
        case .completed:
            hasher.combine(4)
        case .failed(let error):
            hasher.combine(5)
            hasher.combine(String(describing: error))
        }
    }
    
    public static func == (lhs: TaskStatus, rhs: TaskStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.running, .running), (.paused, .paused), 
             (.cancelled, .cancelled), (.completed, .completed):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return String(describing: lhsError) == String(describing: rhsError)
        default:
            return false
        }
    }
}

/// Protocol for tasks that can report progress
public protocol ProgressReporting {
    /// Current progress (0.0 to 1.0)
    var progress: Double { get }
    
    /// Status message
    var statusMessage: String { get }
    
    /// Estimated time remaining in seconds, or nil if unknown
    var estimatedTimeRemaining: TimeInterval? { get }
    
    /// Whether the task can be cancelled
    var isCancellable: Bool { get }
}

/// Protocol for a task that can be managed by the BackgroundTaskCoordinator
public protocol ManagedTask: ProgressReporting, Identifiable where ID == TaskIdentifier {
    /// The task identifier
    var id: TaskIdentifier { get }
    
    /// The current status
    var status: TaskStatus { get }
    
    /// The priority of this task
    var priority: TaskPriority { get }
    
    /// Start the task
    func start() async throws
    
    /// Pause the task if possible
    func pause() async
    
    /// Resume the task if paused
    func resume() async
    
    /// Cancel the task
    func cancel() async
    
    /// Dependencies that must be completed before this task can start
    var dependencies: [TaskIdentifier] { get }
}

/// A concrete implementation of ManagedTask for generic asynchronous work
public class BackgroundTask<T>: ManagedTask {
    public let id: TaskIdentifier
    private var _status: TaskStatus = .pending
    public var priority: TaskPriority
    private let operation: (@escaping (Double, String) -> Void) async throws -> T
    private var progressSubject = CurrentValueSubject<(progress: Double, message: String), Never>((0.0, "Pending"))
    private var cancellables = Set<AnyCancellable>()
    private var task: Task<T, Error>?
    public var dependencies: [TaskIdentifier]
    
    private let statusLock = NSLock()
    
    public init(
        id: TaskIdentifier,
        priority: TaskPriority = .medium,
        dependencies: [TaskIdentifier] = [],
        operation: @escaping (@escaping (Double, String) -> Void) async throws -> T
    ) {
        self.id = id
        self.priority = priority
        self.dependencies = dependencies
        self.operation = operation
    }
    
    public var status: TaskStatus {
        statusLock.lock()
        defer { statusLock.unlock() }
        return _status
    }
    
    private func updateStatus(_ newStatus: TaskStatus) {
        statusLock.lock()
        _status = newStatus
        statusLock.unlock()
    }
    
    public var progress: Double {
        return progressSubject.value.progress
    }
    
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    public var progressPublisher: AnyPublisher<(progress: Double, message: String), Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    // Simple placeholder implementation for ETR
    public var estimatedTimeRemaining: TimeInterval? {
        let currentProgress = progress
        // Avoid division by zero and handle completion
        if currentProgress > 0 && currentProgress < 1.0 {
            // Very basic estimate: assumes linear progress and needs historical data
            // For now, let's return nil as a proper estimate isn't implemented
            return nil
        } else {
            return 0 // Or nil if preferred when completed/not started
        }
    }
    
    public var isCancellable: Bool {
        return true
    }
    
    public func start() async throws {
        guard case .pending = status else {
            if case .completed = status {
                return
            }
            throw TaskCoordinatorError.invalidTaskState(id: id, status: status)
        }
        
        updateStatus(.running)
        progressSubject.send((0.0, "Starting \(id.name)"))
        
        task = Task {
            do {
                let result = try await operation { [weak self] progress, message in
                    guard let self = self else { return }
                    self.progressSubject.send((progress, message))
                }
                
                // Only update status if not already terminal (cancelled, etc.)
                if !self.status.isTerminal {
                    self.updateStatus(.completed)
                    self.progressSubject.send((1.0, "Completed"))
                }
                
                return result
            } catch is CancellationError {
                self.updateStatus(.cancelled)
                self.progressSubject.send((self.progress, "Cancelled"))
                throw TaskCoordinatorError.taskCancelled(id: id)
            } catch {
                self.updateStatus(.failed(error))
                self.progressSubject.send((self.progress, "Failed: \(error.localizedDescription)"))
                throw error
            }
        }
        
        // Wait for the result but don't force unwrapping in case of cancellation
        do {
            _ = try await task?.value
        } catch {
            throw error
        }
    }
    
    public func pause() async {
        // Pausing is not implemented yet
        // This would require cooperative cancellation within the operation
    }
    
    public func resume() async {
        // Resuming is not implemented yet
    }
    
    public func cancel() async {
        task?.cancel()
        updateStatus(.cancelled)
        progressSubject.send((progress, "Cancelled"))
    }
}

/// Errors that can occur in the task coordinator
public enum TaskCoordinatorError: Error, LocalizedError {
    case taskAlreadyRegistered(id: TaskIdentifier)
    case taskNotFound(id: TaskIdentifier)
    case circularDependency(ids: [TaskIdentifier])
    case invalidTaskState(id: TaskIdentifier, status: TaskStatus)
    case taskCancelled(id: TaskIdentifier)
    
    public var errorDescription: String? {
        switch self {
        case .taskAlreadyRegistered(let id):
            return "Task already registered with ID: \(id)"
        case .taskNotFound(let id):
            return "Task not found with ID: \(id)"
        case .circularDependency(let ids):
            return "Circular dependency detected among tasks: \(ids.map { $0.description }.joined(separator: ", "))"
        case .invalidTaskState(let id, let status):
            return "Invalid task state: \(status) for task: \(id)"
        case .taskCancelled(let id):
            return "Task was cancelled: \(id)"
        }
    }
}

/// Coordinates background tasks with dependencies, prioritization, and progress reporting
@MainActor
public class BackgroundTaskCoordinator {
    public static let shared = BackgroundTaskCoordinator()
    
    // Use an actor for thread-safe task management
    private actor TaskStorage {
        var tasks: [TaskIdentifier: any ManagedTask] = [:]
        
        func getTask(_ id: TaskIdentifier) -> (any ManagedTask)? {
            return tasks[id]
        }
        
        func registerTask(_ id: TaskIdentifier, task: any ManagedTask) throws {
            if tasks[id] != nil {
                throw TaskCoordinatorError.taskAlreadyRegistered(id: id)
            }
            tasks[id] = task
        }
        
        func removeTask(_ id: TaskIdentifier) {
            tasks.removeValue(forKey: id)
        }
        
        func getAllTasks() -> [TaskIdentifier: any ManagedTask] {
            return tasks
        }
        
        func getTasksInCategory(_ category: TaskCategory) -> [TaskIdentifier: any ManagedTask] {
            return tasks.filter { $0.key.category == category }
        }
        
        func getTasksToCleanup() -> [TaskIdentifier] {
            return tasks.filter { _, task in
                switch task.status {
                case .completed, .cancelled, .failed:
                    return true
                default:
                    return false
                }
            }.map { $0.key }
        }
    }
    
    private let taskStorage = TaskStorage()
    private var taskPublisher = PassthroughSubject<TaskEvent, Never>()
    // Publisher for aggregated progress updates
    private var aggregatedProgressSubject = PassthroughSubject<(id: TaskIdentifier, progress: Double), Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // Priority queue for managing task execution
    private let priorityQueue: TaskPriorityQueue
    
    private init(maxConcurrentTasks: Int = 4) {
        // Initialize the priority queue with configurable concurrency limit
        self.priorityQueue = TaskPriorityQueue(maxConcurrentTasks: maxConcurrentTasks)
        setupSubscriptions()
    }
    
    /// Events published by the coordinator
    public enum TaskEvent {
        case registered(TaskIdentifier)
        case started(TaskIdentifier)
        case progressed(TaskIdentifier, Double, String)
        case completed(TaskIdentifier)
        case failed(TaskIdentifier, Error)
        case cancelled(TaskIdentifier)
        case queued(TaskIdentifier, TaskPriority)
        case throttled(currentCount: Int, maxAllowed: Int)
    }
    
    /// Publisher for task events
    public var publisher: AnyPublisher<TaskEvent, Never> {
        return taskPublisher.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits the aggregated progress for a task and its dependencies.
    /// The progress is calculated as a weighted average (currently equal weighting).
    /// Note: This involves subscribing to multiple underlying task progress publishers.
    public func aggregatedProgressPublisher(for taskId: TaskIdentifier) -> AnyPublisher<Double, Never> {
        // Placeholder - Full implementation requires dependency traversal and subscription management
        // For now, return a publisher that just passes through the main task's progress
        // This needs significant enhancement later.
        return Future<AnyPublisher<Double, Never>, Never> { promise in
            Task {
                if let task = await self.taskStorage.getTask(taskId) as? BackgroundTask<Any> {
                    let directProgress = task.progressPublisher
                        .map { $0.progress }
                        .eraseToAnyPublisher()
                    promise(.success(directProgress))
                } else {
                    // If task not found or not a BackgroundTask, return a publisher emitting 0.0
                    promise(.success(Just(0.0).eraseToAnyPublisher()))
                }
            }
        }
        .flatMap { $0 } // Flatten the Future<Publisher> to Publisher
        .eraseToAnyPublisher()
    }
    
    private func setupSubscriptions() {
        // Subscribe to priority queue events and forward them
        priorityQueue.publisher
            .sink { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .taskQueued(let taskId, let priority):
                    self.taskPublisher.send(.queued(taskId, priority))
                case .taskStarted(let taskId):
                    self.taskPublisher.send(.started(taskId))
                case .taskCompleted(let taskId):
                    self.taskPublisher.send(.completed(taskId))
                case .queueThrottled(let currentCount, let maxAllowed):
                    self.taskPublisher.send(.throttled(currentCount: currentCount, maxAllowed: maxAllowed))
                }
            }
            .store(in: &cancellables)
    }
    
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
    
    /// Start a registered task
    /// - Parameter id: The ID of the task to start
    /// - Returns: The result of the task
    public func startTask<T>(id: TaskIdentifier) async throws -> T {
        guard let task = await taskStorage.getTask(id) as? BackgroundTask<T> else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        // Enqueue the task in the priority queue instead of starting it directly
        priorityQueue.enqueue(task: task)
        
        // Wait for task completion
        try await waitForTask(id: id)
        
        // Get the task result
        let result = getTaskResult(id: id) as? T
        guard let result = result else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        return result
    }
    
    /// Wait for a task to complete
    /// - Parameter id: The ID of the task to wait for
    public func waitForTask(id: TaskIdentifier) async throws {
        guard let task = await taskStorage.getTask(id) else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        // If task is already completed, return immediately
        if case .completed = task.status {
            return
        }
        
        // Wait for task completion using a custom awaitable
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                var cancellable: AnyCancellable? = nil
                
                cancellable = publisher
                    .filter { event in
                        switch event {
                        case .completed(let eventId), .failed(let eventId, _), .cancelled(let eventId):
                            return eventId == id
                        default:
                            return false
                        }
                    }
                    .sink { [weak self] event in
                        guard self != nil else { return }
                        
                        cancellable?.cancel()
                        
                        switch event {
                        case .completed:
                            continuation.resume()
                        case .failed(_, let error):
                            continuation.resume(throwing: error)
                        case .cancelled:
                            continuation.resume(throwing: TaskCoordinatorError.taskCancelled(id: id))
                        default:
                            break
                        }
                    }
            }
        } onCancel: {
            // If waiting is cancelled, we should cancel the task too
            Task {
                await self.cancelTask(id: id)
            }
        }
    }
    
    /// Cancel a task
    /// - Parameter id: The ID of the task to cancel
    public func cancelTask(id: TaskIdentifier) async {
        guard let task = await taskStorage.getTask(id) else { return }
        
        await task.cancel()
        taskPublisher.send(.cancelled(id))
    }
    
    /// Cancel all tasks in a specific category
    /// - Parameter category: The category of tasks to cancel
    public func cancelAllTasks(in category: TaskCategory? = nil) async {
        let tasksToCancel: [any ManagedTask]
        
        if let category = category {
            let filteredTasks = await taskStorage.getTasksInCategory(category)
            tasksToCancel = Array(filteredTasks.values)
        } else {
            let allTasks = await taskStorage.getAllTasks()
            tasksToCancel = Array(allTasks.values)
        }
        
        for task in tasksToCancel {
            await task.cancel()
            taskPublisher.send(.cancelled(task.id))
        }
    }
    
    /// Get a task's result (for internal use)
    private func getTaskResult(id: TaskIdentifier) -> Any? {
        // This would require storing task results
        // For now, we return nil
        return nil
    }
    
    /// Clean up completed or failed tasks
    public func cleanupTasks() async {
        let tasksToRemove = await taskStorage.getTasksToCleanup()
        
        for id in tasksToRemove {
            await taskStorage.removeTask(id)
        }
    }
    
    /// Get all currently running tasks
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
} 