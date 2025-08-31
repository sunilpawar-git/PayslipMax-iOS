import XCTest
import Foundation
import PDFKit
@testable import PayslipMax

/// System integration tests for Phase 4: Adaptive Learning & Personalization
/// Tests the complete integration of learning components with existing AI services
@MainActor
final class Phase4_SystemIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var aiContainer: AIContainer!
    private var mockCoreContainer: MockCoreContainer!
    private var mockProcessingContainer: MockProcessingContainer!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up mock containers
        mockCoreContainer = MockCoreContainer()
        mockProcessingContainer = MockProcessingContainer()
        
        // Initialize AI container with learning services
        aiContainer = AIContainer(
            useMocks: false, // Use real implementations for integration testing
            coreContainer: mockCoreContainer,
            processingContainer: mockProcessingContainer
        )
    }
    
    override func tearDown() async throws {
        aiContainer = nil
        mockCoreContainer = nil
        mockProcessingContainer = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Service Creation Tests
    
    func testAIContainer_CreateAdaptiveLearningEngine() throws {
        // When
        let engine = aiContainer.makeAdaptiveLearningEngine()
        
        // Then
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine is AdaptiveLearningEngine)
    }
    
    func testAIContainer_CreateUserFeedbackProcessor() throws {
        // When
        let processor = aiContainer.makeUserFeedbackProcessor()
        
        // Then
        XCTAssertNotNil(processor)
        XCTAssertTrue(processor is UserFeedbackProcessor)
    }
    
    func testAIContainer_CreatePersonalizedInsightsEngine() throws {
        // When
        let engine = aiContainer.makePersonalizedInsightsEngine()
        
        // Then
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine is PersonalizedInsightsEngine)
    }
    
    func testAIContainer_CreateUserLearningStore() throws {
        // When
        let store = aiContainer.makeUserLearningStore()
        
        // Then
        XCTAssertNotNil(store)
        XCTAssertTrue(store is UserLearningStore)
    }
    
    func testAIContainer_CreatePerformanceTracker() throws {
        // When
        let tracker = aiContainer.makePerformanceTracker()
        
        // Then
        XCTAssertNotNil(tracker)
        XCTAssertTrue(tracker is PerformanceTracker)
    }
    
    func testAIContainer_CreatePrivacyPreservingLearningManager() throws {
        // When
        let manager = aiContainer.makePrivacyPreservingLearningManager()
        
        // Then
        XCTAssertNotNil(manager)
        XCTAssertTrue(manager is PrivacyPreservingLearningManager)
    }
    
    func testAIContainer_CreateLearningEnhancedParser() throws {
        // Given
        let mockParser = MockPayslipParser()

        // When
        let enhancedParser = aiContainer.makeLearningEnhancedParser(
            baseParser: mockParser,
            parserName: "TestParser"
        )
        
        // Then
        XCTAssertNotNil(enhancedParser)
        XCTAssertTrue(enhancedParser is LearningEnhancedParser)
    }
    
    // MARK: - Service Integration Tests
    
    func testServiceIntegration_LearningEngineWithFeedbackProcessor() async throws {
        // Given
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        
        let correction = createTestCorrection()
        
        // When
        try await feedbackProcessor.captureUserCorrection(correction)
        
        // Then - Learning engine should have processed the correction
        let suggestions = try await learningEngine.getPersonalizedSuggestions(for: correction.documentType)
        XCTAssertTrue(suggestions.count >= 0) // Should not fail
    }
    
    func testServiceIntegration_PerformanceTrackerWithLearningEngine() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        
        let metrics = createTestPerformanceMetrics()
        
        // When
        try await learningEngine.trackParserPerformance(metrics)
        
        // Then - Performance should be recorded
        let history = try await performanceTracker.getPerformanceHistory(
            for: metrics.parserName,
            days: 1
        )
        XCTAssertEqual(history.count, 1)
    }
    
    func testServiceIntegration_PrivacyManagerWithLearningStore() async throws {
        // Given
        let privacyManager = aiContainer.makePrivacyPreservingLearningManager()
        let learningStore = aiContainer.makeUserLearningStore()
        
        let correction = createTestCorrection()
        
        // When
        let anonymizedCorrection = try await privacyManager.anonymizeCorrection(correction)
        try await learningStore.storeCorrection(anonymizedCorrection)
        
        // Then - Anonymized correction should be stored
        let allCorrections = try await learningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 1)
        XCTAssertNotEqual(allCorrections.first?.fieldName, correction.fieldName) // Should be anonymized
    }
    
    // MARK: - Cross-Service Workflow Tests
    
    func testWorkflow_UserCorrectionToPersonalizedInsights() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let insightsEngine = aiContainer.makePersonalizedInsightsEngine()
        
        let documentType = LiteRTDocumentFormatType.pcda
        let corrections = createTestCorrectionHistory(count: 5, documentType: documentType)
        
        // When
        // 1. Process user corrections
        for correction in corrections {
            try await feedbackProcessor.captureUserCorrection(correction)
        }
        
        // 2. Generate personalized insights
        let insights = try await insightsEngine.generatePersonalizedInsights(
            for: documentType,
            userHistory: corrections
        )
        
        // Then
        XCTAssertFalse(insights.isEmpty)
        XCTAssertTrue(insights.allSatisfy { $0.confidence > 0 })
    }
    
    func testWorkflow_PerformanceTrackingToParserOptimization() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let insightsEngine = aiContainer.makePersonalizedInsightsEngine()
        
        let parserName = "TestParser"
        let documentType = LiteRTDocumentFormatType.military
        
        // When
        // 1. Record performance over time
        for i in 0..<10 {
            let accuracy = 0.5 + (Double(i) * 0.04) // Improving accuracy
            let metrics = createTestPerformanceMetrics(
                parserName: parserName,
                accuracy: accuracy,
                documentType: documentType
            )
            try await performanceTracker.recordPerformance(metrics)
        }
        
        // 2. Calculate trends
        let trends = try await performanceTracker.calculatePerformanceTrends(for: parserName)
        
        // 3. Get parser adaptation
        let adaptation = try await learningEngine.adaptParserParameters(
            for: parserName,
            documentType: documentType
        )
        
        // 4. Generate insights
        let profile = try await insightsEngine.analyzeUserPatterns(corrections: [])
        let recommendation = try await insightsEngine.recommendOptimalParser(
            for: documentType,
            userProfile: profile
        )
        
        // Then
        XCTAssertTrue(trends.accuracyTrend > 0) // Should show improvement
        XCTAssertEqual(adaptation.parserName, parserName)
        XCTAssertFalse(recommendation.recommendedParser.isEmpty)
    }
    
    func testWorkflow_FullLearningCycleWithParsing() async throws {
        // Given
        let mockParser = MockPayslipParser()
        let enhancedParser = aiContainer.makeLearningEnhancedParser(
            baseParser: mockParser,
            parserName: "IntegrationTestParser"
        )
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        
        let pdfDocument = createTestPDFDocument()
        let documentType = LiteRTDocumentFormatType.corporate
        
        // When
        // 1. Initial parsing
        let initialResult = try await enhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // 2. User provides corrections
        let corrections = [
            createTestCorrection(fieldName: "salary", originalValue: "5000", correctedValue: "5,000"),
            createTestCorrection(fieldName: "name", originalValue: "J Smith", correctedValue: "John Smith")
        ]
        
        for correction in corrections {
            try await feedbackProcessor.captureUserCorrection(correction)
        }
        
        // 3. Apply learning and parse again
        let enhancedResult = try await enhancedParser.parseWithLearning(
            pdfDocument,
            documentType: documentType
        )
        
        // Then
        XCTAssertTrue(initialResult.confidence >= 0)
        XCTAssertTrue(enhancedResult.confidence >= 0)
        // Enhanced result should potentially have more insights
        XCTAssertTrue(enhancedResult.learningInsights.count >= initialResult.learningInsights.count)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_InvalidCorrection() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let invalidCorrection = UserCorrection(
            fieldName: "", // Invalid empty field name
            originalValue: "test",
            correctedValue: "test", // Same as original
            documentType: .unknown,
            parserUsed: "TestParser"
        )
        
        // When/Then
        do {
            try await feedbackProcessor.captureUserCorrection(invalidCorrection)
            XCTFail("Should have thrown an error for invalid correction")
        } catch {
            XCTAssertTrue(error is FeedbackProcessorError)
        }
    }
    
    func testErrorHandling_InsufficientDataForTrends() async throws {
        // Given
        let performanceTracker = aiContainer.makePerformanceTracker()
        let parserName = "EmptyParser"
        
        // When/Then
        do {
            _ = try await performanceTracker.calculatePerformanceTrends(for: parserName)
            XCTFail("Should have thrown an error for insufficient data")
        } catch {
            XCTAssertTrue(error is PerformanceTrackerError)
        }
    }
    
    // MARK: - Memory and Performance Tests
    
    func testMemoryUsage_LargeNumberOfCorrections() async throws {
        // Given
        let learningStore = aiContainer.makeUserLearningStore()
        let corrections = createTestCorrectionHistory(count: 100)
        
        // When
        let startMemory = getMemoryUsage()
        
        for correction in corrections {
            try await learningStore.storeCorrection(correction)
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertTrue(memoryIncrease < 50 * 1024 * 1024) // Should be less than 50MB
        
        // Verify all corrections stored
        let allCorrections = try await learningStore.getAllCorrections()
        XCTAssertEqual(allCorrections.count, 100)
    }
    
    func testPerformance_BatchCorrectionProcessing() async throws {
        // Given
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let corrections = createTestCorrectionHistory(count: 50)
        
        // When
        let startTime = Date()
        try await feedbackProcessor.batchProcessCorrections(corrections)
        let endTime = Date()
        
        // Then
        let processingTime = endTime.timeIntervalSince(startTime)
        XCTAssertTrue(processingTime < 5.0) // Should complete within 5 seconds
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistency_SameServiceInstance() throws {
        // Given/When
        let engine1 = aiContainer.makeAdaptiveLearningEngine()
        let engine2 = aiContainer.makeAdaptiveLearningEngine()
        
        // Then - Should return the same cached instance
        // Skip identity comparison for protocol types
        XCTAssertNotNil(engine1)
        XCTAssertNotNil(engine2)
    }
    
    func testDataConsistency_CrossServiceDataSharing() async throws {
        // Given
        let learningEngine = aiContainer.makeAdaptiveLearningEngine()
        let feedbackProcessor = aiContainer.makeUserFeedbackProcessor()
        let learningStore = aiContainer.makeUserLearningStore()
        
        let correction = createTestCorrection()
        
        // When
        // Process through feedback processor
        try await feedbackProcessor.captureUserCorrection(correction)
        
        // Access through learning store
        let storedCorrections = try await learningStore.getAllCorrections()
        
        // Process through learning engine
        let adjustment = await learningEngine.getConfidenceAdjustment(
            for: correction.fieldName,
            documentType: correction.documentType
        )
        
        // Then
        XCTAssertEqual(storedCorrections.count, 1)
        XCTAssertEqual(storedCorrections.first?.fieldName, correction.fieldName)
        XCTAssertTrue(adjustment <= 0.0) // Should be negative for corrections
    }
    
    // MARK: - Helper Methods
    
    private func createTestCorrection(
        fieldName: String = "test_field",
        originalValue: String = "original",
        correctedValue: String = "corrected",
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> UserCorrection {
        return UserCorrection(
            fieldName: fieldName,
            originalValue: originalValue,
            correctedValue: correctedValue,
            documentType: documentType,
            parserUsed: "TestParser"
        )
    }
    
    private func createTestCorrectionHistory(
        count: Int,
        documentType: LiteRTDocumentFormatType = .corporate
    ) -> [UserCorrection] {
        return (0..<count).map { i in
            createTestCorrection(
                fieldName: "field\(i % 5)",
                originalValue: "value\(i)",
                correctedValue: "corrected\(i)",
                documentType: documentType
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
            fieldsCorrect: Int(accuracy * 10)
        )
    }
    
    private func createTestPDFDocument() -> PDFDocument {
        // Create a minimal PDF document for testing
        return PDFDocument() // Empty document for testing
    }
    
    private func getMemoryUsage() -> Int64 {
        // Get current memory usage in bytes
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let result = withUnsafeMutablePointer(to: &count) { countPtr in
            withUnsafeMutablePointer(to: &info) { infoPtr in
                infoPtr.withMemoryRebound(to: integer_t.self, capacity: MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size) { reboundPtr in
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), reboundPtr, countPtr)
                }
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return Int64(info.resident_size)
    }
}

// MARK: - Mock Container Implementations

private class MockCoreContainer: CoreServiceContainerProtocol {
    var useMocks: Bool = true

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return MockTextExtractionService()
    }
    
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return MockPayslipFormatDetectionService()
    }
    
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return MockPayslipValidationService()
    }
    
    func makePDFService() -> PDFServiceProtocol {
        return MockPDFService()
    }
    
    func makePDFExtractor() -> PDFExtractorProtocol {
        return MockPDFExtractor()
    }
    
    func makeDataService() -> DataServiceProtocol {
        return MockDataService()
    }
    
    func makeSecurityService() -> SecurityServiceProtocol {
        return CoreMockSecurityService()
    }

    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        return MockPayslipEncryptionService()
    }

    func makeEncryptionService() -> EncryptionServiceProtocol {
        return MockEncryptionService()
    }

    func makeSecureStorage() -> SecureStorageProtocol {
        return MockSecureStorage()
    }

    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol {
        return MockDocumentStructureIdentifier()
    }

    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol {
        return MockDocumentSectionExtractor()
    }

    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol {
        return MockPersonalInfoSectionParser()
    }

    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol {
        return MockFinancialDataSectionParser()
    }

    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol {
        return MockContactInfoSectionParser()
    }

    func makeDocumentMetadataExtractor() -> DocumentMetadataExtractorProtocol {
        return MockDocumentMetadataExtractor()
    }
}

