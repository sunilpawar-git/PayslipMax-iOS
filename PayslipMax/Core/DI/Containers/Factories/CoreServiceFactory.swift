import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

/// Factory for core services in the DI container.
/// Handles PDF, Security, Data, Validation, and Encryption services.
@MainActor
class CoreServiceFactory {

    // MARK: - Dependencies

    /// Core service container for accessing core services
    private let coreContainer: CoreServiceContainerProtocol

    /// Processing container for accessing processing services
    private let processingContainer: ProcessingContainerProtocol

    /// Whether to use mock implementations for testing
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol, processingContainer: ProcessingContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
        self.processingContainer = processingContainer
    }

    // MARK: - PDF Processing Services

    /// Creates a PDFProcessingService.
    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return PDFProcessingService(
            urlProcessor: makePDFURLProcessor(),
            passwordHandler: makePDFPasswordHandler(),
            imageProcessor: makePDFImageProcessor(),
            formatValidator: makePDFFormatValidator(),
            dataProcessor: makePDFDataProcessor(),
            processingPipeline: makePayslipProcessingPipeline(),
            pdfService: makePDFService()
        )
    }

    /// Creates a PDFURLProcessor.
    private func makePDFURLProcessor() -> PDFURLProcessorProtocol {
        return PDFURLProcessor(
            pdfService: makePDFService(),
            validationService: makePayslipValidationService()
        )
    }

    /// Creates a PDFPasswordHandler.
    private func makePDFPasswordHandler() -> PDFPasswordHandlerProtocol {
        return PDFPasswordHandler(
            pdfService: makePDFService(),
            validationService: makePayslipValidationService()
        )
    }

    /// Creates a PDFImageProcessor.
    private func makePDFImageProcessor() -> PDFImageProcessorProtocol {
        return PDFImageProcessor(
            imageProcessingStep: ImageProcessingStep(),
            processingPipeline: makePayslipProcessingPipeline()
        )
    }

    /// Creates a PDFFormatValidator.
    private func makePDFFormatValidator() -> PDFFormatValidatorProtocol {
        return PDFFormatValidator(
            parsingCoordinator: makePDFParsingCoordinator(),
            formatDetectionService: makePayslipFormatDetectionService(),
            validationService: makePayslipValidationService(),
            processorFactory: makePayslipProcessorFactory()
        )
    }

    /// Creates a PDFDataProcessor.
    private func makePDFDataProcessor() -> PDFDataProcessorProtocol {
        return PDFDataProcessor(
            dataExtractionService: DataExtractionService(
                algorithms: DataExtractionAlgorithms(),
                validation: DataExtractionValidation()
            ),
            payslipCreationStep: PayslipCreationProcessingStep(
                dataExtractionService: DataExtractionService(
                    algorithms: DataExtractionAlgorithms(),
                    validation: DataExtractionValidation()
                )
            ),
            pdfExtractor: makePDFExtractor()
        )
    }

    /// Creates a PDFService.
    func makePDFService() -> PDFServiceProtocol {
        return coreContainer.makePDFService()
    }

    /// Creates a PDFExtractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        return coreContainer.makePDFExtractor()
    }

    /// Creates a PDFParsingCoordinator.
    func makePDFParsingCoordinator() -> PDFParsingCoordinatorProtocol {
        return processingContainer.makePDFParsingCoordinator()
    }

    /// Creates a PDFTextExtractionService.
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingContainer.makePDFTextExtractionService()
    }

    // MARK: - Core Service Delegations

    /// Creates a TextExtractionService.
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return coreContainer.makeTextExtractionService()
    }

    /// Creates a PayslipFormatDetectionService.
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return coreContainer.makePayslipFormatDetectionService()
    }

    /// Creates a PayslipValidationService.
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return coreContainer.makePayslipValidationService()
    }

    /// Creates a DataService.
    func makeDataService() -> DataServiceProtocol {
        return coreContainer.makeDataService()
    }

    /// Creates a SecurityService.
    func makeSecurityService() -> SecurityServiceProtocol {
        return coreContainer.makeSecurityService()
    }

    /// Creates a FinancialCalculationService.
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol {
        return coreContainer.makeFinancialCalculationService()
    }

    /// Creates a MilitaryAbbreviationService.
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol {
        return coreContainer.makeMilitaryAbbreviationService()
    }

    /// Creates a PatternLoader.
    func makePatternLoader() -> PatternLoaderProtocol {
        return coreContainer.makePatternLoader()
    }

    /// Creates a TabularDataExtractor.
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol {
        return coreContainer.makeTabularDataExtractor()
    }

    /// Creates a PatternMatchingService.
    func makePatternMatchingService() -> PatternMatchingServiceProtocol {
        return coreContainer.makePatternMatchingService()
    }

    /// Creates a PayslipEncryptionService.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        return coreContainer.makePayslipEncryptionService()
    }

    /// Creates an EncryptionService.
    func makeEncryptionService() -> EncryptionServiceProtocol {
        return coreContainer.makeEncryptionService()
    }

    /// Creates a SecureStorage.
    func makeSecureStorage() -> SecureStorageProtocol {
        return coreContainer.makeSecureStorage()
    }

    /// Creates a PayItemCategorizationService.
    func makePayItemCategorizationService() -> PayItemCategorizationServiceProtocol {
        return PayItemCategorizationService()
    }

    // MARK: - Repository Services

    /// Creates a PayslipRepository instance
    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        #if DEBUG
        if useMocks {
            // This would be a mock implementation if needed
            return PayslipRepository(modelContext: modelContext)
        }
        #endif
        return PayslipRepository(modelContext: modelContext)
    }

    /// Creates a PayslipMigrationUtilities instance
    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        let migrationManager = PayslipMigrationManager(modelContext: modelContext)
        return PayslipMigrationUtilities(migrationManager: migrationManager)
    }

    /// Creates a PayslipBatchOperations instance
    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        let migrationUtilities = makePayslipMigrationUtilities(modelContext: modelContext)
        return PayslipBatchOperations(
            modelContext: modelContext,
            migrationUtilities: migrationUtilities
        )
    }
}
