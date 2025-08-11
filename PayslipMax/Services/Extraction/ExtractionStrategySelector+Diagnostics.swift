import Foundation
import PDFKit

// Diagnostics hooks for ExtractionStrategySelector without modifying core logic.
extension ExtractionStrategySelector {
    func recordDiagnosticsDecision(
        documentAnalysis: StrategyDocumentAnalysis,
        resources: ResourceAssessment,
        recommendation: StrategyRecommendation
    ) {
        let decision = ExtractionDecision(
            pageCount: documentAnalysis.pageCount,
            estimatedSizeBytes: documentAnalysis.estimatedSizeBytes,
            contentComplexity: String(describing: documentAnalysis.contentComplexity),
            hasScannedContent: documentAnalysis.hasScannedContent,
            availableMemoryMB: resources.availableMemoryMB,
            estimatedMemoryNeedMB: resources.estimatedMemoryNeedMB,
            memoryPressureRatio: resources.memoryPressureRatio,
            processorCoreCount: resources.processorCoreCount,
            selectedStrategy: String(describing: recommendation.strategy),
            confidence: recommendation.confidence,
            reasoning: recommendation.reasoning,
            useParallelProcessing: recommendation.options.useParallelProcessing,
            useAdaptiveBatching: recommendation.options.useAdaptiveBatching,
            maxConcurrentOperations: recommendation.options.maxConcurrentOperations,
            memoryThresholdMB: recommendation.options.memoryThresholdMB,
            preprocessText: recommendation.options.preprocessText
        )
        DiagnosticsService.shared.recordExtractionDecision(decision)
    }
}