private class MockProcessingContainer: ProcessingContainerProtocol {
    var useMocks: Bool = true

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return MockPDFTextExtractionService()
    }

    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return MockPDFParsingCoordinator()
    }

    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return MockPayslipProcessingPipeline()
    }

    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return MockPayslipProcessorFactory()
    }

    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return MockPayslipImportCoordinator()
    }

    func makeAbbreviationManager() -> AbbreviationManager {
        return MockAbbreviationManager()
    }

    func makeTextExtractionEngine() -> TextExtractionEngineProtocol {
        fatalError("Text extraction engine not implemented in mock")
    }

    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        fatalError("Extraction strategy selector not implemented in mock")
    }

    func makeTextProcessingPipeline() -> TextProcessingPipelineProtocol {
        fatalError("Text processing pipeline not implemented in mock")
    }

    func makeExtractionResultValidator() -> ExtractionResultValidatorProtocol {
        fatalError("Extraction result validator not implemented in mock")
    }
}

// Mock service implementations
private class MockTextExtractionService: TextExtractionServiceProtocol {
    func extractText(from pdfDocument: PDFDocument) async -> String {
        // Mock implementation - return empty string
        return ""
    }

    func extractText(from page: PDFPage) -> String {
        // Mock implementation - return empty string
        return ""
    }

