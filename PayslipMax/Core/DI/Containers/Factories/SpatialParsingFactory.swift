import Foundation
import PDFKit

/// Factory for spatial parsing services.
/// Handles positional element extraction, spatial analysis, and enhanced tabular data processing.
@MainActor
class SpatialParsingFactory {

    // MARK: - Dependencies

    /// Whether to use mock implementations for testing.
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    // MARK: - Spatial Parsing Services

    /// Creates a positional element extractor for spatial PDF parsing
    func makePositionalElementExtractor() async -> PositionalElementExtractorProtocol {
        return await MainActor.run {
            DefaultPositionalElementExtractor(
                configuration: .payslipDefault,
                elementClassifier: makeElementTypeClassifier()
            )
        }
    }

    /// Creates an element type classifier for categorizing extracted elements
    func makeElementTypeClassifier() -> ElementTypeClassifier {
        return ElementTypeClassifier()
    }

    /// Creates a spatial analyzer for understanding element relationships
    func makeSpatialAnalyzer() -> SpatialAnalyzerProtocol {
        return SpatialAnalyzer(configuration: .payslipDefault)
    }

    /// Creates an enhanced tabular data extractor with spatial intelligence
    func makeEnhancedTabularDataExtractor() -> TabularDataExtractor {
        return TabularDataExtractor(spatialAnalyzer: makeSpatialAnalyzer())
    }

    /// Creates a contextual pattern matcher with spatial validation
    func makeContextualPatternMatcher() -> ContextualPatternMatcher {
        return ContextualPatternMatcher(
            configuration: .payslipDefault,
            spatialAnalyzer: makeSpatialAnalyzer()
        )
    }

    /// Creates an enhanced PDF service with spatial extraction capabilities
    func makeEnhancedPDFService() -> PDFService {
        return DefaultPDFService(positionalExtractor: nil) // Will be created lazily when needed
    }
}
