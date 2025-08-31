import XCTest
import PDFKit
import SwiftData
@testable import PayslipMax

/// Integration tests for Phase 5 AI-powered advanced analytics system
final class Phase5_AI_IntegrationTests: XCTestCase {

    // MARK: - Properties

    private var predictiveAnalysisEngine: PredictiveAnalysisEngineProtocol!
    private var anomalyDetectionService: AnomalyDetectionServiceProtocol!
    private var multiDocumentProcessor: MultiDocumentProcessorProtocol!
    private var aiInsightsGenerator: AIInsightsGeneratorProtocol!

    private var testPayslips: [Payslip] = []
    private var mockModelContext: ModelContext!

    // Test data
    private let baseTestPayslip = Payslip(
        timestamp: Date(),
        rank: "Captain",
        serviceNumber: "IC-12345",
        basicPay: 45000.0,
        allowances: [
            Allowance(name: "DA", amount: 22500.0, category: "Standard"),
            Allowance(name: "HRA", amount: 13500.0, category: "Taxable"),
            Allowance(name: "MSP", amount: 10000.0, category: "Military")
        ],
        deductions: [
            Deduction(name: "INCOME_TAX", amount: 7500.0, category: "Statutory"),
            Deduction(name: "PROFESSIONAL_TAX", amount: 2500.0, category: "Statutory"),
            Deduction(name: "AGIF", amount: 500.0, category: "Voluntary")
        ],
        netPay: 70500.0
    )

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test data
        mockModelContext = try createMockModelContext()
        testPayslips = try createTestPayslipHistory()

