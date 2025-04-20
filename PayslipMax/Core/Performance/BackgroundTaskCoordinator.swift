import Foundation
import Combine

/// Represents a unique identifier for a background task
public struct TaskIdentifier: Hashable, Equatable, CustomStringConvertible {
    private let id: UUID
    public let name: String
    public let category: TaskCategory
    
    public init(name: String, category: TaskCategory = .general) {
        self.id = UUID()
        self.name = name
        self.category = category
    }
    
    public var description: String {
        return "\(category.rawValue).\(name).\(id.uuidString.prefix(8))"
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
public enum TaskStatus {
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
}

/// Protocol for basic progress reporting
public protocol ProgressReporting: AnyObject {
    /// Current progress between 0.0 and 1.0
    var progress: Double { get }
    
    /// Message describing the current status
    var statusMessage: String { get }
    
    /// Whether the task can be cancelled
    var isCancellable: Bool { get }
}

/// Protocol for tasks that can be managed by the coordinator
public protocol ManagedTask: ProgressReporting {
    /// The unique identifier of the task
    var id: UUID { get }
    
    /// The priority of the task
    var priority: TaskPriority { get }
    
    /// Start the task
    func start() async throws
    
    /// Pause the task if possible
    func pause() async throws
    
    /// Resume a paused task
    func resume() async throws
    
    /// Cancel the task
    func cancel() async throws
    
    /// Wait for the task to complete
    func waitForCompletion() async throws
}

/// Possible states for a background task
public enum TaskState: Equatable {
    case notStarted
    case running
    case paused
    case completed
    case failed(Error)
    case cancelled
    
    public static func == (lhs: TaskState, rhs: TaskState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.running, .running),
             (.paused, .paused),
             (.completed, .completed),
             (.cancelled, .cancelled):
            return true
        case (.failed, .failed):
            return true // Not comparing errors
        default:
            return false
        }
    }
}

/// A background task implementation that can be managed
public class BackgroundTask<Result>: ManagedTask, EnhancedProgressReporting {
    public let id: UUID
    public let priority: TaskPriority
    private let workItem: () async throws -> Result
    private let progressSubject = CurrentValueSubject<ProgressUpdate, Never>(
        ProgressUpdate(progress: 0, message: "Waiting to start")
    )
    private var stateSubject = CurrentValueSubject<TaskState, Never>(.notStarted)
    private var taskResult: Result?
    private var taskError: Error?
    private var cancellables = Set<AnyCancellable>()
    private let isCancellableValue: Bool
    
    /// Creates a new background task
    /// - Parameters:
    ///   - id: Unique identifier (generated if not provided)
    ///   - priority: Task priority (default: medium)
    ///   - isCancellable: Whether the task can be cancelled
    ///   - workItem: The closure containing the work to be done
    public init(
        id: UUID = UUID(),
        priority: TaskPriority = .medium,
        isCancellable: Bool = true,
        workItem: @escaping () async throws -> Result
    ) {
        self.id = id
        self.priority = priority
        self.workItem = workItem
        self.isCancellableValue = isCancellable
    }
    
    /// Current progress from 0.0 to 1.0
    public var progress: Double {
        return progressSubject.value.progress
    }
    
    /// Current status message
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    /// Whether the task can be cancelled
    public var isCancellable: Bool {
        return isCancellableValue
    }
    
    /// Publisher for progress updates
    public var progressPublisher: AnyPublisher<ProgressUpdate, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for task state changes
    public var statePublisher: AnyPublisher<TaskState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    /// The current state of the task
    public var state: TaskState {
        return stateSubject.value
    }
    
