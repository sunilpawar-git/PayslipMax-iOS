import Foundation
import SwiftData

/// Container for data, validation, network, and performance services.
@MainActor
class DataServicesContainer {

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    /// Creates a data service.
    func makeDataService(securityService: SecurityServiceProtocol) -> DataServiceProtocol {
        // Create the service without automatic initialization
        let service = try! DataServiceImpl(securityService: securityService)

        // Since initialization is async and DIContainer is sync,
        // we'll rely on the service methods to handle initialization lazily when needed
        return service
    }

    /// Creates a payslip validation service
    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        // Note: This creates a dependency on PDF text extraction service
        // For now, create our own instance to avoid circular dependency
        let textExtractionService = PDFTextExtractionService()

        return PayslipValidationService(textExtractionService: textExtractionService)
    }

    /// Creates a financial calculation service.
    func makeFinancialCalculationService() -> FinancialCalculationServiceProtocol {
        #if DEBUG
        if useMocks {
            return FinancialCalculationService()
        }
        #endif

        // Use the singleton for now to maintain backward compatibility
        return FinancialCalculationUtility.shared
    }

    /// Creates a military abbreviation service.
    func makeMilitaryAbbreviationService() -> MilitaryAbbreviationServiceProtocol {
        #if DEBUG
        if useMocks {
            return MilitaryAbbreviationService()
        }
        #endif

        // Use the bridge for now to maintain backward compatibility
        return MilitaryAbbreviationServiceBridge()
    }

    /// Creates a payslip display name service
    func makePayslipDisplayNameService() -> PayslipDisplayNameServiceProtocol {
        let arrearsFormatter = ArrearsDisplayFormatter()
        return PayslipDisplayNameService(arrearsFormatter: arrearsFormatter)
    }

    /// Creates a military abbreviations service (Phase 2C factory)
    func makeMilitaryAbbreviationsService() -> MilitaryAbbreviationServiceProtocol {
        #if DEBUG
        if useMocks {
            return MilitaryAbbreviationsService(componentMappings: [:])
        }
        #endif
        return MilitaryAbbreviationsService()
    }

    /// Creates a training data store
    func makeTrainingDataStore() -> TrainingDataStore {
        #if DEBUG
        if useMocks {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_training_data.json")
            return TrainingDataStore(customURL: tempURL)
        }
        #endif
        return TrainingDataStore()
    }

    /// Creates a UI appearance service
    @MainActor
    func makeAppearanceService() -> AppearanceService {
        #if DEBUG
        if useMocks {
            return AppearanceService(setupNotifications: false)
        }
        #endif
        return AppearanceService()
    }

    // MARK: - Network Services

    func makeNetworkService() -> NetworkServiceProtocol {
        let responseHandler = makeNetworkResponseHandler()
        let uploadService = makeNetworkUploadService()

        return NetworkService(
            responseHandler: responseHandler,
            uploadService: uploadService
        )
    }

    func makeNetworkResponseHandler() -> NetworkResponseHandlerProtocol {
        return NetworkResponseHandler()
    }

    func makeNetworkUploadService() -> NetworkUploadServiceProtocol {
        return NetworkUploadService()
    }

    // MARK: - Performance Services

    func makePerformanceCoordinator() -> PerformanceCoordinatorProtocol {
        #if DEBUG
        if useMocks { return PerformanceCoordinator() }
        #endif
        return PerformanceCoordinator()
    }

    func makeFPSMonitor() -> FPSMonitorProtocol {
        #if DEBUG
        if useMocks { return PerformanceFPSMonitor() }
        #endif
        return PerformanceFPSMonitor()
    }

    func makeMemoryMonitor() -> MemoryMonitorProtocol {
        #if DEBUG
        if useMocks { return PerformanceMemoryMonitor() }
        #endif
        return PerformanceMemoryMonitor()
    }

    func makeCPUMonitor() -> CPUMonitorProtocol {
        #if DEBUG
        if useMocks { return PerformanceCPUMonitor() }
        #endif
        return PerformanceCPUMonitor()
    }

    func makePerformanceReporter() -> PerformanceReporterProtocol {
        #if DEBUG
        if useMocks { return PerformanceReporter() }
        #endif
        return PerformanceReporter()
    }

    func makeDualSectionPerformanceMonitor() -> DualSectionPerformanceMonitorProtocol {
        return DualSectionPerformanceMonitor.shared
    }

    func makeClassificationCacheManager() -> ClassificationCacheManagerProtocol {
        return ClassificationCacheManager.shared
    }

    func makeParallelPayCodeProcessor() -> ParallelPayCodeProcessorProtocol {
        return ParallelPayCodeProcessor.shared
    }
}
