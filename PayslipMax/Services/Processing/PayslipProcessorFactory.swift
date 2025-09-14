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

    /// RH12 processing service for enhanced RH12 detection
    private let rh12ProcessingService: RH12ProcessingServiceProtocol

    /// Payslip validation coordinator for totals validation
    private let validationCoordinator: PayslipValidationCoordinatorProtocol

    // MARK: - Initialization

    /// Initialize with all required services
    /// - Parameter formatDetectionService: Service for detecting payslip formats
    /// - Parameter dateExtractor: Service for extracting dates from military payslips
    /// - Parameter rh12ProcessingService: Service for RH12 component processing
    /// - Parameter validationCoordinator: Service for payslip totals validation
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol,
         dateExtractor: MilitaryDateExtractorProtocol? = nil,
         rh12ProcessingService: RH12ProcessingServiceProtocol? = nil,
         validationCoordinator: PayslipValidationCoordinatorProtocol? = nil) {
        self.formatDetectionService = formatDetectionService

        // Use provided services or create defaults with all dependencies
        self.dateExtractor = dateExtractor ?? MilitaryDateExtractor(
            datePatterns: DatePatternDefinitions(),
            dateValidation: DateValidationService(),
            dateProcessing: DateProcessingUtilities(),
            dateSelection: DateSelectionService(),
            confidenceCalculator: DateConfidenceCalculator()
        )

        self.rh12ProcessingService = rh12ProcessingService ?? RH12ProcessingService()
        self.validationCoordinator = validationCoordinator ?? PayslipValidationCoordinator()

        // Register unified defense processor for all defense personnel payslips
        self.processors = [
            UnifiedDefensePayslipProcessor(
                dateExtractor: self.dateExtractor,
                rh12ProcessingService: self.rh12ProcessingService,
                validationCoordinator: self.validationCoordinator
            )
        ]
    }

    // MARK: - Public Methods

    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The unified defense processor (only processor for defense personnel)
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        // Since PayslipMax is exclusively for defense personnel, always return the unified defense processor
        print("[PayslipProcessorFactory] Using unified defense processor for defense personnel payslip")
        return processors[0]  // UnifiedDefensePayslipProcessor
    }

    /// Returns a specific processor for a given format
    /// - Parameter format: The payslip format
    /// - Returns: The unified defense processor (handles all defense formats)
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        // Always return unified defense processor for any defense-related format
        return processors[0]  // UnifiedDefensePayslipProcessor
    }

    /// Gets all available processors
    /// - Returns: Array of all registered processors
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }

    // MARK: - Private Methods

    /// Returns the default processor to use when no specific format is detected
    /// - Returns: The unified defense processor (only processor for defense personnel)
    private func getDefaultProcessor() -> PayslipProcessorProtocol {
        return processors[0]  // Always return unified defense processor
    }
}
