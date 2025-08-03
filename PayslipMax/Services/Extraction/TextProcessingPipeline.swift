import Foundation
import PDFKit
import Combine

/// Protocol for text processing pipeline operations
protocol TextProcessingPipelineProtocol {
    /// Processes extracted text through the complete pipeline
    /// - Parameters:
    ///   - rawText: The raw text extracted from PDF
    ///   - document: The source PDF document
    ///   - options: Processing options
    /// - Returns: Processed text and processing metadata
    func processText(
        _ rawText: String,
        from document: PDFDocument,
        options: ProcessingOptions
    ) async -> ProcessingResult
    
    /// Executes a specific pipeline stage
    /// - Parameters:
    ///   - stage: The pipeline stage to execute
    ///   - input: Input text for the stage
    ///   - context: Processing context
    /// - Returns: Stage processing result
    func executeStage(
        _ stage: PipelineStage,
        input: String,
        context: ProcessingContext
    ) async throws -> StageResult
}

/// Text processing pipeline that handles post-extraction text refinement
///
/// This pipeline processes raw extracted text through multiple stages to improve
/// quality, format consistency, and extract structured data. It provides a
/// configurable, composable architecture for text processing operations.
///
/// ## Pipeline Stages:
/// 1. **Cleaning**: Remove artifacts, normalize whitespace, fix encoding issues
/// 2. **Normalization**: Standardize formats, currency, dates, numbers
/// 3. **Structure Detection**: Identify tables, lists, headers, sections
/// 4. **Enhancement**: Apply OCR corrections, spelling fixes, context awareness
/// 5. **Validation**: Verify processing quality and completeness
/// 6. **Formatting**: Apply final formatting and structure
///
/// ## Architecture:
/// The pipeline uses a chain-of-responsibility pattern where each stage
/// can modify the text and pass it to the next stage or short-circuit
/// the process if needed.
class TextProcessingPipeline: TextProcessingPipelineProtocol {
    
    // MARK: - Dependencies
    
    /// Text cleaning service
    private let textCleaner: TextCleaningService
    
    /// Text normalization service
    private let textNormalizer: TextNormalizationService
    
    /// Structure detection service
    private let structureDetector: TextStructureDetector
    
    /// Text enhancement service
    private let textEnhancer: TextEnhancementService
    
    /// Processing validation service
    private let processingValidator: ProcessingValidationService
    
    /// Text formatting service
    private let textFormatter: TextFormattingService
    
    // MARK: - Configuration
    
    /// Default pipeline stages in execution order
    private let defaultStages: [PipelineStage] = [
        .cleaning,
        .normalization,
        .structureDetection,
        .enhancement,
        .validation,
        .formatting
    ]
    
    /// Progress tracking subject
    private let progressSubject = PassthroughSubject<PipelineProgress, Never>()
    
    /// Cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the text processing pipeline with required services
    /// - Parameters:
    ///   - textCleaner: Service for text cleaning operations
    ///   - textNormalizer: Service for text normalization
    ///   - structureDetector: Service for detecting text structure
    ///   - textEnhancer: Service for text enhancement
    ///   - processingValidator: Service for validating processing results
    ///   - textFormatter: Service for final text formatting
    init(
        textCleaner: TextCleaningService,
        textNormalizer: TextNormalizationService,
        structureDetector: TextStructureDetector,
        textEnhancer: TextEnhancementService,
        processingValidator: ProcessingValidationService,
        textFormatter: TextFormattingService
    ) {
        self.textCleaner = textCleaner
        self.textNormalizer = textNormalizer
        self.structureDetector = structureDetector
        self.textEnhancer = textEnhancer
        self.processingValidator = processingValidator
        self.textFormatter = textFormatter
        
        setupProgressTracking()
    }
    
    // MARK: - Pipeline Execution
    
