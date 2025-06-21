import Foundation

/// Simple memory pressure monitor for document analysis
class MemoryPressureMonitor {
    private let memoryThreshold: Int64
    
    /// Initialize with memory threshold
    /// - Parameter memoryThreshold: Memory threshold in bytes (default: 200MB)
    init(memoryThreshold: Int64 = 200 * 1024 * 1024) {
        self.memoryThreshold = memoryThreshold
    }
    
    /// Check if memory pressure is high
    /// - Returns: True if memory usage exceeds threshold
    func isMemoryPressureHigh() -> Bool {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Int64(memoryInfo.resident_size)
            return usedMemory > memoryThreshold
        }
        
        return false
    }
    
    /// Get current memory usage
    /// - Returns: Current memory usage in bytes
    func getCurrentMemoryUsage() -> Int64 {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(memoryInfo.resident_size) : 0
    }
}