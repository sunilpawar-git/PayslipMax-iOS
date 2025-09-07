import Foundation
import PDFKit

/// Adaptive batch configuration calculator
///
/// Following Phase 4B modular pattern: Focused responsibility for configuration optimization
/// Calculates optimal batch parameters based on document and system characteristics
final class BatchConfigurationCalculator {
    
    // MARK: - Dependencies
    
    /// Resource pressure monitor for adaptive processing
    private let pressureMonitor: ResourcePressureMonitor
    
    // MARK: - Initialization
    
    /// Initialize configuration calculator
    /// - Parameter pressureMonitor: Resource pressure monitor instance
    init(pressureMonitor: ResourcePressureMonitor = ResourcePressureMonitor()) {
        self.pressureMonitor = pressureMonitor
    }
    
    // MARK: - Configuration Calculation
    
    /// Calculate adaptive batch configuration based on document and system state
    /// - Parameters:
    ///   - document: PDF document to analyze
    ///   - options: Extraction options
    ///   - baseConfiguration: Base configuration to adapt from
    /// - Returns: Optimized batch configuration
    func calculateAdaptiveBatchConfiguration(
        for document: PDFDocument,
        options: ExtractionOptions,
        baseConfiguration: BatchConfiguration
    ) -> BatchConfiguration {
        
        // Get memory pressure recommendations
        let recommendedBatchSize = pressureMonitor.getRecommendedBatchSize(
            default: baseConfiguration.maxBatchSize
        )
        let recommendedConcurrency = pressureMonitor.getRecommendedConcurrency(
            default: baseConfiguration.maxConcurrentBatches
        )
        
        // Adjust based on document characteristics
        let adjustedBatchSize = calculateOptimalBatchSize(
            pageCount: document.pageCount,
            recommendedSize: recommendedBatchSize
        )
        
        return BatchConfiguration(
            maxBatchSize: adjustedBatchSize,
            maxConcurrentBatches: recommendedConcurrency,
            memoryThreshold: baseConfiguration.memoryThreshold
        )
    }
    
    /// Calculate optimal batch size based on page count
    /// - Parameters:
    ///   - pageCount: Number of pages in document
    ///   - recommendedSize: Recommended batch size from pressure monitor
    /// - Returns: Optimal batch size
    func calculateOptimalBatchSize(pageCount: Int, recommendedSize: Int) -> Int {
        if pageCount > 100 {
            return min(recommendedSize, 5)  // Large documents: smaller batches
        } else if pageCount > 20 {
            return min(recommendedSize, 8)  // Medium documents: moderate batches
        } else {
            return recommendedSize          // Small documents: can use larger batches
        }
    }
    
    /// Get recommended configuration for document size
    /// - Parameter pageCount: Number of pages in document
    /// - Returns: Recommended base configuration
    func getRecommendedConfiguration(for pageCount: Int) -> BatchConfiguration {
        if pageCount > 100 {
            // Large documents: conservative settings
            return BatchConfiguration(
                maxBatchSize: 3,
                maxConcurrentBatches: 1,
                memoryThreshold: 150 * 1024 * 1024
            )
        } else if pageCount > 50 {
            // Medium documents: balanced settings
            return BatchConfiguration(
                maxBatchSize: 5,
                maxConcurrentBatches: 2,
                memoryThreshold: 200 * 1024 * 1024
            )
        } else {
            // Small documents: performance settings
            return BatchConfiguration(
                maxBatchSize: 10,
                maxConcurrentBatches: 3,
                memoryThreshold: 300 * 1024 * 1024
            )
        }
    }
    
    /// Validate configuration against system constraints
    /// - Parameter configuration: Configuration to validate
    /// - Returns: Validated and potentially adjusted configuration
    func validateConfiguration(_ configuration: BatchConfiguration) -> BatchConfiguration {
        let availableMemory = MemoryUtils.getAvailableMemory()
        let maxSafeThreshold = availableMemory / 2 // Use max 50% of available memory
        
        let adjustedThreshold = min(configuration.memoryThreshold, maxSafeThreshold)
        
        return BatchConfiguration(
            maxBatchSize: max(1, min(configuration.maxBatchSize, 20)), // Cap at 20 pages
            maxConcurrentBatches: max(1, min(configuration.maxConcurrentBatches, 4)), // Cap at 4 concurrent
            memoryThreshold: adjustedThreshold
        )
    }
}