    /// Processes extracted text through the complete pipeline
    /// - Parameters:
    ///   - rawText: The raw text extracted from PDF
    ///   - document: The source PDF document
    ///   - options: Processing options
    /// - Returns: Processed text and processing metadata
    func processText(
        _ rawText: String,
        from document: PDFDocument,
        options: ProcessingOptions = .default
    ) async -> ProcessingResult {
        
        let startTime = Date()
        let context = ProcessingContext(
            document: document,
            options: options,
            startTime: startTime
        )
        
        // Initialize processing metadata
        var metadata = ProcessingMetadata(
            originalLength: rawText.count,
            stagesExecuted: [],
            processingTime: 0,
            qualityMetrics: QualityMetrics()
        )
        
        // Determine stages to execute
        let stagesToExecute = options.customStages ?? defaultStages
        
        // Execute pipeline stages
        var currentText = rawText
        var stageResults: [PipelineStage: StageResult] = [:]
        
        for (index, stage) in stagesToExecute.enumerated() {
            // Emit progress
            emitProgress(PipelineProgress(
                stage: stage,
                progress: Double(index) / Double(stagesToExecute.count),
                currentLength: currentText.count
            ))
            
            do {
                // Execute stage
                let stageResult = try await executeStage(stage, input: currentText, context: context)
                
                // Update current text and metadata
                currentText = stageResult.output
                stageResults[stage] = stageResult
                metadata.stagesExecuted.append(stage)
                
                // Check for early termination
                if stageResult.shouldTerminate {
                    metadata.terminatedEarly = true
                    metadata.terminationReason = stageResult.terminationReason
                    break
                }
                
                // Validate intermediate result if configured
                if options.validateIntermediateResults {
                    let validation = await validateIntermediateResult(currentText, stage: stage)
                    if !validation.isValid {
                        metadata.validationWarnings.append(validation.warning)
                    }
                }
                
            } catch {
                // Handle stage error
                let errorResult = handleStageError(error, stage: stage, input: currentText)
                metadata.errors.append(errorResult.error)
                
                if errorResult.shouldContinue {
                    currentText = errorResult.fallbackOutput
                } else {
                    // Fatal error - terminate pipeline
                    metadata.terminatedEarly = true
                    metadata.terminationReason = "Stage \(stage) failed: \(error.localizedDescription)"
                    break
                }
            }
        }
        
        // Finalize processing
        let endTime = Date()
        metadata.processingTime = endTime.timeIntervalSince(startTime)
        metadata.finalLength = currentText.count
        metadata.qualityMetrics = calculateQualityMetrics(
            original: rawText,
            processed: currentText,
            stageResults: stageResults
        )
        
        // Emit completion
        emitProgress(PipelineProgress(
            stage: .completed,
            progress: 1.0,
            currentLength: currentText.count
        ))
        
        return ProcessingResult(
            processedText: currentText,
            metadata: metadata,
            stageResults: stageResults,
            success: !metadata.terminatedEarly || metadata.errors.isEmpty
        )
    }
    
    /// Executes a specific pipeline stage
    /// - Parameters:
    ///   - stage: The pipeline stage to execute
    ///   - input: Input text for the stage
    ///   - context: Processing context
    /// - Returns: Stage processing result
    func executeStage(
        _ stage: PipelineStage,
        input: String,
        context: ProcessingContext
    ) async throws -> StageResult {
        
        let stageStartTime = Date()
        
        let result: StageResult
        
        switch stage {
        case .cleaning:
            result = try await executeCleaning(input: input, context: context)
            
        case .normalization:
            result = try await executeNormalization(input: input, context: context)
            
        case .structureDetection:
            result = try await executeStructureDetection(input: input, context: context)
            
        case .enhancement:
            result = try await executeEnhancement(input: input, context: context)
            
        case .validation:
            result = try await executeValidation(input: input, context: context)
            
        case .formatting:
            result = try await executeFormatting(input: input, context: context)
            
        case .completed:
            // Special case for completion marker
            result = StageResult(
                stage: stage,
                input: input,
                output: input,
                processingTime: 0,
                metrics: StageMetrics(),
                shouldTerminate: false,
                terminationReason: nil
            )
        }
        
        // Update stage timing
        var finalResult = result
        finalResult.processingTime = Date().timeIntervalSince(stageStartTime)
        
        return finalResult
    }
    
