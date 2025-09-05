import Foundation

/// Types and configurations for operation coalescing functionality
/// Provides data structures for managing concurrent request sharing and result broadcasting

// MARK: - Configuration

/// Configuration for operation coalescing behavior
struct CoalescingConfig {
    static let maxPendingOperations = 50
    static let operationTimeout: TimeInterval = 30.0
    static let coalescingWindow: TimeInterval = 5.0 // Window to group similar requests
    static let maxSubscribers = 20 // Maximum subscribers per operation
    static let cleanupInterval: TimeInterval = 60.0 // Cleanup expired operations every minute
}

// MARK: - Operation Result Management

/// Operation result that can be shared across multiple subscribers
final class CoalescedOperation<T>: @unchecked Sendable {
    let key: String
    let startTime: Date
    private(set) var isCompleted: Bool = false
    private(set) var result: Result<T, Error>?
    private var subscribers: [CheckedContinuation<T, Error>] = []
    private let subscriberLock = NSLock()
    
    init(key: String) {
        self.key = key
        self.startTime = Date()
    }
    
    /// Add a subscriber to this operation
    func addSubscriber(_ continuation: CheckedContinuation<T, Error>) -> Bool {
        subscriberLock.lock()
        defer { subscriberLock.unlock() }
        
        if isCompleted, let result = result {
            // Operation already completed, immediately return result
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
            return true
        }
        
        guard subscribers.count < CoalescingConfig.maxSubscribers else {
            continuation.resume(throwing: CoalescingError.tooManySubscribers)
            return false
        }
        
        subscribers.append(continuation)
        return true
    }
    
    /// Complete the operation and notify all subscribers
    func complete(with result: Result<T, Error>) {
        subscriberLock.lock()
        defer { subscriberLock.unlock() }
        
        guard !isCompleted else { return }
        
        self.result = result
        self.isCompleted = true
        
        // Notify all subscribers
        for subscriber in subscribers {
            switch result {
            case .success(let value):
                subscriber.resume(returning: value)
            case .failure(let error):
                subscriber.resume(throwing: error)
            }
        }
        
        subscribers.removeAll()
    }
    
    /// Check if operation has expired
    func hasExpired() -> Bool {
        return Date().timeIntervalSince(startTime) > CoalescingConfig.operationTimeout
    }
    
    /// Get number of active subscribers
    func subscriberCount() -> Int {
        subscriberLock.lock()
        defer { subscriberLock.unlock() }
        return subscribers.count
    }
    
    /// Cancel operation and notify subscribers
    func cancel() {
        complete(with: .failure(CoalescingError.operationCancelled))
    }
}

// MARK: - Operation Statistics

/// Statistics for tracking coalescing effectiveness
struct CoalescingStatistics: Codable {
    var totalOperations: Int = 0
    var coalescedOperations: Int = 0
    var totalSubscribers: Int = 0
    var averageSubscribersPerOperation: Double = 0.0
    var averageOperationDuration: TimeInterval = 0.0
    var operationsTimedOut: Int = 0
    var operationsCancelled: Int = 0
    
    /// Coalescing efficiency percentage
    var coalescingEfficiency: Double {
        return totalOperations > 0 ? (Double(coalescedOperations) / Double(totalOperations)) * 100.0 : 0.0
    }
    
    /// Average time saved through coalescing
    var averageTimeSaved: TimeInterval {
        return coalescedOperations > 0 ? averageOperationDuration * Double(totalSubscribers - coalescedOperations) : 0.0
    }
    
    /// Update statistics with completed operation
    mutating func recordOperation(subscriberCount: Int, duration: TimeInterval, wasCoalesced: Bool) {
        totalOperations += 1
        totalSubscribers += subscriberCount
        
        if wasCoalesced {
            coalescedOperations += 1
        }
        
        // Update rolling average for operation duration
        let count = Double(totalOperations)
        averageOperationDuration = ((averageOperationDuration * (count - 1)) + duration) / count
        
        // Update rolling average for subscribers per operation
        averageSubscribersPerOperation = Double(totalSubscribers) / count
    }
    
    /// Record timeout
    mutating func recordTimeout() {
        operationsTimedOut += 1
    }
    
    /// Record cancellation
    mutating func recordCancellation() {
        operationsCancelled += 1
    }
}

// MARK: - Error Types

/// Errors that can occur during operation coalescing
enum CoalescingError: Error, LocalizedError {
    case tooManySubscribers
    case operationTimeout
    case operationCancelled
    case operationNotFound
    case coalescingDisabled
    
    var errorDescription: String? {
        switch self {
        case .tooManySubscribers:
            return "Too many subscribers for this operation"
        case .operationTimeout:
            return "Operation timed out"
        case .operationCancelled:
            return "Operation was cancelled"
        case .operationNotFound:
            return "Operation not found"
        case .coalescingDisabled:
            return "Operation coalescing is disabled"
        }
    }
}

// MARK: - Operation Context

/// Context information for operation coalescing
struct OperationContext: Hashable {
    let identifier: String
    let parameters: [String: String]
    let priority: OperationPriority
    
    init(identifier: String, parameters: [String: String] = [:], priority: OperationPriority = .normal) {
        self.identifier = identifier
        self.parameters = parameters
        self.priority = priority
    }
    
    /// Generate cache key for this context
    func cacheKey() -> String {
        let parameterString = parameters.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        return "\(identifier)_\(priority.rawValue)_\(parameterString.isEmpty ? "none" : parameterString)"
    }
}

/// Priority levels for operations
enum OperationPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    /// Numeric value for priority comparison
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Operation Tracking

/// Tracks pending operations for monitoring and cleanup
struct PendingOperationTracker {
    private var operations: [String: Date] = [:]
    private let lock = NSLock()
    
    /// Add operation to tracking
    mutating func addOperation(key: String) {
        lock.lock()
        defer { lock.unlock() }
        operations[key] = Date()
    }
    
    /// Remove operation from tracking
    mutating func removeOperation(key: String) {
        lock.lock()
        defer { lock.unlock() }
        operations.removeValue(forKey: key)
    }
    
    /// Get all expired operations
    func getExpiredOperations() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoffTime = Date().addingTimeInterval(-CoalescingConfig.operationTimeout)
        return operations.compactMap { key, startTime in
            startTime < cutoffTime ? key : nil
        }
    }
    
    /// Get current operation count
    var operationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return operations.count
    }
    
    /// Clear all operations
    mutating func clear() {
        lock.lock()
        defer { lock.unlock() }
        operations.removeAll()
    }
}
