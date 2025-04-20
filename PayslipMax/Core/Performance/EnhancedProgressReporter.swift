import Foundation
import Combine

/// Protocol for enhanced progress reporting with time estimation and publishers
public protocol EnhancedProgressReporting: ProgressReporting {
    /// Publisher that emits progress updates
    var progressPublisher: AnyPublisher<ProgressUpdate, Never> { get }
}

/// A concrete implementation of enhanced progress reporting with time estimation
public class EnhancedProgressReporter: EnhancedProgressReporting {
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
    
    // Matching the ProgressReporting protocol in BackgroundTaskCoordinator
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    public var isCancellable: Bool {
        return isCancellableValue
    }
    
    public var progressPublisher: AnyPublisher<ProgressUpdate, Never> {
        return progressSubject.eraseToAnyPublisher()
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
            let startTime = startTime,
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

/// Enhanced aggregator for progress reporters
/// Renamed to avoid conflict with AggregateProgressReporter in ProgressReporter.swift
public class EnhancedAggregateReporter: EnhancedProgressReporting {
    private var reporters: [String: EnhancedProgressReporting] = [:]
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
    
    // Matching the ProgressReporting protocol in BackgroundTaskCoordinator
    public var statusMessage: String {
        return progressSubject.value.message
    }
    
    public var isCancellable: Bool {
        return isCancellableValue
    }
    
    public var progressPublisher: AnyPublisher<ProgressUpdate, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    /// Add a reporter to the aggregate
    /// - Parameters:
    ///   - reporter: The progress reporter to add
    ///   - id: Unique identifier for this reporter
    ///   - weight: Relative weight of this reporter (default: 1.0)
    public func addReporter(_ reporter: EnhancedProgressReporting, id: String, weight: Double = 1.0) {
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
                
                // Use a safer approach to access the current value
                if let progressPublisher = reporter.progressPublisher as? CurrentValueSubject<ProgressUpdate, Never>,
                   let estimate = progressPublisher.value.estimatedTimeRemaining {
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