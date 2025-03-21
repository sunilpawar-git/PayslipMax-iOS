import Foundation
import SwiftUI
import Combine
import PDFKit
import Vision

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
    
    /// The PDF service to use for processing PDFs.
    private let pdfService: PDFServiceProtocol
    
    /// The PDF extractor to use for extracting data from PDFs.
    private let pdfExtractor: PDFExtractorProtocol
    
    /// The data service to use for fetching and saving data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// The parsing coordinator for the feedback view.
    lazy var parsingCoordinator: PDFParsingCoordinator = {
        return PDFParsingCoordinator(abbreviationManager: AbbreviationManager())
    }()
    
    // MARK: - Initialization
    
    /// Initializes a new HomeViewModel.
    ///
    /// - Parameters:
    ///   - pdfService: The PDF service to use for processing PDFs.
    ///   - pdfExtractor: The PDF extractor to use for extracting data from PDFs.
    ///   - dataService: The data service to use for fetching and saving data.
    init(
        pdfService: PDFServiceProtocol? = nil,
        pdfExtractor: PDFExtractorProtocol? = nil,
        dataService: DataServiceProtocol? = nil
    ) {
        self.pdfService = pdfService ?? DIContainer.shared.pdfService
        self.pdfExtractor = pdfExtractor ?? DIContainer.shared.pdfExtractor
        self.dataService = dataService ?? DIContainer.shared.dataService
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
        
        // Directly read the file data
        do {
            let pdfData = try Data(contentsOf: url)
            print("HomeViewModel: Got PDF data, size: \(pdfData.count)")
            
            // Get file size for logging
            let fileSize = pdfData.count
            print("HomeViewModel: PDF file size: \(fileSize) bytes")
            
            // Check if it's a password-protected PDF
            let isPwdProtected = checkIfPasswordProtected(pdfData: pdfData)
            print("HomeViewModel: PDF is password protected: \(isPwdProtected)")
            
            if isPwdProtected {
                // Show password entry field
                currentPasswordProtectedPDFData = pdfData
                showPasswordEntryView = true
            } else {
                // Process the PDF directly if not password protected
                await processPDFData(pdfData, from: url)
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("HomeViewModel: Error loading PDF: \(error.localizedDescription)")
        }
    }
    
    /// Processes PDF data after it has been unlocked or loaded directly.
    ///
    /// - Parameters:
    ///   - data: The PDF data to process.
    ///   - url: The original URL of the PDF file (optional).
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        do {
            isUploading = true
            
            // Initialize services
            let pdfService = DIContainer.shared.makePDFService()
            let pdfExtractor = DefaultPDFExtractor()
            let isMilitary = checkIfMilitaryPDF(data: data)
            
            print("HomeViewModel: Processing PDF data, size: \(data.count) bytes, military: \(isMilitary)")
            
            // Extract text from PDF
            let extractedPages = pdfService.extract(data)
            print("HomeViewModel: Extracted \(extractedPages.count) pages of text")
            
            // Debug log first 100 chars of each page
            for (page, text) in extractedPages {
                let preview = String(text.prefix(100)).replacingOccurrences(of: "\n", with: " ")
                print("HomeViewModel: Page \(page) preview: \(preview)...")
            }
            
            // If no text was extracted, handle the error
            if extractedPages.isEmpty {
                print("HomeViewModel: No text was extracted from the PDF")
                throw AppError.pdfExtractionFailed("Failed to extract text from PDF")
            }
            
            // Join all extracted text
            let extractedText = extractedPages.values.joined(separator: "\n\n")
            
            print("HomeViewModel: Total extracted text length: \(extractedText.count)")
            
            var payslipItem: PayslipItem?
            
            // First attempt: parse with extractor using text
            do {
                let parsedData = try pdfExtractor.parsePayslipData(from: extractedText)
                if let item = parsedData as? PayslipItem {
                    payslipItem = item
                    print("HomeViewModel: Successfully parsed payslip data")
                }
            } catch {
                print("HomeViewModel: Error parsing text: \(error), will try direct PDF extraction")
                
                // Second attempt: If text parsing failed and we have a PDF document, try with the document
                if let pdfDocument = PDFDocument(data: data) {
                    do {
                        if let extractedData = pdfExtractor.extractPayslipData(from: pdfDocument) {
                            payslipItem = extractedData
                            print("HomeViewModel: Successfully extracted payslip data directly from PDF")
                        } else {
                            print("HomeViewModel: Failed direct PDF extraction")
                            
                            // Final attempt: If this is a military PDF that we identified, create a default item
                            if isMilitary {
                                print("HomeViewModel: Creating default military payslip as fallback")
                                payslipItem = PayslipItem(
                                    month: getCurrentMonth(),
                                    year: getCurrentYear(),
                                    credits: 2025.0,
                                    debits: 0.0,
                                    dsop: 0.0,
                                    tax: 0.0,
                                    location: "Military",
                                    name: "Military Personnel",
                                    accountNumber: "",
                                    panNumber: "",
                                    timestamp: Date(),
                                    pdfData: data
                                )
                            } else {
                                throw AppError.pdfExtractionFailed("Failed to extract payslip data")
                            }
                        }
                    } catch {
                        throw AppError.pdfExtractionFailed("Failed direct PDF extraction: \(error.localizedDescription)")
                    }
                } else {
                    throw AppError.pdfExtractionFailed("Failed to create PDF document")
                }
            }
            
            // Make sure we have a payslip item
            guard let payslipItem = payslipItem else {
                print("HomeViewModel: Failed to create payslip item")
                throw AppError.pdfExtractionFailed("Failed to create payslip item")
            }
            
            // Verify that PDF data is included
            if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
                print("HomeViewModel: PDF data was not set on payslip item, setting it now")
                payslipItem.pdfData = data
            }
            
            // Store the newly added payslip for navigation
            newlyAddedPayslip = payslipItem
            
            // Save the imported payslip
            print("HomeViewModel: Saving payslip item - month: \(payslipItem.month), year: \(payslipItem.year), credits: \(payslipItem.credits)")
            try await dataService.save(payslipItem)
            
            // Also save the PDF to the PDFManager for better persistence
            print("HomeViewModel: Saving PDF to PDFManager")
            let pdfData = payslipItem.pdfData ?? data
            do {
                let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                print("HomeViewModel: PDF saved successfully at: \(pdfURL.path)")
            } catch {
                print("HomeViewModel: Failed to save PDF to PDFManager: \(error)")
            }
            
            // Update UI state
            navigateToNewPayslip = true
            currentPasswordProtectedPDFData = nil
            
            // Reload the payslips
            await loadRecentPayslipsWithAnimation()
            
            await MainActor.run {
                isUploading = false
            }
            
        } catch {
            await MainActor.run {
                print("Error in processPDFData: \(error)")
                handleError(error)
                isUploading = false
                currentPasswordProtectedPDFData = nil
            }
        }
    }
    
    /// Handle the unlocked PDF data from the password entry view.
    ///
    /// - Parameter unlockedData: The unlocked PDF data.
    func handleUnlockedPDF(_ unlockedData: Data) async {
        // Handle the unlocked PDF data
        print("HomeViewModel: Received unlocked PDF data, size: \(unlockedData.count)")
        
        // Process the unlocked PDF
        await processPDFData(unlockedData, from: currentPDFURL)
        
        // Reset state
        showPasswordEntryView = false
        currentPasswordProtectedPDFData = nil
    }
    
    /// Loads recent payslips with animation to prevent UI flashing
    private func loadRecentPayslipsWithAnimation() async {
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
    
    /// Processes a scanned payslip from an image.
    ///
    /// - Parameter image: The scanned image.
    func processScannedPayslip(from image: UIImage) {
        isUploading = true
        
        Task {
            do {
                // Initialize the data service if it's not already initialized
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Convert the image to a PDF
                guard let pdfData = createPDFFromImage(image) else {
                    throw AppError.pdfProcessingFailed("Could not create PDF from image")
                }
                
                // Create a PDF document
                guard let pdfDocument = PDFDocument(data: pdfData) else {
                    throw AppError.pdfProcessingFailed("Could not create PDF document")
                }
                
                // Extract payslip data
                guard let payslip = pdfExtractor.extractPayslipData(from: pdfDocument) else {
                    throw AppError.pdfExtractionFailed("Failed to extract payslip data")
                }
                
                // Create a PayslipItem with the PDF data
                let payslipItem = PayslipItem(
                    month: payslip.month,
                    year: payslip.year,
                    credits: payslip.credits,
                    debits: payslip.debits,
                    dsop: payslip.dsop,
                    tax: payslip.tax,
                    location: payslip.location,
                    name: payslip.name,
                    accountNumber: payslip.accountNumber,
                    panNumber: payslip.panNumber,
                    timestamp: payslip.timestamp,
                    pdfData: pdfData
                )
                
                // Store the newly added payslip for navigation
                newlyAddedPayslip = payslipItem
                
                // Save the payslip
                try await dataService.save(payslipItem)
                
                // Also save the PDF to the PDFManager for better persistence
                print("HomeViewModel: Saving scanned PDF to PDFManager")
                do {
                    let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                    print("HomeViewModel: Scanned PDF saved successfully at: \(pdfURL.path)")
                } catch {
                    print("HomeViewModel: Failed to save scanned PDF to PDFManager: \(error)")
                }
                
                // Set the navigation flag to true
                navigateToNewPayslip = true
                
                // Reload the payslips
                await loadRecentPayslipsWithAnimation()
                
                isUploading = false
            } catch {
                handleError(error)
                isUploading = false
            }
        }
    }
    
    /// Processes a manual entry.
    ///
    /// - Parameter data: The manually entered data.
    func processManualEntry(_ data: PayslipManualEntryData) {
        isUploading = true
        
        Task {
            do {
                // Initialize the data service if it's not already initialized
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Create a new payslip
                let payslip = PayslipItem(
                    month: data.month,
                    year: data.year,
                    credits: data.credits,
                    debits: data.debits,
                    dsop: data.dsop,
                    tax: data.tax,
                    location: data.location,
                    name: data.name,
                    accountNumber: "",
                    panNumber: "",
                    timestamp: Date()
                )
                
                // Store the newly added payslip for navigation
                newlyAddedPayslip = payslip
                
                // Save the payslip
                try await dataService.save(payslip)
                
                // Set the navigation flag to true
                navigateToNewPayslip = true
                
                // Reload the payslips
                await loadRecentPayslipsWithAnimation()
                
                // Hide the manual entry form
                showManualEntryForm = false
                
                isUploading = false
            } catch {
                handleError(error)
                isUploading = false
            }
        }
    }
    
    /// Cancels any loading operations and resets loading states
    func cancelLoading() {
        // Reset loading states immediately when navigating away
        isLoading = false
        isUploading = false
    }
    
    // MARK: - Private Methods
    
    /// Prepares chart data in the background to avoid UI blocking
    /// - Parameter payslips: The payslips to prepare chart data from
    /// - Returns: The prepared chart data
    private func prepareChartDataInBackground(from payslips: [PayslipItem]) -> [PayslipChartData] {
        // Create chart data from the payslips
        var result: [PayslipChartData] = []
        
        // Group payslips by month and year
        let groupedPayslips = Dictionary(grouping: payslips) { payslip in
            return "\(payslip.month) \(payslip.year)"
        }
        
        // Create chart data for each month
        for (key, payslipsInMonth) in groupedPayslips {
            let totalCredits = payslipsInMonth.reduce(0) { $0 + $1.credits }
            let totalDebits = payslipsInMonth.reduce(0) { $0 + $1.debits + $1.tax + $1.dsop }
            
            result.append(PayslipChartData(
                month: key,
                credits: totalCredits,
                debits: totalDebits,
                net: totalCredits - totalDebits
            ))
        }
        
        // Sort by date (oldest first)
        result.sort { (data1, data2) -> Bool in
            let components1 = data1.month.components(separatedBy: " ")
            let components2 = data2.month.components(separatedBy: " ")
            
            guard components1.count == 2, components2.count == 2,
                  let year1 = Int(components1[1]), let year2 = Int(components2[1]) else {
                return false
            }
            
            if year1 != year2 {
                return year1 < year2
            }
            
            let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            let month1Index = months.firstIndex(of: components1[0]) ?? 0
            let month2Index = months.firstIndex(of: components2[0]) ?? 0
            
            return month1Index < month2Index
        }
        
        return result
    }
    
    /// Creates a PDF from an image.
    ///
    /// - Parameter image: The image to create a PDF from.
    /// - Returns: The PDF data.
    private func createPDFFromImage(_ image: UIImage) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))
        
        return pdfRenderer.pdfData { context in
            context.beginPage()
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
    
    /// Processes a PDF file at the specified URL.
    ///
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: The original PDF data unmodified.
    /// - Throws: An error if processing fails.
    private func processPDF(at url: URL) async throws -> Data {
        print("HomeViewModel: Processing PDF at \(url.path)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("HomeViewModel: File not found at path: \(url.path)")
            throw AppError.pdfProcessingFailed("The PDF file could not be found at \(url.path)")
        }
        
        // Load file with better error handling
        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
            print("HomeViewModel: Successfully loaded file data, size: \(fileData.count) bytes")
        } catch {
            print("HomeViewModel: Error reading file data: \(error.localizedDescription)")
            throw AppError.pdfProcessingFailed("Error accessing file: \(error.localizedDescription)")
        }
        
        // Validate file size
        guard fileData.count > 0 else {
            print("HomeViewModel: File is empty")
            throw AppError.pdfProcessingFailed("The PDF file is empty")
        }
        
        // Create PDF document to check if it's locked
        if let document = PDFDocument(data: fileData) {
            print("HomeViewModel: Successfully created PDFDocument")
            
            // Even if the document is locked, we'll return it and handle password entry later
            if document.isLocked {
                print("HomeViewModel: PDF is password protected - will handle with PasswordProtectedPDFView")
                
                // IMPORTANT CHANGE: Return the data directly - we'll show the password dialog
                return fileData
            }
            
            print("HomeViewModel: PDF is not password protected")
            return fileData
        }
        
        // Try to extract document even if PDFKit can't create a PDFDocument
        // Some government PDFs have strict security but can still be used
        print("HomeViewModel: Could not create PDFDocument, but returning the data anyway")
        return fileData
    }
    
    private func checkIfPasswordProtected(pdfData: Data) -> Bool {
        // Check if data has our special formats
        let pwdMarker = "PWDPDF:"
        let milMarker = "MILPDF:"
        
        if let pwdMarkerData = pwdMarker.data(using: .utf8),
           pdfData.starts(with: pwdMarkerData) {
            return true
        }
        
        if let milMarkerData = milMarker.data(using: .utf8),
           pdfData.starts(with: milMarkerData) {
            return true
        }
        
        // Try to open with PDFKit
        if let document = PDFDocument(data: pdfData) {
            return document.isLocked
        }
        
        // If PDFKit failed to open it at all, try CoreGraphics
        if let provider = CGDataProvider(data: pdfData as CFData),
           let cgPDF = CGPDFDocument(provider) {
            return cgPDF.isEncrypted
        }
        
        // For military PDFs that might not be recognized correctly,
        // assume they might be password protected
        return true // Safer to assume it needs a password
    }
    
    // Check if a PDF is in military format
    private func checkIfMilitaryPDF(data: Data) -> Bool {
        // First check if it's in our special format already
        if let dataStart = String(data: data.prefix(min(100, data.count)), encoding: .utf8),
           dataStart.hasPrefix("MILPDF:") {
            print("HomeViewModel: Detected military PDF by format marker")
            return true
        }
        
        // Try to open with PDFKit to check content
        if let document = PDFDocument(data: data) {
            // Check document metadata
            if let attributes = document.documentAttributes {
                for (_, value) in attributes {
                    if let stringValue = value as? String {
                        let militaryTerms = ["Ministry of Defence", "PCDA", "Army", "Military", "Defence"]
                        for term in militaryTerms {
                            if stringValue.contains(term) {
                                print("HomeViewModel: Detected military PDF from metadata: \(term)")
                                return true
                            }
                        }
                    }
                }
            }
            
            // Check first page content if accessible
            for i in 0..<min(3, document.pageCount) {
                if let page = document.page(at: i),
                   let text = page.string {
                    let militaryTerms = ["Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", "PCDA", 
                                         "CDA", "Defence", "DSOP FUND", "Military"]
                    for term in militaryTerms {
                        if text.contains(term) {
                            print("HomeViewModel: Detected military PDF from content: \(term)")
                            return true
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    // Helper to get current month name
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    // Helper to get current year
    private func getCurrentYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }
} 