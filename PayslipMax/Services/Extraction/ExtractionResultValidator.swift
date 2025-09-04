import Foundation
import PDFKit

/// Protocol for extraction result validation
protocol ExtractionResultValidatorProtocol {
    /// Validates extraction results for quality and completeness
    /// - Parameters:
    ///   - result: The extraction result to validate
    ///   - originalDocument: The source PDF document
    ///   - validationCriteria: Criteria to use for validation
    /// - Returns: Comprehensive validation result
    func validateExtractionResult(
        _ result: TextExtractionResult,
        from originalDocument: PDFDocument,
        using validationCriteria: ValidationCriteria
    ) async -> ValidationReport
    
    /// Performs quick validation checks for real-time feedback
    /// - Parameters:
    ///   - extractedText: The extracted text to validate
    ///   - expectedMetrics: Expected performance metrics
    /// - Returns: Quick validation result
    func performQuickValidation(
        extractedText: String,
        expectedMetrics: ExtractionMetrics?
    ) -> QuickValidationResult
    
    /// Validates extraction quality against known benchmarks
    /// - Parameters:
    ///   - result: The extraction result
    ///   - benchmarks: Quality benchmarks to compare against
    /// - Returns: Quality assessment result
    func validateQuality(
        _ result: TextExtractionResult,
        against benchmarks: QualityBenchmarks
    ) async -> QualityAssessment
}

/// Comprehensive validation service for extraction results
///
/// This service validates extraction results across multiple dimensions to ensure
/// quality, completeness, and reliability. It provides both real-time quick checks
/// and comprehensive post-extraction validation with detailed reporting.
///
/// ## Validation Dimensions:
/// 1. **Content Quality**: Text coherence, completeness, accuracy
/// 2. **Format Integrity**: Structure preservation, layout consistency
/// 3. **Performance Metrics**: Speed, memory usage, resource efficiency
/// 4. **Data Completeness**: Missing content detection, coverage analysis
/// 5. **Error Detection**: Extraction artifacts, OCR errors, formatting issues
/// 6. **Compliance**: Security requirements, data protection standards
///
/// ## Architecture:
/// The validator uses a multi-layered approach with configurable validation rules,
/// automatic quality scoring, and detailed diagnostic reporting.
class ExtractionResultValidator: ExtractionResultValidatorProtocol {
    
    // MARK: - Dependencies
    
    /// Content quality analyzer
    private let contentAnalyzer: ContentQualityAnalyzer
    
    /// Format integrity checker
    private let formatChecker: FormatIntegrityChecker
    
    /// Performance metrics validator
    private let performanceValidator: PerformanceMetricsValidator
    
    /// Completeness analyzer
    private let completenessAnalyzer: CompletenessAnalyzer
    
    /// Error detection service
    private let errorDetector: ExtractionErrorDetector
    
    /// Compliance checker
    private let complianceChecker: ComplianceChecker
    
    // MARK: - Configuration
    
    /// Default validation thresholds
    private struct ValidationThresholds {
        static let minimumTextLength = 50
        static let maximumProcessingTime: TimeInterval = 30.0
        static let minimumQualityScore = 0.7
        static let maximumMemoryUsageMB: UInt64 = 500
        static let minimumCompleteness = 0.8
    }
    
    /// Validation rule weights
    private struct ValidationWeights {
        static let contentQuality: Double = 0.3
        static let formatIntegrity: Double = 0.2
        static let performance: Double = 0.2
        static let completeness: Double = 0.2
        static let errorFrequency: Double = 0.1
    }
    
    // MARK: - Initialization
    
    /// Initializes the validation service with required analyzers
    /// - Parameters:
    ///   - contentAnalyzer: Analyzer for content quality assessment
    ///   - formatChecker: Checker for format integrity validation
    ///   - performanceValidator: Validator for performance metrics
    ///   - completenessAnalyzer: Analyzer for content completeness
    ///   - errorDetector: Service for detecting extraction errors
    ///   - complianceChecker: Checker for compliance requirements
    init(
        contentAnalyzer: ContentQualityAnalyzer,
        formatChecker: FormatIntegrityChecker,
        performanceValidator: PerformanceMetricsValidator,
        completenessAnalyzer: CompletenessAnalyzer,
        errorDetector: ExtractionErrorDetector,
        complianceChecker: ComplianceChecker
    ) {
        self.contentAnalyzer = contentAnalyzer
        self.formatChecker = formatChecker
        self.performanceValidator = performanceValidator
        self.completenessAnalyzer = completenessAnalyzer
        self.errorDetector = errorDetector
        self.complianceChecker = complianceChecker
    }
    
