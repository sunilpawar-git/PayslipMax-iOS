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

/// A wrapper around BackgroundTaskCoordinator that provides simplified interfaces
@MainActor
public class TaskCoordinatorWrapper {
    // MARK: - Properties
    
    /// Shared instance for simple access
    public static let shared = TaskCoordinatorWrapper()
    
    /// The underlying coordinator
    private(set) public var coordinator: BackgroundTaskCoordinator
    
    /// Logger for tracking operations
    private let logger = SimpleLogger(category: "TaskCoordinatorWrapper")
    
    /// Publisher for task events with additional logging information
    private let eventPublisher = PassthroughSubject<EnhancedTaskEvent, Never>()
    
    // MARK: - Initialization
    
    /// Initialize with the default coordinator or a custom one for testing
    public init(coordinator: BackgroundTaskCoordinator = .shared) {
        self.coordinator = coordinator
        setupSubscriptions()
        logger.log("TaskCoordinatorWrapper initialized")
    }
    
    // MARK: - Enhanced Events
    
    /// An enhanced task event with additional metadata for diagnostics
    public struct EnhancedTaskEvent {
        public let baseEvent: BackgroundTaskCoordinator.TaskEvent
        public let timestamp: Date
        public let metadata: [String: Any]
        
        init(baseEvent: BackgroundTaskCoordinator.TaskEvent, metadata: [String: Any] = [:]) {
            self.baseEvent = baseEvent
            self.timestamp = Date()
            self.metadata = metadata
        }
    }
    
    /// Publisher for enhanced task events
    public var publisher: AnyPublisher<EnhancedTaskEvent, Never> {
        return eventPublisher.eraseToAnyPublisher()
    }
    
    /// Set up subscriptions to the underlying coordinator's events
    @MainActor
    private func setupSubscriptions() {
        // Just forward events with minimal processing
        coordinator.publisher
            .sink { [weak self] event in
                guard let self = self else { return }
                
                // Create enhanced event with basic metadata
                let metadata = ["timestamp": Date()]
                let enhancedEvent = EnhancedTaskEvent(baseEvent: event, metadata: metadata)
                
                // Forward the enhanced event
                self.eventPublisher.send(enhancedEvent)
            }
            .store(in: &cancellables)
    }
    
    /// Create metadata for an event
    private func createEventMetadata() -> [String: Any] {
        return ["timestamp": Date()]
    }
    
    // MARK: - Task Management Simplification
    
    /// Collection to store and handle task cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Create and start a simple task with error handling
    public func executeTask<T>(
        name: String,
        category: TaskCategory = .general,
        priority: TaskPriority = .medium,
        operation: @escaping (@escaping (Double, String) -> Void) async throws -> T
    ) async throws -> T {
        logger.log("Creating task: \(name)")
        
        do {
            // Create and register task
            let taskId = try await coordinator.createTask(
                name: name,
                category: category,
                priority: priority,
                dependencies: [], 
                operation: { progressReporter in
                    return try await operation(progressReporter)
                }
            )
            
            // Execute task
            logger.log("Starting task: \(taskId.description)")
            let result = try await coordinator.startTask(id: taskId) as T
            
            logger.log("Task completed: \(taskId.description)")
            return result
            
        } catch {
            logger.log("Task failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Create and start a task that doesn't return a value
    public func executeVoidTask(
        name: String,
        category: TaskCategory = .general,
        priority: TaskPriority = .medium,
        operation: @escaping (@escaping (Double, String) -> Void) async throws -> Void
    ) async throws {
        try await executeTask(name: name, category: category, priority: priority, operation: operation)
    }
    
    /// Cancel all tasks in a category with logging
    public func cancelAllTasks(in category: TaskCategory? = nil) async {
        logger.log("Cancelling tasks")
        await coordinator.cancelAllTasks(in: category)
    }
    
    /// Clean up completed, cancelled, and failed tasks
    public func cleanupTasks() async {
        logger.log("Cleaning up completed tasks")
        await coordinator.cleanupTasks()
    }
} 