    // MARK: - Stage Implementations
    
    /// Executes text cleaning stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Cleaning stage result
    private func executeCleaning(input: String, context: ProcessingContext) async throws -> StageResult {
        let cleanedText = try await textCleaner.cleanText(
            input,
            options: context.options.cleaningOptions
        )
        
        let metrics = StageMetrics(
            transformationsApplied: textCleaner.getLastTransformationCount(),
            qualityImprovement: calculateCleaningQualityImprovement(original: input, cleaned: cleanedText),
            charactersRemoved: input.count - cleanedText.count
        )
        
        return StageResult(
            stage: .cleaning,
            input: input,
            output: cleanedText,
            processingTime: 0, // Will be set by caller
            metrics: metrics,
            shouldTerminate: false,
            terminationReason: nil
        )
    }
    
    /// Executes text normalization stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Normalization stage result
    private func executeNormalization(input: String, context: ProcessingContext) async throws -> StageResult {
        let normalizedText = try await textNormalizer.normalizeText(
            input,
            options: context.options.normalizationOptions
        )
        
        let metrics = StageMetrics(
            transformationsApplied: textNormalizer.getLastTransformationCount(),
            qualityImprovement: calculateNormalizationQualityImprovement(original: input, normalized: normalizedText),
            charactersChanged: countCharacterDifferences(original: input, normalized: normalizedText)
        )
        
        return StageResult(
            stage: .normalization,
            input: input,
            output: normalizedText,
            processingTime: 0,
            metrics: metrics,
            shouldTerminate: false,
            terminationReason: nil
        )
    }
    
    /// Executes structure detection stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Structure detection stage result
    private func executeStructureDetection(input: String, context: ProcessingContext) async throws -> StageResult {
        let structuredText = try await structureDetector.detectAndMarkStructure(
            input,
            options: context.options.structureOptions
        )
        
        let detectedStructures = structureDetector.getLastDetectedStructures()
        
        let metrics = StageMetrics(
            transformationsApplied: detectedStructures.reduce(0) { $0 + $1.elementCount },
            qualityImprovement: calculateStructureQualityImprovement(structures: detectedStructures),
            structuresDetected: detectedStructures.count
        )
        
        return StageResult(
            stage: .structureDetection,
            input: input,
            output: structuredText,
            processingTime: 0,
            metrics: metrics,
            shouldTerminate: false,
            terminationReason: nil
        )
    }
    
    /// Executes text enhancement stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Enhancement stage result
    private func executeEnhancement(input: String, context: ProcessingContext) async throws -> StageResult {
        let enhancedText = try await textEnhancer.enhanceText(
            input,
            options: context.options.enhancementOptions
        )
        
        let enhancements = textEnhancer.getLastEnhancements()
        
        let metrics = StageMetrics(
            transformationsApplied: enhancements.reduce(0) { $0 + $1.changeCount },
            qualityImprovement: calculateEnhancementQualityImprovement(enhancements: enhancements),
            enhancementsApplied: enhancements.count
        )
        
        return StageResult(
            stage: .enhancement,
            input: input,
            output: enhancedText,
            processingTime: 0,
            metrics: metrics,
            shouldTerminate: false,
            terminationReason: nil
        )
    }
    
    /// Executes validation stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Validation stage result
    private func executeValidation(input: String, context: ProcessingContext) async throws -> StageResult {
        let validationResult = try await processingValidator.validateProcessedText(
            input,
            options: context.options.validationOptions
        )
        
        // Check if validation should terminate processing
        let shouldTerminate = !validationResult.isValid && context.options.terminateOnValidationFailure
        let terminationReason = shouldTerminate ? "Validation failed: \(validationResult.issues.joined(separator: ", "))" : nil
        
        let metrics = StageMetrics(
            transformationsApplied: 0,
            qualityImprovement: validationResult.score,
            validationScore: validationResult.score,
            issuesFound: validationResult.issues.count
        )
        
        return StageResult(
            stage: .validation,
            input: input,
            output: input, // Validation doesn't modify text
            processingTime: 0,
            metrics: metrics,
            shouldTerminate: shouldTerminate,
            terminationReason: terminationReason
        )
    }
    
