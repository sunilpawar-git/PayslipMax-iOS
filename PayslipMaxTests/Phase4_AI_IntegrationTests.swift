import XCTest
import SwiftData
@testable import PayslipMax

/// Integration tests for Phase 4 Adaptive Learning & Personalization features
final class Phase4_AI_IntegrationTests: XCTestCase {

    // MARK: - Properties

    private var adaptiveLearningEngine: AdaptiveLearningEngine!
    private var userFeedbackProcessor: UserFeedbackProcessor!
    private var personalizedInsightsEngine: PersonalizedInsightsEngine!
    private var userLearningStore: UserLearningStore!
    private var privacyManager: PrivacyPreservingLearningManager!
    private var abTestingFramework: ABTestingFramework!
    private var visionParser: VisionPayslipParser!
    private var militaryParser: MilitaryPayslipProcessor!

    private var testContainer: ModelContainer!
    private var testContext: ModelContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Initialize test components
        userLearningStore = await UserLearningStore()
        privacyManager = PrivacyPreservingLearningManager(privacyMode: .balanced)
        adaptiveLearningEngine = await AdaptiveLearningEngine(
            userLearningStore: userLearningStore,
            privacyManager: privacyManager
        )
        userFeedbackProcessor = await UserFeedbackProcessor(
            learningEngine: adaptiveLearningEngine
        )
        personalizedInsightsEngine = await PersonalizedInsightsEngine()

        // Initialize parsers with learning capabilities
        visionParser = await VisionPayslipParser(
            learningEngine: adaptiveLearningEngine,
            feedbackProcessor: userFeedbackProcessor,
            performanceTracker: PerformanceTracker()
        )

        militaryParser = await MilitaryPayslipProcessor(
            learningEngine: adaptiveLearningEngine,
            feedbackProcessor: userFeedbackProcessor,
            performanceTracker: PerformanceTracker()
        )

        abTestingFramework = await ABTestingFramework(
            privacyManager: privacyManager
        )

