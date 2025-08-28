import Foundation
import PDFKit
import SwiftData

/// Protocol for AI-enhanced multi-document processing capabilities
protocol MultiDocumentProcessorProtocol {
    /// Processes multiple payslip documents in optimized batches
    func processBatch(
        documents: [PDFDocument],
        options: BatchProcessingOptions
    ) async throws -> BatchProcessingResult

    /// Performs cross-document validation and consistency checks
    func validateCrossDocumentConsistency(
        payslips: [Payslip]
    ) async throws -> CrossDocumentValidationResult

    /// Analyzes timeline patterns across multiple payslips
    func analyzeTimelinePatterns(
        payslips: [Payslip],
        analysisPeriod: TimelineAnalysisPeriod
    ) async throws -> TimelineAnalysisResult

    /// Optimizes memory usage for large document sets
    func optimizeMemoryForBatch(
        documentCount: Int,
        availableMemory: Int
    ) -> MemoryOptimizationStrategy
}

/// Configuration options for batch processing
public struct BatchProcessingOptions {
    let maxConcurrentDocuments: Int
    let memoryLimitMB: Int
    let timeoutSeconds: TimeInterval
    let enableParallelProcessing: Bool
    let enableCaching: Bool
    let errorHandlingStrategy: BatchErrorStrategy

    public init(
        maxConcurrentDocuments: Int = 3,
        memoryLimitMB: Int = 500,
        timeoutSeconds: TimeInterval = 300,
        enableParallelProcessing: Bool = true,
        enableCaching: Bool = true,
        errorHandlingStrategy: BatchErrorStrategy = .continueOnError
    ) {
        self.maxConcurrentDocuments = maxConcurrentDocuments
        self.memoryLimitMB = memoryLimitMB
        self.timeoutSeconds = timeoutSeconds
        self.enableParallelProcessing = enableParallelProcessing
        self.enableCaching = enableCaching
        self.errorHandlingStrategy = errorHandlingStrategy
    }
}

/// Error handling strategies for batch processing
public enum BatchErrorStrategy: Equatable {
    case stopOnFirstError
    case continueOnError
    case retryFailed(maxRetries: Int)
}

/// Result of batch processing operation
public struct BatchProcessingResult {
    let processedPayslips: [Payslip]
    let failedDocuments: [BatchProcessingFailure]
    let performanceMetrics: BatchPerformanceMetrics
    let memoryUsage: MemoryUsageStats
    let processingSummary: BatchProcessingSummary
}

/// Individual batch processing failure
public struct BatchProcessingFailure {
    let documentIndex: Int
    let error: Error
    let errorType: BatchErrorType
    let retryCount: Int
    let processingTime: TimeInterval
}

/// Types of batch processing errors
public enum BatchErrorType {
    case textExtractionFailed
    case formatDetectionFailed
    case parsingFailed
    case validationFailed
    case memoryLimitExceeded
    case timeoutExceeded
    case unknown
}

/// Performance metrics for batch processing
public struct BatchPerformanceMetrics {
    let totalProcessingTime: TimeInterval
    let averageProcessingTime: TimeInterval
    let documentsPerSecond: Double
    let memoryEfficiency: Double
    let parallelizationEfficiency: Double
}

/// Memory usage statistics
public struct MemoryUsageStats {
    let peakMemoryUsage: Int // MB
    let averageMemoryUsage: Int // MB
    let memoryEfficiency: Double
    let garbageCollections: Int
}

/// Summary of batch processing results
public struct BatchProcessingSummary {
    let totalDocuments: Int
    let successfulDocuments: Int
    let failedDocuments: Int
    let skippedDocuments: Int
    let successRate: Double
    let averageConfidence: Double
}

/// Result of cross-document validation
public struct CrossDocumentValidationResult {
    let consistencyScore: Double
    let validationIssues: [CrossDocumentIssue]
    let recommendations: [String]
    let riskAssessment: ConsistencyRiskLevel
}

/// Individual cross-document validation issue
public struct CrossDocumentIssue {
    let issueType: CrossDocumentIssueType
    let severity: ConsistencyIssueSeverity
    let affectedDocuments: [String] // Document IDs
    let description: String
    let suggestedResolution: String
}

/// Types of cross-document validation issues
public enum CrossDocumentIssueType {
    case salaryInconsistency
    case allowanceDiscrepancy
    case deductionMismatch
    case timelineGap
    case formatInconsistency
    case amountProgressionAnomaly
}

