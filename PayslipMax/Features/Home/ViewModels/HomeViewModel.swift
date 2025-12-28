import Foundation
import SwiftUI
import Combine
import PDFKit
import Vision

/// Main coordinator for HomeViewModel that orchestrates all specialized coordinators
/// Follows Option B refactoring strategy with focused sub-coordinators
/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: ~150 lines (Core state and initialization only)
/// Next action at 250 lines: Extract additional components
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The error to display to the user
    @Published var error: AppError?

    /// Error message to display to the user
    @Published var errorMessage: String?

    /// The error type
    @Published var errorType: AppError?

    // MARK: - Password-related properties (forwarded from passwordHandler)

    /// Flag indicating whether to show the password entry view
    @Published var showPasswordEntryView = false

    /// The current PDF data that needs password unlocking
    @Published var currentPasswordProtectedPDFData: Data?

    /// The password for the current PDF
    @Published var currentPDFPassword: String?

    /// The recent payslips to display
    @Published var recentPayslips: [AnyPayslip] = []

    /// The data for the charts
    @Published var payslipData: [PayslipChartData] = []

    // MARK: - Coordinator Properties (exposed for views)

    /// The PDF processing coordinator
    let pdfCoordinator: PDFProcessingCoordinator

    /// The data loading coordinator
    let dataCoordinator: DataLoadingCoordinator

    /// The notification coordinator
    let notificationCoordinator: NotificationCoordinator

    /// The manual entry coordinator
    let manualEntryCoordinator: ManualEntryCoordinator

    /// The navigation coordinator
    var navigationCoordinator: HomeNavigationCoordinator { backingNavigationCoordinator }

    /// The quiz view model for gamification features
    let quizViewModel: QuizViewModel

    /// The gamification coordinator for achievements and progress
    let gamificationCoordinator: GamificationCoordinator

    // MARK: - Private Properties

    /// The handler for password-protected PDF operations
    internal let passwordHandler: PasswordProtectedPDFHandler

    /// The handler for error management
    internal let errorHandler: ErrorHandler

    /// The navigation coordinator (private backing storage)
    internal let backingNavigationCoordinator: HomeNavigationCoordinator

    /// The cancellables for managing subscriptions
    internal var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes a new HomeViewModelCoordinator
    /// - Parameters:
    ///   - pdfHandler: The handler for PDF processing operations
    ///   - dataHandler: The handler for payslip data operations
    ///   - chartService: The service for chart data preparation
    ///   - passwordHandler: The handler for password-protected PDF operations
    ///   - errorHandler: The handler for error management
    ///   - navigationCoordinator: The coordinator for navigation management
    init(
        pdfHandler: PDFProcessingHandler? = nil,
        dataHandler: PayslipDataHandler? = nil,
        chartService: ChartDataPreparationService? = nil,
        passwordHandler: PasswordProtectedPDFHandler? = nil,
        errorHandler: ErrorHandler? = nil,
        navigationCoordinator: HomeNavigationCoordinator? = nil,
        quizViewModel: QuizViewModel? = nil,
        gamificationCoordinator: GamificationCoordinator? = nil
    ) {
        // Initialize handlers from provided dependencies or default
        let pdfHandlerInstance = pdfHandler ?? DIContainer.shared.makePDFProcessingHandler()
        let dataHandlerInstance = dataHandler ?? DIContainer.shared.makePayslipDataHandler()
        let chartServiceInstance = chartService ?? DIContainer.shared.makeChartDataPreparationService()
        let cacheManagerInstance = DIContainer.shared.makePayslipCacheManager()
        self.passwordHandler = passwordHandler ?? DIContainer.shared.makePasswordProtectedPDFHandler()
        self.errorHandler = errorHandler ?? DIContainer.shared.makeErrorHandler()
        self.backingNavigationCoordinator = navigationCoordinator ?? DIContainer.shared.makeHomeNavigationCoordinator()
        self.quizViewModel = quizViewModel ?? DIContainer.shared.makeQuizViewModel()
        self.gamificationCoordinator = gamificationCoordinator ?? DIContainer.shared.makeGamificationCoordinator()

        // Initialize coordinators
        self.pdfCoordinator = PDFProcessingCoordinator(
            pdfHandler: pdfHandlerInstance,
            passwordHandler: self.passwordHandler,
            navigationCoordinator: self.backingNavigationCoordinator
        )

        self.dataCoordinator = DataLoadingCoordinator(
            dataHandler: dataHandlerInstance,
            cacheManager: cacheManagerInstance,
            chartService: chartServiceInstance
        )

        self.notificationCoordinator = NotificationCoordinator()

        self.manualEntryCoordinator = ManualEntryCoordinator(
            pdfHandler: pdfHandlerInstance
        )

        // Setup coordinator relationships
        setupCoordinatorHandlers()

        // Bind published properties from other components
        bindPasswordHandlerProperties()
        bindErrorHandlerProperties()
        bindDataCoordinatorProperties()
    }

    deinit {
        // Clean up notification observers (handled by individual coordinators)
        NotificationCenter.default.removeObserver(self)
    }
}
