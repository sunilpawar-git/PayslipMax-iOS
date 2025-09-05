import Foundation
import PDFKit

/// Enhanced modular pipeline with optimized stage transitions and intelligent batch processing
/// Builds upon ModularPayslipProcessingPipeline with advanced optimization techniques
@MainActor
final class EnhancedModularPipeline: PayslipProcessingPipeline {
    
    // MARK: - Dependencies
    
    private let originalPipeline: ModularPayslipProcessingPipeline
    private let stageTransitionManager: OptimizedStageTransitionManager
    private let batchProcessor: IntelligentBatchProcessor
    
    // MARK: - Performance Tracking
    
    @Published private(set) var pipelineMetrics = PipelinePerformanceMetrics()
    
    // MARK: - Initialization
    
    init(
        originalPipeline: ModularPayslipProcessingPipeline,
        stageTransitionManager: OptimizedStageTransitionManager? = nil,
        batchProcessor: IntelligentBatchProcessor? = nil
    ) {
        self.originalPipeline = originalPipeline
        self.stageTransitionManager = stageTransitionManager ?? OptimizedStageTransitionManager()
        self.batchProcessor = batchProcessor ?? IntelligentBatchProcessor()
    }
    
    // MARK: - PayslipProcessingPipeline Protocol
    
    func validatePDF(_ data: Data) async -> Result<Data, PDFProcessingError> {
        return await executeOptimizedStage(
            input: data,
            stageType: .validation,
            operation: { [self] in await self.originalPipeline.validatePDF($0) }
        )
    }
    
    func extractText(_ data: Data) async -> Result<(Data, String), PDFProcessingError> {
        return await executeOptimizedStage(
            input: data,
            stageType: .extraction,
            operation: { [self] in await self.originalPipeline.extractText($0) }
        )
    }
    
    func detectFormat(_ data: Data, text: String) async -> Result<(Data, String, PayslipFormat), PDFProcessingError> {
        return await executeOptimizedStage(
            input: (data, text),
            stageType: .detection,
            operation: { [self] input in
                await self.originalPipeline.detectFormat(input.0, text: input.1)
            }
        )
    }
    
    func processPayslip(_ data: Data, text: String, format: PayslipFormat) async -> Result<PayslipItem, PDFProcessingError> {
        return await executeOptimizedStage(
            input: (data, text, format),
            stageType: .processing,
            operation: { [self] input in
                await self.originalPipeline.processPayslip(input.0, text: input.1, format: input.2)
            }
        )
    }
    
    func executePipeline(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        do {
            // Define pipeline stages with optimization
            let stages: [(StageTransitionType, (Any) async throws -> Any)] = [
                (.validation, { input in
                    guard let data = input as? Data else {
                        throw PDFProcessingError.invalidFormat
                    }
                    let result = await self.originalPipeline.validatePDF(data)
                    switch result {
                    case .success(let validatedData):
                        return validatedData
                    case .failure(let error):
                        throw error
                    }
                }),
                (.extraction, { input in
                    guard let data = input as? Data else {
                        throw PDFProcessingError.extractionFailed("Invalid extraction result format")
                    }
                    let result = await self.originalPipeline.extractText(data)
                    switch result {
                    case .success(let extractionResult):
                        return extractionResult
                    case .failure(let error):
                        throw error
                    }
                }),
                (.detection, { input in
                    guard let (data, text) = input as? (Data, String) else {
                        throw PDFProcessingError.parsingFailed("Invalid format result")
                    }
                    let result = await self.originalPipeline.detectFormat(data, text: text)
                    switch result {
                    case .success(let formatResult):
                        return formatResult
                    case .failure(let error):
                        throw error
                    }
                }),
                (.processing, { input in
                    guard let (data, text, format) = input as? (Data, String, PayslipFormat) else {
                        throw PDFProcessingError.parsingFailed("Invalid processing input")
                    }
                    let result = await self.originalPipeline.processPayslip(data, text: text, format: format)
                    switch result {
                    case .success(let payslip):
                        return payslip
                    case .failure(let error):
                        throw error
                    }
                })
            ]
            
            // Execute optimized stage sequence
            let results = try await stageTransitionManager.executeStageSequence(
                input: data,
                stages: stages
            )
            
            guard let finalResult = results.last as? PayslipItem else {
                return .failure(.parsingFailed("Pipeline processing failed"))
            }
            
            await updatePipelineMetrics(successful: true)
            return .success(finalResult)
            
        } catch {
            await updatePipelineMetrics(successful: false)
            if let pdfError = error as? PDFProcessingError {
                return .failure(pdfError)
            } else {
                return .failure(.parsingFailed("Pipeline processing failed"))
            }
        }
    }
    