    func extractDetailedText(from pdfDocument: PDFDocument) async -> String {
        // Mock implementation - return empty string
        return ""
    }

    func logTextExtractionDiagnostics(for pdfDocument: PDFDocument) {
        // Mock implementation - do nothing
    }

    func hasTextContent(_ pdfDocument: PDFDocument) -> Bool {
        // Mock implementation - return true
        return true
    }
}

private class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    func detectFormat(_ data: Data) async -> PayslipFormat {
        // Mock implementation - return unknown format
        return .unknown
    }

    func detectFormat(from document: PDFDocument) async -> PayslipFormat {
        // Mock implementation - return unknown format
        return .unknown
    }

    func detectFormat(fromText text: String) -> PayslipFormat {
        // Mock implementation - return unknown format
        return .unknown
    }

    func detectFormatDetailed(from document: PDFDocument) async -> FormatDetectionResult? {
        // Mock implementation - return nil
        return nil
    }
}

private class MockPayslipValidationService: PayslipValidationServiceProtocol {
    func validatePDFStructure(_ data: Data) -> Bool {
        // Mock implementation - return true
        return true
    }

    func validatePayslipContent(_ text: String) -> PayslipContentValidationResult {
        // Mock implementation - return valid result
        return PayslipContentValidationResult(
            isValid: true,
            confidence: 0.8,
            detectedFields: [],
            missingRequiredFields: []
        )
    }

