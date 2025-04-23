import Foundation
import Combine

/// Structure encapsulating a progress update
public struct ProgressUpdate: Equatable {
    /// Progress value between 0.0 and 1.0
    public let progress: Double
    
    /// Description of the current progress state
    public let message: String
    
    /// Estimated time remaining in seconds (nil if unknown)
    public let estimatedTimeRemaining: TimeInterval?
    
    /// Timestamp when this update was created
    public let timestamp: Date
    
    public init(
        progress: Double,
        message: String,
        estimatedTimeRemaining: TimeInterval? = nil,
        timestamp: Date = Date()
    ) {
        self.progress = max(0, min(1, progress))
        self.message = message
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.timestamp = timestamp
    }
}

/// A concrete implementation of progress reporting with time estimation
public class ProgressReporter: ProgressReporting {
    private let progressSubject = CurrentValueSubject<ProgressUpdate, Never>(
        ProgressUpdate(progress: 0, message: "Not started")
    )
    
    private var startTime: Date?
    private var recentUpdates: [(progress: Double, timestamp: Date)] = []
    private let maxRecentUpdates = 5
    private let isCancellableValue: Bool
    
    public init(isCancellable: Bool = true) {
        self.isCancellableValue = isCancellable
    }
    
    public var progress: Double {
        return progressSubject.value.progress
    }
    
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    public var isCancellable: Bool {
        return isCancellableValue
    }
    
    public var progressPublisher: AnyPublisher<ProgressUpdate, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    public var estimatedTimeRemaining: TimeInterval? {
        // Directly return the estimated time from the last update
        return progressSubject.value.estimatedTimeRemaining
    }
    
    /// Current value of the progress update
    public var currentProgressUpdate: ProgressUpdate {
        return progressSubject.value
    }
    
    /// Update the progress with a new value and message
    /// - Parameters:
    ///   - progress: Current progress (0.0 to 1.0)
    ///   - message: Description of the current state
    public func update(progress: Double, message: String) {
        let now = Date()
        
        if startTime == nil && progress > 0 {
            startTime = now
        }
        
        // Keep track of recent updates for time estimation
        recentUpdates.append((progress: progress, timestamp: now))
        if recentUpdates.count > maxRecentUpdates {
            recentUpdates.removeFirst()
        }
        
        let estimatedTimeRemaining = calculateEstimatedTimeRemaining(currentProgress: progress)
        
        let update = ProgressUpdate(
            progress: progress,
            message: message,
            estimatedTimeRemaining: estimatedTimeRemaining,
            timestamp: now
        )
        
        progressSubject.send(update)
    }
    
    /// Reset the progress reporter to its initial state
    public func reset() {
        startTime = nil
        recentUpdates.removeAll()
        progressSubject.send(ProgressUpdate(progress: 0, message: "Reset"))
    }
    
    /// Calculate the estimated time remaining based on progress history
    /// - Parameter currentProgress: The current progress value (0.0 to 1.0)
    /// - Returns: Estimated time remaining in seconds, or nil if it cannot be calculated
    private func calculateEstimatedTimeRemaining(currentProgress: Double) -> TimeInterval? {
        guard
            startTime != nil,  // Check startTime without assigning to variable
            recentUpdates.count >= 2,
            currentProgress > 0.01 && currentProgress < 0.99
        else {
            return nil
        }
        
        // Calculate progress rate based on recent updates
        let first = recentUpdates.first!
        let last = recentUpdates.last!
        let progressDelta = last.progress - first.progress
        let timeDelta = last.timestamp.timeIntervalSince(first.timestamp)
        
        // Avoid division by zero or very small deltas
        guard progressDelta > 0.001 && timeDelta > 0.1 else {
            return nil
        }
        
        // Calculate rate of progress (progress units per second)
        let progressRate = progressDelta / timeDelta
        
        // Calculate estimated time remaining
        let remainingProgress = 1.0 - currentProgress
        let estimatedTimeRemaining = remainingProgress / progressRate
        
        // Return nil if estimation is unreasonable
        if estimatedTimeRemaining < 0 || estimatedTimeRemaining > 3600 * 24 {
            return nil
        }
        
        return estimatedTimeRemaining
    }
}

/// Aggregates multiple progress reporters into a single reporter
public class AggregateProgressReporter: ProgressReporting {
    private var reporters = [String: ProgressReporter]()
    private var weights: [String: Double] = [:]
    private let progressSubject = CurrentValueSubject<ProgressUpdate, Never>(
        ProgressUpdate(progress: 0, message: "Not started")
    )
    private var cancellables = Set<AnyCancellable>()
    private let isCancellableValue: Bool
    
    public init(isCancellable: Bool = true) {
        self.isCancellableValue = isCancellable
    }
    
    public var progress: Double {
        return progressSubject.value.progress
    }
    
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    public var isCancellable: Bool {
        return isCancellableValue
    }
    
    public var progressPublisher: AnyPublisher<ProgressUpdate, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    public var estimatedTimeRemaining: TimeInterval? {
        // Return the calculated estimate from the last recalculation
        return progressSubject.value.estimatedTimeRemaining
    }
    
    /// Add a reporter to the aggregate
    /// - Parameters:
    ///   - reporter: The progress reporter to add
    ///   - id: Unique identifier for this reporter
    ///   - weight: Relative weight of this reporter (default: 1.0)
    public func addReporter(_ reporter: ProgressReporter, id: String, weight: Double = 1.0) {
        reporters[id] = reporter
        weights[id] = max(0, weight)
        
        reporter.progressPublisher
            .sink { [weak self] _ in
                self?.recalculateProgress()
            }
            .store(in: &cancellables)
    }
    
    /// Remove a reporter from the aggregate
    /// - Parameter id: The identifier of the reporter to remove
    public func removeReporter(id: String) {
        reporters.removeValue(forKey: id)
        weights.removeValue(forKey: id)
        recalculateProgress()
    }
    
    /// Recalculate the overall progress based on all reporters
    private func recalculateProgress() {
        guard !reporters.isEmpty else {
            progressSubject.send(ProgressUpdate(progress: 0, message: "No active tasks"))
            return
        }
        
        var totalProgress = 0.0
        var totalWeight = 0.0
        var messages = [String]()
        var timeEstimates = [TimeInterval]()
        
        // Calculate weighted progress average
        for (id, reporter) in reporters {
            let weight = weights[id] ?? 1.0
            totalProgress += reporter.progress * weight
            totalWeight += weight
            
            if reporter.progress > 0 && reporter.progress < 1 {
                messages.append(reporter.statusMessage)
                
                if let estimate = reporter.currentProgressUpdate.estimatedTimeRemaining {
                    timeEstimates.append(estimate)
                }
            }
        }
        
        let averageProgress = totalWeight > 0 ? totalProgress / totalWeight : 0
        
        // Create a combined message from active tasks
        let combinedMessage = messages.isEmpty ? "Processing..." : messages.joined(separator: ", ")
        
        // Calculate average estimated time remaining
        let estimatedTimeRemaining: TimeInterval?
        if !timeEstimates.isEmpty {
            estimatedTimeRemaining = timeEstimates.reduce(0, +) / Double(timeEstimates.count)
        } else {
            estimatedTimeRemaining = nil
        }
        
        progressSubject.send(ProgressUpdate(
            progress: averageProgress,
            message: combinedMessage,
            estimatedTimeRemaining: estimatedTimeRemaining
        ))
    }
} 