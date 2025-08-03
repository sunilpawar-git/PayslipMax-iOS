import Foundation
import SwiftUI
import PDFKit
import Combine
import Vision

/// Coordinates all PDF processing operations for HomeViewModel
/// Follows single responsibility principle by handling only PDF-related tasks
@MainActor
class PDFProcessingCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether PDF processing is in progress
    @Published var isProcessing = false
    
    /// Whether we're uploading/processing a PDF
    @Published var isUploading = false
    
    /// Whether we're currently processing an unlocked PDF
    @Published var isProcessingUnlocked = false
    
    /// The data for the currently unlocked PDF
    @Published var unlockedPDFData: Data?
    
    // MARK: - Private Properties
    
    /// The handler for PDF processing operations
    private let pdfHandler: PDFProcessingHandler
    
    /// The handler for password-protected PDF operations
    private let passwordHandler: PasswordProtectedPDFHandler
    
    /// The navigation coordinator
    private let navigationCoordinator: HomeNavigationCoordinator
    
    /// Completion handlers for processing results
    private var onProcessingSuccess: ((PayslipItem) -> Void)?
    private var onProcessingFailure: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    init(
        pdfHandler: PDFProcessingHandler,
        passwordHandler: PasswordProtectedPDFHandler,
        navigationCoordinator: HomeNavigationCoordinator
    ) {
        self.pdfHandler = pdfHandler
        self.passwordHandler = passwordHandler
        self.navigationCoordinator = navigationCoordinator
    }
    
    // MARK: - Public Methods
    
    /// Sets completion handlers for processing results
    func setCompletionHandlers(
        onSuccess: @escaping (PayslipItem) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onProcessingSuccess = onSuccess
        self.onProcessingFailure = onFailure
    }
    
    /// Processes a payslip PDF from a URL
    /// - Parameter url: The URL of the PDF to process
    func processPayslipPDF(from url: URL) async {
        isProcessing = true
        isUploading = true
        
        print("[PDFProcessingCoordinator] Processing payslip PDF from: \(url.absoluteString)")
        
        // First, try to load the PDF data directly to check for password protection
        guard let pdfData = try? Data(contentsOf: url) else {
            isProcessing = false
            isUploading = false
            onProcessingFailure?(AppError.message("Failed to read PDF file"))
            return
        }
        
        // Create a PDFDocument to check if it's password protected
        if let pdfDocument = PDFDocument(data: pdfData), pdfDocument.isLocked {
            print("[PDFProcessingCoordinator] PDF is password protected, showing password entry")
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
                print("[PDFProcessingCoordinator] PDF is password protected (detected in processPDF), showing password entry")
                // Show the password entry view
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else {
                // Not password-protected, process normally
                await processPDFData(pdfData, from: url)
            }
            
        case .failure(let error):
            print("[PDFProcessingCoordinator] Error processing PDF: \(error.localizedDescription)")
            
            // Check if the error indicates password protection
            if let appError = error as? AppError, case .passwordProtectedPDF = appError {
                print("[PDFProcessingCoordinator] AppError indicates password protection")
                // Pass the original PDF data to the password handler
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else if let pdfError = error as? PDFProcessingError, pdfError == .passwordProtected {
                print("[PDFProcessingCoordinator] PDFProcessingError indicates password protection")
                // Pass the original PDF data to the password handler
                passwordHandler.showPasswordEntry(for: pdfData)
                navigationCoordinator.currentPDFURL = url
            } else {
                isProcessing = false
                isUploading = false
                onProcessingFailure?(error)
            }
        }
    }
    
    /// Processes PDF data after it has been unlocked or loaded directly
    /// - Parameters:
    ///   - data: The PDF data to process
    ///   - url: The original URL of the PDF file (optional)
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        isProcessing = true
        isUploading = true
        print("[PDFProcessingCoordinator] Processing PDF data with \(data.count) bytes")
        
        // Use the PDF handler to process the data
        let result = await pdfHandler.processPDFData(data, from: url)
        
        // Ensure loading state is reset at the end
        defer {
            isProcessing = false
            isUploading = false
            isProcessingUnlocked = false
        }
        
        switch result {
        case .success(let payslipItem):
            print("[PDFProcessingCoordinator] Successfully parsed payslip")
            onProcessingSuccess?(payslipItem)
            
        case .failure(let error):
            print("[PDFProcessingCoordinator] PDF processing failed: \(error.localizedDescription)")
            onProcessingFailure?(error)
        }
    }
    
    /// Handles an unlocked PDF
    /// - Parameters:
    ///   - data: The unlocked PDF data
    ///   - originalPassword: The original password used to unlock the PDF
    func handleUnlockedPDF(data: Data, originalPassword: String) async {
        print("[PDFProcessingCoordinator] Handling unlocked PDF with \(data.count) bytes")
        
        isProcessingUnlocked = true
        
        // First detect format before we process it
        let format = pdfHandler.detectPayslipFormat(data)
        print("[PDFProcessingCoordinator] Detected format: \(format)")
        
        // Verify we have a valid PDF document
        if let pdfDocument = PDFDocument(data: data) {
            print("[PDFProcessingCoordinator] PDF document created successfully with \(pdfDocument.pageCount) pages")
            
            // Store the unlocked PDF document for later use using the navigation coordinator
            navigationCoordinator.setPDFDocument(pdfDocument, url: navigationCoordinator.currentPDFURL)
            
            // Store the unlocked data
            await MainActor.run {
                self.unlockedPDFData = data
            }
        } else {
            print("[PDFProcessingCoordinator] Warning: Could not create PDF document from unlocked data")
        }
        
        // Process the PDF data using the handler
        await processPDFData(data)
        
        // After processing is complete, mark that we're done
        isProcessingUnlocked = false
        passwordHandler.resetPasswordState()
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) async {
        isUploading = true
        
        // Use the PDF handler to process the scanned image
        let result = await pdfHandler.processScannedImage(image)
        
        switch result {
        case .success(let payslipItem):
            onProcessingSuccess?(payslipItem)
            
        case .failure(let error):
            onProcessingFailure?(AppError.pdfProcessingFailed(error.localizedDescription))
        }
        
        isUploading = false
    }
    
    /// Cancels all PDF processing operations
    func cancelProcessing() {
        isProcessing = false
        isUploading = false
        isProcessingUnlocked = false
    }
} 