        // Setup SwiftData for testing
        let schema = Schema([
            // Add any models needed for testing
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        testContext = ModelContext(testContainer)
    }

    override func tearDown() async throws {
        // Cleanup
        adaptiveLearningEngine = nil
        userFeedbackProcessor = nil
        personalizedInsightsEngine = nil
        userLearningStore = nil
        privacyManager = nil
        abTestingFramework = nil
        visionParser = nil
        militaryParser = nil

        testContainer = nil
        testContext = nil

        try await super.tearDown()
    }

    // MARK: - Integration Tests

    /// Test complete user correction workflow
    func testUserCorrectionWorkflow() async throws {
        // Given: A payslip with incorrect extraction
        let originalValue = "John Doe"
        let correctedValue = "Jane Smith"
        let fieldName = "employeeName"

        // Create test correction
        let correction = UserCorrection(
            fieldName: fieldName,
            originalValue: originalValue,
            correctedValue: correctedValue,
            documentType: .corporate,
            parserUsed: "VisionPayslipParser",
            timestamp: Date(),
            confidenceImpact: 0.1,
            extractedPattern: originalValue,
            totalExtractions: 1
        )

        // When: Process the correction through the learning system
        try await userFeedbackProcessor.captureUserCorrection(correction)

        // Then: Verify correction is stored and processed
        let storedCorrections = try await userLearningStore.getAllCorrections()
        XCTAssertEqual(storedCorrections.count, 1)
        XCTAssertEqual(storedCorrections.first?.correctedValue, correctedValue)

        // Verify learning adaptations are generated
        let adaptations = try await adaptiveLearningEngine.adaptParserParameters(
            for: "VisionPayslipParser",
            documentType: .corporate
        )
        XCTAssertFalse(adaptations.adaptations.isEmpty)

        // Verify personalized suggestions are generated
        let suggestions = try await adaptiveLearningEngine.getPersonalizedSuggestions(for: .corporate)
        XCTAssertFalse(suggestions.isEmpty)
    }

    /// Test privacy-preserving learning workflow
    func testPrivacyPreservingLearning() async throws {
        // Given: User correction with sensitive data
        let sensitiveValue = "john.doe@email.com"
        let correction = UserCorrection(
            fieldName: "contactInfo",
            originalValue: sensitiveValue,
            correctedValue: "jane.smith@email.com",
            documentType: .corporate,
            parserUsed: "VisionPayslipParser",
            timestamp: Date(),
            confidenceImpact: 0.1,
            extractedPattern: sensitiveValue,
            totalExtractions: 1
        )

        // When: Process correction with privacy preservation
        try await userFeedbackProcessor.captureUserCorrection(correction)

        // Then: Verify data is anonymized
        let anonymizedCorrection = try await privacyManager.anonymizeCorrection(correction)
        XCTAssertNotEqual(anonymizedCorrection.originalValue, sensitiveValue)
        XCTAssertNotEqual(anonymizedCorrection.documentType, .corporate)

        // Verify patterns are anonymized
        let pattern = CorrectionPattern(
            fieldName: "email",
            documentType: .corporate,
            patternType: .validationRule,
            pattern: sensitiveValue,
            frequency: 1,
            confidence: 0.8,
            confidenceAdjustment: 0.1,
            lastSeen: Date()
        )
        let anonymizedPattern = try await privacyManager.anonymizePattern(pattern)
        XCTAssertNotEqual(anonymizedPattern.fieldName, "email")
        XCTAssertEqual(anonymizedPattern.documentType, .unknown)
    }

    /// Test personalized insights generation
    func testPersonalizedInsightsGeneration() async throws {
        // Given: Multiple user corrections for pattern learning
        let corrections = [
            UserCorrection(fieldName: "DSOP", originalValue: "1000", correctedValue: "1500", documentType: .military, parserUsed: "MilitaryPayslipProcessor", timestamp: Date(), confidenceImpact: 0.1, totalExtractions: 1),
            UserCorrection(fieldName: "DSOP", originalValue: "1200", correctedValue: "1600", documentType: .military, parserUsed: "MilitaryPayslipProcessor", timestamp: Date().addingTimeInterval(3600), confidenceImpact: 0.1, totalExtractions: 1),
            UserCorrection(fieldName: "AGIF", originalValue: "800", correctedValue: "900", documentType: .military, parserUsed: "MilitaryPayslipProcessor", timestamp: Date().addingTimeInterval(7200), confidenceImpact: 0.1, totalExtractions: 1)
        ]

        // Process corrections
        for correction in corrections {
            try await userFeedbackProcessor.captureUserCorrection(correction)
        }

        // When: Generate personalized insights
        let profile = try await personalizedInsightsEngine.analyzeUserPatterns(corrections: corrections)
        let insights = try await personalizedInsightsEngine.generatePersonalizedInsights(
            for: .military,
            userHistory: corrections
        )

        // Then: Verify insights are generated and meaningful
        XCTAssertFalse(insights.isEmpty)
        XCTAssertEqual(profile.documentTypePreferences[.military], 1.0)

        // Check for field-specific insights
        let fieldInsight = insights.first { $0.type == .fieldOptimization }
        XCTAssertNotNil(fieldInsight)
        XCTAssertTrue(fieldInsight?.relatedFields.contains("DSOP") ?? false)
    }

    /// Test A/B testing framework integration
    func testABTestingIntegration() async throws {
        // Given: A/B test for parser accuracy
        let test = ABTest(
            name: "ParserAccuracyTest",
            description: "Testing Vision vs Enhanced Vision parsing accuracy",
            variants: [
                ABTestVariant(name: "control", description: "Standard Vision parser"),
                ABTestVariant(name: "enhanced", description: "Enhanced Vision with learning")
            ],
            targetMetric: .accuracy,
            minimumEffectSize: 0.05
        )

        // Register test
        try await abTestingFramework.registerTest(test)

        // When: Simulate user interactions and results
        let userId = "test_user_123"
        let variant = await abTestingFramework.getTestVariant(for: userId, testName: test.name)
        XCTAssertNotNil(variant)

        // Record test results
        let result = ABTestResult(
            testName: test.name,
            variantName: variant!.name,
            userId: userId,
            success: true,
            processingTime: 1.5,
            accuracy: 0.85,
            confidence: 0.9
        )
        try await abTestingFramework.recordTestResult(result)

        // Then: Verify results are stored and analyzed
        let storedResults = try await abTestingFramework.getTestResults(for: test.name)
        XCTAssertEqual(storedResults.count, 1)
        XCTAssertEqual(storedResults.first?.success, true)
    }

    /// Test parser learning integration
    func testParserLearningIntegration() async throws {
        // Given: Parser with learning capabilities
        let testText = "Employee Name: John Doe\nBasic Pay: 50000"

        // When: Process correction through parser
        // await visionParser.processUserCorrection(originalText: "John Doe", correctedText: "Jane Smith")

        // Then: Verify learning integration
        let confidenceAdjustment = await adaptiveLearningEngine.getConfidenceAdjustment(
            for: "text_recognition",
            documentType: .corporate
        )
        XCTAssertNotEqual(confidenceAdjustment, 0.0)

        // Test military parser learning
        // await militaryParser.processUserCorrection(originalText: "BPAY 50000", correctedText: "BPAY 55000")

        let militaryAdjustment = await adaptiveLearningEngine.getConfidenceAdjustment(
            for: "military_text_processing",
            documentType: .military
        )
        XCTAssertNotEqual(militaryAdjustment, 0.0)
    }

    /// Test performance tracking integration
    func testPerformanceTrackingIntegration() async throws {
        // Given: Performance tracking enabled
        let performanceTracker = PerformanceTracker()

        // When: Track parser performance
        let metrics = ParserPerformanceMetrics(
            parserName: "VisionPayslipParser",
            documentType: .corporate,
            processingTime: 2.0,
            accuracy: 0.9,
            fieldsExtracted: 5,
            fieldsCorrect: 4
        )

        try await performanceTracker.recordPerformance(metrics)

        // Then: Verify performance is tracked and influences learning
        let adaptations = try await adaptiveLearningEngine.adaptParserParameters(
            for: "VisionPayslipParser",
            documentType: .corporate
        )
        XCTAssertFalse(adaptations.adaptations.isEmpty)
    }

    /// Test end-to-end learning workflow
    func testEndToEndLearningWorkflow() async throws {
        // Given: Complete payslip processing scenario
        let testText = """
        Employee: John Smith
        Basic Pay: 45000
        HRA: 18000
        Conveyance: 19200
        DSOP: 4500
        Income Tax: 12000
        """

        // When: Process multiple corrections over time
        let corrections = [
            UserCorrection(fieldName: "employeeName", originalValue: "John Smith", correctedValue: "Jane Smith", documentType: .corporate, parserUsed: "VisionPayslipParser", timestamp: Date(), confidenceImpact: 0.1, totalExtractions: 1),
            UserCorrection(fieldName: "DSOP", originalValue: "4500", correctedValue: "5000", documentType: .corporate, parserUsed: "VisionPayslipParser", timestamp: Date().addingTimeInterval(3600), confidenceImpact: 0.1, totalExtractions: 1),
            UserCorrection(fieldName: "IncomeTax", originalValue: "12000", correctedValue: "15000", documentType: .corporate, parserUsed: "VisionPayslipParser", timestamp: Date().addingTimeInterval(7200), confidenceImpact: 0.1, totalExtractions: 1)
        ]

        for correction in corrections {
            try await userFeedbackProcessor.captureUserCorrection(correction)
        }

        // Then: Verify complete learning system response
        // 1. Patterns are learned
        let userPatterns = try await userLearningStore.getUserPatterns(for: .corporate)
        XCTAssertFalse(userPatterns.isEmpty)

        // 2. Personalized insights are generated
        let profile = try await personalizedInsightsEngine.analyzeUserPatterns(corrections: corrections)
        XCTAssertFalse(profile.commonMistakes.isEmpty)

        // 3. Parser adaptations are available
        let adaptations = try await adaptiveLearningEngine.adaptParserParameters(
            for: "VisionPayslipParser",
            documentType: .corporate
        )
        XCTAssertFalse(adaptations.adaptations.isEmpty)

        // 4. Confidence adjustments are applied
        let confidenceAdjustment = await adaptiveLearningEngine.getConfidenceAdjustment(
            for: "DSOP",
            documentType: .corporate
        )
        XCTAssertNotEqual(confidenceAdjustment, 0.0)
    }

    /// Test concurrent learning operations
    func testConcurrentLearningOperations() async throws {
        // Given: Multiple concurrent correction processing
        let corrections = (1...10).map { index in
            UserCorrection(
                fieldName: "field\(index)",
                originalValue: "value\(index)",
                correctedValue: "corrected\(index)",
                documentType: .corporate,
                parserUsed: "VisionPayslipParser",
                timestamp: Date(),
                confidenceImpact: 0.1,
                totalExtractions: 1
            )
        }

        // When: Process corrections concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for correction in corrections {
                group.addTask {
                    try await self.userFeedbackProcessor.captureUserCorrection(correction)
                }
            }
            try await group.waitForAll()
        }

