import Foundation
import PDFKit

/// Factory for pipeline optimization components.
/// Handles stage transition optimization, batch processing, and enhanced memory management.
@MainActor
class PipelineOptimizationFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    /// Processing container for accessing pipelines
    private let processingContainer: ProcessingContainerProtocol

    // MARK: - Initialization

    init(useMocks: Bool = false, processingContainer: ProcessingContainerProtocol) {
        self.useMocks = useMocks
        self.processingContainer = processingContainer
    }

    // MARK: - Stage Transition Optimization Components

    /// Creates an optimized stage transition manager for efficient pipeline processing.
    func makeOptimizedStageTransitionManager() -> OptimizedStageTransitionManager {
        return OptimizedStageTransitionManager()
    }

    /// Creates an intelligent batch processor for adaptive batch optimization.
    func makeIntelligentBatchProcessor() -> IntelligentBatchProcessor {
        return IntelligentBatchProcessor()
    }

    /// Creates an enhanced modular pipeline with optimized stage transitions.
    func makeEnhancedModularPipeline() -> EnhancedModularPipeline {
        return EnhancedModularPipeline(
            originalPipeline: processingContainer.makePayslipProcessingPipeline() as! ModularPayslipProcessingPipeline,
            stageTransitionManager: makeOptimizedStageTransitionManager(),
            batchProcessor: makeIntelligentBatchProcessor()
        )
    }

    // MARK: - Optimized Processing Pipeline Components

    /// Creates processing pipeline stages for cache management and operation coordination
    func makeProcessingPipelineStages() -> ProcessingPipelineStages {
        return ProcessingPipelineStages()
    }

    /// Creates processing pipeline optimization for performance tracking and memory pressure handling
    func makeProcessingPipelineOptimization() -> ProcessingPipelineOptimization {
        return ProcessingPipelineOptimization(memoryManager: makeEnhancedMemoryManager())
    }

    /// Creates an enhanced memory manager for memory pressure monitoring
    func makeEnhancedMemoryManager() -> EnhancedMemoryManager {
        return EnhancedMemoryManager()
    }

    /// Creates an optimized processing pipeline with proper dependency injection
    func makeOptimizedProcessingPipeline() -> OptimizedProcessingPipeline {
        return OptimizedProcessingPipeline(
            stages: makeProcessingPipelineStages(),
            optimization: makeProcessingPipelineOptimization()
        )
    }

    // MARK: - Private Methods

}
