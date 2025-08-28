import Foundation
import PDFKit
import UIKit

/// Container for AI-powered services that enhance document processing capabilities.
/// Handles LiteRT integration, intelligent format detection, and semantic analysis.
@MainActor
class AIContainer: AIContainerProtocol {

    // MARK: - Properties

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    /// Core service container for accessing base services
    private let coreContainer: CoreServiceContainerProtocol

    /// Processing container for accessing text extraction services
    private let processingContainer: ProcessingContainerProtocol

    // MARK: - Private Cached Services

    /// Cached LiteRT service instance
    private var _liteRTService: LiteRTServiceProtocol?

    /// Cached smart format detector instance
    private var _smartFormatDetector: SmartFormatDetectorProtocol?

    /// Cached AI parser selector instance
    private var _aiParserSelector: AIPayslipParserSelectorProtocol?

    /// Cached document semantic analyzer instance
    private var _documentSemanticAnalyzer: DocumentSemanticAnalyzerProtocol?

    // MARK: - Initialization

    init(useMocks: Bool = false,
         coreContainer: CoreServiceContainerProtocol,
         processingContainer: ProcessingContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
        self.processingContainer = processingContainer
    }

    // MARK: - AI Core Services

    /// Creates a LiteRT service for on-device AI processing
    func makeLiteRTService() -> LiteRTServiceProtocol {
        if let cached = _liteRTService {
            return cached
        }

        #if DEBUG
        if useMocks {
            // Return a mock LiteRT service for testing
            let mockService = MockLiteRTService()
            _liteRTService = mockService
            return mockService
        }
        #endif

        let service = LiteRTService()
        _liteRTService = service
        return service
    }

    /// Creates a smart format detector with AI capabilities
    func makeSmartFormatDetector() -> SmartFormatDetectorProtocol {
        if let cached = _smartFormatDetector {
            return cached
        }

        #if DEBUG
        if useMocks {
            let mockDetector = MockSmartFormatDetector()
            _smartFormatDetector = mockDetector
            return mockDetector
        }
        #endif

        let liteRTService = makeLiteRTService() as! LiteRTService
        let detector = SmartFormatDetector(
            liteRTService: liteRTService,
            textExtractionService: coreContainer.makeTextExtractionService()
        )
        _smartFormatDetector = detector
        return detector
    }

    /// Creates an AI-powered parser selector
    func makeAIPayslipParserSelector() -> AIPayslipParserSelectorProtocol {
        if let cached = _aiParserSelector {
            return cached
        }

        #if DEBUG
        if useMocks {
            let mockSelector = MockAIPayslipParserSelector()
            _aiParserSelector = mockSelector
            return mockSelector
        }
        #endif

        let liteRTService = makeLiteRTService() as! LiteRTService
        let parserRegistry = StandardPayslipParserRegistry()
        let selector = AIPayslipParserSelector(
            smartFormatDetector: makeSmartFormatDetector(),
            liteRTService: liteRTService,
            parserRegistry: parserRegistry,
            textExtractionService: coreContainer.makeTextExtractionService()
        )
        _aiParserSelector = selector
        return selector
    }

    /// Creates a document semantic analyzer
    func makeDocumentSemanticAnalyzer() -> DocumentSemanticAnalyzerProtocol {
        if let cached = _documentSemanticAnalyzer {
            return cached
        }

        #if DEBUG
        if useMocks {
            let mockAnalyzer = MockDocumentSemanticAnalyzer()
            _documentSemanticAnalyzer = mockAnalyzer
            return mockAnalyzer
        }
        #endif

        let liteRTService = makeLiteRTService() as! LiteRTService
        let analyzer = DocumentSemanticAnalyzer(
            liteRTService: liteRTService,
            textExtractionService: coreContainer.makeTextExtractionService()
        )
        _documentSemanticAnalyzer = analyzer
        return analyzer
    }

    // MARK: - Enhanced Services

    /// Creates an enhanced format detection service with AI capabilities
    func makeEnhancedFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        #if DEBUG
        if useMocks {
            return MockPayslipFormatDetectionService()
        }
        #endif

        return PayslipFormatDetectionService(
            textExtractionService: coreContainer.makeTextExtractionService(),
            smartFormatDetector: makeSmartFormatDetector(),
            useAI: true
        )
    }

    // MARK: - Feature Flags

    /// Creates LiteRT feature flags for controlling AI capabilities
    func makeLiteRTFeatureFlags() -> LiteRTFeatureFlags {
        return LiteRTFeatureFlags.shared
    }
}

// MARK: - AI Container Protocol

@MainActor
protocol AIContainerProtocol {
    func makeLiteRTService() -> LiteRTServiceProtocol
    func makeSmartFormatDetector() -> SmartFormatDetectorProtocol
    func makeAIPayslipParserSelector() -> AIPayslipParserSelectorProtocol
    func makeDocumentSemanticAnalyzer() -> DocumentSemanticAnalyzerProtocol
    func makeEnhancedFormatDetectionService() -> PayslipFormatDetectionServiceProtocol
    func makeLiteRTFeatureFlags() -> LiteRTFeatureFlags
}