/// Severity levels for consistency issues
public enum ConsistencyIssueSeverity {
    case low
    case medium
    case high
    case critical
}

/// Risk levels for consistency validation
public enum ConsistencyRiskLevel {
    case low
    case medium
    case high
    case critical
}

/// Result of timeline analysis
public struct TimelineAnalysisResult {
    let patterns: [TimelinePattern]
    let gaps: [TimelineGap]
    let anomalies: [TimelineAnomaly]
    let projections: [TimelineProjection]
    let insights: [String]
}

/// Patterns detected in timeline analysis
public struct TimelinePattern {
    let patternType: TimelinePatternType
    let frequency: TimelineFrequency
    let confidence: Double
    let description: String
    let affectedMetrics: [String]
}

/// Types of timeline patterns
public enum TimelinePatternType {
    case regularIncrement
    case seasonalVariation
    case policyChange
    case promotionRelated
    case arrearsPayment
}

/// Frequency of timeline patterns
public enum TimelineFrequency {
    case monthly
    case quarterly
    case halfYearly
    case yearly
    case irregular
}

/// Gaps identified in timeline
public struct TimelineGap {
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let gapType: TimelineGapType
    let impact: GapImpactLevel
}

/// Types of timeline gaps
public enum TimelineGapType {
    case missingPayslip
    case processingDelay
    case systemOutage
    case manualEntryGap
}

/// Impact levels for timeline gaps
public enum GapImpactLevel {
    case low
    case medium
    case high
}

/// Anomalies detected in timeline
public struct TimelineAnomaly {
    let date: Date
    let anomalyType: TimelineAnomalyType
    let severity: AnomalySeverity
    let description: String
    let potentialCauses: [String]
}

/// Types of timeline anomalies
public enum TimelineAnomalyType {
    case amountSpike
    case amountDrop
    case irregularTiming
    case formatChange
    case dataQualityIssue
}

/// Timeline projections and forecasts
public struct TimelineProjection {
    let projectionType: ProjectionType
    let timeHorizon: TimeInterval
    let predictedValues: [Date: Double]
    let confidence: Double
    let assumptions: [String]
}

/// Types of timeline projections
public enum ProjectionType {
    case salaryProgression
    case allowanceTrend
    case deductionTrend
    case netPayForecast
}

/// Time periods for timeline analysis
public enum TimelineAnalysisPeriod {
    case last3Months
    case last6Months
    case lastYear
    case last2Years
    case custom(startDate: Date, endDate: Date)
}

/// Memory optimization strategies
public struct MemoryOptimizationStrategy {
    let recommendedBatchSize: Int
    let memoryCleanupFrequency: Int // Documents processed before cleanup
    let cachingStrategy: CachingStrategy
    let parallelProcessingLimit: Int
    let memoryMonitoring: Bool
}

/// Caching strategies for memory optimization
public enum CachingStrategy {
    case noCaching
    case selectiveCaching(maxCacheSize: Int)
    case fullCaching
    case adaptiveCaching
}

