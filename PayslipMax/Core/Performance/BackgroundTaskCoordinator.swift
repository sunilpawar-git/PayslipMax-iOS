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
    /// Note: This is a synchronous property that may return an approximation
    /// For more accurate values, use the async version if available
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
    private var startTime: TimeInterval?
    
    private var statusSubject = CurrentValueSubject<TaskStatus, Never>(.pending)
    
    // Actor for thread-safe state management
    private actor TaskState {
        var status: TaskStatus = .pending
        var startTime: TimeInterval?
        
        func updateStatus(_ newStatus: TaskStatus) {
            status = newStatus
        }
        
        func setStartTime(_ time: TimeInterval) {
            startTime = time
        }
    }
    
    private var _state = TaskState()
    
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
    
    // Cached estimated time remaining (for protocol conformance)
    private var cachedTimeRemaining: TimeInterval?
    private var lastTimeEstimationUpdate: TimeInterval = 0
    
    // Synchronous implementation required by ProgressReporting protocol
    public var estimatedTimeRemaining: TimeInterval? {
        // Return cached value if available and recent (within 1 second)
        let now = Date().timeIntervalSince1970
        if let cached = cachedTimeRemaining, now - lastTimeEstimationUpdate < 1.0 {
            return cached
        }
        
        // If no recent cache, return nil - client should call async version
        return nil
    }
    
    // Asynchronous calculation of estimated time remaining
    public func calculateEstimatedTimeRemaining() async -> TimeInterval? {
        let currentProgress = progress
        
        // Return 0 for completed tasks or tasks that haven't started yet
        if currentProgress >= 1.0 {
            cachedTimeRemaining = 0
            lastTimeEstimationUpdate = Date().timeIntervalSince1970
            return 0
        }
        
        if currentProgress <= 0.0 {
            cachedTimeRemaining = nil
            return nil // Cannot estimate if no progress has been made
        }
        
        // Get the current time
        let now = Date().timeIntervalSince1970
        
        // Access start time through the actor
        let startTime = await _state.startTime
        
        // Check if we're tracking start time - if not, can't calculate
        guard let startTime = startTime else {
            cachedTimeRemaining = nil
            return nil
        }
        
        // Calculate elapsed time
        let elapsedTime = now - startTime
        
        // If we've just started, we might not have enough data for a reliable estimate
        if elapsedTime < 1.0 || currentProgress < 0.05 {
            cachedTimeRemaining = nil
            return nil
        }
        
        // Calculate remaining time based on current progress rate
        // Formula: (elapsed time / current progress) * (1 - current progress)
        let estimatedTotalTime = elapsedTime / currentProgress
        let remainingTime = estimatedTotalTime - elapsedTime
        
        // Return nil if the estimate is unreasonably large (e.g., > 24 hours)
        if remainingTime > 86400 {
            cachedTimeRemaining = nil
            return nil
        }
        
        let result = max(0, remainingTime) // Ensure we don't return negative values
        
        // Update the cache
        cachedTimeRemaining = result
        lastTimeEstimationUpdate = now
        
        return result
    }
    
    public var isCancellable: Bool {
        return true
    }
    
    public func start() async throws {
        // Check current status using the actor
        let currentStatus = await _state.status
        guard case .pending = currentStatus else {
            if case .completed = currentStatus {
                return
            }
            throw TaskCoordinatorError.invalidTaskState(id: id, status: currentStatus)
        }
        
        // Record start time for time remaining calculations
        let now = Date().timeIntervalSince1970
        await _state.setStartTime(now)
        
        // Update status to running
        await _state.updateStatus(.running)
        progressSubject.send((0.0, "Starting \(id.name)"))
        
        // Start a background task to periodically update the estimated time remaining
        let timeEstimationTask = Task {
            while !Task.isCancelled {
                // Calculate and update the estimated time remaining
                _ = await calculateEstimatedTimeRemaining()
                
                // Check if task is still running
                let status = await _state.status
                if status.isTerminal {
                    break
                }
                
                // Wait a short time before updating again
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        
        task = Task {
            // Use defer to ensure cleanup happens regardless of success or failure
            defer {
                // Cancel the time estimation task
                timeEstimationTask.cancel()
            }
            
            do {
                let result = try await operation { [weak self] progress, message in
                    guard let self = self else { return }
                    self.progressSubject.send((progress, message))
                }
                
                // Only update status if not already terminal
                let taskStatus = await self._state.status
                if !taskStatus.isTerminal {
                    await self._state.updateStatus(.completed)
                    self.progressSubject.send((1.0, "Completed"))
                }
                
                // Final time remaining update
                self.cachedTimeRemaining = 0
                self.lastTimeEstimationUpdate = Date().timeIntervalSince1970
                
                return result
            } catch is CancellationError {
                await self._state.updateStatus(.cancelled)
                self.progressSubject.send((self.progress, "Cancelled"))
                throw TaskCoordinatorError.taskCancelled(id: id)
            } catch {
                await self._state.updateStatus(.failed(error))
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
        await _state.updateStatus(.cancelled)
        
        // Update cached time remaining on cancellation
        cachedTimeRemaining = nil
        lastTimeEstimationUpdate = Date().timeIntervalSince1970
        
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
    
    // Simple queue for managing task execution (replaces disabled TaskPriorityQueue)
    private var taskQueue: [TaskIdentifier] = []
    private let queueLock = NSLock()
    
    private init(maxConcurrentTasks: Int = 4) {
        // Initialize simple task management (TaskPriorityQueue temporarily disabled)
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
    /// The progress is calculated as a weighted average with equal weights assigned to each task.
    /// - Parameter taskId: The ID of the main task
    /// - Returns: A publisher emitting the aggregated progress
    public func aggregatedProgressPublisher(for taskId: TaskIdentifier) -> AnyPublisher<Double, Never> {
        return Future<AnyPublisher<Double, Never>, Never> { [weak self] promise in
            guard let self = self else {
                promise(.success(Just(0.0).eraseToAnyPublisher()))
                return
            }
            
            Task {
                // Collect all tasks in the dependency tree
                var allTaskIds = Set<TaskIdentifier>()
                var allTasks = [TaskIdentifier: any ManagedTask]()
                
                // Recursive function to traverse dependency tree
                func collectDependencies(_ id: TaskIdentifier) async {
                    guard !allTaskIds.contains(id),
                          let task = await self.taskStorage.getTask(id) else {
                        return
                    }
                    
                    allTaskIds.insert(id)
                    allTasks[id] = task
                    
                    for dependencyId in task.dependencies {
                        await collectDependencies(dependencyId)
                    }
                }
                
                // Start by collecting the main task and its dependencies
                await collectDependencies(taskId)
                
                // If no tasks found, return a publisher that emits 0.0
                if allTasks.isEmpty {
                    promise(.success(Just(0.0).eraseToAnyPublisher()))
                    return
                }
                
                // Create a subject that will aggregate progress updates
                let aggregatedSubject = CurrentValueSubject<Double, Never>(0.0)
                var taskCancellables = Set<AnyCancellable>()
                
                // Function to calculate the aggregated progress
                func updateAggregatedProgress() {
                    var totalProgress = 0.0
                    var completedTasks = 0
                    
                    for (_, task) in allTasks {
                        switch task.status {
                        case .completed:
                            totalProgress += 1.0
                            completedTasks += 1
                        case .failed, .cancelled:
                            // For failed/cancelled tasks, use current progress
                            totalProgress += task.progress
                            completedTasks += 1
                        case .running, .pending, .paused:
                            totalProgress += task.progress
                        }
                    }
                    
                    // Calculate weighted average (equal weights)
                    let averageProgress = totalProgress / Double(allTasks.count)
                    aggregatedSubject.send(averageProgress)
                }
                
                // Subscribe to progress updates from all tasks
                for (_, task) in allTasks {
                    if let backgroundTask = task as? BackgroundTask<Any> {
                        backgroundTask.progressPublisher
                            .sink { _ in
                                updateAggregatedProgress()
                            }
                            .store(in: &taskCancellables)
                    }
                }
                
                // Subscribe to task status events
                self.publisher
                    .filter { event in
                        switch event {
                        case .completed(let eventId), .failed(let eventId, _), .cancelled(let eventId), .progressed(let eventId, _, _):
                            return allTaskIds.contains(eventId)
                        default:
                            return false
                        }
                    }
                    .sink { _ in
                        updateAggregatedProgress()
                    }
                    .store(in: &taskCancellables)
                
                // Calculate initial progress
                updateAggregatedProgress()
                
                // Return the subject as a publisher
                promise(.success(aggregatedSubject.handleEvents(
                    receiveCancel: {
                        // Clean up cancellables when the publisher is cancelled
                        taskCancellables.forEach { $0.cancel() }
                        taskCancellables.removeAll()
                    }
                ).eraseToAnyPublisher()))
            }
        }
        .flatMap { $0 } // Flatten the Future<Publisher> to Publisher
        .eraseToAnyPublisher()
    }
    
    private func setupSubscriptions() {
        // TaskPriorityQueue temporarily disabled - simple setup for now
        // TODO: Re-enable when TaskPriorityQueue refactoring is complete
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
        
        // Start the task directly (TaskPriorityQueue temporarily disabled)
        try await task.start()
        
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