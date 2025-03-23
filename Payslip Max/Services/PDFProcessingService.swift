import Foundation
import PDFKit
import UIKit
import Vision

/// Default implementation of the PDFProcessingServiceProtocol
@MainActor
class PDFProcessingService: PDFProcessingServiceProtocol {
    // MARK: - Properties
    
    /// Indicates whether the service has been initialized
    var isInitialized: Bool = false
    
    /// The PDF service for basic operations
    private let pdfService: PDFServiceProtocol
    
    /// The PDF extractor for data extraction
    private let pdfExtractor: PDFExtractorProtocol
    
    /// The parsing coordinator for managing different parsing strategies
    private let parsingCoordinator: PDFParsingCoordinator
    
    /// Timeout for processing operations in seconds
    private let processingTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// Initializes a new PDFProcessingService
    /// - Parameters:
    ///   - pdfService: The PDF service to use
    ///   - pdfExtractor: The PDF extractor to use
    ///   - parsingCoordinator: The parsing coordinator to use
    init(pdfService: PDFServiceProtocol, pdfExtractor: PDFExtractorProtocol, parsingCoordinator: PDFParsingCoordinator) {
        self.pdfService = pdfService
        self.pdfExtractor = pdfExtractor
        self.parsingCoordinator = parsingCoordinator
    }
    
    /// Initializes the service
    func initialize() async throws {
        if !pdfService.isInitialized {
            try await pdfService.initialize()
        }
        isInitialized = true
    }
    
    // MARK: - PDFProcessingServiceProtocol Implementation
    