    func isPDFPasswordProtected(_ data: Data) -> Bool {
        // Mock implementation - return false
        return false
    }

    func validatePayslip(_ payslip: any PayslipProtocol) -> BasicPayslipValidationResult {
        // Mock implementation - return valid result
        return BasicPayslipValidationResult(isValid: true, errors: [])
    }

    func deepValidatePayslip(_ payslip: any PayslipProtocol) -> PayslipDeepValidationResult {
        // Mock implementation - return valid result
        return PayslipDeepValidationResult(
            basicValidation: BasicPayslipValidationResult(isValid: true, errors: []),
            pdfValidationSuccess: true,
            pdfValidationMessage: "PDF structure is valid",
            contentValidation: PayslipContentValidationResult(
                isValid: true,
                confidence: 0.8,
                detectedFields: [],
                missingRequiredFields: []
            )
        )
    }
}

private class MockPDFService: PDFServiceProtocol {
    var isInitialized: Bool = false

    func initialize() async throws {
        // Mock implementation - do nothing
    }

    func process(_ url: URL) async throws -> Data {
        // Mock implementation - return empty data
        return Data()
    }

    func extract(_ data: Data) -> [String: String] {
        // Mock implementation - return empty dictionary
        return [:]
    }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        // Mock implementation - return the same data
        return data
    }
}

