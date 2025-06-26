import Foundation
import Darwin

/// Tracks memory usage during PDF parsing operations
final class PDFMemoryTracker {
    
    // MARK: - Properties
    
    private var memoryUsageData: [String: UInt64] = [:]
    
    // MARK: - Public Methods
    
    /// Tracks memory usage updates from text extraction
    /// - Parameters:
    ///   - memoryUsage: Current memory usage in bytes
    ///   - delta: Memory usage change in bytes
    func trackMemoryUsage(memoryUsage: UInt64, delta: UInt64) {
        // Track memory usage for diagnostics
        memoryUsageData["currentUsage"] = memoryUsage
        memoryUsageData["peakDelta"] = max(memoryUsageData["peakDelta"] ?? 0, delta)
        memoryUsageData["peakUsage"] = max(memoryUsageData["peakUsage"] ?? 0, memoryUsage)
        
        // Log significant memory increases
        if delta > 5_000_000 { // 5MB
            print("[PDFMemoryTracker] ⚠️ Significant memory increase: \(formatMemory(delta))")
        }
    }
    
    /// Gets current memory statistics
    /// - Returns: Dictionary containing memory usage statistics
    func getMemoryStatistics() -> [String: String] {
        var stats: [String: String] = [:]
        
        if let currentUsage = memoryUsageData["currentUsage"] {
            stats["currentUsage"] = formatMemory(currentUsage)
        }
        
        if let peakUsage = memoryUsageData["peakUsage"] {
            stats["peakUsage"] = formatMemory(peakUsage)
        }
        
        if let peakDelta = memoryUsageData["peakDelta"] {
            stats["peakDelta"] = formatMemory(peakDelta)
        }
        
        return stats
    }
    
    /// Resets memory tracking data
    func resetTracking() {
        memoryUsageData.removeAll()
        print("[PDFMemoryTracker] Memory tracking data reset")
    }
    
    /// Gets current system memory usage
    /// - Returns: Current memory usage in bytes, or nil if unavailable
    func getCurrentSystemMemoryUsage() -> UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
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
            return nil
        }
    }
    
    /// Logs memory usage summary
    func logMemoryUsageSummary() {
        print("[PDFMemoryTracker] Memory Usage Summary:")
        print("[PDFMemoryTracker] ========================")
        
        let stats = getMemoryStatistics()
        for (key, value) in stats {
            print("[PDFMemoryTracker] \(key): \(value)")
        }
        
        if let currentSystemUsage = getCurrentSystemMemoryUsage() {
            print("[PDFMemoryTracker] Current system usage: \(formatMemory(currentSystemUsage))")
        }
        
        print("[PDFMemoryTracker] ========================")
    }
    
    // MARK: - Private Methods
    
    /// Formats memory size for human-readable output
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted memory size string
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
} 