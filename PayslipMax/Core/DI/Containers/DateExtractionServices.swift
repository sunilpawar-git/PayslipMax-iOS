import Foundation

/// Container for date extraction services and related components.
/// This file contains date processing services extracted from ProcessingContainer for better organization.
@MainActor
class DateExtractionServices {

    // MARK: - Date Extraction Services

    func makeDatePatternDefinitions() -> DatePatternDefinitionsProtocol {
        return DatePatternDefinitions()
    }

    func makeDateValidationService() -> DateValidationServiceProtocol {
        return DateValidationService()
    }

    func makeDateProcessingUtilities() -> DateProcessingUtilitiesProtocol {
        return DateProcessingUtilities()
    }

    func makeDateSelectionService() -> DateSelectionServiceProtocol {
        return DateSelectionService()
    }

    func makeDateConfidenceCalculator() -> DateConfidenceCalculatorProtocol {
        return DateConfidenceCalculator()
    }

    func makeMilitaryDateExtractor() -> MilitaryDateExtractorProtocol {
        let datePatterns = makeDatePatternDefinitions()
        let dateValidation = makeDateValidationService()
        let dateProcessing = makeDateProcessingUtilities()
        let dateSelection = makeDateSelectionService()
        let confidenceCalculator = makeDateConfidenceCalculator()

        return MilitaryDateExtractor(
            datePatterns: datePatterns,
            dateValidation: dateValidation,
            dateProcessing: dateProcessing,
            dateSelection: dateSelection,
            confidenceCalculator: confidenceCalculator
        )
    }
}
