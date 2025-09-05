import Foundation
import Combine

// MARK: - TaskMonitor Recording Methods Extension
extension TaskMonitor {
    
    /// Record the creation of a new task
    internal func recordTaskCreation(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        // Create a new history entry
        let entry = TaskHistoryEntry(id: id)
        
        // We can't directly mutate the TaskInfo struct since it's a let property
        // Commenting out the priority handling for now
        // _ = metadata["priority"] // Acknowledge the variable to avoid 'unused' warning
        
        taskHistory[id.description] = entry
        
        // Publish monitoring event
        eventPublisher.send(.taskCreated(id))
        
        // Trim history if needed
        if taskHistory.count > maxHistoryEntries {
            // Remove the oldest entry
            let oldestKey = taskHistory.keys.sorted { lhs, rhs in
                guard let lhsDate = taskHistory[lhs]?.info.createdAt,
                      let rhsDate = taskHistory[rhs]?.info.createdAt else {
                    return false
                }
                return lhsDate < rhsDate
            }.first
            
            if let oldestKey = oldestKey {
                taskHistory.removeValue(forKey: oldestKey)
            }
        }
    }
    
    /// Record the start of a task
    internal func recordTaskStart(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let startTime = metadata["startTime"] as? Date ?? Date()
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.startedAt = startTime
            updatedMetrics.status = "Running"
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            eventPublisher.send(.taskStarted(id))
        }
    }
    
    /// Record progress update for a task
    internal func recordTaskProgress(_ id: TaskIdentifier, progress: Double, message: String, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let timestamp = metadata["timestamp"] as? Date ?? Date()
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.progressUpdates += 1
            entry.metrics = updatedMetrics
            
            // Only record progress at 10% increments to avoid excessive history
            if entry.progressHistory.isEmpty || 
               abs(progress - entry.progressHistory.last!.progress) >= 0.1 ||
               progress >= 0.99 {
                entry.progressHistory.append((progress: progress, message: message, timestamp: timestamp))
            }
            
            taskHistory[id.description] = entry
        }
    }
    
    /// Record the completion of a task
    internal func recordTaskCompletion(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Completed"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            if let duration = duration {
                eventPublisher.send(.taskCompleted(id, duration: duration))
            } else {
                eventPublisher.send(.taskCompleted(id, duration: 0))
            }
        }
    }
    
    /// Record the failure of a task
    internal func recordTaskFailure(_ id: TaskIdentifier, error: Error, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Failed: \(error.localizedDescription)"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            // Record error information
            entry.error = TaskErrorInfo(error: error)
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            if let duration = duration {
                eventPublisher.send(.taskFailed(id, error: error, duration: duration))
            } else {
                eventPublisher.send(.taskFailed(id, error: error, duration: 0))
            }
        }
    }
    
    /// Record the cancellation of a task
    internal func recordTaskCancellation(_ id: TaskIdentifier, metadata: [String: Any]) {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        if var entry = taskHistory[id.description] {
            let completionTime = metadata["completionTime"] as? Date ?? Date()
            let duration = metadata["duration"] as? TimeInterval ?? 
                          (entry.metrics.startedAt.map { completionTime.timeIntervalSince($0) })
            
            // Update metrics
            var updatedMetrics = entry.metrics
            updatedMetrics.completedAt = completionTime
            updatedMetrics.status = "Cancelled"
            updatedMetrics.duration = duration
            entry.metrics = updatedMetrics
            
            taskHistory[id.description] = entry
            
            // Publish monitoring event
            eventPublisher.send(.taskCancelled(id, duration: duration))
        }
    }
}
