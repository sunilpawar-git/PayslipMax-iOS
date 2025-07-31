import Foundation
import SwiftUI

/// Container for ViewModels and their supporting services.
/// Handles all ViewModel factory methods and manages ViewModel state consistency through caching.
@MainActor
class ViewModelContainer: ViewModelContainerProtocol {
    
    // MARK: - Properties
    
    /// Whether to use mock implementations for testing.
    let useMocks: Bool
    
    // MARK: - Dependencies
    
    /// Core service container for accessing security, data, and validation services
    private let coreContainer: CoreServiceContainerProtocol
    
    /// Processing container for accessing PDF processing services
    private let processingContainer: ProcessingContainerProtocol
    
    // MARK: - Cached ViewModels for State Consistency
    
    /// Cached payslips view model to maintain state consistency
    private var _payslipsViewModel: PayslipsViewModel?
    
    /// Cached quiz view model to maintain state consistency
    private var _quizViewModel: QuizViewModel?
    
    /// Cached achievement service for consistency
    private var _achievementService: AchievementService?
    
    /// Cached quiz generation service for consistency
    private var _quizGenerationService: QuizGenerationService?
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false, 
         coreContainer: CoreServiceContainerProtocol,
         processingContainer: ProcessingContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
        self.processingContainer = processingContainer
    }
    
    // MARK: - Core ViewModels
    
    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel {
        let pdfHandler = makePDFProcessingHandler()
        let dataHandler = makePayslipDataHandler()
        let chartService = makeChartDataPreparationService()
        let passwordHandler = makePasswordProtectedPDFHandler()
        let errorHandler = makeErrorHandler()
        let navigationCoordinator = makeHomeNavigationCoordinator()
        
        return HomeViewModel(
            pdfHandler: pdfHandler,
            dataHandler: dataHandler,
            chartService: chartService,
            passwordHandler: passwordHandler,
            errorHandler: errorHandler,
            navigationCoordinator: navigationCoordinator
        )
    }
    
    /// Creates a PDFProcessingViewModel (delegates to HomeViewModel).
    func makePDFProcessingViewModel() -> any ObservableObject {
        // Use the updated HomeViewModel constructor
        return makeHomeViewModel()
    }
    
    /// Creates a PayslipDataViewModel (delegates to PayslipsViewModel).
    func makePayslipDataViewModel() -> any ObservableObject {
        // Fallback - use PayslipsViewModel instead
        return PayslipsViewModel(dataService: coreContainer.makeDataService())
    }
    
    /// Creates an AuthViewModel.
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: coreContainer.makeSecurityService())
    }
    
    /// Creates a PayslipsViewModel (cached for state consistency).
    func makePayslipsViewModel() -> PayslipsViewModel {
        // Return cached instance if available to maintain state consistency
        if let existingViewModel = _payslipsViewModel {
            return existingViewModel
        }
        
        // Create a new instance and cache it
        let viewModel = PayslipsViewModel(dataService: coreContainer.makeDataService())
        _payslipsViewModel = viewModel
        return viewModel
    }
    
    /// Creates an InsightsCoordinator.
    func makeInsightsCoordinator() -> InsightsCoordinator {
        return InsightsCoordinator(dataService: coreContainer.makeDataService())
    }
    
    /// Creates a SettingsViewModel.
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: coreContainer.makeSecurityService(), dataService: coreContainer.makeDataService())
    }
    
    /// Creates a SecurityViewModel.
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    // MARK: - Feature ViewModels
    
    /// Creates a QuizViewModel (cached for state consistency).
    func makeQuizViewModel() -> QuizViewModel {
        // Return cached instance if available to maintain state consistency
        if let existingViewModel = _quizViewModel {
            return existingViewModel
        }
        
        // Create a new instance and cache it
        let viewModel = QuizViewModel(
            quizGenerationService: makeQuizGenerationService(),
            achievementService: makeAchievementService()
        )
        _quizViewModel = viewModel
        return viewModel
    }
    
    /// Creates a WebUploadViewModel.
    func makeWebUploadViewModel() -> WebUploadViewModel {
        return WebUploadViewModel(
            webUploadService: makeWebUploadService()
        )
    }
    
    // MARK: - Supporting Services for ViewModels
    
    /// Creates a PDFProcessingHandler instance
    private func makePDFProcessingHandler() -> PDFProcessingHandler {
        return PDFProcessingHandler(pdfProcessingService: makePDFProcessingService())
    }
    
    /// Creates a payslip data handler.
    private func makePayslipDataHandler() -> PayslipDataHandler {
        return PayslipDataHandler(dataService: coreContainer.makeDataService())
    }
    
    /// Creates a chart data preparation service.
    private func makeChartDataPreparationService() -> ChartDataPreparationService {
        return ChartDataPreparationService()
    }
    
    /// Creates a PasswordProtectedPDFHandler instance
    private func makePasswordProtectedPDFHandler() -> PasswordProtectedPDFHandler {
        return PasswordProtectedPDFHandler(pdfService: coreContainer.makePDFService())
    }
    
    /// Creates a home navigation coordinator.
    private func makeHomeNavigationCoordinator() -> HomeNavigationCoordinator {
        return HomeNavigationCoordinator()
    }
    
    /// Creates an error handler.
    private func makeErrorHandler() -> ErrorHandler {
        return ErrorHandler()
    }
    
    /// Creates a PDFProcessingService.
    private func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return PDFProcessingService(
            pdfService: coreContainer.makePDFService(),
            pdfExtractor: coreContainer.makePDFExtractor(),
            parsingCoordinator: processingContainer.makePDFParsingCoordinator(),
            formatDetectionService: coreContainer.makePayslipFormatDetectionService(),
            validationService: coreContainer.makePayslipValidationService(),
            textExtractionService: processingContainer.makePDFTextExtractionService()
        )
    }
    
    // MARK: - Gamification Services (for QuizViewModel)
    
    /// Creates a quiz generation service (cached for consistency).
    private func makeQuizGenerationService() -> QuizGenerationService {
        // Return cached instance if available to maintain state consistency
        if let existingService = _quizGenerationService {
            return existingService
        }
        
        // Create a new instance and cache it
        let service = QuizGenerationService(
            financialSummaryViewModel: FinancialSummaryViewModel(),
            trendAnalysisViewModel: TrendAnalysisViewModel(),
            chartDataViewModel: ChartDataViewModel()
        )
        _quizGenerationService = service
        return service
    }
    
    /// Creates an achievement service (cached for consistency).
    private func makeAchievementService() -> AchievementService {
        // Return cached instance if available to maintain state consistency
        if let existingService = _achievementService {
            return existingService
        }
        
        // Create a new instance and cache it
        let service = AchievementService()
        _achievementService = service
        return service
    }
    
    // MARK: - Web Upload Services (for WebUploadViewModel)
    
    /// Creates a WebUploadService instance (delegated implementation)
    /// Note: This should be moved to a FeatureContainer in future phases
    private func makeWebUploadService() -> WebUploadServiceProtocol {
        // This is a temporary delegation - will be moved to FeatureContainer
        // For now, we need to implement basic logic here
        #if DEBUG
        let shouldUseMock = useMocks
        #else
        let shouldUseMock = false
        #endif
        
        if shouldUseMock {
            return MockWebUploadService()
        }
        
        // Create WebUploadCoordinator with proper dependencies
        return WebUploadCoordinator.create(
            secureStorage: coreContainer.makeSecureStorage(),
            baseURL: URL(string: "https://payslipmax.com/api")!
        )
    }
}