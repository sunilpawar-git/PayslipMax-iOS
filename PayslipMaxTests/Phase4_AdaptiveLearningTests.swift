import XCTest
import Foundation
import PDFKit
@testable import PayslipMax

/// Comprehensive tests for Phase 4: Adaptive Learning & Personalization
@MainActor
final class Phase4_AdaptiveLearningTests: XCTestCase {
    
    // MARK: - Properties
    
    private var adaptiveLearningEngine: AdaptiveLearningEngine!
    private var userFeedbackProcessor: UserFeedbackProcessor!
    private var personalizedInsightsEngine: PersonalizedInsightsEngine!
    private var userLearningStore: UserLearningStore!
    private var performanceTracker: PerformanceTracker!
    private var privacyManager: PrivacyPreservingLearningManager!
    private var learningEnhancedParser: LearningEnhancedParser!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize components
        userLearningStore = UserLearningStore()
        performanceTracker = PerformanceTracker()
        privacyManager = PrivacyPreservingLearningManager(privacyMode: .balanced)
        
        adaptiveLearningEngine = AdaptiveLearningEngine(
            userLearningStore: userLearningStore,
            patternAnalyzer: PatternAnalyzer(),
            performanceTracker: performanceTracker,
            privacyManager: privacyManager
        )
        
        userFeedbackProcessor = UserFeedbackProcessor(
            learningEngine: adaptiveLearningEngine
        )
        
        personalizedInsightsEngine = PersonalizedInsightsEngine()
        
