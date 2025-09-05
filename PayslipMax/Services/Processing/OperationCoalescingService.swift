import Foundation
import Combine

/// Operation coalescing service that eliminates redundant processing by sharing results
/// between concurrent identical requests, implementing intelligent operation broadcasting
@MainActor
final class OperationCoalescingServiceSimplified {
    
    // MARK: - Dependencies
    
    private let coalescingManager: OperationCoalescingManager
    
    // MARK: - Published Properties
    
    @Published private(set) var isEnabled = true
    @Published private(set) var statistics = CoalescingStatistics()
    
    // MARK: - Configuration
    
    private struct ServiceConfig {
        static let statisticsUpdateInterval: TimeInterval = 30.0 // Update statistics every 30 seconds
        static let enabledByDefault = true
    }
    
    // MARK: - Properties
    
    private var statisticsTimer: Timer?
    
    // MARK: - Initialization
    
    init(coalescingManager: OperationCoalescingManager = OperationCoalescingManager()) {
        self.coalescingManager = coalescingManager
        setupStatisticsUpdates()
    }
    
    deinit {
        statisticsTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Execute operation with intelligent coalescing
    /// Identical concurrent operations will share results to eliminate redundancy
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation type
    ///   - parameters: Operation parameters for cache key generation
    ///   - operation: The async operation to execute
    /// - Returns: Operation result
    func executeCoalescedOperation<T>(operationId: String,
                                    parameters: [String: String] = [:],
                                    operation: @escaping () async throws -> T) async throws -> T {
        
        let context = OperationContext(
            identifier: operationId,
            parameters: parameters,
            priority: .normal
        )
        
        return try await coalescingManager.executeWithCoalescing(context: context, operation: operation)
    }
    
    /// Execute high-priority operation with coalescing
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation type
    ///   - parameters: Operation parameters for cache key generation
    ///   - operation: The async operation to execute
    /// - Returns: Operation result
    func executeHighPriorityOperation<T>(operationId: String,
                                       parameters: [String: String] = [:],
                                       operation: @escaping () async throws -> T) async throws -> T {
        
        let context = OperationContext(
            identifier: operationId,
            parameters: parameters,
            priority: .high
        )
        
        return try await coalescingManager.executeWithCoalescing(context: context, operation: operation)
    }
    
    /// Execute PDF processing operation with coalescing
    /// Specialized method for PDF processing operations
    /// - Parameters:
    ///   - pdfHash: Hash of the PDF content for deduplication
    ///   - processingType: Type of processing (extraction, validation, etc.)
    ///   - operation: The async operation to execute
    /// - Returns: Operation result
    func executePDFOperation<T>(pdfHash: String,
                              processingType: String,
                              operation: @escaping () async throws -> T) async throws -> T {
        
        let operationId = "pdf_\(processingType)"
        let parameters = ["hash": pdfHash]
        
        return try await executeCoalescedOperation(
            operationId: operationId,
            parameters: parameters,
            operation: operation
        )
    }
    
    /// Check if specific operation is currently being processed
    /// - Parameters:
    ///   - operationId: Operation identifier
    ///   - parameters: Operation parameters
    /// - Returns: True if operation is pending
    func isOperationPending(operationId: String, parameters: [String: String] = [:]) -> Bool {
        let context = OperationContext(identifier: operationId, parameters: parameters)
        return coalescingManager.isOperationPending(key: context.cacheKey())
    }
    
    /// Cancel specific operation
    /// - Parameters:
    ///   - operationId: Operation identifier
    ///   - parameters: Operation parameters
    /// - Returns: True if operation was cancelled
    func cancelOperation(operationId: String, parameters: [String: String] = [:]) -> Bool {
        let context = OperationContext(identifier: operationId, parameters: parameters)
        return coalescingManager.cancelOperation(key: context.cacheKey())
    }
    
    /// Enable or disable operation coalescing
    /// - Parameter enabled: Whether to enable coalescing
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        coalescingManager.setCoalescingEnabled(enabled)
    }
    
    /// Get current coalescing statistics
    func getCurrentStatistics() -> CoalescingStatistics {
        return coalescingManager.getStatistics()
    }
    
    /// Reset all statistics
    func resetStatistics() {
        coalescingManager.clearStatistics()
        updateStatistics()
    }
    
    /// Get number of currently pending operations
    var pendingOperationCount: Int {
        return coalescingManager.pendingOperationCount
    }
    
    /// Get coalescing efficiency percentage
    var coalescingEfficiency: Double {
        return statistics.coalescingEfficiency
    }
    
    /// Get average time saved through coalescing
    var averageTimeSaved: TimeInterval {
        return statistics.averageTimeSaved
    }
    
    // MARK: - Convenience Methods
    
    /// Execute text extraction with coalescing
    func executeTextExtraction<T>(documentHash: String, operation: @escaping () async throws -> T) async throws -> T {
        return try await executePDFOperation(pdfHash: documentHash, processingType: "text_extraction", operation: operation)
    }
    
    /// Execute format detection with coalescing
    func executeFormatDetection<T>(documentHash: String, operation: @escaping () async throws -> T) async throws -> T {
        return try await executePDFOperation(pdfHash: documentHash, processingType: "format_detection", operation: operation)
    }
    
    /// Execute validation with coalescing
    func executeValidation<T>(documentHash: String, operation: @escaping () async throws -> T) async throws -> T {
        return try await executePDFOperation(pdfHash: documentHash, processingType: "validation", operation: operation)
    }
    
    /// Execute pattern extraction with coalescing
    func executePatternExtraction<T>(documentHash: String, operation: @escaping () async throws -> T) async throws -> T {
        return try await executePDFOperation(pdfHash: documentHash, processingType: "pattern_extraction", operation: operation)
    }
    
    // MARK: - Private Methods
    
    private func setupStatisticsUpdates() {
        statisticsTimer = Timer.scheduledTimer(withTimeInterval: ServiceConfig.statisticsUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatistics()
            }
        }
    }
    
    private func updateStatistics() {
        statistics = coalescingManager.getStatistics()
    }
}

// MARK: - Operation Result Broadcasting

extension OperationCoalescingServiceSimplified {
    
    /// Broadcast operation result to multiple subscribers
    /// Useful for scenarios where multiple components need the same result
    /// - Parameters:
    ///   - operationId: Unique identifier for the operation
    ///   - operation: The operation to execute once and broadcast
    ///   - subscriberCount: Expected number of subscribers
    /// - Returns: Publisher that broadcasts the result
    func broadcastOperation<T>(operationId: String, 
                             operation: @escaping () async throws -> T,
                             subscriberCount: Int = 1) -> AnyPublisher<T, Error> {
        
        return Future { promise in
            Task {
                do {
                    let result = try await self.executeCoalescedOperation(
                        operationId: operationId,
                        operation: operation
                    )
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .share()
        .eraseToAnyPublisher()
    }
}
