import Foundation
import Combine

/// Progress tracking for streaming batch processing
///
/// Following Phase 4B modular pattern: Focused responsibility for progress management
/// Handles progress reporting and time estimation for batch operations
final class BatchProgressTracker {
    
    // MARK: - State
    
    /// Progress tracking publisher
    private let progressSubject = PassthroughSubject<ProcessingProgress, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    /// Timing tracking for estimation
    private var batchTimes: [TimeInterval] = []
    private var startTime: Date?
    
    // MARK: - Initialization
    
    /// Initialize progress tracker
    init() {
        // Initialize any required state
    }
    
    // MARK: - Progress Tracking
    
    /// Start tracking for a new processing session
    /// - Parameter totalBatches: Total number of batches to process
    func startTracking(totalBatches: Int) {
        startTime = Date()
        batchTimes.removeAll()
        batchTimes.reserveCapacity(totalBatches)
    }
    
    /// Report progress for a completed batch
    /// - Parameters:
    ///   - batchIndex: Index of completed batch (0-based)
    ///   - totalBatches: Total number of batches
    ///   - completedPages: Number of pages completed
    ///   - totalPages: Total number of pages
    ///   - batchProcessingTime: Time taken for this batch
    ///   - progressHandler: Optional external progress handler
    func reportProgress(
        batchIndex: Int,
        totalBatches: Int,
        completedPages: Int,
        totalPages: Int,
        batchProcessingTime: TimeInterval,
        progressHandler: ((ProcessingProgress) -> Void)? = nil
    ) {
        // Record batch timing
        batchTimes.append(batchProcessingTime)
        
        // Calculate estimated remaining time
        let estimatedTimeRemaining = estimateRemainingTime(
            batchIndex: batchIndex,
            totalBatches: totalBatches
        )
        
        // Create progress object
        let progress = ProcessingProgress(
            completedPages: completedPages,
            totalPages: totalPages,
            currentBatch: batchIndex + 1,
            totalBatches: totalBatches,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        
        // Report progress
        progressHandler?(progress)
        progressSubject.send(progress)
    }
    
    /// Complete tracking session
    func completeTracking() {
        let totalTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
        // Log completion if needed
        print("Batch processing completed in \(totalTime) seconds")
    }
    
    // MARK: - Time Estimation
    
    /// Estimate remaining processing time
    /// - Parameters:
    ///   - batchIndex: Current batch index (0-based)
    ///   - totalBatches: Total number of batches
    /// - Returns: Estimated remaining time in seconds
    private func estimateRemainingTime(
        batchIndex: Int,
        totalBatches: Int
    ) -> TimeInterval {
        guard !batchTimes.isEmpty else { return 0 }
        
        let remainingBatches = totalBatches - (batchIndex + 1)
        guard remainingBatches > 0 else { return 0 }
        
        // Use weighted average of recent batch times
        let recentBatches = Array(batchTimes.suffix(5)) // Last 5 batches
        let averageTime = recentBatches.reduce(0, +) / Double(recentBatches.count)
        
        return Double(remainingBatches) * averageTime
    }
    
    /// Get average processing time per batch
    /// - Returns: Average time per batch, or 0 if no data
    func getAverageProcessingTime() -> TimeInterval {
        guard !batchTimes.isEmpty else { return 0 }
        return batchTimes.reduce(0, +) / Double(batchTimes.count)
    }
    
    /// Get total elapsed time since tracking started
    /// - Returns: Total elapsed time, or 0 if not started
    func getTotalElapsedTime() -> TimeInterval {
        guard let startTime = startTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Progress Publisher
    
    /// Publisher for processing progress updates
    var progressPublisher: AnyPublisher<ProcessingProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    /// Get current progress statistics
    /// - Returns: Dictionary of current statistics
    func getProgressStatistics() -> [String: Any] {
        return [
            "totalBatches": batchTimes.count,
            "averageTimePerBatch": getAverageProcessingTime(),
            "totalElapsedTime": getTotalElapsedTime(),
            "fastestBatch": batchTimes.min() ?? 0,
            "slowestBatch": batchTimes.max() ?? 0
        ]
    }
}