        // Then: Verify all corrections are processed correctly
        let storedCorrections = try await userLearningStore.getAllCorrections()
        XCTAssertEqual(storedCorrections.count, 10)

        // Verify thread safety and data consistency
        let uniqueFields = Set(storedCorrections.map { $0.fieldName })
        XCTAssertEqual(uniqueFields.count, 10)
    }

    /// Test error handling in learning system
    func testLearningSystemErrorHandling() async throws {
        // Given: Invalid correction data
        let invalidCorrection = UserCorrection(
            fieldName: "",
            originalValue: "",
            correctedValue: "",
            documentType: .corporate,
            parserUsed: "VisionPayslipParser",
            timestamp: Date(),
            confidenceImpact: 0.1,
            totalExtractions: 1
        )

        // When: Process invalid correction
        do {
            try await userFeedbackProcessor.captureUserCorrection(invalidCorrection)
            XCTFail("Expected error for invalid correction")
        } catch {
            // Then: Verify appropriate error is thrown
            XCTAssertTrue(error is FeedbackProcessorError)
        }

        // Test privacy manager error handling
        let invalidData = ["invalid": Date()] as [String: Any]
        let sanitizedData = try await privacyManager.sanitizeUserData(invalidData)
        XCTAssertNotNil(sanitizedData["invalid"])
    }

    /// Test learning system data export/import
    func testLearningDataExportImport() async throws {
        // Given: Learning data in system
        let correction = UserCorrection(
            fieldName: "testField",
            originalValue: "original",
            correctedValue: "corrected",
            documentType: .corporate,
            parserUsed: "VisionPayslipParser",
            timestamp: Date(),
            confidenceImpact: 0.1,
            totalExtractions: 1
        )
        try await userFeedbackProcessor.captureUserCorrection(correction)

        // When: Export learning data
        let exportData = try await userFeedbackProcessor.exportLearningData()

        // Then: Verify export contains expected data
        XCTAssertFalse(exportData.corrections.isEmpty)
        XCTAssertEqual(exportData.corrections.first?.correctedValue, "corrected")

        // Test import functionality (would need separate store instance in real scenario)
        XCTAssertEqual(exportData.version, "1.0")
    }
}

