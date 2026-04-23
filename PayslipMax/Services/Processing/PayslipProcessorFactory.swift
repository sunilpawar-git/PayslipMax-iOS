import Foundation
import SwiftData
import os

/// Factory for creating and managing payslip processors
class PayslipProcessorFactory {

    private let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "ProcessorFactory")
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
    ///   - modelContainer: Model container for usage tracking (optional)
    @MainActor
    init(formatDetectionService: PayslipFormatDetectionServiceProtocol,
         settings: LLMSettingsServiceProtocol? = nil,
         modelContainer: ModelContainer? = nil) {
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

        // Resolve settings service from DI, fall back to default construction
        let resolvedKeychain = AppContainer.shared.resolve(SecureStorageProtocol.self) ?? KeychainSecureStorage()
        let resolvedOfflineService = AppContainer.shared.resolve(OfflineModeServiceProtocol.self) ?? OfflineModeService()
        let llmSettings = settings ?? LLMSettingsService(keychain: resolvedKeychain, offlineModeService: resolvedOfflineService)

        // Resolve usage tracker and rate limiter from AppContainer
        var usageTracker: LLMUsageTrackerProtocol?
        var rateLimiter: LLMRateLimiterProtocol?

        // Try to resolve from AppContainer first (preferred)
        if let containerRateLimiter = AppContainer.shared.resolve(LLMRateLimiterProtocol.self) {
            rateLimiter = containerRateLimiter
        } else {
            rateLimiter = LLMRateLimiter() // Fallback
        }

        if let containerUsageTracker = AppContainer.shared.resolve(LLMUsageTrackerProtocol.self) {
            usageTracker = containerUsageTracker
        } else if let container = modelContainer {
            let costCalculator = LLMCostCalculator()
            usageTracker = LLMUsageTracker(modelContainer: container, costCalculator: costCalculator)
            logger.info("LLM usage tracking enabled (local fallback)")
        } else {
            logger.warning("LLM usage tracking disabled — no model container available")
        }

        var onDeviceService: OnDeviceLLMServiceProtocol?
        if #available(iOS 26, *) {
            onDeviceService = FoundationModelPayslipService()
            logger.info("On-device Foundation Model service available")
        }

        let offlineModeService = resolvedOfflineService

        let hybridProcessor = HybridPayslipProcessor(
            regexProcessor: universalProcessor,
            settings: llmSettings,
            rateLimiter: rateLimiter,
            llmFactory: { config in
                return LLMPayslipParserFactory.createParserWithSelectiveRedaction(for: config, usageTracker: usageTracker)
            },
            onDeviceService: onDeviceService,
            offlineModeService: offlineModeService
        )

        // Use Hybrid Processor as the primary processor
        self.processors = [hybridProcessor]
    }

    // MARK: - Public Methods

    /// Gets the appropriate processor for the provided text
    /// - Parameter text: The text extracted from the PDF
    /// - Returns: The hybrid processor (wrapping universal parser)
    func getProcessor(for text: String) -> PayslipProcessorProtocol {
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

}

