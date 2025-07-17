import Foundation
import SwiftUI
import Combine
import PDFKit
import Vision

/// Main coordinator for HomeViewModel that orchestrates all specialized coordinators
/// Follows Option B refactoring strategy with focused sub-coordinators
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
    var navigationCoordinator: HomeNavigationCoordinator { _navigationCoordinator }
    
    // MARK: - Private Properties
    
    /// The handler for password-protected PDF operations
    private let passwordHandler: PasswordProtectedPDFHandler
    
    /// The handler for error management
    private let errorHandler: ErrorHandler
    
    /// The navigation coordinator (private backing storage)
    private let _navigationCoordinator: HomeNavigationCoordinator
    
    /// The cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
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
        navigationCoordinator: HomeNavigationCoordinator? = nil
    ) {
        // Initialize handlers from provided dependencies or default
        let pdfHandlerInstance = pdfHandler ?? DIContainer.shared.makePDFProcessingHandler()
        let dataHandlerInstance = dataHandler ?? DIContainer.shared.makePayslipDataHandler()
        let chartServiceInstance = chartService ?? DIContainer.shared.makeChartDataPreparationService()
        self.passwordHandler = passwordHandler ?? DIContainer.shared.makePasswordProtectedPDFHandler()
        self.errorHandler = errorHandler ?? DIContainer.shared.makeErrorHandler()
        self._navigationCoordinator = navigationCoordinator ?? DIContainer.shared.makeHomeNavigationCoordinator()
        
        // Initialize coordinators
        self.pdfCoordinator = PDFProcessingCoordinator(
            pdfHandler: pdfHandlerInstance,
            passwordHandler: self.passwordHandler,
            navigationCoordinator: self._navigationCoordinator
        )
        
        self.dataCoordinator = DataLoadingCoordinator(
            dataHandler: dataHandlerInstance,
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
    
    // MARK: - Public Methods
    
    /// Loads the recent payslips
    func loadRecentPayslips() {
        Task {
            await dataCoordinator.loadRecentPayslips()
        }
    }
    
    /// Processes a payslip PDF from a URL
    /// - Parameter url: The URL of the PDF to process
    func processPayslipPDF(from url: URL) async {
        await pdfCoordinator.processPayslipPDF(from: url)
    }
    
    /// Processes PDF data after it has been unlocked or loaded directly
    /// - Parameters:
    ///   - data: The PDF data to process
    ///   - url: The original URL of the PDF file (optional)
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        await pdfCoordinator.processPDFData(data, from: url)
    }
    
    /// Handles an unlocked PDF
    /// - Parameters:
    ///   - data: The unlocked PDF data
    ///   - originalPassword: The original password used to unlock the PDF
    func handleUnlockedPDF(data: Data, originalPassword: String) async {
        await pdfCoordinator.handleUnlockedPDF(data: data, originalPassword: originalPassword)
    }
    
    /// Processes a manual entry
    /// - Parameter payslipData: The payslip data to process
    func processManualEntry(_ payslipData: PayslipManualEntryData) {
        Task {
            await manualEntryCoordinator.processManualEntry(payslipData)
        }
    }
    
    /// Hides the manual entry form
    func hideManualEntry() {
        manualEntryCoordinator.hideManualEntry()
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) {
        Task {
            await manualEntryCoordinator.processScannedPayslip(from: image)
        }
    }
    
    /// Loads recent payslips with animation
    func loadRecentPayslipsWithAnimation() async {
        await dataCoordinator.loadRecentPayslipsWithAnimation()
    }
    
    /// Cancels loading
    func cancelLoading() {
        pdfCoordinator.cancelProcessing()
        dataCoordinator.cancelLoading()
        manualEntryCoordinator.cancelProcessing()
    }
    
    /// Handles an error by setting the appropriate error properties
    /// - Parameter error: The error to handle
    func handleError(_ error: Error) {
        errorHandler.handleError(error)
    }
    
    /// Clears the current error state
    func clearError() {
        errorHandler.clearError()
    }
    
    /// Shows the manual entry form
    func showManualEntry() {
        print("[HomeViewModel] showManualEntry called")
        
        // Add a small delay to ensure UI is ready and avoid conflicts with other sheets
        Task { @MainActor in
            // Small delay to ensure any other sheet dismissals are complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            print("[HomeViewModel] About to call manualEntryCoordinator.showManualEntry()")
            manualEntryCoordinator.showManualEntry()
            print("[HomeViewModel] manualEntryCoordinator.showManualEntry() completed")
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up completion handlers between coordinators
    private func setupCoordinatorHandlers() {
        // PDF processing completion handlers
        pdfCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] payslipItem in
                Task { @MainActor in
                    do {
                        try await self?.dataCoordinator.savePayslipAndReload(payslipItem)
                        self?.navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                        
                        // Reset password state if applicable
                        if self?.showPasswordEntryView == true {
                            self?.passwordHandler.resetPasswordState()
                        }
                    } catch {
                        self?.errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { [weak self] error in
                self?.errorHandler.handlePDFError(error)
            }
        )
        
        // Manual entry processing completion handlers
        manualEntryCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] payslipItem in
                Task { @MainActor in
                    do {
                        try await self?.dataCoordinator.savePayslipAndReload(payslipItem)
                        self?.navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                    } catch {
                        self?.errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { [weak self] error in
                self?.errorHandler.handleError(error)
            }
        )
        
        // Data loading completion handlers
        dataCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] in
                guard self != nil else { return }
                print("HomeViewModel: Data loading completed successfully")
            },
            onFailure: { [weak self] (error: Error) in
                self?.errorHandler.handleError(error)
            }
        )
        
        // Notification handling setup
        notificationCoordinator.setCompletionHandlers(
            onPayslipDeleted: { [weak self] payslipId in
                Task { @MainActor in
                    await self?.dataCoordinator.removePayslipFromList(payslipId)
                }
            },
            onPayslipUpdated: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.refreshData()
                }
            },
            onPayslipsRefresh: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.refreshData()
                }
            },
            onPayslipsForcedRefresh: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.forcedRefresh()
                }
            }
        )
    }
    
    /// Binds the password handler's published properties to our own
    private func bindPasswordHandlerProperties() {
        passwordHandler.$showPasswordEntryView
            .assign(to: \HomeViewModel.showPasswordEntryView, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPasswordProtectedPDFData
            .assign(to: \HomeViewModel.currentPasswordProtectedPDFData, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPDFPassword
            .assign(to: \HomeViewModel.currentPDFPassword, on: self)
            .store(in: &cancellables)
    }
    
    /// Binds the error handler's published properties to our own
    private func bindErrorHandlerProperties() {
        errorHandler.$error
            .assign(to: \HomeViewModel.error, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorMessage
            .assign(to: \HomeViewModel.errorMessage, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorType
            .assign(to: \HomeViewModel.errorType, on: self)
            .store(in: &cancellables)
    }
    
    /// Binds the data coordinator's published properties to our own
    private func bindDataCoordinatorProperties() {
        dataCoordinator.$recentPayslips
            .assign(to: \HomeViewModel.recentPayslips, on: self)
            .store(in: &cancellables)
        
        dataCoordinator.$payslipData
            .assign(to: \HomeViewModel.payslipData, on: self)
            .store(in: &cancellables)
    }

}

// MARK: - Convenience Properties

extension HomeViewModel {
    /// Whether the view model is loading data
    var isLoading: Bool {
        dataCoordinator.isLoading || pdfCoordinator.isProcessing || manualEntryCoordinator.isProcessing
    }
    
    /// Whether the view model is uploading a payslip
    var isUploading: Bool {
        pdfCoordinator.isUploading
    }
    
    /// Whether we're currently processing an unlocked PDF
    var isProcessingUnlocked: Bool {
        pdfCoordinator.isProcessingUnlocked
    }
    
    /// The data for the currently unlocked PDF
    var unlockedPDFData: Data? {
        pdfCoordinator.unlockedPDFData
    }
    
    /// Flag indicating whether to show the manual entry form
    var showManualEntryForm: Bool {
        manualEntryCoordinator.showManualEntryForm
    }
    
    /// Binding for the manual entry form state
    var showManualEntryFormBinding: Binding<Bool> {
        Binding(
            get: { 
                let currentState = self.manualEntryCoordinator.showManualEntryForm
                print("[HomeViewModel] showManualEntryFormBinding GET: \(currentState)")
                return currentState
            },
            set: { newValue in
                print("[HomeViewModel] showManualEntryFormBinding SET: \(newValue)")
                if newValue {
                    print("[HomeViewModel] Binding triggered showManualEntry()")
                    self.manualEntryCoordinator.showManualEntry()
                } else {
                    print("[HomeViewModel] Binding triggered hideManualEntry()")
                    self.manualEntryCoordinator.hideManualEntry()
                }
            }
        )
    }
} 