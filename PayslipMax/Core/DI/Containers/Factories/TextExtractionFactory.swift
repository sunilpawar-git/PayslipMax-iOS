import Foundation
import PDFKit

/// Factory for enhanced text extraction services.
/// Handles text extraction, strategy selection, validation, and preprocessing.
@MainActor
class TextExtractionFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Enhanced Text Extraction Services

    /// Creates a text extractor with enhanced universal search capabilities.
    /// Uses Phase 4 universal pay code search to eliminate mutually exclusive column logic.
    func makeTextExtractor() -> TextExtractor {
        let patternProvider = DefaultPatternProvider()
        let universalSearchEngine = makeUniversalPayCodeSearchEngine()
        return EnhancedTextExtractor(
            patternProvider: patternProvider,
            universalSearchEngine: universalSearchEngine
        )
    }

    /// Creates an extraction strategy selector.
    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        #if DEBUG
        if useMocks {
            // TODO: Create mock implementation if needed
            // return MockExtractionStrategySelector()
        }
        #endif

        // Create with proper dependencies according to extracted component architecture
        return ExtractionStrategySelector(
            strategies: ExtractionStrategies(),
            evaluationRules: ExtractionStrategies.defaultEvaluationRules()
        )
    }

    /// Creates a simple text validator for basic extraction validation.
    func makeSimpleValidator() -> SimpleValidator {
        return SimpleValidator()
    }

    /// Creates a simple extraction validator for PayslipItem validation.
    func makeSimpleExtractionValidator() -> SimpleExtractionValidatorProtocol {
        return ExtractionValidator()
    }

    /// Creates an extraction result assembler.
    func makeExtractionResultAssembler() -> ExtractionResultAssemblerProtocol {
        return ExtractionResultAssembler()
    }

    /// Creates a text preprocessing service.
    func makeTextPreprocessingService() -> TextPreprocessingServiceProtocol {
        return TextPreprocessingService()
    }

    /// Creates a data extraction service with all required dependencies.
    func makeDataExtractionService() -> DataExtractionServiceProtocol {
        return DataExtractionService(
            algorithms: DataExtractionAlgorithms(),
            validation: DataExtractionValidation()
        )
    }

    /// Creates a pattern application engine.
    func makePatternApplicationEngine() -> PatternApplicationEngineProtocol {
        return PatternApplicationEngine(
            preprocessingService: makeTextPreprocessingService()
        )
    }

    /// Creates an arrears classification service for Phase 3 implementation.
    func makeArrearsClassificationService() -> ArrearsClassificationServiceProtocol {
        return ArrearsClassificationService()
    }

    /// Creates a universal arrears extraction helper for Phase 3 implementation.
    func makeUniversalArrearsExtractionHelper() -> UniversalArrearsExtractionHelper {
        return UniversalArrearsExtractionHelper()
    }

    /// Creates a universal arrears pattern matcher for Phase 3 implementation.
    func makeUniversalArrearsPatternMatcher() -> UniversalArrearsPatternMatcherProtocol {
        return UniversalArrearsPatternMatcher(
            arrearsClassificationService: makeArrearsClassificationService()
        )
    }

    /// Creates a universal pay code search engine for Phase 4 implementation.
    func makeUniversalPayCodeSearchEngine() -> UniversalPayCodeSearchEngineProtocol {
        return UniversalPayCodeSearchEngine()
    }
}
