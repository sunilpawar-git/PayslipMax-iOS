import Foundation

/// Centralized logging service for OCR operations
public class OCRLogger {
    
    // MARK: - Shared Instance
    
    public static let shared = OCRLogger()
    
    // MARK: - Properties
    
    private let category = "OCR"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Logging Methods
    
    /// Log Vision framework operations
    public func logVisionOperation(_ operation: String, details: [String: Any] = [:]) {
        let detailsString = formatDetails(details)
        Logger.info("🔍 Vision: \(operation) \(detailsString)", category: category)
    }
    
    /// Log Vision framework errors
    public func logVisionError(_ operation: String, error: Error, details: [String: Any] = [:]) {
        let detailsString = formatDetails(details)
        Logger.error("❌ Vision Error: \(operation) - \(error.localizedDescription) \(detailsString)", category: category)
    }
    
    /// Log table detection operations
    public func logTableDetection(_ operation: String, details: [String: Any] = [:]) {
        let detailsString = formatDetails(details)
        Logger.info("📊 Table Detection: \(operation) \(detailsString)", category: category)
    }
    
    /// Log spatial analysis operations
    public func logSpatialAnalysis(_ operation: String, details: [String: Any] = [:]) {
        let detailsString = formatDetails(details)
        Logger.info("📐 Spatial Analysis: \(operation) \(detailsString)", category: category)
    }
    
    /// Log performance metrics
    public func logPerformance(_ operation: String, duration: TimeInterval, details: [String: Any] = [:]) {
        var allDetails = details
        allDetails["duration"] = String(format: "%.3fs", duration)
        let detailsString = formatDetails(allDetails)
        Logger.info("⚡ Performance: \(operation) \(detailsString)", category: category)
    }
    
    /// Log memory usage information
    public func logMemoryUsage(_ operation: String, memoryUsage: UInt64, details: [String: Any] = [:]) {
        var allDetails = details
        allDetails["memory"] = formatMemorySize(memoryUsage)
        let detailsString = formatDetails(allDetails)
        Logger.info("💾 Memory: \(operation) \(detailsString)", category: category)
    }
    
    /// Log fallback operations
    public func logFallback(_ operation: String, reason: String, details: [String: Any] = [:]) {
        var allDetails = details
        allDetails["reason"] = reason
        let detailsString = formatDetails(allDetails)
        Logger.warning("🔄 Fallback: \(operation) \(detailsString)", category: category)
    }
    
    /// Log general OCR operations
    public func logOperation(_ operation: String, level: OCRLogLevel = .info, details: [String: Any] = [:]) {
        let detailsString = formatDetails(details)
        let message = "🔧 OCR: \(operation) \(detailsString)"
        
        switch level {
        case .debug:
            Logger.debug(message, category: category)
        case .info:
            Logger.info(message, category: category)
        case .warning:
            Logger.warning(message, category: category)
        case .error:
            Logger.error(message, category: category)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Format details dictionary into readable string
    private func formatDetails(_ details: [String: Any]) -> String {
        guard !details.isEmpty else { return "" }
        
        let formattedPairs = details.map { key, value in
            "\(key)=\(value)"
        }
        
        return "[\(formattedPairs.joined(separator: ", "))]"
    }
    
    /// Format memory size in human-readable format
    private func formatMemorySize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Types

/// Log levels for OCR operations
public enum OCRLogLevel {
    case debug
    case info
    case warning
    case error
}

// MARK: - Memory Utilities

/// Utility class for memory monitoring
public class MemoryMonitor {
    
    /// Get current memory usage in bytes
    public static func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    /// Log current memory usage for an operation
    public static func logMemoryUsage(for operation: String) {
        let memoryUsage = getCurrentMemoryUsage()
        OCRLogger.shared.logMemoryUsage(operation, memoryUsage: memoryUsage)
    }
}

// MARK: - Performance Timer

/// Utility for timing operations
public class PerformanceTimer {
    
    private let startTime: CFAbsoluteTime
    private let operation: String
    
    public init(operation: String) {
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
        OCRLogger.shared.logOperation("Started: \(operation)", level: .debug)
    }
    
    deinit {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        OCRLogger.shared.logPerformance(operation, duration: duration)
    }
}