import Foundation

/// Entry in the task history for analytics and debugging
public struct TaskHistoryEntry {
    /// Basic information about the task
    public struct TaskInfo {
        public let id: String
        public let name: String
        public let category: String
        public let priority: Int
        public let createdAt: Date
    }
    
    /// Metrics about the task execution
    public struct TaskMetrics {
        public var startedAt: Date?
        public var completedAt: Date?
        public var status: String
        public var duration: TimeInterval?
        public var progressUpdates: Int
        public var peakMemoryUsage: Int?
        public var averageCPUUsage: Double?
    }
    
    /// Basic information about the task
    public let info: TaskInfo
    
    /// Metrics about the task execution
    public var metrics: TaskMetrics
    
    /// Progress history (in 10% increments)
    public var progressHistory: [(progress: Double, message: String, timestamp: Date)]
    
    /// Error information if the task failed
    public var error: TaskErrorInfo?
    
    /// Detailed diagnostics
    public var diagnostics: [String: String]
    
    /// Create a new task history entry
    init(id: TaskIdentifier) {
        self.info = TaskInfo(
            id: id.description,
            name: id.name,
            category: id.category.rawValue,
            priority: 0, // Will be updated later
            createdAt: Date()
        )
        
        self.metrics = TaskMetrics(
            startedAt: nil,
            completedAt: nil,
            status: "Created",
            duration: nil,
            progressUpdates: 0,
            peakMemoryUsage: nil,
            averageCPUUsage: nil
        )
        
        self.progressHistory = []
        self.error = nil
        self.diagnostics = [:]
    }
}

/// Information about a task error
public struct TaskErrorInfo {
    public let message: String
    public let errorType: String
    public let timestamp: Date
    
    init(error: Error, timestamp: Date = Date()) {
        self.message = error.localizedDescription
        self.errorType = String(describing: type(of: error))
        self.timestamp = timestamp
    }
}
