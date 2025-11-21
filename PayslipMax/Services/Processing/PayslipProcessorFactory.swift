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
    /// - Parameters:
    ///   - formatDetectionService: Service for detecting payslip formats
    ///   - settings: LLM settings service (optional, defaults to DI container)
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol,
         settings: LLMSettingsServiceProtocol? = nil) {
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

        // Create the base Universal Parser
        let universalProcessor = UniversalPayslipProcessor(
            validationCoordinator: self.validationCoordinator,
            dateExtractor: self.dateExtractor
        )

        // Resolve settings service
        let llmSettings = settings ?? LLMSettingsService(keychain: KeychainSecureStorage())

        // Create the Hybrid Processor wrapping the Universal Parser
        print("[PayslipProcessorFactory] 🚀 Initializing Hybrid Processor (Universal + LLM)")
        let hybridProcessor = HybridPayslipProcessor(
            regexProcessor: universalProcessor,
            settings: llmSettings,
            llmFactory: { config in
                return LLMPayslipParserFactory.createParser(for: config)
            }
        )

        // Use Hybrid Processor as the primary processor
        self.processors = [hybridProcessor]
    }

    // MARK: - Public Methods

    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The hybrid processor (wrapping universal parser)
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
        print("[PayslipProcessorFactory] Using hybrid processor for defense personnel payslip")
        return processors[0]
    }

    /// Returns a specific processor for a given format
    /// - Parameter format: The payslip format
    /// - Returns: The hybrid processor (handles all defense formats)
    func getProcessor(for format: PayslipFormat) -> PayslipProcessorProtocol {
        return processors[0]
    }

    /// Gets all available processors
    /// - Returns: Array of all registered processors
    func getAllProcessors() -> [PayslipProcessorProtocol] {
        return processors
    }

    // MARK: - Private Methods

    /// Returns the default processor to use when no specific format is detected
    /// - Returns: The hybrid processor
    private func getDefaultProcessor() -> PayslipProcessorProtocol {
        return processors[0]
    }
}

