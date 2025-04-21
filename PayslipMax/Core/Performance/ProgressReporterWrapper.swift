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

/// A wrapper around ProgressReporter that adds extensive logging
/// and simplifies common operations
public class ProgressReporterWrapper: ProgressReporting {
    // MARK: - Properties
    
    /// The underlying progress reporter
    private let reporter: ProgressReporter
    
    /// Logger for tracking operations
    private let logger = SimpleLogger(category: "ProgressReporterWrapper")
    
    /// History of progress updates for diagnostics
    private var progressHistory: [(progress: Double, message: String, timestamp: Date)] = []
    private let historyLock = NSLock()
    private let maxHistoryEntries = 100
    
    /// Name of this progress reporter for logging
    private let reporterName: String
    
    /// Timestamp when this reporter was created
    private let creationTime = Date()
    
    /// Flag to enable detailed logging
    private let verboseLogging: Bool
    
    // MARK: - ProgressReporting Protocol
    
    public var progress: Double {
        return reporter.progress
    }
    
    public var statusMessage: String {
        return reporter.statusMessage
    }
    
    public var isCancellable: Bool {
        return reporter.isCancellable
    }
    
    // MARK: - Enhanced Properties
    
    /// Publisher for progress updates with additional metadata
    public var progressPublisher: AnyPublisher<(progress: Double, message: String, metadata: [String: Any]), Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    /// Subject for publishing enhanced progress updates
    private let progressSubject = PassthroughSubject<(progress: Double, message: String, metadata: [String: Any]), Never>()
    
    /// Get the complete progress history for diagnostics
    public func getProgressHistory() -> [(progress: Double, message: String, timestamp: Date)] {
        historyLock.lock()
        defer { historyLock.unlock() }
        return progressHistory
    }
    
    /// Get analytics about progress reporting
    public func getProgressAnalytics() -> [String: Any] {
        historyLock.lock()
        defer { historyLock.unlock() }
        
        guard !progressHistory.isEmpty else {
            return ["name": reporterName, "status": "No progress updates recorded"]
        }
        
        let firstUpdate = progressHistory.first!
        let lastUpdate = progressHistory.last!
        let totalDuration = lastUpdate.timestamp.timeIntervalSince(firstUpdate.timestamp)
        
        // Calculate progress rate (units per second)
        let progressRate = totalDuration > 0 ? 
            (lastUpdate.progress - firstUpdate.progress) / totalDuration : 0
        
        // Estimate remaining time
        let remainingProgress = 1.0 - lastUpdate.progress
        let estimatedTimeRemaining = progressRate > 0 ? remainingProgress / progressRate : nil
        
        return [
            "name": reporterName,
            "progress": lastUpdate.progress,
            "started": firstUpdate.timestamp,
            "lastUpdate": lastUpdate.timestamp,
            "totalDuration": totalDuration,
            "updateCount": progressHistory.count,
            "progressRate": progressRate,
            "estimatedTimeRemaining": estimatedTimeRemaining as Any,
            "isComplete": lastUpdate.progress >= 0.99
        ]
    }
    
    // MARK: - Initialization
    
    /// Initialize with a new progress reporter
    public init(name: String, isCancellable: Bool = true, verboseLogging: Bool = false) {
        self.reporterName = name
        self.reporter = ProgressReporter(isCancellable: isCancellable)
        self.verboseLogging = verboseLogging
        
        logger.log("ProgressReporterWrapper '\(name)' initialized")
        setupSubscriptions()
    }
    
    /// Initialize with an existing progress reporter
    public init(name: String, wrapping existingReporter: ProgressReporter, verboseLogging: Bool = false) {
        self.reporterName = name
        self.reporter = existingReporter
        self.verboseLogging = verboseLogging
        
        logger.log("ProgressReporterWrapper '\(name)' initialized wrapping an existing reporter")
        setupSubscriptions()
    }
    
    // MARK: - Progress Reporting
    
