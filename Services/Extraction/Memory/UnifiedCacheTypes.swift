import Foundation

// Supporting types for the Unified Cache Manager
// Extracted to maintain 300-line file size compliance

// MARK: - Cache Protocol
/// Protocol that all cache implementations must conform to
protocol CacheProtocol {
    func store<T: Codable>(_ value: T, forKey key: String) -> Bool
    func retrieve<T: Codable>(forKey key: String) -> T?
    func contains(key: String) -> Bool
    func clearCache() -> Bool
    func getCacheMetrics() -> [String: Any]
}

// MARK: - Memory Pressure Types
/// Unified memory pressure thresholds (standardized across system)
struct UnifiedMemoryThresholds {
    static let normal: UInt64 = 150 * 1_024 * 1_024    // 150MB (0-60% usage)
    static let warning: UInt64 = 250 * 1_024 * 1_024   // 250MB (60-80% usage)
    static let critical: UInt64 = 400 * 1_024 * 1_024  // 400MB (80-95% usage)
    static let emergency: UInt64 = 500 * 1_024 * 1_024 // 500MB (95%+ usage)
}

/// Unified pressure levels
enum UnifiedMemoryPressureLevel: Int, CaseIterable {
    case normal = 0      // 0-60% memory usage
    case warning = 1     // 60-80% memory usage
    case critical = 2    // 80-95% memory usage
    case emergency = 3   // 95%+ memory usage

    var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        case .emergency:
            return "Emergency"
        }
    }

    var shouldClearCaches: Bool {
        return rawValue >= UnifiedMemoryPressureLevel.warning.rawValue
    }

    var shouldReduceConcurrency: Bool {
        return rawValue >= UnifiedMemoryPressureLevel.critical.rawValue
    }
}

// MARK: - Cache Hierarchy Types
/// Cache hierarchy levels
enum CacheLevel: Int, CaseIterable {
    case l1Processing = 0  // Fast processing cache (5 min retention)
    case l2Persistent = 1  // Persistent cache (24h retention)
    case l3Disk = 2       // Disk-based cache (long-term)

    var retention: TimeInterval {
        switch self {
        case .l1Processing:
            return 300    // 5 minutes
        case .l2Persistent:
            return 86_400  // 24 hours
        case .l3Disk:
            return 604_800       // 7 days
        }
    }

    var priority: Int {
        return rawValue
    }

    var maxSize: UInt64 {
        switch self {
        case .l1Processing:
            return 25 * 1_024 * 1_024   // 25MB
        case .l2Persistent:
            return 100 * 1_024 * 1_024  // 100MB
        case .l3Disk:
            return 500 * 1_024 * 1_024        // 500MB
        }
    }
}

/// Unified cache namespace definitions
enum CacheNamespace: String, CaseIterable {
    case pdfProcessing = "pdf_processing"
    case documentAnalysis = "document_analysis"
    case textExtraction = "text_extraction"
    case operationResults = "operation_results"
    case streamingBatch = "streaming_batch"
    case patternMatching = "pattern_matching"

    var defaultLevel: CacheLevel {
        switch self {
        case .pdfProcessing, .textExtraction:
            return .l2Persistent
        case .documentAnalysis, .operationResults:
            return .l1Processing
        case .streamingBatch, .patternMatching:
            return .l1Processing
        }
    }
}

// MARK: - Cache Instance Types
/// Cache instance wrapper for registration
struct CacheInstance {
    let cache: any CacheProtocol
    let namespace: CacheNamespace
    let level: CacheLevel
    let maxSize: UInt64
    var lastAccess: Date

    init(cache: any CacheProtocol, namespace: CacheNamespace, level: CacheLevel) {
        self.cache = cache
        self.namespace = namespace
        self.level = level
        self.maxSize = level.maxSize
        self.lastAccess = Date()
    }
}

/// Cache statistics tracking
struct CacheStatistics {
    var hits: Int = 0
    var misses: Int = 0
    var stores: Int = 0
    var evictions: Int = 0

    var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0.0
    }
}

/// Cache operations for statistics tracking
enum CacheOperation {
    case hit, miss, store, eviction
}

// MARK: - Memory Utilities
/// Memory measurement utilities
struct MemoryUtils {
    /// Get current memory usage
    static func getCurrentMemoryUsage() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? UInt64(taskInfo.resident_size) : 0
    }

    /// Calculate pressure level from memory usage
    static func calculatePressureLevel(for usage: UInt64) -> UnifiedMemoryPressureLevel {
        switch usage {
        case 0..<UnifiedMemoryThresholds.normal:
            return .normal
        case UnifiedMemoryThresholds.normal..<UnifiedMemoryThresholds.warning:
            return .warning
        case UnifiedMemoryThresholds.warning..<UnifiedMemoryThresholds.critical:
            return .critical
        default:
            return .emergency
        }
    }
}

// MARK: - Cache Key Utilities
/// Utilities for creating unified cache keys
struct CacheKeyUtils {
    /// Create unified cache key with namespace and level
    static func createUnifiedKey(key: String, namespace: CacheNamespace, level: CacheLevel) -> String {
        return "\(namespace.rawValue)_\(level.rawValue)_\(key)"
    }

    /// Extract namespace from unified key
    static func extractNamespace(from unifiedKey: String) -> CacheNamespace? {
        let components = unifiedKey.components(separatedBy: "_")
        guard components.count >= 2,
              let namespace = CacheNamespace(rawValue: components[0]) else {
            return nil
        }
        return namespace
    }

    /// Extract level from unified key
    static func extractLevel(from unifiedKey: String) -> CacheLevel? {
        let components = unifiedKey.components(separatedBy: "_")
        guard components.count >= 2,
              let levelRaw = Int(components[1]),
              let level = CacheLevel(rawValue: levelRaw) else {
            return nil
        }
        return level
    }
}
