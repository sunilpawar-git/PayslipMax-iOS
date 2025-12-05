import Foundation
import PDFKit

/// Integration service that enhances the existing ModularPayslipProcessingPipeline
/// with advanced deduplication and operation coalescing capabilities
@MainActor
final class EnhancedProcessingPipelineIntegratorSimplified {

    // MARK: - Dependencies

    private let deduplicationService: EnhancedDeduplicationServiceSimplified
    private let coalescingService: OperationCoalescingServiceSimplified
    private let originalPipeline: ModularPayslipProcessingPipeline
    private let cacheManager: SimpleCacheManager

    // MARK: - Performance Tracking

    @Published private(set) var performanceMetrics = IntegratedPerformanceMetrics()

    // MARK: - Configuration

    private struct IntegrationConfig {
        static let enableSemanticFingerprinting = true
        static let enableOperationCoalescing = true
        static let enableAdvancedCaching = true
        static let maxConcurrentDeduplication = 3
    }

    // MARK: - Initialization

    init(originalPipeline: ModularPayslipProcessingPipeline,
         deduplicationService: EnhancedDeduplicationServiceSimplified? = nil,
         coalescingService: OperationCoalescingServiceSimplified? = nil) {
        self.originalPipeline = originalPipeline
        self.cacheManager = SimpleCacheManager()
        self.deduplicationService = deduplicationService ?? EnhancedDeduplicationServiceSimplified()
        self.coalescingService = coalescingService ?? OperationCoalescingServiceSimplified()
    }

    // MARK: - Enhanced Pipeline Interface

    /// Execute pipeline with enhanced deduplication and operation coalescing
    /// - Parameter data: PDF data to process
    /// - Returns: Processed payslip item or cached result
    func executeEnhancedPipeline(_ data: Data) async -> Result<PayslipDTO, PDFProcessingError> {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task { @MainActor in
                self.performanceMetrics.recordDocumentProcessing(duration: duration)
            }
        }

