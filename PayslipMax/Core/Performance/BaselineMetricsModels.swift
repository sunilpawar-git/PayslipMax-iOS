import Foundation

// MARK: - Baseline Metrics Models

/// Complete snapshot of system performance baseline
struct BaselineSnapshot: Codable {
    let timestamp: Date
    let collectionDuration: TimeInterval
    let parsingMetrics: ParsingSystemMetrics
    let cacheMetrics: CacheSystemMetrics
    let memoryMetrics: MemoryUsageMetrics
    let processingMetrics: ProcessingEfficiencyMetrics
    let testDocumentCount: Int
    let systemInfo: SystemInfo
    
    /// Generate summary report of baseline metrics
    func generateSummaryReport() -> String {
        var report = """
        📊 BASELINE METRICS SUMMARY
        Collected: \(timestamp.formatted())
        Collection Duration: \(String(format: "%.2f", collectionDuration))s
        Test Documents: \(testDocumentCount)
        
        🔄 PARSING SYSTEMS (\(parsingMetrics.systemCount) total)
        Average Processing Time: \(String(format: "%.3f", parsingMetrics.averageProcessingTime))s
        Overall Success Rate: \(String(format: "%.1f", overallSuccessRate * 100))%
        
        🗄️ CACHE SYSTEMS (\(cacheMetrics.cacheSystemCount) total)
        Overall Hit Rate: \(String(format: "%.1f", cacheMetrics.overallHitRate * 100))%
        Total Memory Usage: \(formatBytes(cacheMetrics.totalMemoryUsage))
        
        🧠 MEMORY USAGE
        Peak Memory: \(formatBytes(memoryMetrics.peakMemoryUsage))
        Average Memory: \(formatBytes(memoryMetrics.averageMemoryUsage))
        Memory Variability: \(String(format: "%.1f", memoryMetrics.memoryVariability))%
        
        ⚡ PROCESSING EFFICIENCY
        Redundancy Rate: \(String(format: "%.1f", processingMetrics.redundancyPercentage))%
        Resource Utilization: \(String(format: "%.1f", processingMetrics.resourceUtilization * 100))%
        """
        
        return report
    }
    
