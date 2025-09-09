import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

/// Factory for global system services and properties in the DI container.
/// Handles global loading manager, overlay system, and other shared services.
@MainActor
class GlobalServiceFactory {

    // MARK: - Dependencies

    /// Core service container for accessing core services
    private let coreContainer: CoreServiceContainerProtocol

    /// Whether to use mock implementations for testing
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
    }

    // MARK: - Global System Services

    /// Creates a GlobalLoadingManager.
    func makeGlobalLoadingManager() -> GlobalLoadingManager {
        return GlobalLoadingManager.shared
    }

    /// Creates a GlobalOverlaySystem.
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem {
        return GlobalOverlaySystem.shared
    }

    /// Creates a TabTransitionCoordinator.
    func makeTabTransitionCoordinator() -> TabTransitionCoordinator {
        return TabTransitionCoordinator.shared
    }

    // MARK: - Navigation Services

    /// Creates a DestinationFactory.
    func makeDestinationFactory() -> DestinationFactoryProtocol {
        return DestinationFactory(dataService: makeDataService(), pdfManager: PDFUploadManager())
    }

    /// Creates a DestinationConverter.
    func makeDestinationConverter() -> DestinationConverter {
        return DestinationConverter(dataService: makeDataService())
    }

    /// Creates a HomeNavigationCoordinator.
    func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return HomeNavigationCoordinator()
    }

    /// Creates an ErrorHandler.
    func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }

    // MARK: - Handler Services

    /// Creates a PDFProcessingHandler.
    func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }

    /// Creates a PayslipDataHandler.
    func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: makeDataService())
    }

    /// Creates a PasswordProtectedPDFHandler.
    func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: makePDFService())
    }

    /// Creates a ChartDataPreparationService.
    func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }

    // MARK: - Singleton Services

    /// Creates a PCDAPayslipHandler.
    func makePCDAPayslipHandler() -> PCDAPayslipHandler {
        #if DEBUG
        if useMocks {
            // In the future, we might want to create a mock implementation
            return PCDAPayslipHandler()
        }
        #endif

        return PCDAPayslipHandler()
    }

    /// Creates a BiometricAuthService.
    func makeBiometricAuthService() -> BiometricAuthService {
        return BiometricAuthService()
    }

    /// Creates a PDFManager (shared instance).
    func makePDFManager() -> PDFManager {
        return PDFManager.shared
    }

    /// Creates an AnalyticsManager (shared instance).
    func makeAnalyticsManager() -> AnalyticsManager {
        return AnalyticsManager.shared
    }

    /// Creates a GamificationCoordinator (shared instance).
    func makeGamificationCoordinator() -> GamificationCoordinator {
        return GamificationCoordinator.shared
    }

    /// Creates a BankingPatternsProvider.
    func makeBankingPatternsProvider() -> BankingPatternsProvider {
        return BankingPatternsProvider()
    }

    /// Creates a FinancialPatternsProvider.
    func makeFinancialPatternsProvider() -> FinancialPatternsProvider {
        return FinancialPatternsProvider()
    }

    /// Creates a DocumentAnalysisCoordinator.
    func makeDocumentAnalysisCoordinator() -> DocumentAnalysisCoordinator {
        return DocumentAnalysisCoordinator()
    }

    /// Creates a PayslipExtractorService.
    func makePayslipExtractorService() -> PayslipExtractorService {
        guard let patternRepository = AppContainer.shared.resolve(PatternRepositoryProtocol.self) else {
            fatalError("PatternRepositoryProtocol not available in AppContainer")
        }
        return PayslipExtractorService(patternRepository: patternRepository)
    }

    /// Creates a PayslipPatternManager.
    func makePayslipPatternManager() -> PayslipPatternManager {
        // Resolve or create pattern provider from AppContainer
        let patternProvider = AppContainer.shared.resolve(PatternProvider.self) ?? DefaultPatternProvider()

        // Create pattern matching components
        let patternMatcher = UnifiedPatternMatcher()
        let patternValidator = UnifiedPatternValidator(patternProvider: patternProvider)
        let patternDefinitions = UnifiedPatternDefinitions(patternProvider: patternProvider)

        // Create validator and builder
        let validator = PayslipValidator(patternProvider: patternProvider)
        let payslipBuilder = PayslipBuilder(patternProvider: patternProvider, validator: validator)

        // Create and return the pattern manager with all dependencies injected
        return PayslipPatternManager(
            patternMatcher: patternMatcher,
            patternValidator: patternValidator,
            patternDefinitions: patternDefinitions,
            payslipBuilder: payslipBuilder
        )
    }

    // MARK: - Performance Monitoring Services

    /// Creates a PerformanceCoordinator.
    func makePerformanceCoordinator() -> PerformanceCoordinatorProtocol {
        return coreContainer.makePerformanceCoordinator()
    }

    /// Creates an FPSMonitor.
    func makeFPSMonitor() -> FPSMonitorProtocol {
        return coreContainer.makeFPSMonitor()
    }

    /// Creates a MemoryMonitor.
    func makeMemoryMonitor() -> MemoryMonitorProtocol {
        return coreContainer.makeMemoryMonitor()
    }

    /// Creates a CPUMonitor.
    func makeCPUMonitor() -> CPUMonitorProtocol {
        return coreContainer.makeCPUMonitor()
    }

    /// Creates a PerformanceReporter.
    func makePerformanceReporter() -> PerformanceReporterProtocol {
        return coreContainer.makePerformanceReporter()
    }

    // MARK: - Private Helper Methods

    /// Creates a PDFProcessingService (helper for handlers).
    private func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        // This would be injected or created from CoreServiceFactory in real usage
        fatalError("PDFProcessingService should be injected from CoreServiceFactory")
    }

    /// Creates a DataService (helper).
    private func makeDataService() -> DataServiceProtocol {
        return coreContainer.makeDataService()
    }

    /// Creates a PDFService (helper).
    private func makePDFService() -> PDFServiceProtocol {
        return coreContainer.makePDFService()
    }
}
