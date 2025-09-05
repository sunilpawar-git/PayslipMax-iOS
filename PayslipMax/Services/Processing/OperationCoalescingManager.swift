import Foundation
import Combine

/// Manages operation coalescing and result broadcasting
/// Handles the core logic for sharing results between concurrent identical requests
final class OperationCoalescingManager {
    
    // MARK: - Properties
    
    /// Dictionary to store pending operations by key
    private var pendingOperations: [String: Any] = [:]
    
    /// Operation tracker for monitoring and cleanup
    private var operationTracker = PendingOperationTracker()
    
    /// Statistics tracking
    @Published private(set) var statistics = CoalescingStatistics()
    
    /// Queue for thread-safe operations
    private let operationQueue = DispatchQueue(label: "com.payslipmax.coalescing", attributes: .concurrent)
    
    /// Cleanup timer
    private var cleanupTimer: Timer?
    
    /// Whether coalescing is enabled
    private var isEnabled = true
    
    // MARK: - Initialization
    
    init() {
        setupCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Execute operation with coalescing support
    /// - Parameters:
    ///   - key: Unique key for operation identification
    ///   - operation: Async operation to execute
    /// - Returns: Operation result
    func executeWithCoalescing<T>(key: String, operation: @escaping () async throws -> T) async throws -> T {
        guard isEnabled else {
            return try await operation()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            operationQueue.async(flags: .barrier) {
                self.handleOperationRequest(key: key, continuation: continuation, operation: operation)
            }
        }
    }
    
    /// Execute operation with context-based coalescing
    /// - Parameters:
    ///   - context: Operation context for key generation
    ///   - operation: Async operation to execute
    /// - Returns: Operation result
    func executeWithCoalescing<T>(context: OperationContext, operation: @escaping () async throws -> T) async throws -> T {
        return try await executeWithCoalescing(key: context.cacheKey(), operation: operation)
    }
    
    /// Check if operation is currently pending
    /// - Parameter key: Operation key to check
    /// - Returns: True if operation is pending
    func isOperationPending(key: String) -> Bool {
        return operationQueue.sync {
            return pendingOperations[key] != nil
        }
    }
    
    /// Cancel pending operation
    /// - Parameter key: Operation key to cancel
    /// - Returns: True if operation was cancelled
    func cancelOperation(key: String) -> Bool {
        return operationQueue.sync(flags: .barrier) {
            if let operation = pendingOperations[key] as? AnyCoalescedOperation {
                operation.cancel()
                pendingOperations.removeValue(forKey: key)
                operationTracker.removeOperation(key: key)
                statistics.recordCancellation()
                return true
            }
            return false
        }
    }
    
    /// Enable or disable coalescing
    /// - Parameter enabled: Whether to enable coalescing
    func setCoalescingEnabled(_ enabled: Bool) {
        isEnabled = enabled
        
        if !enabled {
            // Cancel all pending operations if disabling
            operationQueue.async(flags: .barrier) {
                for key in self.pendingOperations.keys {
                    if let operation = self.pendingOperations[key] as? AnyCoalescedOperation {
                        operation.cancel()
                    }
                }
                self.pendingOperations.removeAll()
                self.operationTracker.clear()
            }
        }
    }
    
    /// Get current statistics
    func getStatistics() -> CoalescingStatistics {
        return statistics
    }
    
    /// Clear all statistics
    func clearStatistics() {
        statistics = CoalescingStatistics()
    }
    
    /// Get number of pending operations
    var pendingOperationCount: Int {
        return operationQueue.sync {
            return pendingOperations.count
        }
    }
    
    // MARK: - Private Methods
    
    private func handleOperationRequest<T>(key: String, 
                                         continuation: CheckedContinuation<T, Error>,
                                         operation: @escaping () async throws -> T) {
        
        // Check if operation already exists
        if let existingOperation = pendingOperations[key] as? CoalescedOperation<T> {
            // Add subscriber to existing operation
            if existingOperation.addSubscriber(continuation) {
                statistics.totalSubscribers += 1
                return
            } else {
                // Failed to add subscriber, execute independently
                Task {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                return
            }
        }
        
        // Create new coalesced operation
        let coalescedOperation = CoalescedOperation<T>(key: key)
        pendingOperations[key] = coalescedOperation
        operationTracker.addOperation(key: key)
        
        // Add the first subscriber
        if coalescedOperation.addSubscriber(continuation) {
            statistics.totalSubscribers += 1
        }
        
        // Execute the operation
        Task {
            let startTime = Date()
            
            do {
                let result = try await operation()
                
                // Complete operation and notify subscribers
                self.operationQueue.async(flags: .barrier) {
                    coalescedOperation.complete(with: .success(result))
                    self.pendingOperations.removeValue(forKey: key)
                    self.operationTracker.removeOperation(key: key)
                    
                    // Update statistics
                    let duration = Date().timeIntervalSince(startTime)
                    let subscriberCount = coalescedOperation.subscriberCount()
                    self.statistics.recordOperation(
                        subscriberCount: subscriberCount + 1, // +1 for the original subscriber
                        duration: duration,
                        wasCoalesced: subscriberCount > 0
                    )
                }
                
            } catch {
                // Complete operation with error
                self.operationQueue.async(flags: .barrier) {
                    coalescedOperation.complete(with: .failure(error))
                    self.pendingOperations.removeValue(forKey: key)
                    self.operationTracker.removeOperation(key: key)
                    
                    // Update statistics
                    let duration = Date().timeIntervalSince(startTime)
                    let subscriberCount = coalescedOperation.subscriberCount()
                    self.statistics.recordOperation(
                        subscriberCount: subscriberCount + 1,
                        duration: duration,
                        wasCoalesced: subscriberCount > 0
                    )
                }
            }
        }
    }
    
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: CoalescingConfig.cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performCleanup()
            }
        }
    }
    
    private func performCleanup() {
        operationQueue.async(flags: .barrier) {
            let expiredKeys = self.operationTracker.getExpiredOperations()
            
            for key in expiredKeys {
                if let operation = self.pendingOperations[key] as? AnyCoalescedOperation {
                    operation.cancel()
                    self.pendingOperations.removeValue(forKey: key)
                    self.operationTracker.removeOperation(key: key)
                    self.statistics.recordTimeout()
                }
            }
        }
    }
}

// MARK: - Type Erasure

/// Type-erased coalesced operation for storage
private protocol AnyCoalescedOperation {
    func cancel()
}

extension CoalescedOperation: AnyCoalescedOperation {
    // Already implements cancel()
}
