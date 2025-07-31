import Foundation
import Combine

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