import Foundation
import SwiftData
import PDFKit
import Vision

final class PDFServiceImpl: PDFServiceProtocol {
    // MARK: - Properties
    private let security: SecurityServiceProtocol
    private let pdfExtractor: PDFExtractorProtocol
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new PDFServiceImpl with the specified security service and PDF extractor.
    ///
    /// - Parameters:
    ///   - security: The security service to use for encryption and decryption.
    ///   - pdfExtractor: The PDF extractor to use for extracting data from PDFs.
    init(security: SecurityServiceProtocol, pdfExtractor: PDFExtractorProtocol? = nil) {
        self.security = security
        self.pdfExtractor = pdfExtractor ?? DefaultPDFExtractor()
    }
    
    /// Initializes the service.
    ///
    /// This method initializes the security service.
    ///
    /// - Throws: An error if initialization fails.
    func initialize() async throws {
        try await security.initialize()
        isInitialized = true
    }
    
    // MARK: - PDFServiceProtocol
    
    /// Processes a PDF file at the specified URL.
    ///
    /// This method loads the PDF, converts it to data, and encrypts it.
    ///
    /// - Parameter url: The URL of the PDF file to process.
    /// - Returns: The encrypted PDF data.
    /// - Throws: An error if processing fails.
    func process(_ url: URL) async throws -> Data {
        guard isInitialized else {
            throw PDFError.notInitialized
        }
        
        do {
            // Load PDF
            guard let document = PDFDocument(url: url) else {
                throw PDFError.invalidPDF
            }
            
            // Convert to data
            guard let data = document.dataRepresentation() else {
                throw PDFError.conversionFailed
            }
            
            // Encrypt before storing
            return try await security.encrypt(data)
        } catch {
            throw PDFError.processingFailed(error)
        }
    }
    
    /// Extracts payslip data from encrypted PDF data.
    ///
    /// This method decrypts the data, creates a PDF document, and extracts payslip data.
    ///
    /// - Parameter data: The encrypted PDF data.
    /// - Returns: A payslip item containing the extracted data.
    /// - Throws: An error if extraction fails.
    func extract(_ data: Data) async throws -> Any {
        guard isInitialized else {
            throw PDFError.notInitialized
        }
        
        do {
            // Decrypt data
            let decryptedData = try await security.decrypt(data)
            
            // Create PDF document
            guard let document = PDFDocument(data: decryptedData) else {
                throw PDFError.invalidPDF
            }
            
            // Extract text from PDF using the extractor
            return try await pdfExtractor.extractPayslipData(from: document)
            
        } catch {
            throw PDFError.extractionFailed(error)
        }
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur during PDF processing.
    enum PDFError: LocalizedError {
        /// The service is not initialized.
        case notInitialized
        
        /// The PDF document is invalid.
        case invalidPDF
        
        /// Failed to convert the PDF to data.
        case conversionFailed
        
        /// Failed to process the PDF.
        case processingFailed(Error)
        
        /// Failed to extract data from the PDF.
        case extractionFailed(Error)
        
        /// Error description for user-facing messages.
        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "PDF service not initialized"
            case .invalidPDF:
                return "Invalid PDF document"
            case .conversionFailed:
                return "Failed to convert PDF"
            case .processingFailed(let error):
                return "Failed to process PDF: \(error.localizedDescription)"
            case .extractionFailed(let error):
                return "Failed to extract data: \(error.localizedDescription)"
            }
        }
    }
} 
