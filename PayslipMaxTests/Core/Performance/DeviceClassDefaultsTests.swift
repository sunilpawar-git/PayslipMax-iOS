import XCTest
@testable import PayslipMax

final class DeviceClassDefaultsTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Reset to auto-detected current after each test
        DeviceClass.current = {
            let cpuCount = ProcessInfo.processInfo.processorCount
            let memoryBytes = ProcessInfo.processInfo.physicalMemory

            if memoryBytes >= 6 * 1024 * 1024 * 1024 && cpuCount >= 6 {
                return .high
            } else if memoryBytes >= 3 * 1024 * 1024 * 1024 && cpuCount >= 4 {
                return .mid
            } else {
                return .low
            }
        }()
    }

    func testExtractionOptionsDefaultsTrackDeviceClass() {
        for deviceClass in [DeviceClass.low, .mid, .high] {
            DeviceClass.current = deviceClass
            let options = ExtractionOptions()

            XCTAssertEqual(options.maxConcurrentOperations, max(1, deviceClass.parallelismCap))
            XCTAssertEqual(options.memoryThresholdMB, deviceClass.memoryThresholdMB)
        }
    }

    func testStreamingServiceDefaultsFollowDeviceClass() {
        for deviceClass in [DeviceClass.low, .mid, .high] {
            DeviceClass.current = deviceClass

            // Construct service with defaults that should pull from DeviceClass
            let service = StreamingTextExtractionService()

            // Use reflection to peek at private defaults for verification
            let mirror = Mirror(reflecting: service)
            var batchSize: Int? = nil
            var memoryThreshold: Int64? = nil

            for child in mirror.children {
                if child.label == "options" {
                    let opts = child.value
                    let optMirror = Mirror(reflecting: opts)
                    for optChild in optMirror.children {
                        if optChild.label == "batchSize", let v = optChild.value as? Int { batchSize = v }
                        if optChild.label == "memoryThreshold", let v = optChild.value as? Int64 { memoryThreshold = v }
                    }
                }
            }

            XCTAssertEqual(batchSize, deviceClass.streamingBatchSize)
            XCTAssertEqual(memoryThreshold, Int64(deviceClass.streamingCleanupThresholdBytes))
        }
    }

    func testPDFProcessingCacheAdaptiveMemoryLimit() {
        for deviceClass in [DeviceClass.low, .mid, .high] {
            DeviceClass.current = deviceClass

            // Use default init to trigger adaptive memory limit path
            let cache = PDFProcessingCache()
            let metrics = cache.getCacheMetrics()

            // Implementation stores totalCostLimit under key "memoryItems"
            let limit = metrics["memoryItems"] as? Int
            XCTAssertEqual(limit, deviceClass.cacheMemoryLimitBytes)
        }
    }
}