/// AI-enhanced multi-document processor
@MainActor
public final class MultiDocumentProcessor: @preconcurrency MultiDocumentProcessorProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let processingPipeline: ModularPayslipProcessingPipeline
    private var processingCache: [String: Payslip] = [:]
    private var memoryMonitor: MemoryPressureMonitor?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        processingPipeline: ModularPayslipProcessingPipeline
    ) {
        self.modelContext = modelContext
        self.processingPipeline = processingPipeline
        self.memoryMonitor = MemoryPressureMonitor()
    }

    // MARK: - Batch Processing

    func processBatch(
        documents: [PDFDocument],
        options: BatchProcessingOptions
    ) async throws -> BatchProcessingResult {

        let startTime = Date()
        var processedPayslips: [Payslip] = []
        var failedDocuments: [BatchProcessingFailure] = []
        let memoryStats = MemoryUsageStats(peakMemoryUsage: 0, averageMemoryUsage: 0, memoryEfficiency: 1.0, garbageCollections: 0)

        // Optimize batch processing strategy
        let strategy = optimizeMemoryForBatch(
            documentCount: documents.count,
            availableMemory: options.memoryLimitMB
        )

        // Process documents in optimized batches
        let batches = createOptimizedBatches(
            documents: documents,
            batchSize: strategy.recommendedBatchSize
        )

        for (batchIndex, batch) in batches.enumerated() {
            let batchStartTime = Date()

            do {
                let batchResult = try await processBatchChunk(
                    documents: batch,
                    batchIndex: batchIndex,
                    options: options,
                    strategy: strategy
                )

                processedPayslips.append(contentsOf: batchResult.payslips)

                // Collect failures
                for (docIndex, error) in batchResult.failures {
                    let failure = BatchProcessingFailure(
                        documentIndex: batchIndex * strategy.recommendedBatchSize + docIndex,
                        error: error,
                        errorType: classifyError(error),
                        retryCount: 0,
                        processingTime: Date().timeIntervalSince(batchStartTime)
                    )
                    failedDocuments.append(failure)
                }

                // Memory cleanup if needed
                if batchIndex % strategy.memoryCleanupFrequency == 0 {
                    await performMemoryCleanup()
                }

            } catch {
                // Handle batch-level errors
                for (index, _) in batch.enumerated() {
                    let failure = BatchProcessingFailure(
                        documentIndex: batchIndex * strategy.recommendedBatchSize + index,
                        error: error,
                        errorType: .unknown,
                        retryCount: 0,
                        processingTime: Date().timeIntervalSince(batchStartTime)
                    )
                    failedDocuments.append(failure)
                }

                if options.errorHandlingStrategy == .stopOnFirstError {
                    break
                }
            }
        }

        let totalTime = Date().timeIntervalSince(startTime)
        let performanceMetrics = calculatePerformanceMetrics(
            totalTime: totalTime,
            documentCount: documents.count,
            successfulCount: processedPayslips.count
        )

        let summary = BatchProcessingSummary(
            totalDocuments: documents.count,
            successfulDocuments: processedPayslips.count,
            failedDocuments: failedDocuments.count,
            skippedDocuments: 0,
            successRate: Double(processedPayslips.count) / Double(documents.count),
            averageConfidence: calculateAverageConfidence(processedPayslips)
        )

        return BatchProcessingResult(
            processedPayslips: processedPayslips,
            failedDocuments: failedDocuments,
            performanceMetrics: performanceMetrics,
            memoryUsage: memoryStats,
            processingSummary: summary
        )
    }

    // MARK: - Cross-Document Validation

    func validateCrossDocumentConsistency(
        payslips: [Payslip]
    ) async throws -> CrossDocumentValidationResult {

        guard !payslips.isEmpty else {
            throw MultiDocumentError.insufficientData
        }

        let sortedPayslips = payslips.sorted { $0.timestamp < $1.timestamp }
        var validationIssues: [CrossDocumentIssue] = []

        // Validate salary progression consistency
        let salaryIssues = validateSalaryProgression(sortedPayslips)
        validationIssues.append(contentsOf: salaryIssues)

        // Validate allowance consistency
        let allowanceIssues = validateAllowanceConsistency(sortedPayslips)
        validationIssues.append(contentsOf: allowanceIssues)

        // Validate deduction consistency
        let deductionIssues = validateDeductionConsistency(sortedPayslips)
        validationIssues.append(contentsOf: deductionIssues)

        // Check for timeline gaps
        let timelineIssues = validateTimelineContinuity(sortedPayslips)
        validationIssues.append(contentsOf: timelineIssues)

        // Calculate overall consistency score
        let consistencyScore = calculateConsistencyScore(validationIssues, totalDocuments: payslips.count)
        let riskAssessment = assessConsistencyRisk(validationIssues)
        let recommendations = generateConsistencyRecommendations(validationIssues, riskAssessment)

        return CrossDocumentValidationResult(
            consistencyScore: consistencyScore,
            validationIssues: validationIssues,
            recommendations: recommendations,
            riskAssessment: riskAssessment
        )
    }

    // MARK: - Timeline Analysis

    func analyzeTimelinePatterns(
        payslips: [Payslip],
        analysisPeriod: TimelineAnalysisPeriod
    ) async throws -> TimelineAnalysisResult {

        let dateRange = calculateDateRange(for: analysisPeriod)
        let filteredPayslips = payslips.filter {
            $0.timestamp >= dateRange.start && $0.timestamp <= dateRange.end
        }.sorted { $0.timestamp < $1.timestamp }

        guard !filteredPayslips.isEmpty else {
            throw MultiDocumentError.insufficientData
        }

        // Detect recurring patterns
        let patterns = detectTimelinePatterns(filteredPayslips)

        // Identify gaps in timeline
        let gaps = identifyTimelineGaps(filteredPayslips)

        // Detect anomalies
        let anomalies = detectTimelineAnomalies(filteredPayslips)

        // Generate projections
        let projections = generateTimelineProjections(filteredPayslips)

        // Generate insights
        let insights = generateTimelineInsights(patterns, gaps, anomalies, projections)

        return TimelineAnalysisResult(
            patterns: patterns,
            gaps: gaps,
            anomalies: anomalies,
            projections: projections,
            insights: insights
        )
    }

    // MARK: - Memory Optimization

    public func optimizeMemoryForBatch(
        documentCount: Int,
        availableMemory: Int
    ) -> MemoryOptimizationStrategy {

        // Base memory requirements per document (MB)
        let baseMemoryPerDocument = 50

        // Calculate optimal batch size
        let maxBatchSizeByMemory = availableMemory / baseMemoryPerDocument
        let recommendedBatchSize = min(maxBatchSizeByMemory, 10) // Cap at 10 for performance

        // Determine caching strategy
        let cachingStrategy: CachingStrategy
        if availableMemory < 200 {
            cachingStrategy = .noCaching
        } else if availableMemory < 500 {
            cachingStrategy = .selectiveCaching(maxCacheSize: availableMemory / 10)
        } else {
            cachingStrategy = .adaptiveCaching
        }

        // Memory cleanup frequency
        let memoryCleanupFrequency = max(1, recommendedBatchSize / 2)

        // Parallel processing limit
        let parallelProcessingLimit = min(recommendedBatchSize, 5)

        return MemoryOptimizationStrategy(
            recommendedBatchSize: recommendedBatchSize,
            memoryCleanupFrequency: memoryCleanupFrequency,
            cachingStrategy: cachingStrategy,
            parallelProcessingLimit: parallelProcessingLimit,
            memoryMonitoring: availableMemory < 1000 // Enable monitoring for low memory
        )
    }

    // MARK: - Private Helper Methods

    private func createOptimizedBatches(
        documents: [PDFDocument],
        batchSize: Int
    ) -> [[PDFDocument]] {

        var batches: [[PDFDocument]] = []
        var currentBatch: [PDFDocument] = []

        for document in documents {
            currentBatch.append(document)

            if currentBatch.count >= batchSize {
                batches.append(currentBatch)
                currentBatch = []
            }
        }

        if !currentBatch.isEmpty {
            batches.append(currentBatch)
        }

        return batches
    }

    private func processBatchChunk(
        documents: [PDFDocument],
        batchIndex: Int,
        options: BatchProcessingOptions,
        strategy: MemoryOptimizationStrategy
    ) async throws -> (payslips: [Payslip], failures: [(Int, Error)]) {

        var payslips: [Payslip] = []
        var failures: [(Int, Error)] = []

        // Process documents sequentially to avoid Sendable issues
        for (index, document) in documents.enumerated() {
            do {
                let payslip = try await processSingleDocument(document)
                payslips.append(payslip)

                // Cache if enabled
                if options.enableCaching {
                    let cacheKey = "batch_\(batchIndex)_doc_\(index)"
                    processingCache[cacheKey] = payslip
                }
            } catch {
                failures.append((index, error))
            }
        }

        return (payslips, failures)
    }

    private func processSingleDocument(_ document: PDFDocument) async throws -> Payslip {
        // Convert PDF to data for processing
        guard let pdfData = document.dataRepresentation() else {
            throw MultiDocumentError.invalidDocument
        }

        // Use existing processing pipeline
        let result = await processingPipeline.executePipeline(pdfData)
        let payslipItem = try result.get()

        // Convert to Payslip model
        return try convertPayslipItemToPayslip(payslipItem)
    }

    private func convertPayslipItemToPayslip(_ item: PayslipItem) throws -> Payslip {
        // Convert PayslipItem properties to Payslip format
        // PayslipItem has different property structure than Payslip
        
        // Extract rank and service number from metadata if available
        let rank = item.metadata["rank"] ?? ""
        let serviceNumber = item.metadata["serviceNumber"] ?? ""
        
        // Calculate basic pay from earnings
        let basicPay = item.earnings["BASIC PAY"] ?? item.earnings["Basic Pay"] ?? 0.0
        
        // Convert earnings dictionary to Allowance objects
        let allowances = item.earnings.compactMap { (key, value) -> Allowance? in
            guard key != "BASIC PAY" && key != "Basic Pay" else { return nil }
            return Allowance(name: key, amount: value, category: "Allowance")
        }
        
        // Convert deductions dictionary to Deduction objects  
        let deductions = item.deductions.map { (key, value) in
            Deduction(name: key, amount: value, category: "Deduction")
        }
        
        // Calculate net pay
        let netPay = item.credits - item.debits
        
        return Payslip(
            timestamp: item.timestamp,
            rank: rank,
            serviceNumber: serviceNumber,
            basicPay: basicPay,
            allowances: allowances,
            deductions: deductions,
            netPay: netPay
        )
    }

    private func performMemoryCleanup() async {
        // Clear processing cache periodically
        processingCache.removeAll()

        // Force garbage collection if available
        // Note: This is a hint to the system, not guaranteed
        #if canImport(Darwin)
        autoreleasepool {}
        #endif
    }

    private func classifyError(_ error: Error) -> BatchErrorType {
        // Classify errors for better reporting
        if error.localizedDescription.contains("text extraction") {
            return .textExtractionFailed
        } else if error.localizedDescription.contains("format") {
            return .formatDetectionFailed
        } else if error.localizedDescription.contains("parsing") {
            return .parsingFailed
        } else if error.localizedDescription.contains("validation") {
            return .validationFailed
        } else if error.localizedDescription.contains("memory") {
            return .memoryLimitExceeded
        } else {
            return .unknown
        }
    }

    private func calculatePerformanceMetrics(
        totalTime: TimeInterval,
        documentCount: Int,
        successfulCount: Int
    ) -> BatchPerformanceMetrics {

        let averageProcessingTime = documentCount > 0 ? totalTime / Double(documentCount) : 0
        let documentsPerSecond = totalTime > 0 ? Double(successfulCount) / totalTime : 0

        return BatchPerformanceMetrics(
            totalProcessingTime: totalTime,
            averageProcessingTime: averageProcessingTime,
            documentsPerSecond: documentsPerSecond,
            memoryEfficiency: 0.85, // Placeholder - would calculate actual efficiency
            parallelizationEfficiency: 0.9 // Placeholder - would measure actual parallelization
        )
    }

    private func calculateAverageConfidence(_ payslips: [Payslip]) -> Double {
        // Placeholder - would calculate actual confidence scores
        return 0.85
    }

    private func validateSalaryProgression(_ payslips: [Payslip]) -> [CrossDocumentIssue] {
        var issues: [CrossDocumentIssue] = []

        for i in 1..<payslips.count {
            let current = payslips[i].basicPay
            let previous = payslips[i-1].basicPay
            let change = (current - previous) / previous

            // Flag unusual changes (>50% or <-20%)
            if change > 0.5 || change < -0.2 {
                let severity: ConsistencyIssueSeverity = abs(change) > 1.0 ? .critical : .high

                issues.append(CrossDocumentIssue(
                    issueType: .salaryInconsistency,
                    severity: severity,
                    affectedDocuments: [payslips[i-1].id.uuidString, payslips[i].id.uuidString],
                    description: "Unusual salary change of \(String(format: "%.1f", change * 100))%",
                    suggestedResolution: "Verify with issuing authority for promotions, increments, or corrections"
                ))
            }
        }

        return issues
    }

    private func validateAllowanceConsistency(_ payslips: [Payslip]) -> [CrossDocumentIssue] {
        // Implementation for allowance consistency validation
        return []
    }

    private func validateDeductionConsistency(_ payslips: [Payslip]) -> [CrossDocumentIssue] {
        // Implementation for deduction consistency validation
        return []
    }

    private func validateTimelineContinuity(_ payslips: [Payslip]) -> [CrossDocumentIssue] {
        var issues: [CrossDocumentIssue] = []

        for i in 1..<payslips.count {
            let current = payslips[i].timestamp
            let previous = payslips[i-1].timestamp

            // Check for gaps longer than 2 months
            let gap = current.timeIntervalSince(previous)
            if gap > (60 * 24 * 3600) { // 60 days
                issues.append(CrossDocumentIssue(
                    issueType: .timelineGap,
                    severity: .medium,
                    affectedDocuments: [payslips[i-1].id.uuidString, payslips[i].id.uuidString],
                    description: "Gap of \(Int(gap / (24 * 3600))) days between payslips",
                    suggestedResolution: "Request missing payslips from issuing authority"
                ))
            }
        }

        return issues
    }

    private func calculateConsistencyScore(_ issues: [CrossDocumentIssue], totalDocuments: Int) -> Double {
        let totalPossibleIssues = totalDocuments * 3 // Estimate of possible issues
        let issueScore = Double(issues.count) / Double(totalPossibleIssues)

        return max(0, 1.0 - issueScore)
    }

    private func assessConsistencyRisk(_ issues: [CrossDocumentIssue]) -> ConsistencyRiskLevel {
        let criticalCount = issues.filter { $0.severity == .critical }.count
        let highCount = issues.filter { $0.severity == .high }.count

        if criticalCount > 0 {
            return .critical
        } else if highCount > 2 {
            return .high
        } else if highCount > 0 || issues.count > 5 {
            return .medium
        } else {
            return .low
        }
    }

    private func generateConsistencyRecommendations(
        _ issues: [CrossDocumentIssue],
        _ risk: ConsistencyRiskLevel
    ) -> [String] {

        var recommendations: [String] = []

        if risk == .critical {
            recommendations.append("URGENT: Address critical consistency issues before processing payments")
        }

        if issues.contains(where: { $0.issueType == .timelineGap }) {
            recommendations.append("Request missing payslips to ensure complete financial record")
        }

        if issues.contains(where: { $0.issueType == .salaryInconsistency }) {
            recommendations.append("Verify unusual salary changes with HR or issuing authority")
        }

        return recommendations
    }

    private func calculateDateRange(for period: TimelineAnalysisPeriod) -> (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current

        switch period {
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return (start, now)
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            return (start, now)
        case .lastYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        case .last2Years:
            let start = calendar.date(byAdding: .year, value: -2, to: now) ?? now
            return (start, now)
        case .custom(let startDate, let endDate):
            return (startDate, endDate)
        }
    }

    private func detectTimelinePatterns(_ payslips: [Payslip]) -> [TimelinePattern] {
        var patterns: [TimelinePattern] = []

        // Detect regular increment patterns
        if detectRegularIncrements(payslips) {
            patterns.append(TimelinePattern(
                patternType: .regularIncrement,
                frequency: .yearly,
                confidence: 0.8,
                description: "Regular annual salary increments detected",
                affectedMetrics: ["Basic Pay"]
            ))
        }

        // Detect seasonal variations (bonuses, arrears)
        if detectSeasonalVariations(payslips) {
            patterns.append(TimelinePattern(
                patternType: .seasonalVariation,
                frequency: .yearly,
                confidence: 0.7,
                description: "Seasonal payment variations detected",
                affectedMetrics: ["Total Credits", "Net Pay"]
            ))
        }

        return patterns
    }

    private func detectRegularIncrements(_ payslips: [Payslip]) -> Bool {
        guard payslips.count >= 12 else { return false }

        // Check for consistent yearly increments
        let yearlyPayslips = payslips.filter { Calendar.current.component(.month, from: $0.timestamp) == 1 }
        guard yearlyPayslips.count >= 2 else { return false }

        var incrementCount = 0
        for i in 1..<yearlyPayslips.count {
            if yearlyPayslips[i].basicPay > yearlyPayslips[i-1].basicPay {
                incrementCount += 1
            }
        }

        return Double(incrementCount) / Double(yearlyPayslips.count - 1) > 0.7 // 70% show increments
    }

    private func detectSeasonalVariations(_ payslips: [Payslip]) -> Bool {
        guard payslips.count >= 12 else { return false }

        // Check for March/April spikes (typical bonus period)
        let marchAprilPayslips = payslips.filter {
            let month = Calendar.current.component(.month, from: $0.timestamp)
            return month == 3 || month == 4
        }

        if marchAprilPayslips.isEmpty { return false }

        let averageMarchApril = marchAprilPayslips.map { $0.netPay }.reduce(0, +) / Double(marchAprilPayslips.count)
        let averageOther = payslips.filter {
            let month = Calendar.current.component(.month, from: $0.timestamp)
            return month != 3 && month != 4
        }.map { $0.netPay }.reduce(0, +) / Double(payslips.count - marchAprilPayslips.count)

        return averageMarchApril > averageOther * 1.3 // 30% higher than normal
    }

    private func identifyTimelineGaps(_ payslips: [Payslip]) -> [TimelineGap] {
        var gaps: [TimelineGap] = []

        for i in 1..<payslips.count {
            let current = payslips[i].timestamp
            let previous = payslips[i-1].timestamp
            let gapDuration = current.timeIntervalSince(previous)

            // Identify gaps longer than 35 days (allowing for monthly variations)
            if gapDuration > (35 * 24 * 3600) {
                gaps.append(TimelineGap(
                    startDate: previous,
                    endDate: current,
                    duration: gapDuration,
                    gapType: .missingPayslip,
                    impact: gapDuration > (60 * 24 * 3600) ? .high : .medium
                ))
            }
        }

        return gaps
    }

    private func detectTimelineAnomalies(_ payslips: [Payslip]) -> [TimelineAnomaly] {
        var anomalies: [TimelineAnomaly] = []

        for payslip in payslips {
            // Check for unusual amount spikes
            let totalCredits = payslip.basicPay + payslip.allowances.reduce(0) { $0 + $1.amount }

            // This would compare against historical averages
            // For now, just checking for extremely high amounts
            if totalCredits > 200_000 { // 2 lakhs threshold
                anomalies.append(TimelineAnomaly(
                    date: payslip.timestamp,
                    anomalyType: .amountSpike,
                    severity: .moderate,
                    description: "Unusually high total credits detected",
                    potentialCauses: ["Arrears payment", "Bonus", "One-time adjustment"]
                ))
            }
        }

        return anomalies
    }

    private func generateTimelineProjections(_ payslips: [Payslip]) -> [TimelineProjection] {
        var projections: [TimelineProjection] = []

        // Generate salary progression projection
        if let salaryProjection = generateSalaryProjection(payslips) {
            projections.append(salaryProjection)
        }

        return projections
    }

    private func generateSalaryProjection(_ payslips: [Payslip]) -> TimelineProjection? {
        guard payslips.count >= 6 else { return nil }

        // Simple linear projection based on recent trend
        let recentPayslips = Array(payslips.suffix(6))
        let growthRate = calculateGrowthRate(recentPayslips.map { ($0.timestamp, $0.basicPay) })

        let projectionMonths = 12
        var predictedValues: [Date: Double] = [:]
        let calendar = Calendar.current

        if let lastPayslip = recentPayslips.last {
            let lastAmount = lastPayslip.basicPay

            for month in 1...projectionMonths {
                if let futureDate = calendar.date(byAdding: .month, value: month, to: lastPayslip.timestamp) {
                    let predictedAmount = lastAmount * pow(1 + growthRate, Double(month) / 12.0)
                    predictedValues[futureDate] = predictedAmount
                }
            }
        }

        return TimelineProjection(
            projectionType: .salaryProgression,
            timeHorizon: Double(projectionMonths) * 30 * 24 * 3600, // Approximate months in seconds
            predictedValues: predictedValues,
            confidence: 0.75,
            assumptions: ["Current growth rate continues", "No policy changes", "Regular increments"]
        )
    }

    private func calculateGrowthRate(_ data: [(Date, Double)]) -> Double {
        guard data.count >= 2 else { return 0 }

        var totalGrowth = 0.0
        var validComparisons = 0

        for i in 1..<data.count {
            let (_, current) = data[i]
            let (_, previous) = data[i - 1]

            if previous > 0 {
                let growth = (current - previous) / previous
                totalGrowth += growth
                validComparisons += 1
            }
        }

        return validComparisons > 0 ? totalGrowth / Double(validComparisons) : 0
    }

    private func generateTimelineInsights(
        _ patterns: [TimelinePattern],
        _ gaps: [TimelineGap],
        _ anomalies: [TimelineAnomaly],
        _ projections: [TimelineProjection]
    ) -> [String] {

        var insights: [String] = []

        if !patterns.isEmpty {
            insights.append("Detected \(patterns.count) recurring patterns in your payslip timeline")
        }

        if !gaps.isEmpty {
            insights.append("Found \(gaps.count) gaps in payslip records - consider requesting missing documents")
        }

        if !anomalies.isEmpty {
            insights.append("Identified \(anomalies.count) unusual payments - review for accuracy")
        }

        if !projections.isEmpty {
            insights.append("Generated salary projections based on historical trends")
        }

        return insights
    }
}

/// Errors that can occur during multi-document processing
public enum MultiDocumentError: Error {
    case insufficientData
    case invalidDocument
    case processingFailed
    case memoryLimitExceeded
    case batchProcessingError
}
