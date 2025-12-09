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
    /// Phase 2D-Gamma: Updated to support DI pattern
    func makeGlobalOverlaySystem() -> GlobalOverlaySystem {
        // Create with dependency injection
        let loadingManager = makeGlobalLoadingManager()
        return GlobalOverlaySystem(loadingManager: loadingManager)
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
        // Resolve via DIContainer to avoid using the local stub.
        return PDFProcessingHandler(pdfProcessingService: DIContainer.shared.makePDFProcessingService())
    }

    /// Creates a PayslipDataHandler.
    func makePayslipDataHandler() -> PayslipDataHandler {
        // Use default constructor which handles dependency injection internally
        return PayslipDataHandler()
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
        if let patternRepository = AppContainer.shared.resolve(PatternRepositoryProtocol.self) {
            return PayslipExtractorService(patternRepository: patternRepository)
        }
        // Fallback to a minimal repository to keep DI stable
        let fallbackRepository = MinimalPatternRepository()
        return PayslipExtractorService(patternRepository: fallbackRepository)
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

    /// Creates a DataService (helper).
    private func makeDataService() -> DataServiceProtocol {
        return coreContainer.makeDataService()
    }

    /// Creates a PDFService (helper).
    private func makePDFService() -> PDFServiceProtocol {
        return coreContainer.makePDFService()
    }
}

// MARK: - Fallbacks

private final class MinimalPatternRepository: PatternRepositoryProtocol {
    func getAllPatterns() async -> [PatternDefinition] { [] }
    func getCorePatterns() async -> [PatternDefinition] { [] }
    func getUserPatterns() async -> [PatternDefinition] { [] }
    func getPatternsForCategory(_ category: PatternCategory) async -> [PatternDefinition] { [] }
    func getPattern(withID id: UUID) async -> PatternDefinition? { nil }
    func savePattern(_ pattern: PatternDefinition) async throws {}
    func deletePattern(withID id: UUID) async throws {}
    func resetToDefaults() async throws {}
    func exportPatternsToJSON() async throws -> Data { Data() }
    func importPatternsFromJSON(_ data: Data) async throws -> Int { 0 }
    func exportPatterns(to url: URL, includeCore: Bool) async throws -> Int { 0 }
    func importPatterns(from url: URL) async throws -> Int { 0 }
}