    // MARK: - Comprehensive Validation
    
    /// Validates extraction results for quality and completeness
    /// - Parameters:
    ///   - result: The extraction result to validate
    ///   - originalDocument: The source PDF document
    ///   - validationCriteria: Criteria to use for validation
    /// - Returns: Comprehensive validation result
    func validateExtractionResult(
        _ result: TextExtractionResult,
        from originalDocument: PDFDocument,
        using validationCriteria: ValidationCriteria = .default
    ) async -> ValidationReport {
        
        let validationStartTime = Date()
        var validationResults: [ValidationDimension: ValidationDimensionResult] = [:]
        var overallIssues: [ValidationIssue] = []
        
        // 1. Content Quality Validation
        let contentQuality = await validateContentQuality(
            text: result.text,
            originalDocument: originalDocument,
            criteria: validationCriteria.contentCriteria
        )
        validationResults[.contentQuality] = contentQuality
        overallIssues.append(contentsOf: contentQuality.issues)
        
        // 2. Format Integrity Validation
        let formatIntegrity = await validateFormatIntegrity(
            text: result.text,
            originalDocument: originalDocument,
            criteria: validationCriteria.formatCriteria
        )
        validationResults[.formatIntegrity] = formatIntegrity
        overallIssues.append(contentsOf: formatIntegrity.issues)
        
        // 3. Performance Metrics Validation
        let performanceMetrics = validatePerformanceMetrics(
            metrics: result.metrics ?? ExtractionMetrics(),
            criteria: validationCriteria.performanceCriteria
        )
        validationResults[.performance] = performanceMetrics
        overallIssues.append(contentsOf: performanceMetrics.issues)
        
        // 4. Completeness Validation
        let completeness = await validateCompleteness(
            text: result.text,
            originalDocument: originalDocument,
            criteria: validationCriteria.completenessCriteria
        )
        validationResults[.completeness] = completeness
        overallIssues.append(contentsOf: completeness.issues)
        
        // 5. Error Detection
        let errorDetection = await detectExtractionErrors(
            text: result.text,
            metrics: result.metrics ?? ExtractionMetrics(),
            criteria: validationCriteria.errorCriteria
        )
        validationResults[.errorDetection] = errorDetection
        overallIssues.append(contentsOf: errorDetection.issues)
        
        // 6. Compliance Validation
        let compliance = await validateCompliance(
            result: result,
            criteria: validationCriteria.complianceCriteria
        )
        validationResults[.compliance] = compliance
        overallIssues.append(contentsOf: compliance.issues)
        
        // Calculate overall score
        let overallScore = calculateOverallScore(from: validationResults)
        
        // Determine validation outcome
        let isValid = overallScore >= validationCriteria.minimumOverallScore
        let validationTime = Date().timeIntervalSince(validationStartTime)
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            from: validationResults,
            overallScore: overallScore
        )
        
