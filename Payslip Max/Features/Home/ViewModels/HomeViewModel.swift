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
    
    // MARK: - Private Properties
    
    /// The PDF service to use for processing PDFs.
    private let pdfService: PDFServiceProtocol
    
    /// The PDF extractor to use for extracting data from PDFs.
    private let pdfExtractor: PDFExtractorProtocol
    
    /// The data service to use for fetching and saving data.
    private let dataService: DataServiceProtocol
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
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
                recentPayslips = Array(sortedPayslips.prefix(5))
                
                // Prepare chart data
                prepareChartData(from: sortedPayslips)
                
                isLoading = false
            } catch {
                handleError(error)
                isLoading = false
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
                
                // Process the PDF with better error handling
                let data: Data
                do {
                    data = try await pdfService.process(url)
                    print("PDF processed successfully, data size: \(data.count) bytes")
                } catch let error as PDFServiceImpl.PDFError {
                    print("PDFServiceImpl error: \(error.localizedDescription)")
                    // Convert PDFError to AppError for better user feedback
                    switch error {
                    case .invalidPDF, .invalidPDFFormat:
                        throw AppError.pdfProcessingFailed("The file is not a valid PDF document")
                    case .emptyPDF:
                        throw AppError.pdfProcessingFailed("The PDF document is empty")
                    case .fileNotFound:
                        throw AppError.pdfProcessingFailed("The PDF file could not be found")
                    case .emptyFile:
                        throw AppError.pdfProcessingFailed("The PDF file is empty")
                    case .fileReadError(let underlyingError):
                        print("File read error details: \(underlyingError)")
                        throw AppError.pdfProcessingFailed("Could not read the PDF file: \(underlyingError.localizedDescription)")
                    default:
                        throw AppError.pdfProcessingFailed(error.localizedDescription)
                    }
                } catch {
                    print("Unexpected error during PDF processing: \(error)")
                    throw AppError.pdfProcessingFailed("Unexpected error: \(error.localizedDescription)")
                }
                
                // Create a PDF document
                guard let pdfDocument = PDFDocument(data: data) else {
                    print("Failed to create PDFDocument from data")
                    throw AppError.pdfProcessingFailed("Could not create PDF document from the processed data")
                }
                
                // Validate PDF document has pages
                guard pdfDocument.pageCount > 0 else {
                    print("PDF document has no pages")
                    throw AppError.pdfProcessingFailed("The PDF document has no pages")
                }
                
                print("PDF document created successfully with \(pdfDocument.pageCount) pages")
                
                // Extract payslip data
                let payslip: any PayslipItemProtocol
                do {
                    payslip = try await pdfExtractor.extractPayslipData(from: pdfDocument)
                    print("Payslip data extracted successfully")
                } catch {
                    print("Data extraction error: \(error)")
                    throw AppError.dataExtractionFailed("Could not extract payslip data from the PDF: \(error.localizedDescription)")
                }
                
                // Save the payslip
                try await dataService.save(payslip as! PayslipItem)
                print("Payslip saved successfully")
                
                // Reload the payslips
                loadRecentPayslips()
                
                isUploading = false
            } catch {
                print("Final error in processPayslipPDF: \(error)")
                handleError(error)
                isUploading = false
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
                let payslip = try await pdfExtractor.extractPayslipData(from: pdfDocument)
                
                // Save the payslip
                try await dataService.save(payslip as! PayslipItem)
                
                // Reload the payslips
                loadRecentPayslips()
                
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
                    dspof: data.dspof,
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
                loadRecentPayslips()
                
                isUploading = false
            } catch {
                handleError(error)
                isUploading = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Prepares chart data from payslips.
    ///
    /// - Parameter payslips: The payslips to prepare chart data from.
    private func prepareChartData(from payslips: [any PayslipItemProtocol]) {
        guard !payslips.isEmpty else {
            payslipData = []
            return
        }
        
        // Group by month and year
        var monthlyData: [String: Double] = [:]
        
        for payslip in payslips {
            let key = "\(payslip.month) \(payslip.year)"
            monthlyData[key, default: 0] += payslip.credits
        }
        
        // Convert to chart data
        payslipData = monthlyData.map { PayslipChartData(label: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
            .prefix(6)
            .sorted { monthYearToDate($0.label) < monthYearToDate($1.label) }
            .map { PayslipChartData(label: $0.label, value: $0.value) }
    }
    
    /// Converts a month and year string to a date.
    ///
    /// - Parameter monthYear: The month and year string.
    /// - Returns: The date.
    private func monthYearToDate(_ monthYear: String) -> Date {
        let components = monthYear.components(separatedBy: " ")
        guard components.count == 2,
              let year = Int(components[1]),
              let month = monthNameToNumber(components[0]) else {
            return Date.distantPast
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents) ?? Date.distantPast
    }
    
    /// Converts a month name to a month number.
    ///
    /// - Parameter name: The month name.
    /// - Returns: The month number.
    private func monthNameToNumber(_ name: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        if let date = formatter.date(from: name) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Try abbreviated month names
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: name) {
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Try numeric month
        return Int(name)
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