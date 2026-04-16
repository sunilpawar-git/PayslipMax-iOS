import Foundation
import Combine

// MARK: - Internal Methods

extension TaskMonitor {

    func setupSubscriptions() {
        taskCoordinatorWrapper.publisher
            .sink { [weak self] enhancedEvent in
                guard let self = self, self.isMonitoringEnabled else { return }
                
                self.processEnhancedEvent(enhancedEvent)
            }
            .store(in: &cancellables)
    }

    func processEnhancedEvent(_ enhancedEvent: TaskCoordinatorWrapper.EnhancedTaskEvent) {
        switch enhancedEvent.baseEvent {
        case .registered(let id):
            recordTaskCreation(id, metadata: enhancedEvent.metadata)
            
        case .started(let id):
            recordTaskStart(id, metadata: enhancedEvent.metadata)
            
        case .progressed(let id, let progress, let message):
            recordTaskProgress(id, progress: progress, message: message, metadata: enhancedEvent.metadata)
            
        case .completed(let id):
            recordTaskCompletion(id, metadata: enhancedEvent.metadata)
            
        case .failed(let id, let error):
            recordTaskFailure(id, error: error, metadata: enhancedEvent.metadata)
            
        case .cancelled(let id):
            recordTaskCancellation(id, metadata: enhancedEvent.metadata)
            
        case .queued(_, _):
            break
            
        case .throttled(let currentCount, let maxAllowed):
            print("Task throttled: \(currentCount)/\(maxAllowed) tasks running")
        }
    }

    // MARK: - Periodic Cleanup

    func setupPeriodicCleanup() {
        cleanupTask = Task {
            while !Task.isCancelled && isMonitoringEnabled {
                try? await Task.sleep(nanoseconds: 3_600_000_000_000)
                await cleanupOldTaskHistory()
            }
        }
    }

    func cleanupOldTaskHistory() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                let cutoffTime = Date().addingTimeInterval(-24 * 60 * 60)
                
                var keysToRemove = [String]()
                
                self.historyLock.withLock {
                    for (key, entry) in self.taskHistory {
                        if let completedAt = entry.metrics.completedAt, completedAt < cutoffTime {
                            keysToRemove.append(key)
                        }
                    }
                    
                    for key in keysToRemove {
                        self.taskHistory.removeValue(forKey: key)
                    }
                }
                
                let count = keysToRemove.count
                
                if count > 0 {
                    self.logMessage("Cleaned up \(count) old task history entries")
                }
                
                continuation.resume()
            }
        }
    }
}