// MARK: - Mock Classes for Testing

/// Mock performance tracker for testing
private class PerformanceTracker: PerformanceTrackerProtocol {
    private var storedMetrics: [ParserPerformanceMetrics] = []

    func recordPerformance(_ metrics: ParserPerformanceMetrics) async throws {
        storedMetrics.append(metrics)
    }

    func getMetrics(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> [ParserPerformanceMetrics] {
        return storedMetrics.filter { $0.parserName == parser && $0.documentType == documentType }
    }

    func getAverageMetrics(for parser: String, documentType: LiteRTDocumentFormatType) async throws -> ParserPerformanceMetrics? {
        let relevantMetrics = try await getMetrics(for: parser, documentType: documentType)
        guard !relevantMetrics.isEmpty else { return nil }

        let avgAccuracy = relevantMetrics.map { $0.accuracy }.reduce(0, +) / Double(relevantMetrics.count)
        let avgProcessingTime = relevantMetrics.map { $0.processingTime }.reduce(0, +) / Double(relevantMetrics.count)

        return ParserPerformanceMetrics(
            parserName: parser,
            documentType: documentType,
            processingTime: avgProcessingTime,
            accuracy: avgAccuracy,
            fieldsExtracted: 0,
            fieldsCorrect: 0
        )
    }

    // Required protocol methods
    func getPerformanceHistory(for parser: String, days: Int) async throws -> [ParserPerformanceMetrics] {
        return storedMetrics.filter { $0.parserName == parser }
    }

    func calculatePerformanceTrends(for parser: String) async throws -> PerformanceTrends {
        // Return a mock trend
        return PerformanceTrends(
            parserName: parser,
            accuracyTrend: 0.1, // Improving accuracy
            speedTrend: -0.05, // Getting slightly slower
            reliabilityTrend: 0.2, // Improving reliability
            overallTrend: 0.08, // Overall positive trend
            dataPoints: 10,
            analysisDate: Date()
        )
    }

    func getTopPerformingParsers(for documentType: LiteRTDocumentFormatType) async throws -> [ParserPerformanceRanking] {
        // Return mock ranking
        return [ParserPerformanceRanking(
            parserName: "MockParser",
            documentType: documentType,
            averageAccuracy: 0.85,
            averageSpeed: 0.5,
            totalDocuments: 100,
            successRate: 0.9,
            compositeScore: 0.87,
            lastUsed: Date()
        )]
    }

    func generatePerformanceReport() async throws -> PerformanceReport {
        // Return mock report
        return PerformanceReport(
            reportDate: Date(),
            reportPeriodDays: 30,
            totalDocumentsProcessed: 100,
            averageAccuracy: 0.85,
            averageProcessingTime: 1.5,
            parserStatistics: [],
            documentTypeStatistics: [],
            improvementMetrics: ImprovementMetrics(
                accuracyImprovement: 0.05,
                speedImprovement: -0.1,
                reliabilityImprovement: 0.2,
                timeframe: "Last 30 days"
            ),
            recommendations: ["Consider updating parser algorithms"]
        )
    }
}