    private var overallSuccessRate: Double {
        let rates = parsingMetrics.successRates.values
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

/// Metrics for parsing system performance
struct ParsingSystemMetrics: Codable {
    let systemCount: Int
    let totalProcessingTime: TimeInterval
    let averageProcessingTime: TimeInterval
    let successRates: [String: Double]
    let memoryUsagePeaks: [String: UInt64]
    let telemetryData: [ParserTelemetry]
    let documentProcessingDistribution: [String: TimeInterval]
}

/// Metrics for cache system effectiveness
struct CacheSystemMetrics: Codable {
    let cacheSystemCount: Int
    let overallHitRate: Double
    let totalMemoryUsage: UInt64
    let cacheEffectiveness: [String: CacheEffectivenessMetrics]
    let memoryDistribution: [String: UInt64]
    let operationDistribution: [String: Int]
}

/// Metrics for memory usage patterns
struct MemoryUsageMetrics: Codable {
    let initialMemoryUsage: (resident: UInt64, virtual: UInt64, peak: UInt64)
    let measurements: [MemoryMeasurement]
    let peakMemoryUsage: UInt64
    let averageMemoryUsage: UInt64
    let memoryVariability: Double
    
    private enum CodingKeys: String, CodingKey {
        case initialResidentMemory, initialVirtualMemory, initialPeakMemory
        case measurements, peakMemoryUsage, averageMemoryUsage, memoryVariability
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(initialMemoryUsage.resident, forKey: .initialResidentMemory)
        try container.encode(initialMemoryUsage.virtual, forKey: .initialVirtualMemory)
        try container.encode(initialMemoryUsage.peak, forKey: .initialPeakMemory)
        try container.encode(measurements, forKey: .measurements)
        try container.encode(peakMemoryUsage, forKey: .peakMemoryUsage)
        try container.encode(averageMemoryUsage, forKey: .averageMemoryUsage)
        try container.encode(memoryVariability, forKey: .memoryVariability)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let resident = try container.decode(UInt64.self, forKey: .initialResidentMemory)
        let virtual = try container.decode(UInt64.self, forKey: .initialVirtualMemory)
        let peak = try container.decode(UInt64.self, forKey: .initialPeakMemory)
        initialMemoryUsage = (resident: resident, virtual: virtual, peak: peak)
        measurements = try container.decode([MemoryMeasurement].self, forKey: .measurements)
        peakMemoryUsage = try container.decode(UInt64.self, forKey: .peakMemoryUsage)
        averageMemoryUsage = try container.decode(UInt64.self, forKey: .averageMemoryUsage)
        memoryVariability = try container.decode(Double.self, forKey: .memoryVariability)
    }
    
    init(
        initialMemoryUsage: (resident: UInt64, virtual: UInt64, peak: UInt64),
        measurements: [MemoryMeasurement],
        peakMemoryUsage: UInt64,
        averageMemoryUsage: UInt64,
        memoryVariability: Double
    ) {
        self.initialMemoryUsage = initialMemoryUsage
        self.measurements = measurements
        self.peakMemoryUsage = peakMemoryUsage
        self.averageMemoryUsage = averageMemoryUsage
        self.memoryVariability = memoryVariability
    }
}

/// Metrics for processing efficiency
struct ProcessingEfficiencyMetrics: Codable {
    let redundancyPercentage: Double
    let duplicateOperations: Int
    let resourceUtilization: Double
    let concurrencyEfficiency: Double
    let bottleneckIdentification: [String]
}

// MARK: - Supporting Models

/// Individual memory measurement
struct MemoryMeasurement: Codable {
    let timestamp: Date
    let residentSize: UInt64
    let virtualSize: UInt64
    let peakResident: UInt64
}

/// Cache effectiveness metrics
struct CacheEffectivenessMetrics: Codable {
    let hitRate: Double
    let missRate: Double
    let totalOperations: Int
    let memoryUsage: UInt64
    let evictionRate: Double
    let averageResponseTime: TimeInterval
}

/// Information about parsing systems
struct ParsingSystemInfo {
    let name: String
    let type: ParsingSystemType
    
    enum ParsingSystemType {
        case unified
        case legacy
        case sectionBased
        case asyncPattern
    }
}

/// Information about cache systems
struct CacheSystemInfo {
    let name: String
    let type: CacheSystemType
    
    enum CacheSystemType {
        case multiLevel
        case lruPressureAware
        case processingCache
        case documentCache
        case memoryManagement
        case streamingCache
    }
}

/// System information for context
struct SystemInfo: Codable {
    let deviceModel: String
    let osVersion: String
    let processorCount: Int
    let physicalMemory: UInt64
    let freeMemory: UInt64
    
    static func current() -> SystemInfo {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        
        return SystemInfo(
            deviceModel: modelCode ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            processorCount: ProcessInfo.processInfo.processorCount,
            physicalMemory: ProcessInfo.processInfo.physicalMemory,
            freeMemory: getAvailableMemory()
        )
    }
    
    private static func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }
}

// MARK: - Performance Measurement Models

/// Result of measuring parsing performance
struct ParsingPerformanceMeasurement {
    let telemetry: ParserTelemetry
    let processingTime: TimeInterval
    let memoryDelta: UInt64
    let success: Bool
}

/// Redundancy measurement results
struct RedundancyMetrics {
    let redundancyPercentage: Double
    let duplicateOperations: Int
    let uniqueOperations: Int
    let totalOperations: Int
}

// MARK: - Additional Performance Models

/// Result of measuring parsing performance
struct ParsingPerformanceResult {
    let success: Bool
    let extractedItemCount: Int
    let textLength: Int
    let processingTime: TimeInterval
    let memoryUsage: UInt64?
}