    /// Update the progress of the task
    /// - Parameters:
    ///   - progress: The progress value (0.0 to 1.0)
    ///   - message: The status message
    public func updateProgress(progress: Double, message: String) {
        let normalizedProgress = max(0, min(1, progress))
        
        // Only calculate time remaining if we're in a running state
        let estimatedTimeRemaining: TimeInterval?
        if state == .running {
            estimatedTimeRemaining = calculateTimeRemaining(currentProgress: normalizedProgress)
        } else {
            estimatedTimeRemaining = nil
        }
        
        let update = ProgressUpdate(
            progress: normalizedProgress,
            message: message,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        
        progressSubject.send(update)
    }
    
    /// Start the task
    public func start() async throws {
        guard state == .notStarted || state == .paused else {
            throw TaskCoordinatorError.invalidStateTransition(from: state, to: .running)
        }
        
        stateSubject.send(.running)
        updateProgress(progress: 0.01, message: "Starting task")
        
        do {
            taskResult = try await workItem()
            updateProgress(progress: 1.0, message: "Task completed")
            stateSubject.send(.completed)
        } catch {
            taskError = error
            stateSubject.send(.failed(error))
            throw error
        }
    }
    
    /// Pause the task (placeholder - implement in subclasses that support pausing)
    public func pause() async throws {
        guard state == .running else {
            throw TaskCoordinatorError.invalidStateTransition(from: state, to: .paused)
        }
        
        // Base implementation doesn't support pausing
        throw TaskCoordinatorError.operationNotSupported("Pause is not supported by this task type")
    }
    
    /// Resume the task (placeholder - implement in subclasses that support pausing)
    public func resume() async throws {
        guard state == .paused else {
            throw TaskCoordinatorError.invalidStateTransition(from: state, to: .running)
        }
        
        // Base implementation doesn't support pausing/resuming
        throw TaskCoordinatorError.operationNotSupported("Resume is not supported by this task type")
    }
    
    /// Cancel the task
    public func cancel() async throws {
        guard isCancellable else {
            throw TaskCoordinatorError.operationNotSupported("Task does not support cancellation")
        }
        
        guard state == .running || state == .paused || state == .notStarted else {
            throw TaskCoordinatorError.invalidStateTransition(from: state, to: .cancelled)
        }
        
        // Note: This is a placeholder. In a real implementation, you would need
        // to implement a cancellation mechanism for the running task.
        stateSubject.send(.cancelled)
        updateProgress(progress: 0, message: "Task cancelled")
    }
    
    /// Wait for the task to complete
    public func waitForCompletion() async throws {
        // If already completed, just return
        if case .completed = state {
            return
        }
        
        // This is a simplified implementation
        // In a real app, you would use a continuation or task cancellation
        var subscription: AnyCancellable?
        return try await withCheckedThrowingContinuation { continuation in
            subscription = statePublisher
                .filter { state in
                    if case .running = state { return false }
                    if case .paused = state { return false }
                    if case .notStarted = state { return false }
                    return true
                }
                .first()
                .sink { [weak self] state in
                    subscription?.cancel()
                    
                    switch state {
                    case .completed:
                        continuation.resume()
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    case .cancelled:
                        continuation.resume(throwing: TaskCoordinatorError.taskCancelled)
                    default:
                        continuation.resume(throwing: TaskCoordinatorError.unknown)
                    }
                }
        }
    }
    
    /// Get the task's result
    /// - Returns: The result of the task execution
    /// - Throws: Error if the task failed or didn't complete
    public func getResult() throws -> Result {
        switch state {
        case .completed:
            if let result = taskResult {
                return result
            }
            throw TaskCoordinatorError.resultNotAvailable
        case .failed(let error):
            throw error
        case .cancelled:
            throw TaskCoordinatorError.taskCancelled
        default:
            throw TaskCoordinatorError.resultNotAvailable
        }
    }
    
    /// Calculate estimated time remaining based on progress history
    private func calculateTimeRemaining(currentProgress: Double) -> TimeInterval? {
        // Time remaining estimation is now handled by the ProgressUpdate structure
        // This is a placeholder that would be implemented with advanced estimation logic
        return nil
    }
}

/// Error types for task coordination
public enum TaskCoordinatorError: Error, Equatable {
    case taskNotFound(id: UUID)
    case invalidStateTransition(from: TaskState, to: TaskState)
    case operationNotSupported(String)
    case taskCancelled
    case resultNotAvailable
    case unknown
    
