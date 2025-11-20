import Foundation

/// Factory for creating and managing payslip processors
class PayslipProcessorFactory {
    // MARK: - Properties

    /// Available processors
    private let processors: [PayslipProcessorProtocol]

    /// Format detection service
    private let formatDetectionService: PayslipFormatDetectionServiceProtocol

    /// Date extractor service for military payslips
    private let dateExtractor: MilitaryDateExtractorProtocol

    /// Payslip validation coordinator for totals validation
    private let validationCoordinator: PayslipValidationCoordinatorProtocol

    // MARK: - Initialization

    /// Initialize with all required services
    /// - Parameter formatDetectionService: Service for detecting payslip formats
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol) {
        self.formatDetectionService = formatDetectionService

        // Use default services
        self.dateExtractor = MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )

        self.validationCoordinator = PayslipValidationCoordinator()

        // Always use Universal Parser (legacy and simplified parsers removed in Phase 6)
        print("[PayslipProcessorFactory] 🚀 Using UNIVERSAL parser (243 codes, parallel search)")
        self.processors = [
            UniversalPayslipProcessor(
                validationCoordinator: self.validationCoordinator,
                dateExtractor: self.dateExtractor
            )
        ]
    }

    // MARK: - Public Methods

    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The universal parser (only processor)
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        print("[PayslipProcessorFactory] Using universal parser for defense personnel payslip")
        return processors[0]  // UniversalPayslipProcessor
    }

    /// Returns a specific processor for a given format
    /// - Parameter format: The payslip format
    /// - Returns: The universal parser (handles all defense formats)
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        return processors[0]  // UniversalPayslipProcessor
    }

    /// Gets all available processors
    /// - Returns: Array of all registered processors
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }

    // MARK: - Private Methods

    /// Returns the default processor to use when no specific format is detected
    /// - Returns: The universal parser (only processor)
    private func getDefaultProcessor() -> PayslipProcessorProtocol {
        return processors[0]  // UniversalPayslipProcessor
    }
}

