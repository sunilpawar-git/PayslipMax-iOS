import Foundation
import PDFKit

// MARK: - Stage Transition Types and Models

/// Container for stage results that supports both value and reference semantics
/// depending on data size to optimize memory usage
struct StageResult<T> {
    let value: T
    let metadata: StageMetadata
    let isReferenceType: Bool
    let cacheKey: String
    
    init(value: T, metadata: StageMetadata, isReferenceType: Bool = false) {
        self.value = value
        self.metadata = metadata
        self.isReferenceType = isReferenceType
        self.cacheKey = "\(metadata.stageName):\(metadata.timestamp.timeIntervalSince1970)"
    }
}

/// Metadata about stage execution for optimization and debugging
struct StageMetadata {
    let stageName: String
    let executionTime: TimeInterval
    let memoryUsage: UInt64
    let timestamp: Date
    let dataSize: UInt64
    let cacheHit: Bool
    
    var efficiency: Double {
        return cacheHit ? 1.0 : max(0.1, 1.0 - (executionTime / 10.0))
    }
}

/// Configuration for stage transition optimization
struct TransitionConfig {
    static let maxStageResultCache = 50
    static let stageResultTTL: TimeInterval = 300 // 5 minutes
    static let zeroCopyThreshold = 1024 * 1024 // 1MB - use reference passing above this
}

/// Types of stage transitions for optimization
enum StageTransitionType {
    case validation
    case extraction
    case detection
    case processing
    case enhancement
    
    var requiresZeroCopy: Bool {
        switch self {
        case .extraction, .processing:
            return true
        default:
            return false
        }
    }
}

/// Result container with copy-on-write semantics for large data
struct COWData {
    private var _dataRef: DataWrapper
    
    init(_ data: Data) {
        self._dataRef = DataWrapper(data)
    }
    
    var data: Data {
        get { _dataRef.data }
        set {
            if !isKnownUniquelyReferenced(&_dataRef) {
                _dataRef = DataWrapper(newValue)
            } else {
                _dataRef.data = newValue
            }
        }
    }
    
    var count: Int { _dataRef.data.count }
}

/// Wrapper class to enable copy-on-write semantics for Data
private final class DataWrapper {
    var data: Data
    
    init(_ data: Data) {
        self.data = data
    }
}

/// Cached stage result with expiration
struct CachedStageResult {
    let result: Any
    let metadata: StageMetadata
    let expirationDate: Date
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
}

/// Stage execution context for tracking performance
struct StageExecutionContext {
    let stageType: StageTransitionType
    let inputSize: UInt64
    let startTime: Date
    var metadata: [String: Any] = [:]
    
    func createMetadata(executionTime: TimeInterval, memoryUsage: UInt64, cacheHit: Bool) -> StageMetadata {
        return StageMetadata(
            stageName: "\(stageType)",
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            timestamp: startTime,
            dataSize: inputSize,
            cacheHit: cacheHit
        )
    }
}