        do {
            // Step 1: Check for duplicate processing
            if let duplicateRecord = await deduplicationService.checkForDuplicate(data: data) {
                await recordDeduplicationHit()
                if let payslipItem = try? extractPayslipItem(from: duplicateRecord.result) {
                    let payslipDTO = PayslipDTO(from: payslipItem)
                    return .success(payslipDTO)
                }
            }

            // Step 2: Check cache with enhanced key
            let enhancedKey = await deduplicationService.generateEnhancedCacheKey(data: data)
            if let cachedResult: PayslipItem = cacheManager.retrieve(forKey: enhancedKey) {
                await recordCacheHit()
                let payslipDTO = PayslipDTO(from: cachedResult)
                return .success(payslipDTO)
            }

            // Step 3: Execute with operation coalescing
            let result = try await coalescingService.executePDFOperation(
                pdfHash: enhancedKey,
                processingType: "full_pipeline"
            ) {
                return await self.originalPipeline.executePipeline(data)
            }

            // Step 4: Cache successful result and convert to DTO
            if case .success(let payslipItem) = result {
                cacheManager.store(payslipItem, forKey: enhancedKey)
                await deduplicationService.recordProcessing(data: data, document: nil, result: payslipItem)
                // Convert to DTO for Sendable compliance
                let payslipDTO = PayslipDTO(from: payslipItem)
                return .success(payslipDTO)
            } else {
                return result.map { PayslipDTO(from: $0) }
            }

        } catch {
            await recordProcessingError()
            return .failure(.processingFailed)
        }
    }

    /// Execute enhanced batch processing with intelligent deduplication
    /// - Parameter dataArray: Array of PDF data to process
    /// - Returns: Array of processing results
    func executeEnhancedBatchProcessing(_ dataArray: [Data]) async -> [Result<PayslipDTO, PDFProcessingError>] {
        let startTime = Date()

        // Pre-process for deduplication
        var uniqueData: [String: Data] = [:]
        var dataKeyMapping: [Int: String] = [:]

        for (index, data) in dataArray.enumerated() {
            let key = await deduplicationService.generateEnhancedCacheKey(data: data)
            dataKeyMapping[index] = key

            if uniqueData[key] == nil {
                uniqueData[key] = data
            }
        }

        // Process unique data only
        var uniqueResults: [String: Result<PayslipDTO, PDFProcessingError>] = [:]

        await withTaskGroup(of: (String, Result<PayslipDTO, PDFProcessingError>).self) { taskGroup in
            for (key, data) in uniqueData {
                taskGroup.addTask {
                    let result = await self.executeEnhancedPipeline(data)
                    return (key, result)
                }
            }

            for await (key, result) in taskGroup {
                uniqueResults[key] = result
            }
        }

        // Map results back to original array
        var finalResults: [Result<PayslipDTO, PDFProcessingError>] =
            Array(repeating: .failure(.processingFailed), count: dataArray.count)

        for (index, key) in dataKeyMapping {
            let result = uniqueResults[key] ?? .failure(.processingFailed)
            finalResults[index] = result
        }

        // Record batch processing metrics
        let duration = Date().timeIntervalSince(startTime)
        let deduplicationSaved = dataArray.count - uniqueData.count
        await recordBatchProcessing(
            total: dataArray.count,
            unique: uniqueData.count,
            duration: duration,
            deduplicationSaved: deduplicationSaved
        )

        return finalResults
    }

    /// Execute specific pipeline stage with enhanced caching
    /// - Parameters:
    ///   - data: PDF data to process
    ///   - stage: Pipeline stage to execute
    ///   - operation: Operation to execute if not cached
    /// - Returns: Stage result
    func executeStageWithCaching<T: Codable>(_ data: Data,
                                           stage: PipelineStage,
                                           operation: @escaping () async throws -> T) async throws -> T {

        let stageKey = await generateStageKey(data: data, stage: stage)

        // Check cache for stage result
        if let cachedResult: T = cacheManager.retrieve(forKey: stageKey) {
            await recordStageCacheHit()
            return cachedResult
        }

        // Execute operation with coalescing
        let result = try await coalescingService.executeCoalescedOperation(
            operationId: stage.rawValue,
            parameters: ["key": stageKey]
        ) {
            return try await operation()
        }

        // Cache stage result
        cacheManager.store(result, forKey: stageKey)
        await recordStageCacheMiss()

        return result
    }

    /// Get current performance metrics
    func getPerformanceMetrics() -> IntegratedPerformanceMetrics {
        return performanceMetrics
    }

    /// Generate performance summary
    func generatePerformanceSummary() -> PerformanceSummary {
        return performanceMetrics.generateSummary()
    }

    /// Reset performance metrics
    func resetMetrics() {
        performanceMetrics.reset()
    }

    // MARK: - Private Methods

    private func generateStageKey(data: Data, stage: PipelineStage) async -> String {
        let baseKey = await deduplicationService.generateEnhancedCacheKey(data: data)
        return "\(stage.rawValue)_\(baseKey)"
    }

    private func extractPayslipItem(from data: Data) throws -> PayslipItem? {
        // Simplified extraction - in production use proper deserialization
        return try? JSONDecoder().decode(PayslipItem.self, from: data)
    }

    private func recordCacheHit() async {
        performanceMetrics.recordCacheHit()
    }

    private func recordStageCacheHit() async {
        performanceMetrics.recordStageCacheHit()
    }

    private func recordStageCacheMiss() async {
        performanceMetrics.recordStageCacheMiss()
    }

    private func recordDeduplicationHit() async {
        performanceMetrics.recordDeduplicationHit()
    }

    private func recordProcessingError() async {
        performanceMetrics.recordProcessingError()
    }

    private func recordBatchProcessing(total: Int, unique: Int, duration: TimeInterval, deduplicationSaved: Int) async {
        let timeSavedPerDocument = duration / Double(unique)
        let totalTimeSaved = timeSavedPerDocument * Double(deduplicationSaved)

        performanceMetrics.recordDeduplicationHit(
            timeSaved: totalTimeSaved,
            memorySaved: Int64(deduplicationSaved * 1024 * 1024) // Estimate 1MB per document
        )
    }
}

// MARK: - Pipeline Stages

/// Pipeline stages for enhanced caching
enum PipelineStage: String, CaseIterable {
    case validation = "validate"
    case textExtraction = "extract"
    case formatDetection = "format"
    case processing = "process"

    var processingContext: ProcessingContext {
        switch self {
        case .validation: return .validation
        case .textExtraction: return .textExtraction
        case .formatDetection: return .formatDetection
        case .processing: return .processing
        }
    }
}

// MARK: - Simple Cache Manager for Phase 3

/// Simple cache manager for enhanced processing pipeline
final class SimpleCacheManager {
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.payslipmax.simple.cache", attributes: .concurrent)

    func store<T: Codable>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) { self.cache[key] = value }
    }

    func retrieve<T: Codable>(forKey key: String) -> T? {
        queue.sync { cache[key] as? T }
    }

    func remove(forKey key: String) {
        queue.async(flags: .barrier) { self.cache.removeValue(forKey: key) }
    }

    func clearAll() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }

    var count: Int { queue.sync { cache.count } }
}
