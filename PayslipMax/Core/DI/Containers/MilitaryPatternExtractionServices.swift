import Foundation

/// Container for military pattern extraction services and related components.
/// This file contains military pattern services extracted from ProcessingContainer for better organization.
@MainActor
class MilitaryPatternExtractionServices {

    // MARK: - Military Pattern Extraction Services

    func makeMilitaryPatternExtractor() -> MilitaryPatternExtractorProtocol {
        return MilitaryPatternExtractionContainer().makeMilitaryPatternExtractor()
    }

    func makeSpatialAnalysisProcessor() -> SpatialAnalysisProcessorProtocol {
        return MilitaryPatternExtractionContainer().makeSpatialAnalysisProcessor()
    }

    func makePatternMatchingProcessor() -> PatternMatchingProcessorProtocol {
        return MilitaryPatternExtractionContainer().makePatternMatchingProcessor()
    }

    func makeGradeInferenceService() -> GradeInferenceServiceProtocol {
        return MilitaryPatternExtractionContainer().makeGradeInferenceService()
    }
}
