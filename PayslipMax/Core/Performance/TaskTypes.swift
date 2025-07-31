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