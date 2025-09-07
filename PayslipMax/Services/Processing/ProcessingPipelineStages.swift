import Foundation
import Combine

/// Processing pipeline stages containing cache management and operation coordination
/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: ~150/300 lines
class ProcessingPipelineStages {
    
    // MARK: - Configuration
    
    struct StageConfig {
        static let cacheRetentionTime: TimeInterval = 300 // 5 minutes
        static let deduplicationWindow: TimeInterval = 60 // 1 minute
    }
    
    // MARK: - Properties
    
    private var processingCache: [String: CachedResult] = [:]
    private var activeOperations: [String: Operation] = [:]
    private let cacheQueue = DispatchQueue(label: "processing.cache", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        startCacheCleanupTimer()
    }
    
    // MARK: - Cache Management
    
    func getCachedResult(for key: String) -> Any? {
        return cacheQueue.sync {
            guard let cached = processingCache[key],
                  !cached.isExpired else {
                processingCache.removeValue(forKey: key)
                return nil
            }
            return cached.result
        }
    }
    
    func cacheResult(_ result: Any, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.processingCache[key] = CachedResult(
                result: result,
                timestamp: Date()
            )
        }
    }
    
    func generateCacheKey<T>(for input: T) -> String {
        // Create deterministic cache key
        return "\(type(of: input))_\(String(describing: input).hash)"
    }
    
    // MARK: - Operation Management
    
    func getActiveOperation(for key: String) -> Operation? {
        return cacheQueue.sync {
            activeOperations[key]
        }
    }
    
    func setActiveOperation(_ operation: Operation, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.activeOperations[key] = operation
        }
    }
    
    func removeActiveOperation(for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.activeOperations.removeValue(forKey: key)
        }
    }
    
    func executeOperation<R>(_ operation: ProcessingOperation<R>, 
                           operationQueue: OperationQueue) async throws -> R {
        defer {
            removeActiveOperation(for: operation.cacheKey)
        }
        
        return try await withUnsafeThrowingContinuation { continuation in
            operation.completionBlock = {
                if let error = operation.error {
                    continuation.resume(throwing: error)
                } else if let result = operation.result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: ProcessingError.operationFailed)
                }
            }
            
            operationQueue.addOperation(operation)
        }
    }
    
    func waitForOperation<R>(_ operation: Operation) async throws -> R {
        return try await withUnsafeThrowingContinuation { continuation in
            let observer = operation.observe(\.isFinished) { operation, _ in
                if operation.isFinished {
                    if let processingOp = operation as? ProcessingOperation<R> {
                        if let error = processingOp.error {
                            continuation.resume(throwing: error)
                        } else if let result = processingOp.result {
                            continuation.resume(returning: result)
                        } else {
                            continuation.resume(throwing: ProcessingError.operationFailed)
                        }
                    } else {
                        continuation.resume(throwing: ProcessingError.invalidOperation)
                    }
                }
            }
            
            // Clean up observer
            operation.completionBlock = {
                observer.invalidate()
            }
        }
    }
    
    // MARK: - Cache Cleanup
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.clearExpiredCache()
        }
    }
    
    func clearExpiredCache() {
        cacheQueue.async(flags: .barrier) {
            let now = Date()
            self.processingCache = self.processingCache.filter { _, cached in
                now.timeIntervalSince(cached.timestamp) < StageConfig.cacheRetentionTime
            }
        }
    }
    
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.processingCache.removeAll()
        }
    }
}

// MARK: - Supporting Types

struct CachedResult {
    let result: Any
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ProcessingPipelineStages.StageConfig.cacheRetentionTime
    }
}

class ProcessingOperation<T>: Operation, @unchecked Sendable {
    let cacheKey: String
    private let processor: () async throws -> T
    
    var result: T?
    var error: Error?
    
    private var _isExecuting = false
    private var _isFinished = false
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    init(cacheKey: String, processor: @escaping () async throws -> T) {
        self.cacheKey = cacheKey
        self.processor = processor
        super.init()
    }
    
    override func start() {
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        Task {
            do {
                result = try await processor()
            } catch {
                self.error = error
            }
            
            DispatchQueue.main.async {
                self.willChangeValue(forKey: "isExecuting")
                self.willChangeValue(forKey: "isFinished")
                self._isExecuting = false
                self._isFinished = true
                self.didChangeValue(forKey: "isExecuting")
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }
}

enum ProcessingError: Error {
    case operationFailed
    case invalidOperation
}