    // MARK: - Batch Processing Operations
    
    /// Process multiple documents efficiently using intelligent batching
    func processBatch(_ documents: [Data]) async -> [Result<PayslipItem, PDFProcessingError>] {
        do {
            let results = try await batchProcessor.processBatch(items: documents) { data in
                await self.executePipeline(data)
            }
            
            await updateBatchMetrics(batchSize: documents.count, results: results)
            return results
            
        } catch {
            let failureResults = documents.map { _ in
                Result<PayslipItem, PDFProcessingError>.failure(.parsingFailed("Batch processing failed"))
            }
            return failureResults
        }
    }
    
    /// Process documents with progress tracking
    func processBatchWithProgress(
        _ documents: [Data],
        progressHandler: @escaping (Double) -> Void
    ) async -> [Result<PayslipItem, PDFProcessingError>] {
        do {
            let results = try await batchProcessor.processWithProgressTracking(
                items: documents,
                processor: { data in await self.executePipeline(data) },
                progressHandler: progressHandler
            )
            
            await updateBatchMetrics(batchSize: documents.count, results: results)
            return results
            
        } catch {
            let failureResults = documents.map { _ in
                Result<PayslipItem, PDFProcessingError>.failure(.parsingFailed("Batch processing failed"))
            }
            return failureResults
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func executeOptimizedStage<T, U>(
        input: T,
        stageType: StageTransitionType,
        operation: @escaping (T) async -> Result<U, PDFProcessingError>
    ) async -> Result<U, PDFProcessingError> {
        do {
            let stageResult = try await stageTransitionManager.executeStage(
                { input in
                    let result = await operation(input)
                    switch result {
                    case .success(let value):
                        return value
                    case .failure(let error):
                        throw error
                    }
                },
                input: input,
                stageType: stageType
            )
            
            return .success(stageResult.value)
            
        } catch {
            if let pdfError = error as? PDFProcessingError {
                return .failure(pdfError)
            } else {
                return .failure(.parsingFailed("Stage execution failed"))
            }
        }
    }
    
    private func updatePipelineMetrics(successful: Bool) async {
        pipelineMetrics.totalExecutions += 1
        if successful {
            pipelineMetrics.successfulExecutions += 1
        }
    }
    
    private func updateBatchMetrics(batchSize: Int, results: [Result<PayslipItem, PDFProcessingError>]) async {
        let successCount = results.compactMap { result in
            if case .success = result { return result } else { return nil }
        }.count
        
        pipelineMetrics.totalBatches += 1
        pipelineMetrics.totalProcessedDocuments += batchSize
        pipelineMetrics.successfulDocuments += successCount
    }
    
    // MARK: - Performance Access
    
    func getOptimizedMetrics() async -> OptimizedPipelineMetrics {
        let stageMetrics = await stageTransitionManager.getPerformanceMetrics()
        let batchMetrics = await batchProcessor.getDetailedMetrics()
        
        return OptimizedPipelineMetrics(
            pipeline: pipelineMetrics,
            stageTransitions: stageMetrics,
            batchProcessing: batchMetrics
        )
    }
    
    func clearOptimizationCaches() async {
        await stageTransitionManager.clearCaches()
    }
}

// MARK: - Performance Metrics Models

struct PipelinePerformanceMetrics {
    var totalExecutions: Int = 0
    var successfulExecutions: Int = 0
    var totalBatches: Int = 0
    var totalProcessedDocuments: Int = 0
    var successfulDocuments: Int = 0
    
    var successRate: Double {
        return totalExecutions > 0 ? Double(successfulExecutions) / Double(totalExecutions) : 0.0
    }
    
    var batchSuccessRate: Double {
        return totalProcessedDocuments > 0 ? Double(successfulDocuments) / Double(totalProcessedDocuments) : 0.0
    }
}

struct OptimizedPipelineMetrics {
    let pipeline: PipelinePerformanceMetrics
    let stageTransitions: Any // TransitionPerformanceMetrics
    let batchProcessing: BatchProcessingMetrics
}