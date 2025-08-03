import Foundation
import Combine

/// Coordinates the execution of tasks with dependency management and prioritization
@MainActor
public class TaskExecutionCoordinator {
    
    // MARK: - Properties
    
    private let taskStorage: TaskStorage
    private var taskPublisher: PassthroughSubject<TaskEvent, Never>
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(taskStorage: TaskStorage, taskPublisher: PassthroughSubject<TaskEvent, Never>) {
        self.taskStorage = taskStorage
        self.taskPublisher = taskPublisher
    }
    
    // MARK: - Task Execution
    
    /// Start a registered task
    /// - Parameter id: The ID of the task to start
    /// - Returns: The result of the task
    public func startTask<T>(id: TaskIdentifier) async throws -> T {
        guard let task = await taskStorage.getTask(id) as? BackgroundTask<T> else {
            throw TaskCoordinatorError.taskNotFound(id: id)
        }
        
        // Check dependencies are completed
        try await validateDependencies(for: task)
        
        // Start the task
        taskPublisher.send(.started(id))
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
                
                cancellable = taskPublisher
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
    
    // MARK: - Progress Tracking
    
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
                self.taskPublisher
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
    
    // MARK: - Private Methods
    
    /// Validate that all dependencies for a task are completed
    /// - Parameter task: The task to validate dependencies for
    private func validateDependencies(for task: any ManagedTask) async throws {
        for dependencyId in task.dependencies {
            guard let dependencyTask = await taskStorage.getTask(dependencyId) else {
                throw TaskCoordinatorError.taskNotFound(id: dependencyId)
            }
            
            if !dependencyTask.status.isTerminal {
                // Start dependency task if it's pending
                if case .pending = dependencyTask.status {
                    // Start dependency task without type parameter (let the system infer)
                    try await dependencyTask.start()
                } else {
                    // Wait for running dependency to complete
                    try await waitForTask(id: dependencyId)
                }
            }
            
            // Check if dependency completed successfully
            if case .failed(let error) = dependencyTask.status {
                throw error
            }
            
            if case .cancelled = dependencyTask.status {
                throw TaskCoordinatorError.taskCancelled(id: dependencyId)
            }
        }
    }
    
    /// Get a task's result (for internal use)
    private func getTaskResult(id: TaskIdentifier) -> Any? {
        // This would require storing task results
        // For now, we return nil
        return nil
    }
}