    /// Update progress with a new value and message
    /// - Parameters:
    ///   - progress: Current progress (0.0 to 1.0)
    ///   - message: Description of the current state
    public func update(progress: Double, message: String) {
        // Add to history first
        let now = Date()
        historyLock.lock()
        progressHistory.append((progress: progress, message: message, timestamp: now))
        
        // Trim history if needed
        if progressHistory.count > maxHistoryEntries {
            progressHistory.removeFirst(progressHistory.count - maxHistoryEntries)
        }
        historyLock.unlock()
        
        // Log progress changes
        if verboseLogging || progress.truncatingRemainder(dividingBy: 0.1) < 0.01 || progress >= 0.99 {
            logger.log("[\(reporterName)] Progress: \(Int(progress * 100))% - \(message)")
        }
        
        // Create metadata for this update
        let metadata: [String: Any] = [
            "timestamp": now,
            "reporterName": reporterName,
            "elapsedTime": now.timeIntervalSince(creationTime),
            "isComplete": progress >= 0.99
        ]
        
        // Update the underlying reporter
        reporter.update(progress: progress, message: message)
        
        // Send enhanced update
        progressSubject.send((progress: progress, message: message, metadata: metadata))
    }
    
    /// Reset the progress reporter to its initial state
    public func reset() {
        logger.log("[\(reporterName)] Progress reset")
        
        historyLock.lock()
        progressHistory.removeAll()
        historyLock.unlock()
        
        reporter.reset()
        
        progressSubject.send((progress: 0, message: "Reset", metadata: [
            "timestamp": Date(),
            "reporterName": reporterName,
            "action": "reset"
        ]))
    }
    
    /// Complete the progress reporting
    public func complete(with message: String = "Completed") {
        logger.log("[\(reporterName)] Progress completed: \(message)")
        update(progress: 1.0, message: message)
    }
    
    /// Report an error in the progress
    public func reportError(_ error: Error, progress: Double? = nil) {
        let errorMessage = "Error: \(error.localizedDescription)"
        logger.log("[\(reporterName)] \(errorMessage)")
        
        let currentProgress = progress ?? self.progress
        update(progress: currentProgress, message: errorMessage)
    }
    
    // MARK: - Convenience Methods
    
    /// Update progress based on items processed
    /// - Parameters:
    ///   - itemsProcessed: Number of items processed so far
    ///   - totalItems: Total number of items to process
    ///   - message: Optional message to include
    public func updateWithItemCount(itemsProcessed: Int, totalItems: Int, message: String? = nil) {
        guard totalItems > 0 else {
            update(progress: 0, message: message ?? "No items to process")
            return
        }
        
        let progressValue = Double(itemsProcessed) / Double(totalItems)
        let statusMessage = message ?? "Processed \(itemsProcessed) of \(totalItems) items"
        update(progress: progressValue, message: statusMessage)
    }
    
    /// Update progress for a task that has multiple stages
    /// - Parameters:
    ///   - currentStage: Current stage number (1-based)
    ///   - totalStages: Total number of stages
    ///   - stageProgress: Progress within the current stage (0.0 to 1.0)
    ///   - message: Optional message to include
    public func updateWithStages(currentStage: Int, totalStages: Int, stageProgress: Double, message: String? = nil) {
        guard totalStages > 0 else {
            update(progress: 0, message: message ?? "No stages defined")
            return
        }
        
        let stageSize = 1.0 / Double(totalStages)
        let baseProgress = stageSize * Double(currentStage - 1)
        let progressValue = baseProgress + (stageSize * stageProgress)
        
        let statusMessage = message ?? "Stage \(currentStage) of \(totalStages): \(Int(stageProgress * 100))%"
        update(progress: progressValue, message: statusMessage)
    }
    
    // MARK: - Private Methods
    
    /// Set up subscriptions to the underlying reporter
    private func setupSubscriptions() {
        // Optional: Subscribe to the internal reporter's publisher if needed
    }
} 