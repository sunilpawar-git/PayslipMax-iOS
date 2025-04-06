import Foundation
import PDFKit
import UIKit

/// A handler for PDF processing operations
@MainActor
class PDFProcessingHandler {
    /// The PDF processing service
    private let pdfProcessingService: PDFProcessingServiceProtocol
    
    /// Flag indicating whether the PDF processing service is initialized
    private var isServiceInitialized: Bool {
        pdfProcessingService.isInitialized
    }
    
    /// Initializes a new PDF processing handler
    /// - Parameter pdfProcessingService: The PDF processing service to use
    init(pdfProcessingService: PDFProcessingServiceProtocol) {
        self.pdfProcessingService = pdfProcessingService
    }
    
    /// Processes a payslip PDF from the specified URL
    /// - Parameter url: The URL of the PDF to process
    /// - Returns: A result containing the processed PDF data or an error
    func processPDF(from url: URL) async -> Result<Data, Error> {
        // Check if PDF processing service is initialized
        if !isServiceInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                return .failure(error)
            }
        }
        
        // Process the PDF using the service
        let result = await pdfProcessingService.processPDF(from: url)
        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let data):
            return .success(data)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Checks if the specified PDF data is password protected
    /// - Parameter data: The PDF data to check
    /// - Returns: A boolean indicating whether the PDF is password protected
    func isPasswordProtected(_ data: Data) -> Bool {
        return pdfProcessingService.isPasswordProtected(data)
    }
    
    /// Processes the PDF data
    /// - Parameter data: The PDF data to process
    /// - Parameter url: The original URL of the PDF (optional)
    /// - Returns: A result containing the parsed payslip or an error
    func processPDFData(_ data: Data, from url: URL? = nil) async -> Result<PayslipItem, Error> {
        print("[PDFProcessingHandler] Process PDF Data started with \(data.count) bytes")
        if let url = url {
            print("[PDFProcessingHandler] PDF Source URL: \(url.lastPathComponent)")
        }
        
        // Verify we can create a valid PDFDocument from the data
        var pdfDocument: PDFDocument? = PDFDocument(data: data)
        
        if pdfDocument == nil {
            print("[PDFProcessingHandler] WARNING: Could not create PDFDocument from data")
            // Try to repair the PDF
            let repairedData = PDFManager.shared.verifyAndRepairPDF(data: data)
            print("[PDFProcessingHandler] Repaired PDF data size: \(repairedData.count) bytes")
            
            pdfDocument = PDFDocument(data: repairedData)
            if pdfDocument != nil {
                print("[PDFProcessingHandler] Successfully created PDF document from repaired data")
            }
        } else {
            print("[PDFProcessingHandler] Valid PDF document created with \(pdfDocument!.pageCount) pages")
        }
        
        // Detect format before processing
        let format = pdfProcessingService.detectPayslipFormat(data)
        print("[PDFProcessingHandler] Detected format: \(format)")
        
        // Use the PDF processing service to process the data
        print("[PDFProcessingHandler] Calling pdfProcessingService.processPDFData")
        let result = await pdfProcessingService.processPDFData(data)
        print("[PDFProcessingHandler] processPDFData completed")
        
        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image to process
    /// - Returns: A result containing the parsed payslip or an error
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, Error> {
        // Check if PDF processing service is initialized
        if !isServiceInitialized {
            do {
                try await pdfProcessingService.initialize()
            } catch {
                return .failure(error)
            }
        }
        
        // Use the service to process the scanned image
        let result = await pdfProcessingService.processScannedImage(image)
        // Convert PDFProcessingError to Error for return type compatibility
        switch result {
        case .success(let item):
            return .success(item)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Detects the payslip format from the specified PDF data
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        return pdfProcessingService.detectPayslipFormat(data)
    }
} 