    /// Executes formatting stage
    /// - Parameters:
    ///   - input: Input text
    ///   - context: Processing context
    /// - Returns: Formatting stage result
    private func executeFormatting(input: String, context: ProcessingContext) async throws -> StageResult {
        let formattedText = try await textFormatter.formatText(
            input,
            options: context.options.formattingOptions
        )
        
        let formattingChanges = textFormatter.getLastFormattingChanges()
        
        let metrics = StageMetrics(
            transformationsApplied: formattingChanges.reduce(0) { $0 + $1.changeCount },
            qualityImprovement: calculateFormattingQualityImprovement(changes: formattingChanges),
            formattingChanges: formattingChanges.count
        )
        
        return StageResult(
            stage: .formatting,
            input: input,
            output: formattedText,
            processingTime: 0,
            metrics: metrics,
            shouldTerminate: false,
            terminationReason: nil
        )
    }
    
    // MARK: - Helper Methods
    
    /// Sets up progress tracking
    private func setupProgressTracking() {
        progressSubject
            .sink { progress in
                print("[TextProcessingPipeline] Stage: \(progress.stage), Progress: \(Int(progress.progress * 100))%, Length: \(progress.currentLength)")
            }
            .store(in: &cancellables)
    }
    
    /// Emits pipeline progress
    /// - Parameter progress: Progress information
    private func emitProgress(_ progress: PipelineProgress) {
        progressSubject.send(progress)
    }
    
    /// Validates intermediate processing result
    /// - Parameters:
    ///   - text: Text to validate
    ///   - stage: Current pipeline stage
    /// - Returns: Validation result
    private func validateIntermediateResult(_ text: String, stage: PipelineStage) async -> IntermediateValidation {
        // Basic validation - could be more sophisticated
        let isValid = !text.isEmpty && text.count > 10
        let warning = isValid ? nil : "Stage \(stage) produced minimal output (\(text.count) characters)"
        
        return IntermediateValidation(isValid: isValid, warning: warning)
    }
    
    /// Handles stage processing errors
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - stage: The stage where error occurred
    ///   - input: Input text for the stage
    /// - Returns: Error handling result
    private func handleStageError(_ error: Error, stage: PipelineStage, input: String) -> StageErrorResult {
        let stageError = ProcessingError(
            stage: stage,
            error: error,
            timestamp: Date()
        )
        
        // Determine if processing should continue
        let shouldContinue = stage != .validation // Continue for most stages except validation
        
        return StageErrorResult(
            error: stageError,
            shouldContinue: shouldContinue,
            fallbackOutput: input // Use input as fallback
        )
    }
    
    /// Calculates overall quality metrics
    /// - Parameters:
    ///   - original: Original text
    ///   - processed: Processed text
    ///   - stageResults: Results from all stages
    /// - Returns: Quality metrics
    private func calculateQualityMetrics(
        original: String,
        processed: String,
        stageResults: [PipelineStage: StageResult]
    ) -> QualityMetrics {
        let overallImprovement = stageResults.values.reduce(0) { $0 + $1.metrics.qualityImprovement }
        let totalTransformations = stageResults.values.reduce(0) { $0 + $1.metrics.transformationsApplied }
        
        return QualityMetrics(
            overallImprovement: overallImprovement / Double(stageResults.count),
            totalTransformations: totalTransformations,
            lengthChangeRatio: Double(processed.count) / Double(original.count),
            stageCount: stageResults.count
        )
    }
    
    // MARK: - Quality Calculation Methods
    