    public static func == (lhs: TaskCoordinatorError, rhs: TaskCoordinatorError) -> Bool {
        switch (lhs, rhs) {
        case (.taskNotFound(let id1), .taskNotFound(let id2)):
            return id1 == id2
        case (.invalidStateTransition(let from1, let to1), .invalidStateTransition(let from2, let to2)):
            return from1 == from2 && to1 == to2
        case (.operationNotSupported(let msg1), .operationNotSupported(let msg2)):
            return msg1 == msg2
        case (.taskCancelled, .taskCancelled),
             (.resultNotAvailable, .resultNotAvailable),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}

/// Coordinates the execution of background tasks
public class BackgroundTaskCoordinator {
    private var tasks: [UUID: ManagedTask] = [:]
    private var taskResults: [UUID: Any] = [:]
    private let maxConcurrentTasks: Int
    private var runningTaskCount = 0
    private let taskQueue = DispatchQueue(label: "com.payslipmax.taskCoordinator", attributes: .concurrent)
    
    /// Publisher that emits events when tasks are added or removed
    private let tasksSubject = PassthroughSubject<[UUID: ManagedTask], Never>()
    
    /// Publisher for tasks in the coordinator
    public var tasksPublisher: AnyPublisher<[UUID: ManagedTask], Never> {
        return tasksSubject.eraseToAnyPublisher()
    }
    
    /// Initialize the coordinator
    /// - Parameter maxConcurrentTasks: Maximum number of tasks that can run simultaneously
    public init(maxConcurrentTasks: Int = 4) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }
    
    /// Register a task with the coordinator
    /// - Parameter task: The task to register
    /// - Returns: The registered task's ID
    @discardableResult
    public func registerTask(_ task: ManagedTask) -> UUID {
        taskQueue.sync(flags: .barrier) {
            tasks[task.id] = task
            tasksSubject.send(tasks)
        }
        return task.id
    }
    
    /// Create and register a task with a work closure
    /// - Parameters:
    ///   - priority: The task priority
    ///   - isCancellable: Whether the task can be cancelled
    ///   - work: The work closure
    /// - Returns: The created task's ID
    @discardableResult
    public func createTask<T>(
        priority: TaskPriority = .medium,
        isCancellable: Bool = true,
        work: @escaping () async throws -> T
    ) -> UUID {
        let task = BackgroundTask(
            priority: priority,
            isCancellable: isCancellable,
            workItem: work
        )
        return registerTask(task)
    }
    
    /// Create and start a task with progress reporting
    /// - Parameters:
    ///   - priority: The task priority
    ///   - progressHandler: Handler for progress updates
    ///   - work: The work closure that takes a progress update function
    /// - Returns: The created task's ID
    @discardableResult
    public func progressReportingTask<T>(
        priority: TaskPriority = .medium,
        work: @escaping (_ updateProgress: @escaping (Double, String) -> Void) async throws -> T
    ) -> UUID {
        let taskID = UUID()
        
        let task = BackgroundTask<T>(
            id: taskID,
            priority: priority,
            workItem: {
                // This closure captures the task itself for progress reporting
                guard let enhancedTask = self.getTask(id: taskID) as? EnhancedProgressReporting & BackgroundTask<T> else {
                    throw TaskCoordinatorError.taskNotFound(id: taskID)
                }
                
                return try await work { progress, message in
                    enhancedTask.updateProgress(progress: progress, message: message)
                }
            }
        )
        
        registerTask(task)
        
        return taskID
    }
    
    /// Start a task by its ID
    /// - Parameter id: The task ID
    /// - Throws: Error if the task cannot be started
    public func startTask<Result>(id: UUID) async throws -> Result {
        guard let task = getTask(id: id) else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        try await task.start()
        
        // Get the task result
        if let backgroundTask = task as? BackgroundTask<Result> {
            return try backgroundTask.getResult()
        }
        
        throw TaskCoordinatorError.resultNotAvailable
    }
    
    /// Start a task and get its progress publisher
    /// - Parameter id: The task ID
    /// - Returns: A publisher for task progress updates
    /// - Throws: Error if the task cannot be started
    public func startTaskWithProgress<Result>(id: UUID) async throws -> (AnyPublisher<ProgressUpdate, Never>, Result) {
        guard let task = getTask(id: id) as? (EnhancedProgressReporting & ManagedTask) else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        let progressPublisher = task.progressPublisher
        
        try await task.start()
        
        // Get the task result
        if let backgroundTask = task as? BackgroundTask<Result> {
            let result = try backgroundTask.getResult()
            return (progressPublisher, result)
        }
        
        throw TaskCoordinatorError.resultNotAvailable
    }
    
    /// Cancel a task by its ID
    /// - Parameter id: The task ID
    /// - Throws: Error if the task cannot be cancelled
    public func cancelTask(id: UUID) async throws {
        guard let task = getTask(id: id) else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        try await task.cancel()
        
        // Remove the task after cancellation
        removeTask(id: id)
    }
    
    /// Remove a task from the coordinator
    /// - Parameter id: The task ID
    /// - Returns: Whether the task was successfully removed
    @discardableResult
    public func removeTask(id: UUID) -> Bool {
        var result = false
        
        taskQueue.sync(flags: .barrier) {
            if tasks.removeValue(forKey: id) != nil {
                taskResults.removeValue(forKey: id)
                result = true
            }
            
            tasksSubject.send(tasks)
        }
        
        return result
    }
    
    /// Get a task by its ID
    /// - Parameter id: The task ID
    /// - Returns: The task if found, nil otherwise
    public func getTask(id: UUID) -> ManagedTask? {
        return taskQueue.sync {
            return tasks[id]
        }
    }
    
    /// Get all registered tasks
    /// - Returns: Dictionary of task IDs to tasks
    public func getAllTasks() -> [UUID: ManagedTask] {
        return taskQueue.sync {
            return tasks
        }
    }
    
    /// Get a task result by its ID
    /// - Parameter id: The task ID
    /// - Returns: The task result if available
    public func getTaskResult<T>(id: UUID) -> T? {
        guard let task = getTask(id: id) else {
            return nil
        }
        
        if let backgroundTask = task as? BackgroundTask<T> {
            do {
                return try backgroundTask.getResult()
            } catch {
                return nil
            }
        }
        
        // Return cached result if available
        return taskQueue.sync {
            return taskResults[id] as? T
        }
    }
    
    /// Get tasks filtered by priority
    /// - Parameter priority: The priority to filter by
    /// - Returns: Array of tasks with the specified priority
    public func getTasksByPriority(_ priority: TaskPriority) -> [ManagedTask] {
        return taskQueue.sync {
            return tasks.values.filter { $0.priority == priority }
        }
    }
} 