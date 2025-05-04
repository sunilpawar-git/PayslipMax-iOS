import Foundation
import SwiftUI
import Combine
import PDFKit
import Vision

// Add the following line if needed
// import PayslipMax

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The error to display to the user.
    @Published var error: AppError?
    
    /// Error message to display to the user.
    @Published var errorMessage: String?
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// Whether the view model is uploading a payslip.
    @Published var isUploading = false
    
    /// The recent payslips to display.
    @Published var recentPayslips: [AnyPayslip] = []
    
    /// The data for the charts.
    @Published var payslipData: [PayslipChartData] = []
    
    /// Whether we're currently processing an unlocked PDF
    @Published var isProcessingUnlocked = false
    
    /// The data for the currently unlocked PDF
    @Published var unlockedPDFData: Data?
    
    /// The error type.
    @Published var errorType: AppError?
    
    // MARK: - Password-related properties (forwarded from passwordHandler)
    
    /// Flag indicating whether to show the password entry view.
    @Published var showPasswordEntryView = false
    
    /// The current PDF data that needs password unlocking.
    @Published var currentPasswordProtectedPDFData: Data?
    
    /// The password for the current PDF
    @Published var currentPDFPassword: String?
    
    // MARK: - Navigation Coordinator (exposed for views)
    
    /// The navigation coordinator that manages navigation logic.
    /// This is exposed to allow views to bind to its published properties.
    var navigationCoordinator: HomeNavigationCoordinator { _navigationCoordinator }
    
    // MARK: - Private Properties
    
    /// The handler for PDF processing operations
    private let pdfHandler: PDFProcessingHandler
    
    /// The handler for payslip data operations
    private let dataHandler: PayslipDataHandler
    
    /// The service for chart data preparation
    private let chartService: ChartDataPreparationService
    
    /// The handler for password-protected PDF operations
    private let passwordHandler: PasswordProtectedPDFHandler
    
    /// The handler for error management
    private let errorHandler: ErrorHandler
    
    /// The coordinator for navigation management
    private let _navigationCoordinator: HomeNavigationCoordinator
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes a new HomeViewModel.
    ///
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
        // Initialize from provided dependencies or default
        self.pdfHandler = pdfHandler ?? DIContainer.shared.makePDFProcessingHandler()
        self.dataHandler = dataHandler ?? DIContainer.shared.makePayslipDataHandler()
        self.chartService = chartService ?? DIContainer.shared.makeChartDataPreparationService()
        self.passwordHandler = passwordHandler ?? DIContainer.shared.makePasswordProtectedPDFHandler()
        self.errorHandler = errorHandler ?? DIContainer.shared.makeErrorHandler()
        self._navigationCoordinator = navigationCoordinator ?? DIContainer.shared.makeHomeNavigationCoordinator()
        
        // Bind published properties from other components
        bindPasswordHandlerProperties()
        bindErrorHandlerProperties()
        bindNavigationCoordinatorProperties()
        
        // Register for notifications
        setupNotificationHandlers()
    }
    
    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    /// Binds the password handler's published properties to our own
    private func bindPasswordHandlerProperties() {
        // Forward passwordHandler published properties to our own
        passwordHandler.$showPasswordEntryView
            .assign(to: \.showPasswordEntryView, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPasswordProtectedPDFData
            .assign(to: \.currentPasswordProtectedPDFData, on: self)
            .store(in: &cancellables)
        
        passwordHandler.$currentPDFPassword
            .assign(to: \.currentPDFPassword, on: self)
            .store(in: &cancellables)
    }
    
    /// Binds the error handler's published properties to our own
    private func bindErrorHandlerProperties() {
        // Forward errorHandler published properties to our own
        errorHandler.$error
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        errorHandler.$errorType
            .assign(to: \.errorType, on: self)
            .store(in: &cancellables)
    }
    
    /// Binds the navigation coordinator's published properties
    private func bindNavigationCoordinatorProperties() {
        // No need to bind properties here since we'll directly expose the coordinator
    }
    
    // MARK: - Notification Handling
    
    /// Sets up notification handlers for payslip events
    private func setupNotificationHandlers() {
        // Listen for payslip deleted events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipDeleted(_:)),
            name: .payslipDeleted,
            object: nil
        )
        
        // Listen for payslip updated events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipUpdated(_:)),
            name: .payslipUpdated,
            object: nil
        )
        
        // Listen for general refresh events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsRefresh),
            name: .payslipsRefresh,
            object: nil
        )
        
        // Listen for forced refresh events (more aggressive refresh)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsForcedRefresh),
            name: .payslipsForcedRefresh,
            object: nil
        )
    }
    
    /// Handles payslip deleted notification
    @objc private func handlePayslipDeleted(_ notification: Notification) {
        guard let payslipId = notification.userInfo?["payslipId"] as? UUID else { return }
        
        // Remove the deleted payslip from recentPayslips if present
        if let index = recentPayslips.firstIndex(where: { $0.id == payslipId }) {
            print("HomeViewModel: Removing deleted payslip from recent payslips")
            recentPayslips.remove(at: index)
        }
        
        // Reload all data to keep everything in sync
        Task {
            await loadRecentPayslipsWithAnimation()
        }
    }
    
    /// Handles payslip updated notification
    @objc private func handlePayslipUpdated(_ notification: Notification) {
        // Reload payslips to get the updated data
        Task {
            await loadRecentPayslipsWithAnimation()
        }
    }
    
    /// Handles general refresh notification
    @objc private func handlePayslipsRefresh() {
        // Reload all payslips
        Task {
            await loadRecentPayslipsWithAnimation()
        }
    }
    
    /// Handles forced refresh notification (more aggressive than regular refresh)
    @objc private func handlePayslipsForcedRefresh() {
        // Force reload of all data with a clean slate
        Task {
            // Clear current data first
            self.recentPayslips = []
            self.payslipData = []
            
            // Small delay to ensure UI updates properly
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Reload all data from scratch
            // Use loadRecentPayslips instead of directly accessing dataService
            await loadRecentPayslipsWithAnimation()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads the recent payslips.
    func loadRecentPayslips() {
        isLoading = true
        
        Task {
            do {
                // Load payslips using the data handler
                let payslips = try await dataHandler.loadRecentPayslips()
                
                // Sort by date (newest first) and take the 5 most recent
                let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
                
                // Prepare chart data using the chart service
                let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)
                
                // Add a slight delay to ensure smooth UI updates
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                
                // Update UI on the main thread with animation
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.recentPayslips = Array(sortedPayslips.prefix(5))
                        self.payslipData = chartData
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorHandler.handleError(error)
                    isLoading = false
                }
            }
        }
    }
    
    /// Processes a payslip PDF from a URL.
    ///
    /// - Parameter url: The URL of the PDF to process.
    func processPayslipPDF(from url: URL) async {
        isLoading = true
        isUploading = true
        
        print("[HomeViewModel] Processing payslip PDF from: \(url.absoluteString)")
        
        // First, try to load the PDF data directly to check for password protection
        guard let pdfData = try? Data(contentsOf: url) else {
            isLoading = false
            isUploading = false
            errorHandler.handleError(AppError.message("Failed to read PDF file"))
            return
        }
        
        // Create a PDFDocument to check if it's password protected
        if let pdfDocument = PDFDocument(data: pdfData), pdfDocument.isLocked {
            print("[HomeViewModel] PDF is password protected, showing password entry")
            // Show the password entry view
            passwordHandler.showPasswordEntry(for: pdfData)
            navigationCoordinator.currentPDFURL = url
            return
        }
        
        // If we got here, the PDF isn't password protected directly, process normally
        let pdfResult = await pdfHandler.processPDF(from: url)
        
        switch pdfResult {
        case .success(let pdfData):
            // Double-check password protection
            if pdfHandler.isPasswordProtected(pdfData) {
                print("[HomeViewModel] PDF is password protected (detected in processPDF), showing password entry")
                // Show the password entry view
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else {
                // Not password-protected, process normally
                await processPDFData(pdfData, from: url)
            }
            
        case .failure(let error):
            print("[HomeViewModel] Error processing PDF: \(error.localizedDescription)")
            
            // Check if the error indicates password protection
            if let appError = error as? AppError, case .passwordProtectedPDF = appError {
                print("[HomeViewModel] AppError indicates password protection")
                // Pass the original PDF data to the password handler
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else if let pdfError = error as? PDFProcessingError, pdfError == .passwordProtected {
                print("[HomeViewModel] PDFProcessingError indicates password protection")
                // Pass the original PDF data to the password handler
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else {
                isLoading = false
                isUploading = false
                errorHandler.handlePDFError(error)
            }
        }
    }
    
    /// Processes PDF data after it has been unlocked or loaded directly.
    ///
    /// - Parameters:
    ///   - data: The PDF data to process.
    ///   - url: The original URL of the PDF file (optional).
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        isLoading = true
        isUploading = true
        print("[HomeViewModel] Processing PDF data with \(data.count) bytes")
        
        // Use the PDF handler to process the data
        let result = await pdfHandler.processPDFData(data, from: url)
        
        // Ensure loading state is reset at the end
        defer {
            isLoading = false
            isUploading = false
            isProcessingUnlocked = false
        }
        
        switch result {
        case .success(let payslipItem):
            print("[HomeViewModel] Successfully parsed payslip")
            
            // Save the imported payslip using the data handler
            do {
                try await dataHandler.savePayslipItem(payslipItem)
                print("[HomeViewModel] Payslip saved successfully")
                
                // Reload the payslips
                await loadRecentPayslipsWithAnimation()
                
                // Navigate to the newly added payslip using the navigation coordinator
                navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                
                // Reset password state if applicable
                if showPasswordEntryView {
                    passwordHandler.resetPasswordState()
                }
            } catch {
                print("[HomeViewModel] Error saving payslip: \(error.localizedDescription)")
                errorHandler.handleError(error)
            }
            
        case .failure(let error):
            print("[HomeViewModel] PDF processing failed: \(error.localizedDescription)")
            errorHandler.handlePDFError(error)
        }
    }
    
    /// Handles an unlocked PDF.
    ///
    /// - Parameter data: The unlocked PDF data.
    /// - Parameter originalPassword: The original password used to unlock the PDF.
    func handleUnlockedPDF(data: Data, originalPassword: String) async {
        print("[HomeViewModel] Handling unlocked PDF with \(data.count) bytes")
        
        isProcessingUnlocked = true
        
        // First detect format before we process it
        let format = pdfHandler.detectPayslipFormat(data)
        print("[HomeViewModel] Detected format: \(format)")
        
        // Verify we have a valid PDF document
        if let pdfDocument = PDFDocument(data: data) {
            print("[HomeViewModel] PDF document created successfully with \(pdfDocument.pageCount) pages")
            
            // Store the unlocked PDF document for later use using the navigation coordinator
            navigationCoordinator.setPDFDocument(pdfDocument, url: navigationCoordinator.currentPDFURL)
            
            // Store the unlocked data
            DispatchQueue.main.async {
                self.unlockedPDFData = data
            }
        } else {
            print("[HomeViewModel] Warning: Could not create PDF document from unlocked data")
        }
        
        // Process the PDF data using the handler
        await processPDFData(data)
        
        // After processing is complete, mark that we're done
        isProcessingUnlocked = false
        passwordHandler.resetPasswordState()
    }
    
    /// Processes a manual entry.
    ///
    /// - Parameter payslipData: The payslip data to process.
    func processManualEntry(_ payslipData: PayslipManualEntryData) {
        Task {
            // Create a payslip item from the manual entry data
            let payslipItem = dataHandler.createPayslipFromManualEntry(payslipData)
            
            // Save the manual entry using the data handler
            do {
                try await dataHandler.savePayslipItem(payslipItem)
                await loadRecentPayslipsWithAnimation()
                
                // Navigate to the newly added payslip using the navigation coordinator
                navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
            } catch {
                errorHandler.handleError(error)
            }
        }
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) {
        isUploading = true
        
        Task {
            // Use the PDF handler to process the scanned image
            let result = await pdfHandler.processScannedImage(image)
            
            switch result {
            case .success(let payslipItem):
                do {
                    // Save the payslip using the data handler
                    try await dataHandler.savePayslipItem(payslipItem)
                    
                    // Update UI and navigate using the navigation coordinator
                    navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                    await loadRecentPayslipsWithAnimation()
                } catch {
                    errorHandler.handleError(AppError.pdfProcessingFailed(error.localizedDescription))
                }
                
            case .failure(let error):
                errorHandler.handleError(AppError.pdfProcessingFailed(error.localizedDescription))
            }
            
            isUploading = false
        }
    }
    
    /// Loads recent payslips with animation.
    func loadRecentPayslipsWithAnimation() async {
        do {
            // Get payslips from the data handler
            let payslips = try await dataHandler.loadRecentPayslips()
            
            // Sort and filter
            let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
            let recentOnes = Array(sortedPayslips.prefix(5))
            
            // Update chart data using the chart service
            let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)
            
            // Update UI with animation
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.recentPayslips = recentOnes
                    self.payslipData = chartData
                }
            }
        } catch {
            print("HomeViewModel: Error loading payslips: \(error.localizedDescription)")
        }
    }
    
    /// Cancels loading.
    func cancelLoading() {
        isLoading = false
        isUploading = false
    }
    
    /// Handles an error by setting the appropriate error properties.
    /// - Parameter error: The error to handle.
    func handleError(_ error: Error) {
        // Delegate to the error handler
        errorHandler.handleError(error)
    }
    
    /// Clears the current error state.
    func clearError() {
        // Delegate to the error handler
        errorHandler.clearError()
    }
    
    /// Shows the manual entry form.
    func showManualEntry() {
        // Delegate to the navigation coordinator
        navigationCoordinator.showManualEntry()
    }
} 