    private func calculateCleaningQualityImprovement(original: String, cleaned: String) -> Double {
        // Simple quality metric based on character removal ratio
        let removalRatio = Double(original.count - cleaned.count) / Double(original.count)
        return min(1.0, removalRatio * 2) // Higher removal generally indicates better cleaning
    }
    
    private func calculateNormalizationQualityImprovement(original: String, normalized: String) -> Double {
        // Quality improvement based on format consistency
        let changeRatio = Double(countCharacterDifferences(original: original, normalized: normalized)) / Double(original.count)
        return min(1.0, changeRatio) // More changes generally indicate better normalization
    }
    
    private func calculateStructureQualityImprovement(structures: [DetectedStructure]) -> Double {
        // Quality based on number and complexity of detected structures
        let structureScore = Double(structures.count) * 0.1
        return min(1.0, structureScore)
    }
    
    private func calculateEnhancementQualityImprovement(enhancements: [TextEnhancement]) -> Double {
        // Quality based on successful enhancements
        let enhancementScore = Double(enhancements.count) * 0.1
        return min(1.0, enhancementScore)
    }
    
    private func calculateFormattingQualityImprovement(changes: [FormattingChange]) -> Double {
        // Quality based on formatting improvements
        let formattingScore = Double(changes.count) * 0.05
        return min(1.0, formattingScore)
    }
    
    private func countCharacterDifferences(original: String, normalized: String) -> Int {
        // Simple diff count - could be more sophisticated
        return abs(original.count - normalized.count)
    }
}

// MARK: - Supporting Models and Protocols

/// Pipeline processing stages
enum PipelineStage: String, CaseIterable {
    case cleaning = "cleaning"
    case normalization = "normalization"
    case structureDetection = "structureDetection"
    case enhancement = "enhancement"
    case validation = "validation"
    case formatting = "formatting"
    case completed = "completed"
}

/// Processing options for the pipeline
struct ProcessingOptions {
    let customStages: [PipelineStage]?
    let validateIntermediateResults: Bool
    let terminateOnValidationFailure: Bool
    let cleaningOptions: TextCleaningOptions
    let normalizationOptions: TextNormalizationOptions
    let structureOptions: StructureDetectionOptions
    let enhancementOptions: TextEnhancementOptions
    let validationOptions: ValidationOptions
    let formattingOptions: FormattingOptions
    
    static let `default` = ProcessingOptions(
        customStages: nil,
        validateIntermediateResults: false,
        terminateOnValidationFailure: false,
        cleaningOptions: TextCleaningOptions.default,
        normalizationOptions: TextNormalizationOptions.default,
        structureOptions: StructureDetectionOptions.default,
        enhancementOptions: TextEnhancementOptions.default,
        validationOptions: ValidationOptions.default,
        formattingOptions: FormattingOptions.default
    )
}

/// Processing context passed between stages
struct ProcessingContext {
    let document: PDFDocument
    let options: ProcessingOptions
    let startTime: Date
}

/// Result of pipeline processing
struct ProcessingResult {
    let processedText: String
    let metadata: ProcessingMetadata
    let stageResults: [PipelineStage: StageResult]
    let success: Bool
}

/// Result of individual stage processing
struct StageResult {
    let stage: PipelineStage
    let input: String
    let output: String
    var processingTime: TimeInterval
    let metrics: StageMetrics
    let shouldTerminate: Bool
    let terminationReason: String?
}

/// Metrics for individual stage processing
struct StageMetrics {
    let transformationsApplied: Int
    let qualityImprovement: Double
    let charactersRemoved: Int?
    let charactersChanged: Int?
    let structuresDetected: Int?
    let enhancementsApplied: Int?
    let validationScore: Double?
    let issuesFound: Int?
    let formattingChanges: Int?
    
