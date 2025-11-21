import Foundation
import PDFKit
import SwiftUI
import SwiftData

/// Container for core services that other components depend on.
/// Handles PDF, Security, Data, Validation, and Encryption services.
/// Refactored to delegate to specialized sub-containers.
@MainActor
class CoreServiceContainer: CoreServiceContainerProtocol {

    // MARK: - Properties

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    // MARK: - Sub-Containers

    private let securityContainer: SecurityServicesContainer
    private let pdfContainer: PDFServicesContainer
    private let dataContainer: DataServicesContainer

    // MARK: - Phase 2: Dual-Mode Storage

    /// Storage for registered singletons
    private var singletons: [String: Any] = [:]

    /// Storage for registered factories
    private var factories: [String: () -> Any] = [:]

    // MARK: - Initialization

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
        self.securityContainer = SecurityServicesContainer(useMocks: useMocks)
        self.pdfContainer = PDFServicesContainer(useMocks: useMocks)
        self.dataContainer = DataServicesContainer(useMocks: useMocks)
    }

    // MARK: - Phase 2: Dual-Mode Registration Methods

    /// Register a singleton instance
    func registerSingleton<T>(_ instance: T, for serviceType: T.Type) {
        let key = String(describing: serviceType)
        singletons[key] = instance
    }

    /// Register a factory function
    func registerFactory<T>(_ factory: @escaping () -> T, for serviceType: T.Type) {
        let key = String(describing: serviceType)
        factories[key] = factory
    }

    /// Resolve a service
    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)
        return singletons[key] as? T
    }

    // MARK: - Core Services

    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol {
        return pdfContainer.makePDFService()
    }

    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        return pdfContainer.makePDFExtractor()
    }

    /// Creates a data service.
    func makeDataService() -> DataServiceProtocol {
        return dataContainer.makeDataService(securityService: securityService)
    }

    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol {
        return securityContainer.makeSecurityService()
    }

    /// Creates a text extraction service
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return pdfContainer.makeTextExtractionService()
    }

    /// Creates a payslip format detection service
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return pdfContainer.makePayslipFormatDetectionService()
    }

    /// Creates a payslip validation service
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return dataContainer.makePayslipValidationService()
    }

    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        return securityContainer.makePayslipEncryptionService()
    }

    /// Creates an encryption service
    func makeEncryptionService() -> EncryptionServiceProtocol {
        return securityContainer.makeEncryptionService()
    }

    /// Creates a secure storage service
    func makeSecureStorage() -> SecureStorageProtocol {
        return securityContainer.makeSecureStorage()
    }

    // MARK: - Network Services

    func makeNetworkService() -> NetworkServiceProtocol {
        return dataContainer.makeNetworkService()
    }

    func makeNetworkResponseHandler() -> NetworkResponseHandlerProtocol {
        return dataContainer.makeNetworkResponseHandler()
    }

    func makeNetworkUploadService() -> NetworkUploadServiceProtocol {
        return dataContainer.makeNetworkUploadService()
    }

    /// Creates a document structure identifier service
    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol {
        return pdfContainer.makeDocumentStructureIdentifier()
    }

    /// Creates a document section extractor service
    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol {
        return pdfContainer.makeDocumentSectionExtractor()
    }

    /// Creates a personal info section parser service
    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol {
        return pdfContainer.makePersonalInfoSectionParser()
    }

    /// Creates a financial data section parser service
    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol {
        return pdfContainer.makeFinancialDataSectionParser()
    }

    /// Creates a contact info section parser service
    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol {
        return pdfContainer.makeContactInfoSectionParser()
    }

    /// Creates a document metadata extractor service
    func makeDocumentMetadataExtractor() -> DocumentMetadataExtractorProtocol {
        return pdfContainer.makeDocumentMetadataExtractor()
    }

    // MARK: - Business Logic Services

    /// Creates a financial calculation service.
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol {
        return dataContainer.makeFinancialCalculationService()
    }

    /// Creates a military abbreviation service.
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol {
        return dataContainer.makeMilitaryAbbreviationService()
    }

    // MARK: - Pattern Extraction Services

    /// Creates a tabular data extractor service.
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol {
        return pdfContainer.makeTabularDataExtractor()
    }

    /// Creates a pattern matching service.
    func makePatternMatchingService() -> PatternMatchingServiceProtocol {
        return pdfContainer.makePatternMatchingService()
    }

    // MARK: - Performance Monitoring Services

    func makePerformanceCoordinator() -> PerformanceCoordinatorProtocol {
        return dataContainer.makePerformanceCoordinator()
    }

    func makeFPSMonitor() -> FPSMonitorProtocol {
        return dataContainer.makeFPSMonitor()
    }

    func makeMemoryMonitor() -> MemoryMonitorProtocol {
        return dataContainer.makeMemoryMonitor()
    }

    func makeCPUMonitor() -> CPUMonitorProtocol {
        return dataContainer.makeCPUMonitor()
    }

    func makePerformanceReporter() -> PerformanceReporterProtocol {
        return dataContainer.makePerformanceReporter()
    }

    func makeDualSectionPerformanceMonitor() -> DualSectionPerformanceMonitorProtocol {
        return dataContainer.makeDualSectionPerformanceMonitor()
    }

    func makeClassificationCacheManager() -> ClassificationCacheManagerProtocol {
        return dataContainer.makeClassificationCacheManager()
    }

    func makeParallelPayCodeProcessor() -> ParallelPayCodeProcessorProtocol {
        return dataContainer.makeParallelPayCodeProcessor()
    }

    /// Creates a payslip display name service
    func makePayslipDisplayNameService() -> PayslipDisplayNameServiceProtocol {
        return dataContainer.makePayslipDisplayNameService()
    }

    // MARK: - Phase 2C: Service Layer Migration Factory Methods

    /// Creates a PDF extraction trainer
    func makePDFExtractionTrainer() -> PDFExtractionTrainer {
        let dataStore = dataContainer.makeTrainingDataStore()
        return pdfContainer.makePDFExtractionTrainer(dataStore: dataStore)
    }

    /// Creates a military abbreviations service
    func makeMilitaryAbbreviationsService() -> MilitaryAbbreviationServiceProtocol {
        return dataContainer.makeMilitaryAbbreviationsService()
    }

    /// Creates a training data store
    func makeTrainingDataStore() -> TrainingDataStore {
        return dataContainer.makeTrainingDataStore()
    }

    /// Creates a UI appearance service
    @MainActor
    func makeAppearanceService() -> AppearanceService {
        return dataContainer.makeAppearanceService()
    }

    /// Creates a contact info extractor
    func makeContactInfoExtractor() -> ContactInfoExtractor {
        return pdfContainer.makeContactInfoExtractor()
    }

    // MARK: - LLM Services

    /// Creates an LLM settings service
    func makeLLMSettingsService() -> LLMSettingsServiceProtocol {
        return LLMSettingsService(keychain: makeSecureStorage())
    }

    // MARK: - Internal Access

    /// Access the security service (cached for consistency)
    var securityService: SecurityServiceProtocol {
        return securityContainer.securityService
    }
}
