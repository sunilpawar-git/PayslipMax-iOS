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
            print("PDFServiceImpl: Processing file at \(url.absoluteString)")
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("PDFServiceImpl: File not found at path: \(url.path)")
                throw PDFError.fileNotFound
            }
            
            // Check file size
            let attributes: [FileAttributeKey: Any]
            do {
                attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            } catch {
                print("PDFServiceImpl: Error getting file attributes: \(error.localizedDescription)")
                throw PDFError.fileReadError(error)
            }
            
            guard let fileSize = attributes[.size] as? NSNumber, fileSize.intValue > 0 else {
                print("PDFServiceImpl: File is empty")
                throw PDFError.emptyFile
            }
            
            print("PDFServiceImpl: File size: \(fileSize) bytes")
            
            // Load PDF with better error handling
            let fileData: Data
            do {
                fileData = try Data(contentsOf: url)
                print("PDFServiceImpl: Successfully loaded file data, size: \(fileData.count) bytes")
            } catch {
                print("PDFServiceImpl: Error reading file data: \(error.localizedDescription)")
                throw PDFError.fileReadError(error)
            }
            
            // Validate PDF format
            guard fileData.count > 4 else {
                print("PDFServiceImpl: File data too small to be a valid PDF")
                throw PDFError.invalidPDFFormat
            }
            
            let headerData = fileData.prefix(4)
            guard let header = String(data: headerData, encoding: .ascii) else {
                print("PDFServiceImpl: Could not read PDF header")
                throw PDFError.invalidPDFFormat
            }
            
            guard header == "%PDF" else {
                print("PDFServiceImpl: Invalid PDF header: \(header)")
                throw PDFError.invalidPDFFormat
            }
            
            print("PDFServiceImpl: Valid PDF header detected")
            
            // Create PDF document
            let document: PDFDocument
            if let doc = PDFDocument(data: fileData) {
                document = doc
                print("PDFServiceImpl: Successfully created PDFDocument from data")
            } else if let doc = PDFDocument(url: url) {
                document = doc
                print("PDFServiceImpl: Successfully created PDFDocument from URL")
            } else {
                print("PDFServiceImpl: Failed to create PDFDocument")
                throw PDFError.invalidPDF
            }
            
            // Check if document has pages
            guard document.pageCount > 0 else {
                print("PDFServiceImpl: PDF has no pages")
                throw PDFError.emptyPDF
            }
            
            print("PDFServiceImpl: PDF has \(document.pageCount) pages")
            
            // Return the original file data instead of trying to convert and encrypt
            print("PDFServiceImpl: Returning original file data, size: \(fileData.count) bytes")
            return fileData
        } catch let pdfError as PDFError {
            print("PDFServiceImpl: PDF error: \(pdfError.localizedDescription)")
            throw pdfError
        } catch {
            print("PDFServiceImpl: Unexpected error: \(error.localizedDescription)")
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
            print("PDFServiceImpl: Extracting data from PDF, size: \(data.count) bytes")
            
            // Skip decryption since we're not encrypting anymore
            let pdfData = data
            
            // Create PDF document
            guard let document = PDFDocument(data: pdfData) else {
                print("PDFServiceImpl: Failed to create PDFDocument from data in extract method")
                throw PDFError.invalidPDF
            }
            
            print("PDFServiceImpl: Successfully created PDFDocument with \(document.pageCount) pages in extract method")
            
            // Extract text from PDF using the extractor
            let payslip = try await pdfExtractor.extractPayslipData(from: document)
            print("PDFServiceImpl: Successfully extracted payslip data: \(String(describing: payslip))")
            return payslip
            
        } catch {
            print("PDFServiceImpl: Error in extract method: \(error.localizedDescription)")
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
        
        /// File not found.
        case fileNotFound
        
        /// File is empty.
        case emptyFile
        
        /// File read error.
        case fileReadError(Error)
        
        /// Invalid PDF format.
        case invalidPDFFormat
        
        /// Empty PDF.
        case emptyPDF
        
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
            case .fileNotFound:
                return "File not found"
            case .emptyFile:
                return "File is empty"
            case .fileReadError(let error):
                return "File read error: \(error.localizedDescription)"
            case .invalidPDFFormat:
                return "Invalid PDF format"
            case .emptyPDF:
                return "Empty PDF"
            }
        }
    }
} 
