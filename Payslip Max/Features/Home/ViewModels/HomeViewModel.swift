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
    
    /// Whether we're currently processing an unlocked PDF
    @Published var isProcessingUnlocked = false
    
    /// The data for the currently unlocked PDF
    @Published var unlockedPDFData: Data?
    
    /// The password for the current PDF
    @Published var currentPDFPassword: String?
    
    /// The error type.
    @Published var errorType: AppError?
    
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
        print("[HomeViewModel] Process PDF Data started with \(data.count) bytes")
        if let url = url {
            print("[HomeViewModel] PDF Source URL: \(url.lastPathComponent)")
        }
        
        // First, verify we can actually create a valid PDFDocument from the data
        if let pdfDocument = PDFDocument(data: data) {
            print("[HomeViewModel] Valid PDF document created with \(pdfDocument.pageCount) pages")
            // Set the current document for potential display
            DispatchQueue.main.async {
                self.currentPDFDocument = pdfDocument
            }
        } else {
            print("[HomeViewModel] WARNING: Could not create PDFDocument from data")
            // Try to repair the PDF
            let repairedData = PDFManager.shared.verifyAndRepairPDF(data: data)
            print("[HomeViewModel] Repaired PDF data size: \(repairedData.count) bytes")
            
            if let repairedDocument = PDFDocument(data: repairedData) {
                print("[HomeViewModel] Successfully created PDF document from repaired data")
                DispatchQueue.main.async {
                    self.currentPDFDocument = repairedDocument
                }
            }
        }
        
        // Special handling for military PDFs - check format before processing
        let format = pdfProcessingService.detectPayslipFormat(data)
        print("[HomeViewModel] Detected format: \(format)")
        
        if format == .military {
            print("[HomeViewModel] Military PDF format detected, applying special handling")
            
            // For military PDFs that have been unlocked, we need special handling
            if currentPasswordProtectedPDFData != nil {
                print("[HomeViewModel] This was originally a password-protected PDF")
            }
        }
        
        // Use the PDF processing service to process the data
        print("[HomeViewModel] Calling pdfProcessingService.processPDFData")
        let result = await pdfProcessingService.processPDFData(data)
        print("[HomeViewModel] processPDFData completed with result: \(result)")
        
        switch result {
        case .success(let payslipItem):
            print("[HomeViewModel] Successfully parsed payslip: \(payslipItem.month) \(payslipItem.year), credits: \(payslipItem.credits), debits: \(payslipItem.debits)")
            
            // Additional debug for military PDFs
            if format == .military {
                print("[HomeViewModel] Military PDF earnings count: \(payslipItem.earnings.count)")
                for (key, value) in payslipItem.earnings {
                    print("[HomeViewModel] Earning: \(key) = \(value)")
                }
                print("[HomeViewModel] Military PDF deductions count: \(payslipItem.deductions.count)")
                for (key, value) in payslipItem.deductions {
                    print("[HomeViewModel] Deduction: \(key) = \(value)")
                }
            }
            
            // Ensure the PDF data is attached to the payslip
            if payslipItem.pdfData == nil {
                print("[HomeViewModel] Attaching PDF data to payslip")
                payslipItem.pdfData = data
            }
            
            // Store the newly added payslip for navigation
            newlyAddedPayslip = payslipItem
            
            // Save the imported payslip
            do {
                print("[HomeViewModel] Saving payslip to dataService...")
                try await dataService.save(payslipItem)
                print("[HomeViewModel] Payslip saved successfully")
                
                // Also save the PDF to the PDFManager for better persistence
                // Use our current PDF document's data if available for better display
                let pdfData = currentPDFDocument?.dataRepresentation() ?? payslipItem.pdfData ?? data
                do {
                    let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                    print("[HomeViewModel] PDF saved successfully at: \(pdfURL.path)")
                    
                    // Verify the saved PDF can be loaded
                    if let savedDoc = PDFDocument(url: pdfURL) {
                        print("[HomeViewModel] Successfully verified saved PDF: \(savedDoc.pageCount) pages")
                    } else {
                        print("[HomeViewModel] WARNING: Saved PDF cannot be loaded directly")
                        // Try using the repair function to save a viewable version
                        let repairedData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
                        let repairedURL = try PDFManager.shared.savePDF(data: repairedData, identifier: "\(payslipItem.id.uuidString)_repaired")
                        print("[HomeViewModel] Repaired PDF saved at: \(repairedURL.path)")
                    }
                } catch {
                    print("[HomeViewModel] Error saving PDF: \(error.localizedDescription)")
                }
                
                // Reload the payslips
                print("[HomeViewModel] Reloading recent payslips...")
                await loadRecentPayslipsWithAnimation()
                
                // Navigate to the newly added payslip
                print("[HomeViewModel] Setting navigateToNewPayslip = true")
                navigateToNewPayslip = true
                
                // Reset password state
                DispatchQueue.main.async {
                    if self.showPasswordEntryView {
                        print("[HomeViewModel] Resetting password entry state")
                        self.showPasswordEntryView = false
                        self.currentPasswordProtectedPDFData = nil
                    }
                }
            } catch {
                print("[HomeViewModel] Error saving payslip: \(error.localizedDescription)")
                handleError(error)
            }
            
        case .failure(let error):
            print("[HomeViewModel] PDF processing failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isUploading = false
        isLoading = false
        print("[HomeViewModel] Process PDF Data completed")
    }
    
    /// Handles an unlocked PDF.
    ///
    /// - Parameter data: The unlocked PDF data.
    /// - Parameter originalPassword: The original password used to unlock the PDF.
    func handleUnlockedPDF(data: Data, originalPassword: String) async {
        print("[HomeViewModel] Handling unlocked PDF with \(data.count) bytes")
        
        isProcessingUnlocked = true
        
        // First detect format before we process it
        print("[HomeViewModel] Detecting format before processing...")
        let format = pdfProcessingService.detectPayslipFormat(data)
        print("[HomeViewModel] Detected format: \(format)")
        
        // Verify we have a valid PDF document
        if let pdfDocument = PDFDocument(data: data) {
            print("[HomeViewModel] PDF document created successfully with \(pdfDocument.pageCount) pages")
            
            // Save to temp file for debugging
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_unlocked.pdf")
            do {
                try data.write(to: tempURL)
                print("[HomeViewModel] Successfully wrote unlocked PDF to: \(tempURL.path)")
                
                // Verify the saved PDF can be opened
                if let verificationDocument = PDFDocument(url: tempURL) {
                    print("[HomeViewModel] Verification successful: PDF document can be loaded from temp file with \(verificationDocument.pageCount) pages")
                } else {
                    print("[HomeViewModel] Warning: Could not verify saved PDF file")
                }
            } catch {
                print("[HomeViewModel] Error saving temp PDF: \(error)")
            }
            
            // Store the unlocked PDF document for later use
            DispatchQueue.main.async {
                self.currentPDFDocument = pdfDocument
                self.unlockedPDFData = data  // Store the unlocked data
            }
        } else {
            print("[HomeViewModel] Warning: Could not create PDF document from unlocked data")
        }
        
        // Always use the unlocked data for processing, never the original
        await processPDFData(data)
        
        // After processing is complete, mark that we're done
        DispatchQueue.main.async {
            self.isProcessingUnlocked = false
            self.currentPasswordProtectedPDFData = nil
            self.currentPDFPassword = nil
        }
        
        print("[HomeViewModel] Finished processing unlocked PDF data")
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