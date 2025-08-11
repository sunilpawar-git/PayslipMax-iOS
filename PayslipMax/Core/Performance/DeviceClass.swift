import Foundation
import UIKit

/// Represents a coarse device capability class to guide performance tuning
enum DeviceClass {
    case low
    case mid
    case high

    /// Determine the current device class using CPU cores and physical memory
    static var current: DeviceClass = {
        let cpuCount = ProcessInfo.processInfo.processorCount
        let memoryBytes = ProcessInfo.processInfo.physicalMemory

        if memoryBytes >= 6 * 1024 * 1024 * 1024 && cpuCount >= 6 { // ≥6GB RAM & ≥6 cores
            return .high
        } else if memoryBytes >= 3 * 1024 * 1024 * 1024 && cpuCount >= 4 { // ≥3GB RAM & ≥4 cores
            return .mid
        } else {
            return .low
        }
    }()

    /// Maximum parallelism cap for text extraction tasks
    var parallelismCap: Int {
        switch self {
        case .low: return 2
        case .mid: return 4
        case .high: return 8
        }
    }

    /// Memory threshold in MB at which to prefer streaming extraction
    var memoryThresholdMB: Int {
        switch self {
        case .low: return 120
        case .mid: return 200
        case .high: return 300
        }
    }

    /// Preferred streaming batch size (pages per batch)
    var streamingBatchSize: Int {
        switch self {
        case .low: return 3
        case .mid: return 5
        case .high: return 8
        }
    }

    /// Threshold in bytes for triggering streaming processor cleanup
    var streamingCleanupThresholdBytes: UInt64 {
        switch self {
        case .low: return 30 * 1024 * 1024 // 30 MB
        case .mid: return 50 * 1024 * 1024 // 50 MB
        case .high: return 80 * 1024 * 1024 // 80 MB
        }
    }

    /// Suggested memory cache limit in bytes for PDF processing cache
    var cacheMemoryLimitBytes: Int {
        switch self {
        case .low: return 20 * 1024 * 1024
        case .mid: return 40 * 1024 * 1024
        case .high: return 60 * 1024 * 1024
        }
    }
}