    init(
        transformationsApplied: Int = 0,
        qualityImprovement: Double = 0.0,
        charactersRemoved: Int? = nil,
        charactersChanged: Int? = nil,
        structuresDetected: Int? = nil,
        enhancementsApplied: Int? = nil,
        validationScore: Double? = nil,
        issuesFound: Int? = nil,
        formattingChanges: Int? = nil
    ) {
        self.transformationsApplied = transformationsApplied
        self.qualityImprovement = qualityImprovement
        self.charactersRemoved = charactersRemoved
        self.charactersChanged = charactersChanged
        self.structuresDetected = structuresDetected
        self.enhancementsApplied = enhancementsApplied
        self.validationScore = validationScore
        self.issuesFound = issuesFound
        self.formattingChanges = formattingChanges
    }
}

/// Processing metadata
struct ProcessingMetadata {
    let originalLength: Int
    var stagesExecuted: [PipelineStage]
    var processingTime: TimeInterval
    var qualityMetrics: QualityMetrics
    var finalLength: Int?
    var terminatedEarly: Bool = false
    var terminationReason: String?
    var errors: [ProcessingError] = []
    var validationWarnings: [String?] = []
}

/// Quality metrics for processed text
struct QualityMetrics {
    let overallImprovement: Double
    let totalTransformations: Int
    let lengthChangeRatio: Double
    let stageCount: Int
    
    init(
        overallImprovement: Double = 0.0,
        totalTransformations: Int = 0,
        lengthChangeRatio: Double = 1.0,
        stageCount: Int = 0
    ) {
        self.overallImprovement = overallImprovement
        self.totalTransformations = totalTransformations
        self.lengthChangeRatio = lengthChangeRatio
        self.stageCount = stageCount
    }
}

/// Pipeline progress information
struct PipelineProgress {
    let stage: PipelineStage
    let progress: Double
    let currentLength: Int
}

/// Intermediate validation result
struct IntermediateValidation {
    let isValid: Bool
    let warning: String?
}

/// Stage error handling result
struct StageErrorResult {
    let error: ProcessingError
    let shouldContinue: Bool
    let fallbackOutput: String
}

/// Processing error information
struct ProcessingError {
    let stage: PipelineStage
    let error: Error
    let timestamp: Date
}

// MARK: - Placeholder Service Protocols and Options

protocol TextCleaningService {
    func cleanText(_ text: String, options: TextCleaningOptions) async throws -> String
    func getLastTransformationCount() -> Int
}

protocol TextNormalizationService {
    func normalizeText(_ text: String, options: TextNormalizationOptions) async throws -> String
    func getLastTransformationCount() -> Int
}

protocol TextStructureDetector {
    func detectAndMarkStructure(_ text: String, options: StructureDetectionOptions) async throws -> String
    func getLastDetectedStructures() -> [DetectedStructure]
}

protocol TextEnhancementService {
    func enhanceText(_ text: String, options: TextEnhancementOptions) async throws -> String
    func getLastEnhancements() -> [TextEnhancement]
}

protocol ProcessingValidationService {
    func validateProcessedText(_ text: String, options: ValidationOptions) async throws -> ProcessingValidationResult
}

protocol TextFormattingService {
    func formatText(_ text: String, options: FormattingOptions) async throws -> String
    func getLastFormattingChanges() -> [FormattingChange]
}

// MARK: - Placeholder Options and Data Structures

struct TextCleaningOptions {
    static let `default` = TextCleaningOptions()
}

struct TextNormalizationOptions {
    static let `default` = TextNormalizationOptions()
}

struct StructureDetectionOptions {
    static let `default` = StructureDetectionOptions()
}

struct TextEnhancementOptions {
    static let `default` = TextEnhancementOptions()
}

struct ValidationOptions {
    static let `default` = ValidationOptions()
}

struct FormattingOptions {
    static let `default` = FormattingOptions()
}

struct DetectedStructure {
    let elementCount: Int
}

struct TextEnhancement {
    let changeCount: Int
}

struct ProcessingValidationResult {
    let isValid: Bool
    let score: Double
    let issues: [String]
}

struct FormattingChange {
    let changeCount: Int
}