        // Create mock parser for testing
        let mockParser = MockPayslipParser()
        learningEnhancedParser = LearningEnhancedParser(
            baseParser: mockParser as! any PayslipParserProtocol,
            parserName: "TestParser",
            learningEngine: adaptiveLearningEngine,
            userLearningStore: userLearningStore,
            performanceTracker: performanceTracker
        )
    }
    
    override func tearDown() async throws {
        adaptiveLearningEngine = nil
        userFeedbackProcessor = nil
        personalizedInsightsEngine = nil
        userLearningStore = nil
        performanceTracker = nil
        privacyManager = nil
        learningEnhancedParser = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Adaptive Learning Engine Tests
    
    func testAdaptiveLearningEngine_ProcessUserCorrection() async throws {
        // Given
        let correction = createTestCorrection()
        
        // When
        try await adaptiveLearningEngine.processUserCorrection(correction)
        
        // Then
        let allCorrections = try await userLearningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 1)
        XCTAssertEqual(allCorrections.first?.fieldName, correction.fieldName)
    }
    
    func testAdaptiveLearningEngine_GeneratePersonalizedSuggestions() async throws {
        // Given
        let documentType = LiteRTDocumentFormatType.pcda
        let correction = createTestCorrection(documentType: documentType)
        try await adaptiveLearningEngine.processUserCorrection(correction)
        
        // When
        let suggestions = try await adaptiveLearningEngine.getPersonalizedSuggestions(for: documentType)
        
        // Then
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.confidence > 0 })
    }
    
    func testAdaptiveLearningEngine_AdaptParserParameters() async throws {
        // Given
        let parserName = "TestParser"
        let documentType = LiteRTDocumentFormatType.corporate
        
        // Add some corrections to create adaptation data
        for i in 0..<5 {
            let correction = createTestCorrection(
                fieldName: "field\(i)",
                documentType: documentType,
                parserUsed: parserName
            )
            try await adaptiveLearningEngine.processUserCorrection(correction)
        }
        
        // When
        let adaptation = try await adaptiveLearningEngine.adaptParserParameters(
            for: parserName,
            documentType: documentType
        )
        
        // Then
        XCTAssertEqual(adaptation.parserName, parserName)
        XCTAssertTrue(adaptation.confidenceMultiplier <= 1.0)
        XCTAssertTrue(adaptation.confidenceMultiplier >= 0.0)
    }
    
    func testAdaptiveLearningEngine_ConfidenceAdjustment() async throws {
        // Given
        let fieldName = "salary"
        let documentType = LiteRTDocumentFormatType.military
        let correction = createTestCorrection(fieldName: fieldName, documentType: documentType)
        
        try await adaptiveLearningEngine.processUserCorrection(correction)
        
        // When
        let adjustment = await adaptiveLearningEngine.getConfidenceAdjustment(
            for: fieldName,
            documentType: documentType
        )
        
        // Then
        XCTAssertTrue(adjustment <= 0.0) // Should be negative for corrections
        XCTAssertTrue(adjustment >= -0.5) // Should not be too negative
    }
    
    // MARK: - User Feedback Processor Tests
    
    func testUserFeedbackProcessor_CaptureCorrection() async throws {
        // Given
        let correction = createTestCorrection()
        
        // When
        try await userFeedbackProcessor.captureUserCorrection(correction)
        
        // Then
        let history = try await userFeedbackProcessor.getCorrectionHistory(for: correction.fieldName)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.fieldName, correction.fieldName)
    }
    
    func testUserFeedbackProcessor_BatchProcessCorrections() async throws {
        // Given
        let corrections = (0..<5).map { i in
            createTestCorrection(fieldName: "field\(i)")
        }
        
        // When
        try await userFeedbackProcessor.batchProcessCorrections(corrections)
        
        // Then
        for correction in corrections {
            let history = try await userFeedbackProcessor.getCorrectionHistory(for: correction.fieldName)
            XCTAssertEqual(history.count, 1)
        }
    }
    
    func testUserFeedbackProcessor_GenerateSmartSuggestions() async throws {
        // Given
        let fieldName = "employee_name"
        let currentValue = "John D"
        let documentType = LiteRTDocumentFormatType.corporate
        
        // Add some correction history
        let correction = createTestCorrection(
            fieldName: fieldName,
            originalValue: "John D",
            correctedValue: "John Doe",
            documentType: documentType
        )
        try await userFeedbackProcessor.captureUserCorrection(correction)
        
        // When
        let suggestions = try await userFeedbackProcessor.generateSmartSuggestions(
            for: fieldName,
            currentValue: currentValue,
            documentType: documentType
        )
        
        // Then
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertTrue(suggestions.allSatisfy { $0.confidence > 0 })
    }
    
    func testUserFeedbackProcessor_ExportLearningData() async throws {
        // Given
        let correction = createTestCorrection()
        try await userFeedbackProcessor.captureUserCorrection(correction)
        
        // When
        let export = try await userFeedbackProcessor.exportLearningData()
        
        // Then
        XCTAssertEqual(export.version, "1.0")
        XCTAssertFalse(export.corrections.isEmpty)
        XCTAssertEqual(export.corrections.first?.fieldName, correction.fieldName)
    }
    
    // MARK: - Personalized Insights Engine Tests
    
    func testPersonalizedInsightsEngine_GenerateInsights() async throws {
        // Given
        let documentType = LiteRTDocumentFormatType.pcda
        let corrections = createTestCorrectionHistory(count: 10, documentType: documentType)
        
        // When
        let insights = try await personalizedInsightsEngine.generatePersonalizedInsights(
            for: documentType,
            userHistory: corrections
        )
        
        // Then
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.allSatisfy { $0.confidence > 0 })
        XCTAssertTrue(insights.contains { $0.type == .accuracyImprovement })
    }
    
    func testPersonalizedInsightsEngine_AnalyzeUserPatterns() async throws {
        // Given
        let corrections = createTestCorrectionHistory(count: 15)
        
        // When
        let profile = try await personalizedInsightsEngine.analyzeUserPatterns(corrections: corrections)
        
        // Then
        XCTAssertEqual(profile.userId, "anonymous_user")
        XCTAssertFalse(profile.documentTypePreferences.isEmpty)
        XCTAssertFalse(profile.fieldAccuracyPatterns.isEmpty)
        XCTAssertFalse(profile.parserPreferences.isEmpty)
    }
    
    func testPersonalizedInsightsEngine_RecommendOptimalParser() async throws {
        // Given
        let corrections = createTestCorrectionHistory(count: 10)
        let profile = try await personalizedInsightsEngine.analyzeUserPatterns(corrections: corrections)
        let documentType = LiteRTDocumentFormatType.military
        
        // When
        let recommendation = try await personalizedInsightsEngine.recommendOptimalParser(
            for: documentType,
            userProfile: profile
        )
        
        // Then
        XCTAssertFalse(recommendation.recommendedParser.isEmpty)
        XCTAssertTrue(recommendation.confidence >= 0.0)
        XCTAssertTrue(recommendation.confidence <= 1.0)
        XCTAssertEqual(recommendation.documentType, documentType)
    }
    
    func testPersonalizedInsightsEngine_GenerateFinancialTrendAnalysis() async throws {
        // Given
        let corrections = createTestCorrectionHistory(count: 20)
        
        // When
        let trendAnalysis = try await personalizedInsightsEngine.generateFinancialTrendAnalysis(
            userHistory: corrections
        )
        
        // Then
        XCTAssertTrue(trendAnalysis.confidence >= 0.0)
        XCTAssertTrue(trendAnalysis.confidence <= 1.0)
        XCTAssertFalse(trendAnalysis.trends.isEmpty)
    }
    
    // MARK: - User Learning Store Tests
    
    func testUserLearningStore_StoreAndRetrieveCorrections() async throws {
        // Given
        let correction = createTestCorrection()
        
        // When
        try await userLearningStore.storeCorrection(correction)
        
        // Then
        let allCorrections = try await userLearningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 1)
        XCTAssertEqual(allCorrections.first?.id, correction.id)
    }
    
    func testUserLearningStore_GetCorrectionsByField() async throws {
        // Given
        let fieldName = "test_field"
        let documentType = LiteRTDocumentFormatType.corporate
        let correction1 = createTestCorrection(fieldName: fieldName, documentType: documentType)
        let correction2 = createTestCorrection(fieldName: "other_field", documentType: documentType)
        
        try await userLearningStore.storeCorrection(correction1)
        try await userLearningStore.storeCorrection(correction2)
        
        // When
        let fieldCorrections = try await userLearningStore.getCorrections(
            for: fieldName,
            documentType: documentType
        )
        
        // Then
        XCTAssertEqual(fieldCorrections.count, 1)
        XCTAssertEqual(fieldCorrections.first?.fieldName, fieldName)
    }
    
    func testUserLearningStore_GetUserPatterns() async throws {
        // Given
        let documentType = LiteRTDocumentFormatType.pcda
        let corrections = createTestCorrectionHistory(count: 5, documentType: documentType)
        
        for correction in corrections {
            try await userLearningStore.storeCorrection(correction)
        }
        
        // When
        let patterns = try await userLearningStore.getUserPatterns(for: documentType)
        
        // Then
        XCTAssertFalse(patterns.isEmpty)
        XCTAssertTrue(patterns.allSatisfy { $0.confidence > 0 })
    }
    
    // MARK: - Performance Tracker Tests
    
    func testPerformanceTracker_RecordPerformance() async throws {
        // Given
        let metrics = createTestPerformanceMetrics()
        
        // When
        try await performanceTracker.recordPerformance(metrics)
        
        // Then
        let history = try await performanceTracker.getPerformanceHistory(
            for: metrics.parserName,
            days: 1
        )
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.parserName, metrics.parserName)
    }
    
    func testPerformanceTracker_CalculateTrends() async throws {
        // Given
        let parserName = "TestParser"
        
        // Record multiple performance metrics
        for i in 0..<5 {
            let metrics = createTestPerformanceMetrics(
                parserName: parserName,
                accuracy: Double(i) / 10.0 + 0.5 // Increasing accuracy
            )
            try await performanceTracker.recordPerformance(metrics)
        }
        
        // When
        let trends = try await performanceTracker.calculatePerformanceTrends(for: parserName)
        
        // Then
        XCTAssertEqual(trends.parserName, parserName)
        XCTAssertTrue(trends.accuracyTrend > 0) // Should be positive (improving)
        XCTAssertEqual(trends.dataPoints, 5)
    }
    
    func testPerformanceTracker_GenerateReport() async throws {
        // Given
        let metrics = createTestPerformanceMetrics()
        try await performanceTracker.recordPerformance(metrics)
        
        // When
        let report = try await performanceTracker.generatePerformanceReport()
        
        // Then
        XCTAssertEqual(report.totalDocumentsProcessed, 1)
        XCTAssertTrue(report.averageAccuracy > 0)
        XCTAssertFalse(report.parserStatistics.isEmpty)
    }
    
    // MARK: - Privacy Preserving Learning Manager Tests
    
    func testPrivacyManager_AnonymizeCorrection() async throws {
        // Given
        let correction = createTestCorrection()
        
        // When
        let anonymized = try await privacyManager.anonymizeCorrection(correction)
        
        // Then
        XCTAssertNotEqual(anonymized.id, correction.id) // Should have new ID
        XCTAssertNotEqual(anonymized.fieldName, correction.fieldName) // Should be anonymized
        XCTAssertEqual(anonymized.documentType, .unknown) // Should be anonymized
    }
    
    func testPrivacyManager_ValidateCompliance() async throws {
        // When
        let compliance = try await privacyManager.validatePrivacyCompliance()
        
        // Then
        XCTAssertTrue(compliance.isCompliant)
        XCTAssertTrue(compliance.complianceScore >= 0)
        XCTAssertTrue(compliance.complianceScore <= 100)
    }
    
    func testPrivacyManager_GeneratePrivacyReport() async throws {
        // When
        let report = try await privacyManager.generatePrivacyReport()
        
        // Then
        XCTAssertTrue(report.complianceStatus)
        XCTAssertFalse(report.encryptionStatus.isEmpty)
        XCTAssertFalse(report.anonymizationMethods.isEmpty)
        XCTAssertFalse(report.userRights.isEmpty)
    }
    
    // MARK: - Learning Enhanced Parser Tests
    
    func testLearningEnhancedParser_ParseWithLearning() async throws {
        // Given
        let pdfDocument = createTestPDFDocument()
        let documentType = LiteRTDocumentFormatType.corporate
        
        // When
        let result = try await learningEnhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // Then
        XCTAssertTrue(result.confidence >= 0.0)
        XCTAssertTrue(result.confidence <= 1.0)
        XCTAssertTrue(result.accuracy >= 0.0)
        XCTAssertTrue(result.accuracy <= 1.0)
        XCTAssertTrue(result.processingTime > 0)
    }
    
    func testLearningEnhancedParser_ApplyAdaptation() async throws {
        // Given
        let adaptation = ParserAdaptation(
            parserName: "TestParser",
            adaptations: ["field1": 0.1, "field2": -0.05],
            confidenceMultiplier: 0.9,
            priority: .medium
        )
        
        // When
        try await learningEnhancedParser.applyAdaptation(adaptation)
        
        // Then
        let adjustments = await learningEnhancedParser.getConfidenceAdjustments()
        XCTAssertFalse(adjustments.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_FullLearningCycle() async throws {
        // Given
        let documentType = LiteRTDocumentFormatType.pcda
        let pdfDocument = createTestPDFDocument()
        
        // 1. Initial parsing
        let initialResult = try await learningEnhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // 2. User provides corrections
        let corrections = [
            createTestCorrection(fieldName: "salary", originalValue: "50000", correctedValue: "50,000"),
            createTestCorrection(fieldName: "name", originalValue: "J Doe", correctedValue: "John Doe")
        ]
        
        for correction in corrections {
            try await userFeedbackProcessor.captureUserCorrection(correction)
        }
        
        // 3. Generate insights
        let insights = try await personalizedInsightsEngine.generatePersonalizedInsights(
            for: documentType,
            userHistory: corrections
        )
        
        // 4. Parse again with learning applied
        let enhancedResult = try await learningEnhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // Then
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(enhancedResult.suggestions.count >= initialResult.suggestions.count)
    }
    
    func testIntegration_PerformanceImprovementOverTime() async throws {
        // Given
        let parserName = "TestParser"
        let documentType = LiteRTDocumentFormatType.military
        
        var accuracies: [Double] = []
        
        // Simulate multiple parsing sessions with learning
        for i in 0..<10 {
            // Record performance (simulating improvement over time)
            let accuracy = 0.6 + (Double(i) * 0.03) // Gradual improvement
            let metrics = createTestPerformanceMetrics(
                parserName: parserName,
                accuracy: accuracy,
                documentType: documentType
            )
            
            try await performanceTracker.recordPerformance(metrics)
            accuracies.append(accuracy)
            
            // Add user corrections (more corrections early on, fewer later)
            let correctionCount = max(1, 5 - i/2)
            for j in 0..<correctionCount {
                let correction = createTestCorrection(
                    fieldName: "field\(j)",
                    documentType: documentType,
                    parserUsed: parserName
                )
                try await adaptiveLearningEngine.processUserCorrection(correction)
            }
        }
        
        // When
        let trends = try await performanceTracker.calculatePerformanceTrends(for: parserName)
        let report = try await performanceTracker.generatePerformanceReport()
        
        // Then
        XCTAssertTrue(trends.accuracyTrend > 0, "Accuracy should show improvement trend")
        XCTAssertEqual(trends.dataPoints, 10)
        XCTAssertTrue(report.averageAccuracy > 0.6)
    }
    
    // MARK: - Helper Methods
    
    private func createTestCorrection(
        fieldName: String = "test_field",
        originalValue: String = "original",
        correctedValue: String = "corrected",
        documentType: LiteRTDocumentFormatType = .corporate,
        parserUsed: String = "TestParser"
    ) -> UserCorrection {
        return UserCorrection(
            fieldName: fieldName,
            originalValue: originalValue,
            correctedValue: correctedValue,
            documentType: documentType,
            parserUsed: parserUsed,
            timestamp: Date(),
            confidenceImpact: -0.1,
            extractedPattern: nil,
            suggestedValidationRule: nil,
            totalExtractions: 1
        )
    }
    
    private func createTestCorrectionHistory(
        count: Int,
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> [UserCorrection] {
        return (0..<count).map { i in
            createTestCorrection(
                fieldName: "field\(i % 5)", // Create some overlap
                originalValue: "value\(i)",
                correctedValue: "corrected\(i)",
                documentType: documentType,
                parserUsed: "Parser\(i % 3)" // Vary parsers
            )
        }
    }
    
    private func createTestPerformanceMetrics(
        parserName: String = "TestParser",
        accuracy: Double = 0.8,
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> ParserPerformanceMetrics {
        return ParserPerformanceMetrics(
            parserName: parserName,
            documentType: documentType,
            processingTime: 2.5,
            accuracy: accuracy,
            fieldsExtracted: 10,
            fieldsCorrect: Int(accuracy * 10),
            timestamp: Date(),
            memoryUsage: 1024 * 1024, // 1MB
            cpuUsage: 0.3
        )
    }
    
    private func createTestPDFDocument() -> PDFDocument {
        // Create a minimal PDF document for testing
        let pdfData = Data() // In a real test, this would be actual PDF data
        return PDFDocument(data: pdfData) ?? PDFDocument()
    }
}

// MARK: - Mock Implementations
// Note: Using centralized MockPayslipParser from Mocks/PDF/MockPDFAdvancedServices.swift

// Note: LiteRTDocumentFormatType Codable conformance already exists in main module

// MARK: - Test Extensions

extension UserCorrection: @retroactive Equatable {
    public static func == (lhs: UserCorrection, rhs: UserCorrection) -> Bool {
        return lhs.id == rhs.id &&
               lhs.fieldName == rhs.fieldName &&
               lhs.originalValue == rhs.originalValue &&
               lhs.correctedValue == rhs.correctedValue
    }
}
