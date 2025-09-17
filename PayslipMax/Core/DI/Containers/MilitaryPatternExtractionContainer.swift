//
//  MilitaryPatternExtractionContainer.swift
//  PayslipMax
//
//  Created for military pattern extraction services
//  Extracted from ProcessingContainer to maintain file size compliance
//

import Foundation

/// Container for military pattern extraction services
/// Handles creation and dependency injection of military-specific processors
final class MilitaryPatternExtractionContainer {

    // MARK: - Military Pattern Extraction Services

    func makeMilitaryPatternExtractor() -> MilitaryPatternExtractorProtocol {
        let spatialAnalysisProcessor = makeSpatialAnalysisProcessor()
        let patternMatchingProcessor = makePatternMatchingProcessor()
        let gradeInferenceService = makeGradeInferenceService()

        return MilitaryPatternExtractor(
            spatialAnalysisProcessor: spatialAnalysisProcessor,
            patternMatchingProcessor: patternMatchingProcessor,
            gradeInferenceService: gradeInferenceService
        )
    }

    func makeSpatialAnalysisProcessor() -> SpatialAnalysisProcessorProtocol {
        return SpatialAnalysisProcessor()
    }

    func makePatternMatchingProcessor() -> PatternMatchingProcessorProtocol {
        return PatternMatchingProcessor()
    }

    func makeGradeInferenceService() -> GradeInferenceServiceProtocol {
        return GradeInferenceService()
    }
}
