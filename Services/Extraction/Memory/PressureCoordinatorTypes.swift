import Foundation

/// Supporting types for SystemPressureCoordinator
/// Extracted to maintain 300-line file size compliance

// MARK: - Memory Pressure Responder Protocol
/// Protocol for objects that respond to memory pressure changes
protocol MemoryPressureResponder: AnyObject {
    /// Respond to memory pressure level change
    /// - Parameter level: New pressure level
    func respondToMemoryPressure(_ level: UnifiedMemoryPressureLevel) async
}

// MARK: - Standardized Memory Thresholds
/// Standardized memory pressure thresholds (unified across all systems)
struct StandardizedMemoryThresholds {
    static let normal: UInt64 = 150 * 1_024 * 1_024    // 150MB (0-60% usage)
    static let warning: UInt64 = 250 * 1_024 * 1_024   // 250MB (60-80% usage)
    static let critical: UInt64 = 400 * 1_024 * 1_024  // 400MB (80-95% usage)
    static let emergency: UInt64 = 500 * 1_024 * 1_024 // 500MB (95%+ usage)
    
    /// Calculate pressure level from memory usage
    static func calculatePressureLevel(for usage: UInt64) -> UnifiedMemoryPressureLevel {
        switch usage {
        case 0..<normal:
            return .normal
        case normal..<warning:
            return .warning
        case warning..<critical:
            return .critical
        default:
            return .emergency
        }
    }
    
    /// Get thresholds as tuple for external systems
    static var thresholds: (normal: UInt64, warning: UInt64, critical: UInt64, emergency: UInt64) {
        return (normal: normal, warning: warning, critical: critical, emergency: emergency)
    }
}

// MARK: - Pressure Assessment Types
/// Pressure trend analysis
enum PressureTrend {
    case increasing
    case decreasing
    case stable
    
    var description: String {
        switch self {
        case .increasing:
            return "Increasing"
        case .decreasing:
            return "Decreasing"
        case .stable:
            return "Stable"
        }
    }
}

/// Complete pressure assessment
struct PressureAssessment {
    let level: UnifiedMemoryPressureLevel
    let memoryUsage: UInt64
    let availablePercentage: Double
    let trend: PressureTrend
    let timestamp: Date
    
    var summary: String {
        let percentage = String(format: "%.1f", availablePercentage * 100)
        let trendDescription = trend.description.lowercased()
        return "\(level.description) pressure (\(percentage)% available, \(trendDescription))"
    }
}

/// Pressure reading for history tracking
struct PressureReading {
    let timestamp: Date
    let memoryUsage: UInt64
    let pressureLevel: UnifiedMemoryPressureLevel
    
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Weak Reference Wrapper
/// Weak reference wrapper for pressure responders
struct WeakPressureResponder {
    weak var responder: MemoryPressureResponder?
    
    init(_ responder: MemoryPressureResponder) {
        self.responder = responder
    }
    
    var isValid: Bool {
        return responder != nil
    }
}

// MARK: - Pressure Analysis Utilities
/// Utilities for pressure trend analysis and calculation
struct PressureAnalysisUtils {
    
    /// Calculate pressure trend from readings
    /// - Parameter readings: Array of recent pressure readings
    /// - Returns: Calculated trend
    static func calculateTrend(from readings: [PressureReading]) -> PressureTrend {
        guard readings.count >= 3 else {
            return .stable
        }
        
        let recent = readings.suffix(3)
        let levels = recent.map { $0.pressureLevel.rawValue }
        
        if levels[2] > levels[1] && levels[1] > levels[0] {
            return .increasing
        } else if levels[2] < levels[1] && levels[1] < levels[0] {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    /// Calculate available memory percentage
    /// - Parameter current: Current memory usage
    /// - Returns: Available memory as percentage (0.0-1.0)
    static func calculateAvailableMemoryPercentage(current: UInt64) -> Double {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        guard totalMemory > 0 else {
            return 0.0
        }
        
        let usedPercentage = Double(current) / Double(totalMemory)
        return max(0.0, min(1.0, 1.0 - usedPercentage))
    }
    
    /// Clean up old pressure readings
    /// - Parameters:
    ///   - readings: Array of pressure readings
    ///   - maxAge: Maximum age in seconds
    ///   - maxCount: Maximum number of readings to keep
    /// - Returns: Cleaned array of readings
    static func cleanupReadings(
        _ readings: [PressureReading],
        maxAge: TimeInterval = 60,
        maxCount: Int = 60
    ) -> [PressureReading] {
        let cutoffTime = Date().addingTimeInterval(-maxAge)
        
        // Filter by age and limit count
        let recentReadings = readings.filter { $0.timestamp > cutoffTime }
        
        if recentReadings.count > maxCount {
            return Array(recentReadings.suffix(maxCount))
        }
        
        return recentReadings
    }
}

// MARK: - Legacy Conversion Utilities
/// Utilities for converting legacy pressure level types
struct LegacyPressureConverter {
    
    /// Convert legacy EnhancedMemoryManager pressure level
    /// - Parameter legacyLevel: Legacy pressure level
    /// - Returns: Unified pressure level
    static func convert(_ legacyLevel: EnhancedMemoryManager.MemoryPressureLevel) -> UnifiedMemoryPressureLevel {
        switch legacyLevel {
        case .normal:
            return .normal
        case .warning:
            return .warning
        case .critical:
            return .critical
        case .emergency:
            return .emergency
        }
    }
    
    /// Convert legacy ResourcePressureMonitor pressure level
    /// - Parameter legacyLevel: Legacy pressure level
    /// - Returns: Unified pressure level
    static func convert(_ legacyLevel: ResourcePressureMonitor.MemoryPressureLevel) -> UnifiedMemoryPressureLevel {
        switch legacyLevel {
        case .normal:
            return .normal
        case .low:
            return .warning  // Map low to warning
        case .medium:
            return .warning
        case .high:
            return .critical
        case .critical:
            return .emergency  // Map critical to emergency
        }
    }
    
    /// Convert any legacy pressure level object
    /// - Parameter legacyLevel: Legacy pressure level (Any type)
    /// - Returns: Unified pressure level
    static func convertAny(_ legacyLevel: Any) -> UnifiedMemoryPressureLevel {
        if let enhancedLevel = legacyLevel as? EnhancedMemoryManager.MemoryPressureLevel {
            return convert(enhancedLevel)
        } else if let resourceLevel = legacyLevel as? ResourcePressureMonitor.MemoryPressureLevel {
            return convert(resourceLevel)
        }
        
        // Default fallback for unknown types
        return .normal
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    /// System-wide memory pressure change notification
    static let systemMemoryPressureChanged = Notification.Name("systemMemoryPressureChanged")
    
    /// Legacy memory pressure detected notification (for compatibility)
    static let legacyMemoryPressureDetected = Notification.Name("memoryPressureDetected")
}
