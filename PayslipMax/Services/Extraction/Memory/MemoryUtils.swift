import Foundation

/// Shared memory utility functions for Phase 4B components
struct MemoryUtils {
    
    /// Get current memory usage using mach_task_basic_info
    /// - Returns: Current memory usage in bytes
    static func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            withUnsafeMutablePointer(to: &count) { countPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    task_info_t(OpaquePointer(infoPtr)),
                    countPtr
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    /// Format memory size for display
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted string (e.g., "123.45 MB")
    static func formatMemorySize(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        return String(format: "%.1f MB", mb)
    }
    
    /// Memory-efficient text preprocessing
    /// - Parameter text: Text to preprocess
    /// - Returns: Preprocessed text
    static func preprocessTextMemoryEfficient(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 