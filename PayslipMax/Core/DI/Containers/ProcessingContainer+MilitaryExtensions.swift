import Foundation

/// Military pattern extraction services extension for ProcessingContainer
/// Extracted to maintain 300-line limit per architectural rules
extension ProcessingContainer {
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
