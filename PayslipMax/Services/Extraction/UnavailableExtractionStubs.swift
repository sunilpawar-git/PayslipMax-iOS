import Foundation
import PDFKit
import Combine

enum UnavailableExtractionStubs {
    final class TextExtractionEngineStub: TextExtractionEngineProtocol {
        private let subject = PassthroughSubject<ExtractionProgress, Never>()
        func executeExtraction(from document: PDFDocument, using strategy: TextExtractionStrategy, options: ExtractionOptions) async -> TextExtractionResult {
            return TextExtractionResult(
                text: "",
                metrics: ExtractionMetrics(),
                success: false,
                error: NSError(domain: "ExtractionUnavailable", code: -1, userInfo: [NSLocalizedDescriptionKey: "Text extraction engine unavailable in this build"]) )
        }
        func getProgressPublisher() -> AnyPublisher<ExtractionProgress, Never> { subject.eraseToAnyPublisher() }
    }

    final class ExtractionStrategySelectorStub: ExtractionStrategySelectorProtocol {
        func selectOptimalStrategy(for document: PDFDocument, userPreferences: ExtractionPreferences?) async -> StrategyRecommendation {
            return StrategyRecommendation(strategy: .sequential, options: ExtractionOptions(), confidence: 0.0, reasoning: "Selector unavailable; defaulted to sequential")
        }
        func analyzeDocument(_ document: PDFDocument) async -> StrategyDocumentAnalysis {
            let req = ProcessingRequirements(estimatedTimeSeconds: 0, estimatedMemoryMB: 0, requiresOCR: false)
            return StrategyDocumentAnalysis(pageCount: document.pageCount, estimatedSizeBytes: 0, contentComplexity: .low, hasScannedContent: false, processingRequirements: req, documentCharacteristics: [:] as [String: Any])
        }
    }

    final class TextProcessingPipelineStub: TextProcessingPipelineProtocol {
        func processText(_ rawText: String, from document: PDFDocument, options: ProcessingOptions) async -> ProcessingResult {
            let metadata = ProcessingMetadata(
                originalLength: rawText.count,
                stagesExecuted: [],
                processingTime: 0,
                qualityMetrics: QualityMetrics()
            )
            return ProcessingResult(
                processedText: rawText,
                metadata: metadata,
                stageResults: [:],
                success: false
            )
        }
        func executeStage(_ stage: PipelineStage, input: String, context: ProcessingContext) async throws -> StageResult {
            return StageResult(
                stage: stage,
                input: input,
                output: input,
                processingTime: 0,
                metrics: StageMetrics(
                    transformationsApplied: 0,
                    qualityImprovement: 0,
                    charactersRemoved: nil,
                    charactersChanged: nil,
                    structuresDetected: nil,
                    enhancementsApplied: nil,
                    validationScore: nil,
                    issuesFound: nil,
                    formattingChanges: nil
                ),
                shouldTerminate: true,
                terminationReason: "Text processing pipeline unavailable"
            )
        }
    }

    final class ExtractionResultValidatorStub: ExtractionResultValidatorProtocol {
        func validateExtractionResult(_ result: TextExtractionResult, from originalDocument: PDFDocument, using validationCriteria: ValidationCriteria) async -> ValidationReport {
            return ValidationReport(
                isValid: false,
                overallScore: 0.0,
                validationTime: 0,
                dimensionResults: [:],
                issues: [],
                recommendations: [],
                summary: "Validator unavailable"
            )
        }
        func performQuickValidation(extractedText: String, expectedMetrics: ExtractionMetrics?) -> QuickValidationResult {
            return QuickValidationResult(
                isValid: false,
                quickScore: 0,
                issues: [],
                warnings: ["Validator unavailable"],
                textLength: extractedText.count,
                artifactRatio: 0
            )
        }
        func validateQuality(_ result: TextExtractionResult, against benchmarks: QualityBenchmarks) async -> QualityAssessment {
            return QualityAssessment(
                overallQuality: 0,
                accuracyScore: 0,
                completenessScore: 0,
                consistencyScore: 0,
                qualityMetrics: TextQualityMetrics(
                    readability: 0,
                    coherence: 0,
                    accuracy: 0,
                    completeness: 0
                ),
                benchmarkComparisons: [],
                meetsStandards: false
            )
        }
    }
}