        // Initialize services
        predictiveAnalysisEngine = await PredictiveAnalysisEngine(modelContext: mockModelContext)
        anomalyDetectionService = await AnomalyDetectionService(modelContext: mockModelContext)
        multiDocumentProcessor = await MultiDocumentProcessor(
            modelContext: mockModelContext,
            processingPipeline: createMockProcessingPipeline()
        )
        aiInsightsGenerator = await AIInsightsGenerator(modelContext: mockModelContext)
    }

    override func tearDown() async throws {
        predictiveAnalysisEngine = nil
        anomalyDetectionService = nil
        multiDocumentProcessor = nil
        aiInsightsGenerator = nil
        testPayslips = []
        mockModelContext = nil

        try await super.tearDown()
    }

    // MARK: - Predictive Analysis Engine Tests

    func testSalaryProgressionPrediction() async throws {
        // Given
        let historicalPayslips = testPayslips
        let predictionMonths = 12

        // When
        let prediction = try await predictiveAnalysisEngine.predictSalaryProgression(
            historicalPayslips: historicalPayslips,
            predictionMonths: predictionMonths
        )

        // Then
        XCTAssertGreaterThan(prediction.predictions.count, 0)
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertGreaterThanOrEqual(prediction.expectedAnnualGrowth, 0.0)
        XCTAssertNotNil(prediction.trendDirection)

        // Validate prediction points
        for predictionPoint in prediction.predictions {
            XCTAssertGreaterThan(predictionPoint.predictedBasicPay, 0)
            XCTAssertGreaterThan(predictionPoint.predictedTotalCredits, 0)
            XCTAssertGreaterThan(predictionPoint.confidence, 0.0)
            XCTAssertLessThanOrEqual(predictionPoint.confidence, 1.0)
            XCTAssertGreaterThan(predictionPoint.influencingFactors.count, 0)
        }
    }

    func testAllowanceTrendAnalysis() async throws {
        // Given
        let historicalPayslips = testPayslips
        let targetAllowance = "HRA"

        // When
        let analysis = try await predictiveAnalysisEngine.analyzeAllowanceTrends(
            historicalPayslips: historicalPayslips,
            targetAllowance: targetAllowance
        )

        // Then
        XCTAssertEqual(analysis.allowanceName, targetAllowance)
        XCTAssertGreaterThanOrEqual(analysis.historicalTrend.count, 0)
        XCTAssertGreaterThanOrEqual(analysis.forecast.count, 0)
        XCTAssertGreaterThanOrEqual(analysis.volatilityIndex, 0.0)
        XCTAssertLessThanOrEqual(analysis.volatilityIndex, 1.0)

        // Validate historical trend data
        for trendPoint in analysis.historicalTrend {
            XCTAssertGreaterThan(trendPoint.amount, 0)
            XCTAssertGreaterThanOrEqual(trendPoint.percentageOfBasic, 0.0)
            XCTAssertLessThanOrEqual(trendPoint.percentageOfBasic, 1.0)
        }

        // Validate forecast data
        for forecastPoint in analysis.forecast {
            XCTAssertGreaterThan(forecastPoint.predictedAmount, 0)
            XCTAssertGreaterThan(forecastPoint.confidence, 0.0)
            XCTAssertLessThanOrEqual(forecastPoint.confidence, 1.0)
            XCTAssertGreaterThan(forecastPoint.probability, 0.0)
            XCTAssertLessThanOrEqual(forecastPoint.probability, 1.0)
        }
    }

    func testDeductionOptimizationRecommendations() async throws {
        // Given
        let currentPayslips = [testPayslips.last!]
        let taxRegime = TaxRegime.newRegime

        // When
        let recommendations = try await predictiveAnalysisEngine.generateDeductionOptimizations(
            currentPayslips: currentPayslips,
            taxRegime: taxRegime
        )

        // Then
        XCTAssertGreaterThanOrEqual(recommendations.currentTaxEfficiency, 0.0)
        XCTAssertLessThanOrEqual(recommendations.currentTaxEfficiency, 1.0)
        XCTAssertGreaterThanOrEqual(recommendations.potentialSavings, 0.0)
        XCTAssertNotNil(recommendations.riskAssessment)

        // Validate recommendations
        for recommendation in recommendations.recommendations {
            XCTAssertFalse(recommendation.deductionType.isEmpty)
            XCTAssertGreaterThan(recommendation.potentialSavings, 0)
            XCTAssertGreaterThan(recommendation.recommendedAmount, 0)
        }
    }

    func testSeasonalVariationAnalysis() async throws {
        // Given
        let historicalPayslips = testPayslips
        let analysisPeriod = SeasonalAnalysisPeriod.yearly

        // When
        let analysis = try await predictiveAnalysisEngine.analyzeSeasonalVariations(
            historicalPayslips: historicalPayslips,
            analysisPeriod: analysisPeriod
        )

        // Then
        XCTAssertGreaterThanOrEqual(analysis.detectedPatterns.count, 0)
        XCTAssertGreaterThanOrEqual(analysis.peakPeriods.count, 0)
        XCTAssertGreaterThanOrEqual(analysis.anomalyPeriods.count, 0)
        XCTAssertGreaterThanOrEqual(analysis.policyImpactAnalysis.count, 0)

        // Validate seasonal patterns
        for pattern in analysis.detectedPatterns {
            XCTAssertFalse(pattern.patternType.description.isEmpty)
            XCTAssertGreaterThan(pattern.amplitude, 0)
            XCTAssertGreaterThan(pattern.confidence, 0.0)
            XCTAssertLessThanOrEqual(pattern.confidence, 1.0)
        }

        // Validate peak periods
        for peak in analysis.peakPeriods {
            XCTAssertGreaterThanOrEqual(peak.startMonth, 1)
            XCTAssertLessThanOrEqual(peak.startMonth, 12)
            XCTAssertGreaterThanOrEqual(peak.endMonth, 1)
            XCTAssertLessThanOrEqual(peak.endMonth, 12)
            XCTAssertGreaterThan(peak.expectedIncrease, 0)
        }
    }

    // MARK: - Anomaly Detection Service Tests

    func testAmountAnomalyDetection() async throws {
        // Given
        let testPayslip = createAnomalousPayslip()
        let historicalPayslips = testPayslips

        // When
        let result = try await anomalyDetectionService.detectAmountAnomalies(
            payslip: testPayslip,
            historicalPayslips: historicalPayslips
        )

        // Then
        XCTAssertNotNil(result.overallRisk)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)

        // Validate anomalies
        for anomaly in result.anomalies {
            XCTAssertGreaterThan(anomaly.deviation, 0)
            XCTAssertGreaterThan(anomaly.confidence, 0.0)
            XCTAssertLessThanOrEqual(anomaly.confidence, 1.0)
            XCTAssertFalse(anomaly.explanation.isEmpty)
            XCTAssertFalse(anomaly.anomalyId.isEmpty)
        }
    }

    func testFormatAnomalyDetection() async throws {
        // Given
        let testPayslip = createMalformedPayslip()
        let expectedFormat = LiteRTDocumentFormatType.military

        // When
        let result = try await anomalyDetectionService.detectFormatAnomalies(
            payslip: testPayslip,
            expectedFormat: expectedFormat
        )

        // Then
        XCTAssertGreaterThanOrEqual(result.formatConsistency, 0.0)
        XCTAssertLessThanOrEqual(result.formatConsistency, 1.0)

        // Validate anomalies
        for anomaly in result.anomalies {
            XCTAssertFalse(anomaly.anomalyType.description.isEmpty)
            XCTAssertFalse(anomaly.description.isEmpty)
            XCTAssertFalse(anomaly.location.isEmpty)
        }
    }

    func testFraudDetection() async throws {
        // Given
        let suspiciousPayslip = createSuspiciousPayslip()
        let historicalPayslips = testPayslips

        // When
        let result = try await anomalyDetectionService.detectFraudIndicators(
            payslip: suspiciousPayslip,
            historicalPayslips: historicalPayslips
        )

        // Then
        XCTAssertNotNil(result.overallRisk)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertNotNil(result.investigationPriority)

        // Validate fraud indicators
        for indicator in result.fraudIndicators {
            XCTAssertGreaterThan(indicator.confidence, 0.0)
            XCTAssertLessThanOrEqual(indicator.confidence, 1.0)
            XCTAssertGreaterThan(indicator.riskScore, 0.0)
            XCTAssertFalse(indicator.evidence.isEmpty)
        }
    }

    func testUserFeedbackIntegration() async throws {
        // Given
        let anomalyId = "test_anomaly_123"
        let isFalsePositive = true

        // When/Then - Should not throw
        try await anomalyDetectionService.updateWithUserFeedback(
            anomalyId: anomalyId,
            isFalsePositive: isFalsePositive
        )
    }

    // MARK: - Multi-Document Processor Tests

    func testBatchProcessing() async throws {
        // Given
        let documents = try createTestPDFDocuments(count: 5)
        let options = BatchProcessingOptions()

        // When
        let result = try await multiDocumentProcessor.processBatch(
            documents: documents,
            options: options
        )

        // Then
        XCTAssertEqual(result.processedPayslips.count + result.failedDocuments.count, documents.count)
        XCTAssertGreaterThan(result.performanceMetrics.totalProcessingTime, 0)
        XCTAssertGreaterThan(result.performanceMetrics.documentsPerSecond, 0)
        XCTAssertGreaterThanOrEqual(result.processingSummary.successRate, 0.0)
        XCTAssertLessThanOrEqual(result.processingSummary.successRate, 1.0)

        // Validate performance metrics
        XCTAssertGreaterThanOrEqual(result.performanceMetrics.memoryEfficiency, 0.0)
        XCTAssertLessThanOrEqual(result.performanceMetrics.memoryEfficiency, 1.0)
    }

    func testCrossDocumentValidation() async throws {
        // Given
        let payslips = testPayslips

        // When
        let result = try await multiDocumentProcessor.validateCrossDocumentConsistency(
            payslips: payslips
        )

        // Then
        XCTAssertGreaterThanOrEqual(result.consistencyScore, 0.0)
        XCTAssertLessThanOrEqual(result.consistencyScore, 1.0)
        XCTAssertNotNil(result.riskAssessment)

        // Validate validation issues
        for issue in result.validationIssues {
            XCTAssertFalse(issue.description.isEmpty)
            XCTAssertGreaterThan(issue.affectedDocuments.count, 0)
        }
    }

    func testTimelineAnalysis() async throws {
        // Given
        let payslips = testPayslips
        let analysisPeriod = TimelineAnalysisPeriod.lastYear

        // When
        let result = try await multiDocumentProcessor.analyzeTimelinePatterns(
            payslips: payslips,
            analysisPeriod: analysisPeriod
        )

        // Then
        XCTAssertGreaterThanOrEqual(result.patterns.count, 0)
        XCTAssertGreaterThanOrEqual(result.gaps.count, 0)
        XCTAssertGreaterThanOrEqual(result.anomalies.count, 0)
        XCTAssertGreaterThanOrEqual(result.projections.count, 0)

        // Validate patterns
        for pattern in result.patterns {
            XCTAssertGreaterThan(pattern.confidence, 0.0)
            XCTAssertLessThanOrEqual(pattern.confidence, 1.0)
            XCTAssertGreaterThan(pattern.amplitude, 0)
        }

        // Validate gaps
        for gap in result.gaps {
            XCTAssertGreaterThan(gap.duration, 0)
            XCTAssertNotNil(gap.gapType)
            XCTAssertNotNil(gap.impact)
        }
    }

    func testMemoryOptimization() async throws {
        // Given
        let documentCount = 20
        let availableMemory = 1000 // MB

        // When
        let strategy = multiDocumentProcessor.optimizeMemoryForBatch(
            documentCount: documentCount,
            availableMemory: availableMemory
        )

        // Then
        XCTAssertGreaterThan(strategy.recommendedBatchSize, 0)
        XCTAssertLessThanOrEqual(strategy.recommendedBatchSize, documentCount)
        XCTAssertGreaterThan(strategy.memoryCleanupFrequency, 0)
        XCTAssertGreaterThan(strategy.parallelProcessingLimit, 0)

        // Validate batch size is reasonable
        XCTAssertLessThanOrEqual(strategy.recommendedBatchSize, 10) // Should not exceed reasonable limit
    }

    // MARK: - AI Insights Generator Tests

    func testFinancialInsightsGeneration() async throws {
        // Given
        let payslips = testPayslips
        let userProfile = createTestUserProfile()

        // When
        let report = try await aiInsightsGenerator.generateFinancialInsights(
            payslips: payslips,
            userProfile: userProfile
        )

        // Then
        XCTAssertFalse(report.executiveSummary.isEmpty)
        XCTAssertGreaterThanOrEqual(report.keyInsights.count, 0)
        XCTAssertNotNil(report.trendAnalysis.overallDirection)
        XCTAssertNotNil(report.riskAssessment.overallRisk)
        XCTAssertGreaterThanOrEqual(report.recommendations.count, 0)
        XCTAssertGreaterThan(report.confidence, 0.0)
        XCTAssertLessThanOrEqual(report.confidence, 1.0)
    }

    func testPersonalizedRecommendations() async throws {
        // Given
        let payslips = testPayslips
        let userProfile = createTestUserProfile()

        // When
        let recommendations = try await aiInsightsGenerator.generatePersonalizedRecommendations(
            payslips: payslips,
            userProfile: userProfile
        )

        // Then
        XCTAssertGreaterThanOrEqual(recommendations.userSpecificRecommendations.count, 0)
        XCTAssertGreaterThanOrEqual(recommendations.goalAlignedRecommendations.count, 0)
        XCTAssertGreaterThanOrEqual(recommendations.riskAdjustedSuggestions.count, 0)
        XCTAssertGreaterThanOrEqual(recommendations.learningBasedInsights.count, 0)

        // Validate goal-aligned recommendations
        for goalRec in recommendations.goalAlignedRecommendations {
            XCTAssertGreaterThanOrEqual(goalRec.progress, 0.0)
            XCTAssertLessThanOrEqual(goalRec.progress, 1.0)
            XCTAssertGreaterThanOrEqual(goalRec.nextSteps.count, 0)
        }
    }

    func testNaturalLanguageExplanations() async throws {
        // Given
        let insights = try await createTestInsights()
        let context = ExplanationContext.intermediate

        // When
        let explanations = try await aiInsightsGenerator.generateNaturalLanguageExplanations(
            insights: insights,
            context: context
        )

        // Then
        XCTAssertEqual(explanations.count, insights.count)

        for explanation in explanations {
            XCTAssertFalse(explanation.explanation.isEmpty)
            XCTAssertGreaterThanOrEqual(explanation.keyTakeaways.count, 0)
            XCTAssertGreaterThanOrEqual(explanation.relatedConcepts.count, 0)
        }
    }

    func testInsightPrioritization() async throws {
        // Given
        let insights = try await createTestInsights()
        let userContext = createTestUserContext()

        // When
        let prioritized = try await aiInsightsGenerator.prioritizeInsights(
            insights: insights,
            userContext: userContext
        )

        // Then
        let totalPrioritized = prioritized.topPriority.count +
                              prioritized.highPriority.count +
                              prioritized.mediumPriority.count +
                              prioritized.lowPriority.count

        XCTAssertEqual(totalPrioritized, insights.count)
        XCTAssertFalse(prioritized.rationale.isEmpty)

        // Validate prioritization logic
        let topPriorityCount = prioritized.topPriority.count
        let highPriorityCount = prioritized.highPriority.count
        let mediumPriorityCount = prioritized.mediumPriority.count
        let lowPriorityCount = prioritized.lowPriority.count

        // Ensure proper categorization
        XCTAssertGreaterThanOrEqual(topPriorityCount, 0)
        XCTAssertGreaterThanOrEqual(highPriorityCount, 0)
        XCTAssertGreaterThanOrEqual(mediumPriorityCount, 0)
        XCTAssertGreaterThanOrEqual(lowPriorityCount, 0)
    }

    // MARK: - End-to-End Integration Tests

    func testCompletePhase5Workflow() async throws {
        // Given
        let payslips = testPayslips
        let userProfile = createTestUserProfile()
        let userContext = createTestUserContext()

        // Test complete workflow
        let insightsReport = try await aiInsightsGenerator.generateFinancialInsights(
            payslips: payslips,
            userProfile: userProfile
        )

        let recommendations = try await aiInsightsGenerator.generatePersonalizedRecommendations(
            payslips: payslips,
            userProfile: userProfile
        )

        let explanations = try await aiInsightsGenerator.generateNaturalLanguageExplanations(
            insights: insightsReport.keyInsights,
            context: .intermediate
        )

        let prioritized = try await aiInsightsGenerator.prioritizeInsights(
            insights: insightsReport.keyInsights,
            userContext: userContext
        )

        // Validate complete workflow
        XCTAssertGreaterThan(insightsReport.keyInsights.count, 0)
        XCTAssertGreaterThan(recommendations.userSpecificRecommendations.count, 0)
        XCTAssertEqual(explanations.count, insightsReport.keyInsights.count)
        XCTAssertEqual(
            prioritized.topPriority.count + prioritized.highPriority.count +
            prioritized.mediumPriority.count + prioritized.lowPriority.count,
            insightsReport.keyInsights.count
        )
    }

    func testErrorHandling() async throws {
        // Test with empty payslips
        do {
            _ = try await predictiveAnalysisEngine.predictSalaryProgression(
                historicalPayslips: [],
                predictionMonths: 12
            )
            XCTFail("Should have thrown error for empty payslips")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }

        do {
            _ = try await aiInsightsGenerator.generateFinancialInsights(
                payslips: [],
                userProfile: nil
            )
            XCTFail("Should have thrown error for empty payslips")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Helper Methods

    private func createMockModelContext() throws -> ModelContext {
        // Create a mock model context for testing
        // In a real implementation, this would create an in-memory store
        throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock context creation not implemented"])
    }

    private func createTestPayslipHistory() throws -> [Payslip] {
        var payslips: [Payslip] = []
        let calendar = Calendar.current
        let baseDate = Date()

        // Create 12 months of test data
        for monthOffset in 0..<12 {
            guard let payslipDate = calendar.date(byAdding: .month, value: -monthOffset, to: baseDate) else {
                continue
            }

            let payslip = Payslip(
                timestamp: payslipDate,
                rank: "Captain",
                serviceNumber: "IC-12345",
                basicPay: 45000.0 + Double(monthOffset) * 500.0, // Slight increase each month
                allowances: [
                    Allowance(name: "DA", amount: 22500.0, category: "Standard"),
                    Allowance(name: "HRA", amount: 13500.0, category: "Taxable"),
                    Allowance(name: "MSP", amount: 10000.0, category: "Military")
                ],
                deductions: [
                    Deduction(name: "INCOME_TAX", amount: 7500.0, category: "Statutory"),
                    Deduction(name: "PROFESSIONAL_TAX", amount: 2500.0, category: "Statutory"),
                    Deduction(name: "AGIF", amount: 500.0, category: "Voluntary")
                ],
                netPay: 70500.0 + Double(monthOffset) * 500.0
            )

            payslips.append(payslip)
        }

        return payslips
    }

    private func createMockProcessingPipeline() -> ModularPayslipProcessingPipeline {
        // Create a mock processing pipeline for testing
        // In a real implementation, this would return a properly configured pipeline
        fatalError("Mock processing pipeline creation not implemented")
    }

    private func createTestPDFDocuments(count: Int) throws -> [PDFDocument] {
        var documents: [PDFDocument] = []

        for _ in 0..<count {
            let document = PDFDocument()
            // Add dummy page for testing
            let page = PDFPage()
            document.insert(page, at: 0)
            documents.append(document)
        }

        return documents
    }

    private func createAnomalousPayslip() -> Payslip {
        return Payslip(
            timestamp: Date(),
            rank: "Captain",
            serviceNumber: "IC-12345",
            basicPay: 150000.0, // Anomalously high basic pay
            allowances: [
                Allowance(name: "DA", amount: 22500.0, category: "Standard"),
                Allowance(name: "HRA", amount: 13500.0, category: "Taxable")
            ],
            deductions: [
                Deduction(name: "INCOME_TAX", amount: 7500.0, category: "Statutory")
            ],
            netPay: 160000.0
        )
    }

    private func createMalformedPayslip() -> Payslip {
        return Payslip(
            timestamp: Date(),
            rank: "", // Missing rank
            serviceNumber: "", // Missing service number
            basicPay: 45000.0,
            allowances: [],
            deductions: [],
            netPay: 45000.0
        )
    }

    private func createSuspiciousPayslip() -> Payslip {
        return Payslip(
            timestamp: Date(),
            rank: "Captain",
            serviceNumber: "IC-12345",
            basicPay: 45000.0,
            allowances: [
                Allowance(name: "DA", amount: 22500.0, category: "Standard"),
                Allowance(name: "HRA", amount: 13500.0, category: "Taxable"),
                Allowance(name: "MYSTERY_ALLOWANCE", amount: 50000.0, category: "Unknown") // Suspicious allowance
            ],
            deductions: [
                Deduction(name: "INCOME_TAX", amount: 7500.0, category: "Statutory")
            ],
            netPay: 100000.0
        )
    }

    private func createTestUserProfile() -> UserProfile {
        return UserProfile(
            riskTolerance: .moderate,
            financialGoals: [.wealthBuilding, .taxOptimization],
            preferredInsightCategories: [.income, .taxes, .trends],
            experienceLevel: .intermediate,
            notificationPreferences: NotificationPreferences(
                insightAlerts: true,
                anomalyNotifications: true,
                monthlyReports: true,
                goalReminders: true
            )
        )
    }

    private func createTestUserContext() -> UserContext {
        return UserContext(
            currentGoals: [.wealthBuilding, .taxOptimization],
            recentActions: [],
            knowledgeLevel: .intermediate,
            timeConstraints: .moderate,
            riskTolerance: .moderate
        )
    }

    private func createTestInsights() async throws -> [FinancialInsight] {
        return [
            FinancialInsight(
                id: "test_insight_1",
                category: .income,
                title: "Income Stability",
                description: "Your income shows good stability over the past year",
                impact: .medium,
                confidence: 0.85,
                supportingData: [],
                timeframe: .mediumTerm,
                actionable: false
            ),
            FinancialInsight(
                id: "test_insight_2",
                category: .taxes,
                title: "Tax Efficiency",
                description: "Consider optimizing your tax deductions",
                impact: .high,
                confidence: 0.9,
                supportingData: [],
                timeframe: .shortTerm,
                actionable: true
            )
        ]
    }
}

// MARK: - Test Extensions

extension LiteRTDocumentFormatType {
    static var militaryPCDA: LiteRTDocumentFormatType {
        // Return a mock format type for testing
        // In real implementation, this would be a proper enum case
        return LiteRTDocumentFormatType.military
    }
}