// MARK: - Mock Implementations

#if DEBUG
private class MockLiteRTService: LiteRTServiceProtocol {
    func initializeService() async throws {
        // Mock initialization - do nothing
    }

    func isServiceAvailable() -> Bool {
        return true
    }

    func processDocument(data: Data) async throws -> LiteRTDocumentAnalysisResult {
        // Mock implementation - return empty result
        return LiteRTDocumentAnalysisResult(
            tableStructure: LiteRTTableStructure(
                bounds: CGRect.zero,
                columns: [],
                rows: [],
                cells: [],
                confidence: 0.5,
                isPCDAFormat: false
            ),
            textAnalysis: LiteRTTextAnalysisResult(
                extractedText: "",
                textElements: [],
                confidence: 0.5
            ),
            formatAnalysis: LiteRTDocumentFormatAnalysis(
                formatType: .unknown,
                layoutType: .linear,
                languageInfo: LiteRTLanguageInfo(
                    primaryLanguage: "en",
                    secondaryLanguage: nil,
                    englishRatio: 1.0,
                    hindiRatio: 0.0,
                    isBilingual: false
                ),
                confidence: 0.5,
                keyIndicators: []
            ),
            confidence: 0.5
        )
    }

    func detectTableStructure(in image: UIImage) async throws -> LiteRTTableStructure {
        // Mock implementation - return empty structure
        return LiteRTTableStructure(
            bounds: CGRect.zero,
            columns: [],
            rows: [],
            cells: [],
            confidence: 0.5,
            isPCDAFormat: false
        )
    }

    func analyzeDocumentFormat(text: String) async throws -> LiteRTDocumentFormatAnalysis {
        // Mock implementation - return standard format
        return LiteRTDocumentFormatAnalysis(
            formatType: .unknown,
            layoutType: .linear,
            languageInfo: LiteRTLanguageInfo(
                primaryLanguage: "en",
                secondaryLanguage: nil,
                englishRatio: 1.0,
                hindiRatio: 0.0,
                isBilingual: false
            ),
            confidence: 0.5,
            keyIndicators: []
        )
    }

    func classifyDocument(text: String) async throws -> (format: PayslipFormat, confidence: Double) {
        // Simple mock implementation that returns standard format
        return (.standard, 0.5)
    }
}

private class MockSmartFormatDetector: SmartFormatDetectorProtocol {
    func detectFormat(from document: PDFDocument) async -> (PayslipFormat, Double) {
        return (.standard, 0.5)
    }

    func analyzeDocumentStructure(text: String) -> FormatDetectionResult {
        return FormatDetectionResult(
            format: .standard,
            confidence: 0.5,
            features: [],
            reasoning: "Mock implementation"
        )
    }

    func extractSemanticFeatures(from text: String) -> [SemanticFeature] {
        return []
    }
}

private class MockAIPayslipParserSelector: AIPayslipParserSelectorProtocol {
    func selectOptimalParser(for document: PDFDocument) async -> ParserSelectionResult {
        return ParserSelectionResult(
            parser: nil,
            confidence: 0.0,
            reasoning: "Mock implementation",
            alternativeParsers: [],
            analysis: AIParserSelectionDocumentAnalysis(
                format: .standard,
                complexity: .simple,
                quality: .good,
                features: []
            )
        )
    }

    func selectParser(for text: String) -> ParserSelectionResult {
        return ParserSelectionResult(
            parser: nil,
            confidence: 0.0,
            reasoning: "Mock implementation",
            alternativeParsers: [],
            analysis: AIParserSelectionDocumentAnalysis(
                format: .standard,
                complexity: .simple,
                quality: .good,
                features: []
            )
        )
    }

    func evaluateParsers(for text: String) -> [ParserEvaluation] {
        return []
    }

    func learn(from text: String, selectedParser: PayslipParser, success: Bool) {
        // Mock learning - do nothing
    }
}

private class MockDocumentSemanticAnalyzer: DocumentSemanticAnalyzerProtocol {
    func analyzeDocument(_ document: PDFDocument) async -> SemanticAnalysisResult {
        return SemanticAnalysisResult(
            documentType: .standard,
            confidence: 0.5,
            fieldRelationships: [],
            qualityAssessment: DocumentQualityAssessment(
                overallScore: 0.5,
                issues: [],
                recommendations: [],
                completeness: .complete
            ),
            semanticFeatures: [],
            recommendations: []
        )
    }

    func analyzeText(_ text: String) -> SemanticAnalysisResult {
        return SemanticAnalysisResult(
            documentType: .standard,
            confidence: 0.5,
            fieldRelationships: [],
            qualityAssessment: DocumentQualityAssessment(
                overallScore: 0.5,
                issues: [],
                recommendations: [],
                completeness: .complete
            ),
            semanticFeatures: [],
            recommendations: []
        )
    }

    func identifyFieldRelationships(in text: String) -> [FieldRelationship] {
        return []
    }

    func assessDocumentQuality(_ text: String) -> DocumentQualityAssessment {
        return DocumentQualityAssessment(
            overallScore: 0.5,
            issues: [],
            recommendations: [],
            completeness: .complete
        )
    }
}
#endif