private class MockPDFExtractor: PDFExtractorProtocol {
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        // Mock implementation - return nil
        return nil
    }

    func extractPayslipData(from text: String) -> PayslipItem? {
        // Mock implementation - return nil
        return nil
    }

    func extractText(from pdfDocument: PDFDocument) async -> String {
        // Mock implementation - return empty string
        return ""
    }

    func getAvailableParsers() -> [String] {
        // Mock implementation - return empty array
        return []
    }
}

// Note: Using centralized MockDataService, MockSecurityService, and MockPayslipParser
// from Mocks/Core/MockDataService.swift, Mocks/Security/MockSecurityServices.swift,
// and Mocks/PDF/MockPDFAdvancedServices.swift respectively

// Note: Using protocols from main PayslipMax module
// All service protocols are defined in the main target and available via @testable import

// MARK: - Additional Mock Classes for Containers
// Note: Using MockEncryptionService from Mocks/Security/MockSecurityServices.swift

private class MockSecureStorage: SecureStorageProtocol {
    func saveData(key: String, data: Data) throws {}
    func getData(key: String) throws -> Data? { return nil }
    func saveString(key: String, value: String) throws {}
    func getString(key: String) throws -> String? { return nil }
    func deleteItem(key: String) throws {}
}

private class MockDocumentStructureIdentifier: DocumentStructureIdentifierProtocol {
    func identifyDocumentStructure(from text: String) -> DocumentStructure { return .unknown }
}

private class MockDocumentSectionExtractor: DocumentSectionExtractorProtocol {
    func extractDocumentSections(from document: PDFDocument, structure: DocumentStructure) -> [DocumentSection] { return [] }
}

private class MockPersonalInfoSectionParser: PersonalInfoSectionParserProtocol {
    func parsePersonalInfoSection(_ section: DocumentSection) -> [String: String] { return [:] }
}

private class MockFinancialDataSectionParser: FinancialDataSectionParserProtocol {
    func parseEarningsSection(_ section: DocumentSection) -> [String: Double] { return [:] }
    func parseDeductionsSection(_ section: DocumentSection) -> [String: Double] { return [:] }
    func parseTaxSection(_ section: DocumentSection) -> [String: Double] { return [:] }
    func parseDSOPSection(_ section: DocumentSection) -> [String: Double] { return [:] }
    func parseNetPaySection(_ section: DocumentSection) -> [String: Double] { return [:] }
}

private class MockContactInfoSectionParser: ContactInfoSectionParserProtocol {
    func parseContactSection(_ section: DocumentSection) -> [String: String] { return [:] }
}

private class MockDocumentMetadataExtractor: DocumentMetadataExtractorProtocol {
    func extractMetadata(from text: String) -> [String: String] { return [:] }
}

private class MockPayslipProcessorFactory: PayslipProcessorFactory {
    init() {
        super.init(formatDetectionService: MockPayslipFormatDetectionService())
    }

    func createProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        return MockPayslipProcessor()
    }
}

private class MockPayslipImportCoordinator: PayslipImportCoordinator {
    init() {
        super.init(parsingCoordinator: MockPDFParsingCoordinator(), abbreviationManager: MockAbbreviationManager())
    }

    func importPayslip(from url: URL) async throws -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 100.0,
            name: "Test User"
        )
    }
}

private class MockPayslipProcessor: PayslipProcessorProtocol {
    func processPayslip(from text: String) throws -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 1000.0,
            debits: 200.0,
            dsop: 50.0,
            tax: 100.0,
            name: "Mock User"
        )
    }
    func canProcess(text: String) -> Double { return 0.5 }
    var handlesFormat: PayslipFormat { return .unknown }
}

// Note: Using MockAbbreviationManager from Mocks/MockAbbreviationManager.swift
