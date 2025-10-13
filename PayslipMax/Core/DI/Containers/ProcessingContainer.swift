import Foundation
import PDFKit

/// Container for processing services that handle text extraction, PDF processing, and payslip processing pipelines.
/// Handles text extraction, PDF parsing, and processing pipeline coordination.
@MainActor
class ProcessingContainer: ProcessingContainerProtocol {

    // MARK: - Properties

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    // MARK: - Dependencies

    /// Core service container for accessing validation and format detection services
    private let coreContainer: CoreServiceContainerProtocol

    // MARK: - Factory

    /// Unified processing service factory that handles all processing services
    internal lazy var processingFactory = UnifiedProcessingFactory(useMocks: useMocks, coreContainer: coreContainer)

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }

    // MARK: - Core Processing Services

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingFactory.makePDFTextExtractionService()
    }

    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return processingFactory.makePDFParsingCoordinator()
    }

    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return processingFactory.makePayslipProcessingPipeline()
    }

    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return processingFactory.makePayslipProcessorFactory()
    }

    func makePayslipImportCoordinator() -> PayslipImportCoordinator {
        return processingFactory.makePayslipImportCoordinator()
    }

    func makeAbbreviationManager() -> AbbreviationManager {
        return processingFactory.makeAbbreviationManager()
    }

    // MARK: - Text Extraction Services

    func makeTextExtractor() -> TextExtractor {
        return processingFactory.makeTextExtractor()
    }

    func makeExtractionStrategySelector() -> ExtractionStrategySelectorProtocol {
        return processingFactory.makeExtractionStrategySelector()
    }

    func makeSimpleValidator() -> SimpleValidator {
        return processingFactory.makeSimpleValidator()
    }

    // MARK: - Pattern Application Services

    func makePatternApplicationStrategies() -> PatternApplicationStrategies {
        return processingFactory.makePatternApplicationStrategies()
    }

    func makePatternApplicationValidation() -> PatternApplicationValidation {
        return processingFactory.makePatternApplicationValidation()
    }

    func makePatternApplier() -> PatternApplier {
        return processingFactory.makePatternApplier()
    }

    // MARK: - Unified Factory Delegations

    // Factory delegation methods have been extracted to ProcessingContainerFactoryDelegations.swift
    // for better maintainability and to comply with the 300-line file size limit.

    // MARK: - Date Extraction Services

    func makeDatePatternDefinitions() -> DatePatternDefinitionsProtocol {
        return DateExtractionServices().makeDatePatternDefinitions()
    }

    func makeDateValidationService() -> DateValidationServiceProtocol {
        return DateExtractionServices().makeDateValidationService()
    }

    func makeDateProcessingUtilities() -> DateProcessingUtilitiesProtocol {
        return DateExtractionServices().makeDateProcessingUtilities()
    }

    func makeDateSelectionService() -> DateSelectionServiceProtocol {
        return DateExtractionServices().makeDateSelectionService()
    }

    func makeDateConfidenceCalculator() -> DateConfidenceCalculatorProtocol {
        return DateExtractionServices().makeDateConfidenceCalculator()
    }

    func makeMilitaryDateExtractor() -> MilitaryDateExtractorProtocol {
        return DateExtractionServices().makeMilitaryDateExtractor()
    }

    func makeRH12ProcessingService() -> RH12ProcessingServiceProtocol {
        return RH12ProcessingService()
    }

    func makePayslipValidationCoordinator() -> PayslipValidationCoordinatorProtocol {
        return PayslipValidationCoordinator()
    }

    // MARK: - Military Pattern Extraction Services

    func makeMilitaryPatternExtractor() -> MilitaryPatternExtractorProtocol {
        return MilitaryPatternExtractionServices().makeMilitaryPatternExtractor()
    }

    func makeSpatialAnalysisProcessor() -> SpatialAnalysisProcessorProtocol {
        return MilitaryPatternExtractionServices().makeSpatialAnalysisProcessor()
    }

    func makePatternMatchingProcessor() -> PatternMatchingProcessorProtocol {
        return MilitaryPatternExtractionServices().makePatternMatchingProcessor()
    }

    func makeGradeInferenceService() -> GradeInferenceServiceProtocol {
        return MilitaryPatternExtractionServices().makeGradeInferenceService()
    }

    func makeUniversalDualSectionProcessor() -> UniversalDualSectionProcessorProtocol {
        return UniversalDualSectionProcessor()
    }

    // MARK: - Simplified Parsing Services

    /// Creates a SimplifiedPayslipParser for essential-only extraction
    func makeSimplifiedPayslipParser() -> SimplifiedPayslipParser {
        return SimplifiedPayslipParser()
    }

    /// Creates a SimplifiedPDFProcessingService
    func makeSimplifiedPDFProcessingService() -> SimplifiedPDFProcessingService {
        return SimplifiedPDFProcessingService(
            textExtractionService: makePDFTextExtractionService()
        )
    }

}
