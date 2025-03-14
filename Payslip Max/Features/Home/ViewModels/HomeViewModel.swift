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
    
    /// The parsed payslip item to display in the feedback view.
    @Published var parsedPayslipItem: PayslipItem?
    
    /// The PDF document being processed.
    @Published var currentPDFDocument: PDFDocument?
    
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
    func processPayslipPDF(from url: URL) {
        isUploading = true
        
        Task {
            do {
                print("Processing PDF from URL: \(url.absoluteString)")
                
                // Validate the file extension
                guard url.pathExtension.lowercased() == "pdf" else {
                    throw AppError.invalidFileType("Only PDF files are supported")
                }
                
                // Verify file exists and is accessible
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: url.path) else {
                    print("File does not exist at path: \(url.path)")
                    throw AppError.pdfProcessingFailed("The PDF file could not be found at \(url.path)")
                }
                
                // Check file attributes
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: url.path)
                    let fileSize = attributes[.size] as? NSNumber ?? 0
                    print("File size: \(fileSize) bytes")
                    
                    if fileSize.intValue <= 0 {
                        throw AppError.pdfProcessingFailed("The PDF file is empty")
                    }
                } catch let fileError as NSError {
                    print("Error checking file attributes: \(fileError.localizedDescription)")
                    throw AppError.pdfProcessingFailed("Error accessing file: \(fileError.localizedDescription)")
                }
                
                // Initialize the data service if it's not already initialized
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Initialize the PDF service if it's not already initialized
                if !pdfService.isInitialized {
                    try await pdfService.initialize()
                }
                
                // Process the PDF file
                let fileData = try Data(contentsOf: url)
                print("Successfully read PDF data, size: \(fileData.count) bytes")
                
                // First, try to create a PDFDocument directly from the URL to verify it's valid
                guard let directPdfDocument = PDFDocument(url: url) else {
                    print("Failed to create PDFDocument directly from URL")
                    throw AppError.pdfProcessingFailed("Could not create PDF document from the file")
                }
                
                print("Successfully created direct PDFDocument with \(directPdfDocument.pageCount) pages")
                
                // Store the PDF document for the feedback view
                currentPDFDocument = directPdfDocument
                
                // Extract payslip data directly from the document we already verified
                do {
                    guard let payslip = pdfExtractor.extractPayslipData(from: directPdfDocument) else {
                        throw AppError.pdfExtractionFailed("Failed to extract payslip data")
                    }
                    print("Payslip data extracted successfully: \(String(describing: payslip))")
                    print("Extracted month: \(payslip.month), year: \(payslip.year), credits: \(payslip.credits)")
                    
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
                        pdfData: fileData
                    )
                    
                    // Store the parsed payslip item for the feedback view
                    parsedPayslipItem = payslipItem
                    
                    // Show the parsing feedback view
                    showParsingFeedbackView = true
                    
                    // Save the payslip with PDF data
                    try await dataService.save(payslipItem)
                    print("Payslip saved successfully with PDF data")
                } catch {
                    print("Data extraction error: \(error)")
                    throw AppError.dataExtractionFailed("Could not extract payslip data from the PDF: \(error.localizedDescription)")
                }
                
                // Reload the payslips with animation
                await loadRecentPayslipsWithAnimation()
                
                isUploading = false
            } catch {
                print("Final error in processPayslipPDF: \(error)")
                handleError(error)
                isUploading = false
            }
        }
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
                
                // Save the payslip
                try await dataService.save(payslipItem)
                
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
                
                // Save the payslip
                try await dataService.save(payslip)
                
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
} 