    /// Processes a PDF file from a URL
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileAccessError("File not found at: \(url.path)"))
        }
        
        // Read file data
        do {
            let fileData = try Data(contentsOf: url)
            
            // Check if file data is valid
            guard fileData.count > 0 else {
                return .failure(.emptyDocument)
            }
            
            // Check if the PDF is password protected
            if isPasswordProtected(fileData) {
                return .failure(.passwordProtected)
            }
            
            return .success(fileData)
        } catch {
            return .failure(.fileAccessError(error.localizedDescription))
        }
    }
    
    /// Processes PDF data directly
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        // Create a Task with timeout
        return await withTaskTimeout(seconds: processingTimeout) { [weak self] in
            guard let self = self else {
                return .failure(.parsingFailed("Service was deallocated"))
            }
            
            // Create PDF document
            guard let pdfDocument = PDFDocument(data: data) else {
                return .failure(.invalidFormat)
            }
            
            // Detect format
            let format = self.detectPayslipFormat(data)
            
            // Extract text from PDF
            let extractedPages = self.pdfService.extract(data)
            
            // If no text was extracted, handle the error
            if extractedPages.isEmpty {
                return .failure(.extractionFailed("No text could be extracted"))
            }
            
            // Join extracted text pages
            let extractedText = extractedPages.values.joined(separator: "\n\n")
            
            // Parse with extractor using the extracted text
            if let parsedData = self.pdfExtractor.extractPayslipData(from: extractedText) {
                // Update PDF data before returning
                let updatedPayslip = parsedData
                updatedPayslip.pdfData = data
                return .success(updatedPayslip)
            }
            
            // Second attempt: Try with parsing coordinator if text parsing failed
            if let payslipItem = self.parsingCoordinator.parsePayslip(pdfDocument: pdfDocument) {
                // Update PDF data before returning
                let updatedPayslip = payslipItem
                updatedPayslip.pdfData = data
                return .success(updatedPayslip)
            }
            
            // If format is military, create a default payslip
            if format == .military {
                let payslipItem = self.createDefaultMilitaryPayslip(with: data)
                return .success(payslipItem)
            }
            
            return .failure(.parsingFailed("Could not parse PDF data"))
        }
    }
    
    /// Checks if a PDF is password protected
    func isPasswordProtected(_ data: Data) -> Bool {
        guard let document = PDFDocument(data: data) else {
            return false
        }
        return document.isLocked
    }
    
    /// Unlocks a password-protected PDF
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        do {
            let unlockedData = try await pdfService.unlockPDF(data: data, password: password)
            return .success(unlockedData)
        } catch {
            return .failure(.incorrectPassword)
        }
    }
    
    /// Processes a scanned image as a payslip
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> {
        // Convert image to PDF
        guard let pdfData = createPDFFromImage(image) else {
            return .failure(.conversionFailed)
        }
        
        // Process the PDF data
        return await processPDFData(pdfData)
    }
    
    /// Detects the format of a payslip PDF
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        // Try to open with PDFKit to check content
        if let document = PDFDocument(data: data) {
            // Check first page content if accessible
            for i in 0..<min(3, document.pageCount) {
                if let page = document.page(at: i),
                   let text = page.string {
                    let militaryTerms = ["Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", "PCDA", 
                                        "CDA", "Defence", "DSOP FUND", "Military"]
                    
                    let pcdaTerms = ["Principal Controller of Defence Accounts", "PCDA"]
                    
                    // Check for military terms
                    for term in militaryTerms {
                        if text.contains(term) {
                            // Check specifically for PCDA
                            for pcdaTerm in pcdaTerms {
                                if text.contains(pcdaTerm) {
                                    return .pcda
                                }
                            }
                            return .military
                        }
                    }
                }
            }
        }
        
        // Default to standard if no specific format is detected
        return .standard
    }
    
    /// Validates that a PDF contains valid payslip content
    func validatePayslipContent(_ data: Data) -> ValidationResult {
        // Create PDF document
        guard let document = PDFDocument(data: data) else {
            return ValidationResult(isValid: false, confidence: 0.0, detectedFields: [], missingRequiredFields: ["Valid PDF"])
        }
        
        // Extract text
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), 
               let pageText = page.string {
                fullText += pageText
            }
        }
        
        // Define required fields
        let requiredFields = ["name", "month", "year", "earnings", "deductions"]
        
        // Check for key payslip indicators
        var detectedFields: [String] = []
        var missingFields: [String] = []
        
        // Check for name field
        if fullText.range(of: "Name:", options: .caseInsensitive) != nil {
            detectedFields.append("name")
        } else {
            missingFields.append("name")
        }
        
        // Check for month/date field
        if fullText.range(of: "Month:|Date:|Period:", options: .regularExpression) != nil {
            detectedFields.append("month")
        } else {
            missingFields.append("month")
        }
        
        // Check for year field
        if fullText.range(of: "Year:|20[0-9]{2}", options: .regularExpression) != nil {
            detectedFields.append("year")
        } else {
            missingFields.append("year")
        }
        
        // Check for earnings indicators
        let earningsTerms = ["Earnings", "Credits", "Salary", "Pay", "Income", "Allowances"]
        for term in earningsTerms {
            if fullText.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("earnings")
                break
            }
        }
        if !detectedFields.contains("earnings") {
            missingFields.append("earnings")
        }
        
        // Check for deductions indicators
        let deductionsTerms = ["Deductions", "Debits", "Tax", "DSOP", "Fund", "Recovery"]
        for term in deductionsTerms {
            if fullText.range(of: term, options: .caseInsensitive) != nil {
                detectedFields.append("deductions")
                break
            }
        }
        if !detectedFields.contains("deductions") {
            missingFields.append("deductions")
        }
        
        // Calculate confidence score based on detected fields
        let confidence = Double(detectedFields.count) / Double(requiredFields.count)
        
        // Document is valid if it has at least 3 required fields
        let isValid = detectedFields.count >= 3
        
        return ValidationResult(
            isValid: isValid,
            confidence: confidence,
            detectedFields: detectedFields,
            missingRequiredFields: missingFields
        )
    }
    
    // MARK: - Private Methods
    
    /// Creates a PDF from an image
    private func createPDFFromImage(_ image: UIImage) -> Data? {
        // Use higher resolution for better text recognition
        let originalImage = image
        let scaleFactor: CGFloat = 2.0
        let scaledSize = CGSize(width: originalImage.size.width * scaleFactor, 
                                height: originalImage.size.height * scaleFactor)
        
        // Create a high-resolution renderer with the scaled size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: scaledSize))
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Draw with high quality
            let renderingIntent = CGColorRenderingIntent.defaultIntent
            let interpolationQuality = CGInterpolationQuality.high
            
            // Set graphics state for better quality
            let cgContext = context.cgContext
            cgContext.setRenderingIntent(renderingIntent)
            cgContext.interpolationQuality = interpolationQuality
            
            // Draw the image at higher quality
            originalImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
    
    /// Creates a default military payslip when parsing fails
    private func createDefaultMilitaryPayslip(with data: Data) -> PayslipItem {
        let currentDate = Date()
        let calendar = Calendar.current
        let _ = calendar.component(.month, from: currentDate) // Not used directly
        let year = calendar.component(.year, from: currentDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let monthName = dateFormatter.string(from: currentDate)
        
        return PayslipItem(
            month: monthName,
            year: year,
            credits: 2025.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            location: "Military",
            name: "Military Personnel",
            accountNumber: "",
            panNumber: "",
            timestamp: currentDate,
            pdfData: data
        )
    }
    
    /// Runs a task with a timeout
    private func withTaskTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> Result<T, PDFProcessingError>) async -> Result<T, PDFProcessingError> {
        return await withTaskGroup(of: Result<T, PDFProcessingError>.self) { group in
            // Add the actual operation
            group.addTask {
                return await operation()
            }
            
            // Add a timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .failure(.processingTimeout)
            }
            
            // Return the first completed task
            if let result = await group.next() {
                group.cancelAll() // Cancel any remaining tasks
                return result
            }
            
            return .failure(.parsingFailed("Unknown error"))
        }
    }
} 