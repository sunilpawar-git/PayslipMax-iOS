import Foundation
import SwiftUI
import Combine
import PDFKit
import Vision

// Add the following line if needed
// import Payslip_Max

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
    
    /// Whether to show the manual entry form.
    @Published var showManualEntryForm = false
    
    /// The recent payslips to display.
    @Published var recentPayslips: [any PayslipItemProtocol] = []
    
    /// The data for the charts.
    @Published var payslipData: [PayslipChartData] = []
    
    /// Flag indicating whether to show the parsing feedback view.
    @Published var showParsingFeedbackView = false
    
    /// Flag indicating whether to navigate to the detail view for a newly added payslip.
    @Published var navigateToNewPayslip = false
    
    /// Flag indicating whether to show the password entry view.
    @Published var showPasswordEntryView = false
    
    /// The parsed payslip item to display in the feedback view.
    @Published var parsedPayslipItem: PayslipItem?
    
    /// The newly added payslip for direct navigation.
    @Published var newlyAddedPayslip: PayslipItem?
    
    /// The PDF document being processed.
    @Published var currentPDFDocument: PDFDocument?
    
    /// The current PDF data that needs password unlocking.
    @Published var currentPasswordProtectedPDFData: Data?
    
    /// The current PDF URL that is being processed.
    @Published var currentPDFURL: URL?
    
    // MARK: - Private Properties
    
    /// The PDF processing service for all PDF operations.
    private let pdfProcessingService: PDFProcessingServiceProtocol
    
    /// The data service to use for fetching and saving data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes a new HomeViewModel.
    ///
    /// - Parameters:
    ///   - pdfProcessingService: The PDF processing service for all PDF operations.
    ///   - dataService: The data service to use for fetching and saving data.
    init(
        pdfProcessingService: PDFProcessingServiceProtocol,
        dataService: DataServiceProtocol
    ) {
        self.pdfProcessingService = pdfProcessingService
        self.dataService = dataService
    }
    
    // MARK: - Public Methods
    
    /// Loads the recent payslips.
    func loadRecentPayslips() {
        isLoading = true
        
        Task {
            do {
                // Initialize the data service if it's not already initialized
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                let payslips = try await dataService.fetch(PayslipItem.self)
                
                // Sort by date (newest first) and take the 5 most recent
                let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
                
                // Prepare chart data
                let chartData = prepareChartDataInBackground(from: sortedPayslips)
                
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
                handleError(error)
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
        currentPDFURL = url
        
        // Check if PDF processing service is initialized
        if !pdfProcessingService.isInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                isLoading = false
                errorMessage = "Failed to initialize PDF processing: \(error.localizedDescription)"
                return
            }
        }
        
        // Process the PDF using the service
        let result = await pdfProcessingService.processPDF(from: url)
        
        switch result {
        case .success(let pdfData):
            // Check if it's password protected
            if pdfProcessingService.isPasswordProtected(pdfData) {
                // Show password entry field
                currentPasswordProtectedPDFData = pdfData
                showPasswordEntryView = true
                isLoading = false
            } else {
                // Process the PDF data directly
                await processPDFData(pdfData)
            }
            
        case .failure(let error):
            isLoading = false
            
            if case .passwordProtected = error {
                // Handle password protected case
                if let pdfData = try? Data(contentsOf: url) {
                    currentPasswordProtectedPDFData = pdfData
                    showPasswordEntryView = true
                } else {
                    errorMessage = "Failed to read PDF file"
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Processes PDF data after it has been unlocked or loaded directly.
    ///
    /// - Parameters:
    ///   - data: The PDF data to process.
    ///   - url: The original URL of the PDF file (optional).
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        isUploading = true
        
        // Use the PDF processing service to process the data
        let result = await pdfProcessingService.processPDFData(data)
        
        switch result {
        case .success(let payslipItem):
            // Store the newly added payslip for navigation
            newlyAddedPayslip = payslipItem
            
            // Save the imported payslip
            do {
                try await dataService.save(payslipItem)
                
                // Also save the PDF to the PDFManager for better persistence
                let pdfData = payslipItem.pdfData ?? data
                do {
                    let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                    print("HomeViewModel: PDF saved successfully at: \(pdfURL.path)")
                } catch {
                    print("HomeViewModel: Error saving PDF: \(error.localizedDescription)")
                }
                
                // Reload the payslips
                await loadRecentPayslipsWithAnimation()
                
                // Navigate to the newly added payslip
                navigateToNewPayslip = true
            } catch {
                handleError(error)
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        
        isUploading = false
        isLoading = false
    }
    
    /// Handles an unlocked PDF.
    ///
    /// - Parameter unlockedData: The unlocked PDF data.
    func handleUnlockedPDF(_ unlockedData: Data) async {
        await processPDFData(unlockedData, from: currentPDFURL)
    }
    
    /// Processes a manual entry.
    ///
    /// - Parameter payslipData: The payslip data to process.
    func processManualEntry(_ payslipData: PayslipManualEntryData) {
        Task {
            // Initialize the data service if it's not already initialized
            if !dataService.isInitialized {
                do {
                    try await dataService.initialize()
                } catch {
                    handleError(error)
                    return
                }
            }
            
            // Convert PayslipManualEntryData to PayslipItem
            let payslipItem = PayslipItem(
                id: UUID(),
                month: payslipData.month,
                year: payslipData.year,
                credits: payslipData.credits,
                debits: payslipData.debits,
                dsop: payslipData.dsop,
                tax: payslipData.tax,
                location: payslipData.location,
                name: payslipData.name,
                accountNumber: "",
                panNumber: "",
                timestamp: Date(),
                pdfData: nil
            )
            
            // Save the manual entry
            do {
                try await dataService.save(payslipItem)
                await loadRecentPayslipsWithAnimation()
                
                // Store for navigation
                newlyAddedPayslip = payslipItem
                navigateToNewPayslip = true
            } catch {
                handleError(error)
            }
        }
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) {
        isUploading = true
        
        Task {
            // Initialize services if needed
            if !dataService.isInitialized {
                do {
                    try await dataService.initialize()
                } catch {
                    handleError(error)
                    isUploading = false
                    return
                }
            }
            
            if !pdfProcessingService.isInitialized {
                do {
                    try await pdfProcessingService.initialize()
                } catch {
                    handleError(error)
                    isUploading = false
                    return
                }
            }
            
            // Use the service to process the scanned image
            let result = await pdfProcessingService.processScannedImage(image)
            
            switch result {
            case .success(let payslipItem):
                // Store the newly added payslip for navigation
                newlyAddedPayslip = payslipItem
                
                do {
                    // Save the payslip
                    try await dataService.save(payslipItem)
                    
                    // Also save the PDF to the PDFManager
                    if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
                        do {
                            let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                            print("HomeViewModel: Scanned PDF saved at: \(pdfURL.path)")
                        } catch {
                            print("HomeViewModel: Failed to save scanned PDF: \(error)")
                        }
                    }
                    
                    // Update UI
                    navigateToNewPayslip = true
                    await loadRecentPayslipsWithAnimation()
                } catch {
                    handleError(error)
                }
                
            case .failure(let error):
                handleError(AppError.pdfProcessingFailed(error.localizedDescription))
            }
            
            isUploading = false
        }
    }
    
    /// Loads recent payslips with animation.
    func loadRecentPayslipsWithAnimation() async {
        do {
            // Get payslips from the data service
            let payslips = try await dataService.fetch(PayslipItem.self)
            
            // Sort and filter
            let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
            let recentOnes = Array(sortedPayslips.prefix(5))
            
            // Update chart data
            let chartData = prepareChartDataInBackground(from: sortedPayslips)
            
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
    
    // MARK: - Private Methods
    
    /// Prepares chart data from payslips.
    ///
    /// - Parameter payslips: The payslips to prepare chart data from.
    /// - Returns: The prepared chart data.
    private func prepareChartDataInBackground(from payslips: [any PayslipItemProtocol]) -> [PayslipChartData] {
        var chartDataArray: [PayslipChartData] = []
        
        // Group payslips by month and year
        for payslip in payslips {
            let month = "\(payslip.month)"
            let credits = payslip.credits
            let debits = payslip.debits
            let net = credits - debits
            
            // Create chart data for this payslip
            let chartData = PayslipChartData(
                month: month,
                credits: credits,
                debits: debits,
                net: net
            )
            
            chartDataArray.append(chartData)
        }
        
        return chartDataArray
    }
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
} 