        return ValidationReport(
            isValid: isValid,
            overallScore: overallScore,
            validationTime: validationTime,
            dimensionResults: validationResults,
            issues: overallIssues,
            recommendations: recommendations,
            summary: generateValidationSummary(
                isValid: isValid,
                score: overallScore,
                issueCount: overallIssues.count
            )
        )
    }
    
    // MARK: - Quick Validation
    
    /// Performs quick validation checks for real-time feedback
    /// - Parameters:
    ///   - extractedText: The extracted text to validate
    ///   - expectedMetrics: Expected performance metrics
    /// - Returns: Quick validation result
    func performQuickValidation(
        extractedText: String,
        expectedMetrics: ExtractionMetrics? = nil
    ) -> QuickValidationResult {
        
        var issues: [QuickValidationIssue] = []
        var warnings: [String] = []
        
        // Check text length
        if extractedText.count < ValidationThresholds.minimumTextLength {
            issues.append(.insufficientContent(extractedText.count))
        }
        
        // Check for empty text
        if extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.emptyContent)
        }
        
        // Check for obvious extraction artifacts
        let artifactRatio = calculateArtifactRatio(in: extractedText)
        if artifactRatio > 0.1 {
            warnings.append("High artifact ratio detected (\(Int(artifactRatio * 100))%)")
        }
        
        // Check expected metrics if provided
        if let metrics = expectedMetrics {
            if metrics.executionTime > ValidationThresholds.maximumProcessingTime {
                warnings.append("Processing time exceeded expected threshold")
            }
            
            if metrics.peakMemoryUsage > ValidationThresholds.maximumMemoryUsageMB {
                warnings.append("Memory usage exceeded threshold")
            }
        }
        
        // Calculate quick score
        let quickScore = calculateQuickScore(
            textLength: extractedText.count,
            artifactRatio: artifactRatio,
            issueCount: issues.count
        )
        
        return QuickValidationResult(
            isValid: issues.isEmpty,
            quickScore: quickScore,
            issues: issues,
            warnings: warnings,
            textLength: extractedText.count,
            artifactRatio: artifactRatio
        )
    }
    
    // MARK: - Quality Validation
    
    /// Validates extraction quality against known benchmarks
    /// - Parameters:
    ///   - result: The extraction result
    ///   - benchmarks: Quality benchmarks to compare against
    /// - Returns: Quality assessment result
    func validateQuality(
        _ result: TextExtractionResult,
        against benchmarks: QualityBenchmarks
    ) async -> QualityAssessment {
        
        // Analyze text quality metrics
        let qualityMetrics = await analyzeQualityMetrics(text: result.text)
        
        // Compare against benchmarks
        let benchmarkComparisons = compareToBenchmarks(
            metrics: qualityMetrics,
            benchmarks: benchmarks
        )
        
        // Calculate quality scores
        let accuracyScore = calculateAccuracyScore(
            metrics: qualityMetrics,
            benchmarks: benchmarks
        )
        
        let completenessScore = calculateCompletenessScore(
            textLength: result.text.count,
            expectedLength: benchmarks.expectedTextLength
        )
        
        let consistencyScore = calculateConsistencyScore(
            metrics: qualityMetrics,
            benchmarks: benchmarks
        )
        
        // Overall quality assessment
        let overallQuality = (accuracyScore + completenessScore + consistencyScore) / 3.0
        
        return QualityAssessment(
            overallQuality: overallQuality,
            accuracyScore: accuracyScore,
            completenessScore: completenessScore,
            consistencyScore: consistencyScore,
            qualityMetrics: qualityMetrics,
            benchmarkComparisons: benchmarkComparisons,
            meetsStandards: overallQuality >= benchmarks.minimumQualityThreshold
        )
    }
    
    // MARK: - Private Validation Methods
    
    /// Validates content quality
    /// - Parameters:
    ///   - text: Extracted text
    ///   - originalDocument: Source document
    ///   - criteria: Content validation criteria
    /// - Returns: Content quality validation result
    private func validateContentQuality(
        text: String,
        originalDocument: PDFDocument,
        criteria: ContentValidationCriteria
    ) async -> ValidationDimensionResult {
        
        let analysis = await contentAnalyzer.analyzeContent(
            text: text,
            originalDocument: originalDocument
        )
        
        var issues: [ValidationIssue] = []
        
        // Check readability
        if analysis.readabilityScore < criteria.minimumReadability {
            issues.append(.contentQuality(.lowReadability(analysis.readabilityScore)))
        }
        
        // Check coherence
        if analysis.coherenceScore < criteria.minimumCoherence {
            issues.append(.contentQuality(.lowCoherence(analysis.coherenceScore)))
        }
        
        // Check language detection confidence
        if analysis.languageConfidence < criteria.minimumLanguageConfidence {
            issues.append(.contentQuality(.uncertainLanguage(analysis.languageConfidence)))
        }
        
        let score = (analysis.readabilityScore + analysis.coherenceScore + analysis.languageConfidence) / 3.0
        
        return ValidationDimensionResult(
            dimension: .contentQuality,
            score: score,
            issues: issues,
            details: analysis.detailedResults
        )
    }
    
    /// Validates format integrity
    /// - Parameters:
    ///   - text: Extracted text
    ///   - originalDocument: Source document
    ///   - criteria: Format validation criteria
    /// - Returns: Format integrity validation result
    private func validateFormatIntegrity(
        text: String,
        originalDocument: PDFDocument,
        criteria: FormatValidationCriteria
    ) async -> ValidationDimensionResult {
        
        let formatAnalysis = await formatChecker.checkFormat(
            text: text,
            originalDocument: originalDocument
        )
        
        var issues: [ValidationIssue] = []
        
        // Check structure preservation
        if formatAnalysis.structurePreservationScore < criteria.minimumStructurePreservation {
            issues.append(.formatIntegrity(.poorStructurePreservation(formatAnalysis.structurePreservationScore)))
        }
        
        // Check table integrity
        if formatAnalysis.tableIntegrityScore < criteria.minimumTableIntegrity {
            issues.append(.formatIntegrity(.tableFormatLoss(formatAnalysis.tableIntegrityScore)))
        }
        
        // Check layout consistency
        if formatAnalysis.layoutConsistencyScore < criteria.minimumLayoutConsistency {
            issues.append(.formatIntegrity(.layoutInconsistency(formatAnalysis.layoutConsistencyScore)))
        }
        
        let score = (formatAnalysis.structurePreservationScore + 
                    formatAnalysis.tableIntegrityScore + 
                    formatAnalysis.layoutConsistencyScore) / 3.0
        
        return ValidationDimensionResult(
            dimension: .formatIntegrity,
            score: score,
            issues: issues,
            details: formatAnalysis.detailedResults
        )
    }
    
    /// Validates performance metrics
    /// - Parameters:
    ///   - metrics: Extraction performance metrics
    ///   - criteria: Performance validation criteria
    /// - Returns: Performance validation result
    private func validatePerformanceMetrics(
        metrics: ExtractionMetrics,
        criteria: PerformanceValidationCriteria
    ) -> ValidationDimensionResult {
        
        let performanceAnalysis = performanceValidator.validateMetrics(
            metrics: metrics,
            criteria: criteria
        )
        
        var issues: [ValidationIssue] = []
        
        // Check execution time
        if metrics.executionTime > criteria.maximumExecutionTime {
            issues.append(.performance(.excessiveExecutionTime(metrics.executionTime)))
        }
        
        // Check memory usage
        if metrics.peakMemoryUsage > criteria.maximumMemoryUsage {
            issues.append(.performance(.excessiveMemoryUsage(metrics.peakMemoryUsage)))
        }
        
        // Check extraction rate
        let extractionRate = Double(metrics.charactersExtracted) / metrics.executionTime
        if extractionRate < criteria.minimumExtractionRate {
            issues.append(.performance(.lowExtractionRate(extractionRate)))
        }
        
        return ValidationDimensionResult(
            dimension: .performance,
            score: performanceAnalysis.overallScore,
            issues: issues,
            details: performanceAnalysis.detailedMetrics
        )
    }
    
    /// Validates content completeness
    /// - Parameters:
    ///   - text: Extracted text
    ///   - originalDocument: Source document
    ///   - criteria: Completeness validation criteria
    /// - Returns: Completeness validation result
    private func validateCompleteness(
        text: String,
        originalDocument: PDFDocument,
        criteria: CompletenessValidationCriteria
    ) async -> ValidationDimensionResult {
        
        let completenessAnalysis = await completenessAnalyzer.analyzeCompleteness(
            extractedText: text,
            originalDocument: originalDocument
        )
        
        var issues: [ValidationIssue] = []
        
        // Check overall completeness
        if completenessAnalysis.overallCompleteness < criteria.minimumCompleteness {
            issues.append(.completeness(.insufficientCompleteness(completenessAnalysis.overallCompleteness)))
        }
        
        // Check missing content indicators
        if !completenessAnalysis.missingContentIndicators.isEmpty {
            issues.append(.completeness(.missingContent(completenessAnalysis.missingContentIndicators)))
        }
        
        return ValidationDimensionResult(
            dimension: .completeness,
            score: completenessAnalysis.overallCompleteness,
            issues: issues,
            details: completenessAnalysis.detailedAnalysis
        )
    }
    
    /// Detects extraction errors
    /// - Parameters:
    ///   - text: Extracted text
    ///   - metrics: Extraction metrics
    ///   - criteria: Error detection criteria
    /// - Returns: Error detection result
    private func detectExtractionErrors(
        text: String,
        metrics: ExtractionMetrics,
        criteria: ErrorDetectionCriteria
    ) async -> ValidationDimensionResult {
        
        let errorAnalysis = await errorDetector.detectErrors(
            in: text,
            with: metrics
        )
        
        var issues: [ValidationIssue] = []
        
        // Check OCR errors
        if errorAnalysis.ocrErrorRate > criteria.maximumOCRErrorRate {
            issues.append(.errorDetection(.highOCRErrorRate(errorAnalysis.ocrErrorRate)))
        }
        
        // Check formatting errors
        if errorAnalysis.formattingErrorCount > criteria.maximumFormattingErrors {
            issues.append(.errorDetection(.excessiveFormattingErrors(errorAnalysis.formattingErrorCount)))
        }
        
        // Check extraction artifacts
        if errorAnalysis.artifactCount > criteria.maximumArtifacts {
            issues.append(.errorDetection(.excessiveArtifacts(errorAnalysis.artifactCount)))
        }
        
        let errorScore = 1.0 - (errorAnalysis.ocrErrorRate + 
                               Double(errorAnalysis.formattingErrorCount) / 100.0 + 
                               Double(errorAnalysis.artifactCount) / 100.0) / 3.0
        
        return ValidationDimensionResult(
            dimension: .errorDetection,
            score: max(0.0, errorScore),
            issues: issues,
            details: errorAnalysis.detailedResults
        )
    }
    
    /// Validates compliance requirements
    /// - Parameters:
    ///   - result: Extraction result
    ///   - criteria: Compliance validation criteria
    /// - Returns: Compliance validation result
    private func validateCompliance(
        result: TextExtractionResult,
        criteria: ComplianceValidationCriteria
    ) async -> ValidationDimensionResult {
        
        let complianceAnalysis = await complianceChecker.checkCompliance(
            extractionResult: result,
            criteria: criteria
        )
        
        var issues: [ValidationIssue] = []
        
        // Check data protection compliance
        if !complianceAnalysis.dataProtectionCompliant {
            issues.append(.compliance(.dataProtectionViolation))
        }
        
        // Check security requirements
        if !complianceAnalysis.securityRequirementsMet {
            issues.append(.compliance(.securityRequirementsNotMet))
        }
        
        let complianceScore = complianceAnalysis.overallComplianceScore
        
        return ValidationDimensionResult(
            dimension: .compliance,
            score: complianceScore,
            issues: issues,
            details: complianceAnalysis.detailedReport
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculates overall validation score
    /// - Parameter results: Validation results by dimension
    /// - Returns: Weighted overall score
    private func calculateOverallScore(from results: [ValidationDimension: ValidationDimensionResult]) -> Double {
        var weightedScore = 0.0
        
        if let contentResult = results[.contentQuality] {
            weightedScore += contentResult.score * ValidationWeights.contentQuality
        }
        
        if let formatResult = results[.formatIntegrity] {
            weightedScore += formatResult.score * ValidationWeights.formatIntegrity
        }
        
        if let performanceResult = results[.performance] {
            weightedScore += performanceResult.score * ValidationWeights.performance
        }
        
        if let completenessResult = results[.completeness] {
            weightedScore += completenessResult.score * ValidationWeights.completeness
        }
        
        if let errorResult = results[.errorDetection] {
            weightedScore += errorResult.score * ValidationWeights.errorFrequency
        }
        
        return min(1.0, max(0.0, weightedScore))
    }
    
    /// Calculates artifact ratio in text
    /// - Parameter text: Text to analyze
    /// - Returns: Ratio of artifacts to total content
    private func calculateArtifactRatio(in text: String) -> Double {
        let totalCharacters = text.count
        guard totalCharacters > 0 else { return 0.0 }
        
        // Simple artifact detection - could be more sophisticated
        let artifactPatterns = ["�", "□", "▢", "◇", "○"]
        let artifactCount = artifactPatterns.reduce(0) { count, pattern in
            count + text.components(separatedBy: pattern).count - 1
        }
        
        return Double(artifactCount) / Double(totalCharacters)
    }
    
    /// Calculates quick validation score
    /// - Parameters:
    ///   - textLength: Length of extracted text
    ///   - artifactRatio: Ratio of artifacts in text
    ///   - issueCount: Number of validation issues
    /// - Returns: Quick validation score
    private func calculateQuickScore(textLength: Int, artifactRatio: Double, issueCount: Int) -> Double {
        let lengthScore = min(1.0, Double(textLength) / 1000.0) // Normalize to 1000 chars
        let artifactScore = 1.0 - artifactRatio
        let issueScore = max(0.0, 1.0 - Double(issueCount) * 0.2)
        
        return (lengthScore + artifactScore + issueScore) / 3.0
    }
    
    /// Analyzes quality metrics for text
    /// - Parameter text: Text to analyze
    /// - Returns: Quality metrics
    private func analyzeQualityMetrics(text: String) async -> TextQualityMetrics {
        // This would be implemented with actual quality analysis
        return TextQualityMetrics(
            readability: 0.75,
            coherence: 0.80,
            accuracy: 0.85,
            completeness: 0.90
        )
    }
    
    /// Compares metrics to benchmarks
    /// - Parameters:
    ///   - metrics: Quality metrics
    ///   - benchmarks: Quality benchmarks
    /// - Returns: Benchmark comparisons
    private func compareToBenchmarks(
        metrics: TextQualityMetrics,
        benchmarks: QualityBenchmarks
    ) -> [BenchmarkComparison] {
        return [
            BenchmarkComparison(
                metric: "readability",
                actual: metrics.readability,
                benchmark: benchmarks.readabilityBenchmark,
                meetsBenchmark: metrics.readability >= benchmarks.readabilityBenchmark
            ),
            BenchmarkComparison(
                metric: "coherence",
                actual: metrics.coherence,
                benchmark: benchmarks.coherenceBenchmark,
                meetsBenchmark: metrics.coherence >= benchmarks.coherenceBenchmark
            )
        ]
    }
    
    /// Calculates accuracy score
    private func calculateAccuracyScore(metrics: TextQualityMetrics, benchmarks: QualityBenchmarks) -> Double {
        return metrics.accuracy
    }
    
    /// Calculates completeness score
    private func calculateCompletenessScore(textLength: Int, expectedLength: Int?) -> Double {
        guard let expected = expectedLength, expected > 0 else { return 1.0 }
        return min(1.0, Double(textLength) / Double(expected))
    }
    
    /// Calculates consistency score
    private func calculateConsistencyScore(metrics: TextQualityMetrics, benchmarks: QualityBenchmarks) -> Double {
        return metrics.coherence
    }
    
    /// Generates validation recommendations
    /// - Parameters:
    ///   - results: Validation results
    ///   - overallScore: Overall validation score
    /// - Returns: List of recommendations
    private func generateRecommendations(
        from results: [ValidationDimension: ValidationDimensionResult],
        overallScore: Double
    ) -> [ValidationRecommendation] {
        var recommendations: [ValidationRecommendation] = []
        
        // Generate recommendations based on scores and issues
        for (dimension, result) in results {
            if result.score < 0.7 {
                let recommendation = generateRecommendationFor(dimension: dimension, score: result.score)
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    /// Generates recommendation for specific dimension
    /// - Parameters:
    ///   - dimension: Validation dimension
    ///   - score: Dimension score
    /// - Returns: Validation recommendation
    private func generateRecommendationFor(dimension: ValidationDimension, score: Double) -> ValidationRecommendation {
        let priority: RecommendationPriority = score < 0.5 ? .high : .medium
        
        let description: String
        switch dimension {
        case .contentQuality:
            description = "Improve text preprocessing and OCR settings"
        case .formatIntegrity:
            description = "Enhance structure detection and layout preservation"
        case .performance:
            description = "Optimize processing parameters and resource usage"
        case .completeness:
            description = "Review extraction coverage and missing content detection"
        case .errorDetection:
            description = "Implement additional error correction and validation steps"
        case .compliance:
            description = "Review security and data protection measures"
        }
        
        return ValidationRecommendation(
            dimension: dimension,
            priority: priority,
            description: description,
            estimatedImpact: score < 0.5 ? .high : .medium
        )
    }
    
    /// Generates validation summary
    /// - Parameters:
    ///   - isValid: Whether validation passed
    ///   - score: Overall validation score
    ///   - issueCount: Number of issues found
    /// - Returns: Validation summary
    private func generateValidationSummary(isValid: Bool, score: Double, issueCount: Int) -> String {
        let status = isValid ? "PASSED" : "FAILED"
        let scorePercent = Int(score * 100)
        return "Validation \(status) - Score: \(scorePercent)%, Issues: \(issueCount)"
    }
}

// MARK: - Supporting Models and Enums

/// Validation dimensions
enum ValidationDimension: String, CaseIterable {
    case contentQuality = "contentQuality"
    case formatIntegrity = "formatIntegrity"
    case performance = "performance"
    case completeness = "completeness"
    case errorDetection = "errorDetection"
    case compliance = "compliance"
}

/// Validation criteria configuration
struct ValidationCriteria {
    let minimumOverallScore: Double
    let contentCriteria: ContentValidationCriteria
    let formatCriteria: FormatValidationCriteria
    let performanceCriteria: PerformanceValidationCriteria
    let completenessCriteria: CompletenessValidationCriteria
    let errorCriteria: ErrorDetectionCriteria
    let complianceCriteria: ComplianceValidationCriteria
    
    static let `default` = ValidationCriteria(
        minimumOverallScore: 0.7,
        contentCriteria: ContentValidationCriteria.default,
        formatCriteria: FormatValidationCriteria.default,
        performanceCriteria: PerformanceValidationCriteria.default,
        completenessCriteria: CompletenessValidationCriteria.default,
        errorCriteria: ErrorDetectionCriteria.default,
        complianceCriteria: ComplianceValidationCriteria.default
    )
}

/// Comprehensive validation report
struct ValidationReport {
    let isValid: Bool
    let overallScore: Double
    let validationTime: TimeInterval
    let dimensionResults: [ValidationDimension: ValidationDimensionResult]
    let issues: [ValidationIssue]
    let recommendations: [ValidationRecommendation]
    let summary: String
}

/// Result for individual validation dimension
struct ValidationDimensionResult {
    let dimension: ValidationDimension
    let score: Double
    let issues: [ValidationIssue]
    let details: Any
}

/// Validation issues categorized by type
enum ValidationIssue {
    case contentQuality(ContentQualityIssue)
    case formatIntegrity(FormatIntegrityIssue)
    case performance(PerformanceIssue)
    case completeness(CompletenessIssue)
    case errorDetection(ErrorDetectionIssue)
    case compliance(ComplianceIssue)
}

/// Quick validation result for real-time feedback
struct QuickValidationResult {
    let isValid: Bool
    let quickScore: Double
    let issues: [QuickValidationIssue]
    let warnings: [String]
    let textLength: Int
    let artifactRatio: Double
}

/// Quick validation issues
enum QuickValidationIssue {
    case emptyContent
    case insufficientContent(Int)
    case highArtifactRatio(Double)
    case processingTimeout
}

/// Quality assessment result
struct QualityAssessment {
    let overallQuality: Double
    let accuracyScore: Double
    let completenessScore: Double
    let consistencyScore: Double
    let qualityMetrics: TextQualityMetrics
    let benchmarkComparisons: [BenchmarkComparison]
    let meetsStandards: Bool
}

/// Quality benchmarks for comparison
struct QualityBenchmarks {
    let readabilityBenchmark: Double
    let coherenceBenchmark: Double
    let accuracyBenchmark: Double
    let completenessBenchmark: Double
    let minimumQualityThreshold: Double
    let expectedTextLength: Int?
}

/// Text quality metrics
struct TextQualityMetrics {
    let readability: Double
    let coherence: Double
    let accuracy: Double
    let completeness: Double
}

/// Benchmark comparison result
struct BenchmarkComparison {
    let metric: String
    let actual: Double
    let benchmark: Double
    let meetsBenchmark: Bool
}

/// Validation recommendation
struct ValidationRecommendation {
    let dimension: ValidationDimension
    let priority: RecommendationPriority
    let description: String
    let estimatedImpact: ImpactLevel
}

/// Recommendation priority levels
enum RecommendationPriority {
    case low, medium, high, critical
}

/// Impact level estimates
enum ImpactLevel {
    case low, medium, high
}

// MARK: - Issue Type Enums

enum ContentQualityIssue {
    case lowReadability(Double)
    case lowCoherence(Double)
    case uncertainLanguage(Double)
}

enum FormatIntegrityIssue {
    case poorStructurePreservation(Double)
    case tableFormatLoss(Double)
    case layoutInconsistency(Double)
}

enum PerformanceIssue {
    case excessiveExecutionTime(TimeInterval)
    case excessiveMemoryUsage(UInt64)
    case lowExtractionRate(Double)
}

enum CompletenessIssue {
    case insufficientCompleteness(Double)
    case missingContent([String])
}

enum ErrorDetectionIssue {
    case highOCRErrorRate(Double)
    case excessiveFormattingErrors(Int)
    case excessiveArtifacts(Int)
}

enum ComplianceIssue {
    case dataProtectionViolation
    case securityRequirementsNotMet
}

// MARK: - Criteria Structures

struct ContentValidationCriteria {
    let minimumReadability: Double
    let minimumCoherence: Double
    let minimumLanguageConfidence: Double
    
    static let `default` = ContentValidationCriteria(
        minimumReadability: 0.7,
        minimumCoherence: 0.7,
        minimumLanguageConfidence: 0.8
    )
}

struct FormatValidationCriteria {
    let minimumStructurePreservation: Double
    let minimumTableIntegrity: Double
    let minimumLayoutConsistency: Double
    
    static let `default` = FormatValidationCriteria(
        minimumStructurePreservation: 0.7,
        minimumTableIntegrity: 0.8,
        minimumLayoutConsistency: 0.7
    )
}

struct PerformanceValidationCriteria {
    let maximumExecutionTime: TimeInterval
    let maximumMemoryUsage: UInt64
    let minimumExtractionRate: Double
    
    static let `default` = PerformanceValidationCriteria(
        maximumExecutionTime: 30.0,
        maximumMemoryUsage: 500 * 1024 * 1024,
        minimumExtractionRate: 1000.0
    )
}

struct CompletenessValidationCriteria {
    let minimumCompleteness: Double
    
    static let `default` = CompletenessValidationCriteria(
        minimumCompleteness: 0.8
    )
}

struct ErrorDetectionCriteria {
    let maximumOCRErrorRate: Double
    let maximumFormattingErrors: Int
    let maximumArtifacts: Int
    
    static let `default` = ErrorDetectionCriteria(
        maximumOCRErrorRate: 0.05,
        maximumFormattingErrors: 10,
        maximumArtifacts: 5
    )
}

struct ComplianceValidationCriteria {
    let requireDataProtectionCompliance: Bool
    let requireSecurityCompliance: Bool
    
    static let `default` = ComplianceValidationCriteria(
        requireDataProtectionCompliance: true,
        requireSecurityCompliance: true
    )
}

// MARK: - Placeholder Service Protocols

protocol ContentQualityAnalyzer {
    func analyzeContent(text: String, originalDocument: PDFDocument) async -> ContentAnalysis
}

protocol FormatIntegrityChecker {
    func checkFormat(text: String, originalDocument: PDFDocument) async -> FormatAnalysis
}

protocol PerformanceMetricsValidator {
    func validateMetrics(metrics: ExtractionMetrics, criteria: PerformanceValidationCriteria) -> PerformanceAnalysis
}

protocol CompletenessAnalyzer {
    func analyzeCompleteness(extractedText: String, originalDocument: PDFDocument) async -> CompletenessAnalysis
}

protocol ExtractionErrorDetector {
    func detectErrors(in text: String, with metrics: ExtractionMetrics) async -> ErrorAnalysis
}

protocol ComplianceChecker {
    func checkCompliance(extractionResult: TextExtractionResult, criteria: ComplianceValidationCriteria) async -> ComplianceAnalysis
}

// MARK: - Analysis Result Structures

struct ContentAnalysis {
    let readabilityScore: Double
    let coherenceScore: Double
    let languageConfidence: Double
    let detailedResults: Any
}

struct FormatAnalysis {
    let structurePreservationScore: Double
    let tableIntegrityScore: Double
    let layoutConsistencyScore: Double
    let detailedResults: Any
}

struct PerformanceAnalysis {
    let overallScore: Double
    let detailedMetrics: Any
}

struct CompletenessAnalysis {
    let overallCompleteness: Double
    let missingContentIndicators: [String]
    let detailedAnalysis: Any
}

struct ErrorAnalysis {
    let ocrErrorRate: Double
    let formattingErrorCount: Int
    let artifactCount: Int
    let detailedResults: Any
}

struct ComplianceAnalysis {
    let overallComplianceScore: Double
    let dataProtectionCompliant: Bool
    let securityRequirementsMet: Bool
    let detailedReport: Any
}