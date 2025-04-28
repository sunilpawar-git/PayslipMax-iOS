import Foundation
import PDFKit
import UIKit

/// Errors that can occur during PDF storage and management operations.
enum PDFStorageError: Error {
    /// An error occurred while attempting to save the PDF file to disk.
    case failedToSave
    /// The requested PDF file could not be found at the expected location.
    case fileNotFound
    /// The provided data was not recognized as valid PDF data.
    case invalidData
    /// The necessary directory for storing PDFs could not be created.
    case failedToCreateDirectory
}

/// Manages the storage, retrieval, verification, and repair of PDF files.
/// Provides a centralized interface for handling PDF documents within the application's sandboxed storage.
class PDFManager {
    /// Shared singleton instance of the PDFManager.
    static let shared = PDFManager()
    /// Standard file manager instance.
    private let fileManager = FileManager.default
    /// Logging category for this manager.
    private let logCategory = "PDFManager"
    /// Utility for repairing PDF data.
    private let pdfRepairer = PDFRepairer()
    /// Utility for generating placeholder PDF documents.
    private let placeholderGenerator = PDFPlaceholderGenerator()
    
    /// Private initializer to ensure singleton usage. Creates the PDF directory if it doesn't exist.
    private init() {
        checkAndCreatePDFDirectory()
    }
    
    // MARK: - PDF Directory Management
    
    /// Checks if the PDF storage directory exists, creates it if necessary, and verifies writability.
    private func checkAndCreatePDFDirectory() {
        let directoryPath = getPDFDirectoryPath().path
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: getPDFDirectoryPath(), withIntermediateDirectories: true)
                Logger.info("PDF directory created successfully", category: logCategory)
            } catch {
                Logger.error("Error creating PDF directory: \(error)", category: logCategory)
            }
        }
        
        // Verify the directory is writable
        if FileManager.default.fileExists(atPath: directoryPath) {
            // Try to create a test file to verify write access
            let testFilePath = getPDFDirectoryPath().appendingPathComponent("write_test.txt")
            do {
                try "Test write access".write(to: testFilePath, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(at: testFilePath) // Clean up test file
                Logger.info("PDF directory is writable", category: logCategory)
            } catch {
                Logger.error("PDF directory is not writable: \(error)", category: logCategory)
            }
        } else {
            Logger.error("PDF directory does not exist and could not be created", category: logCategory)
        }
    }
    
    /// Gets the URL for the directory where PDFs are stored within the app's documents directory.
    /// - Returns: A `URL` pointing to the `Documents/PDFs/` directory.
    private func getPDFDirectoryPath() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent("PDFs", isDirectory: true)
    }
    
    /// Constructs the file URL for a PDF with a specific identifier.
    /// - Parameter identifier: A unique string identifying the PDF file (e.g., a UUID).
    /// - Returns: A `URL` pointing to the potential location of the PDF file.
    private func getFileURL(for identifier: String) -> URL {
        return getPDFDirectoryPath().appendingPathComponent("\(identifier).pdf")
    }
    
    // MARK: - PDF Storage Methods
    
    /// Saves PDF data to a file with the given identifier.
    /// - Parameters:
    ///   - data: The PDF data to save.
    ///   - identifier: A unique string to name the PDF file.
    /// - Returns: The `URL` where the PDF was saved.
    /// - Throws: An error if writing the data to the file fails.
    func savePDF(data: Data, identifier: String) throws -> URL {
        let fileURL = getFileURL(for: identifier)
        try data.write(to: fileURL)
        return fileURL
    }
    
    /// Verifies, potentially repairs, and then saves PDF data.
    /// If the data is invalid and cannot be repaired, a placeholder PDF is saved instead.
    /// - Parameters:
    ///   - data: The PDF data to verify, repair, and save.
    ///   - identifier: A unique string to name the PDF file.
    /// - Returns: The `URL` where the (potentially repaired or placeholder) PDF was saved.
    /// - Throws: An error if saving the final data fails.
    func savePDFWithRepair(data: Data, identifier: String) throws -> URL {
        let repairedData = verifyAndRepairPDF(data: data)
        return try savePDF(data: repairedData, identifier: identifier)
    }
    
    /// Saves PDF data with automatic retries on failure.
    /// - Parameters:
    ///   - data: The PDF data to save.
    ///   - identifier: A unique string to name the PDF file.
    ///   - maxRetries: The maximum number of times to retry saving upon failure.
    /// - Returns: The `URL` where the PDF was saved.
    /// - Throws: The last error encountered if saving fails after all retries.
    func saveWithRetry(data: Data, identifier: String, maxRetries: Int = 3) throws -> URL {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let fileURL = getFileURL(for: identifier)
                try data.write(to: fileURL)
                Logger.info("PDF saved successfully on attempt \(attempt)", category: logCategory)
                return fileURL
        } catch {
                lastError = error
                Logger.warning("Error saving PDF (attempt \(attempt)): \(error)", category: logCategory)
                
                // Wait a bit before retrying
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }
        
        throw lastError ?? NSError(domain: "PDFManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save PDF after \(maxRetries) attempts"])
    }
    
    /// Gets the URL for a stored PDF if it exists.
    /// - Parameter identifier: The unique identifier of the PDF.
    /// - Returns: The `URL` of the PDF file, or `nil` if it doesn't exist.
    func getPDFURL(for identifier: String) -> URL? {
        let fileURL = getFileURL(for: identifier)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    /// Retrieves the data for a stored PDF if it exists.
    /// - Parameter identifier: The unique identifier of the PDF.
    /// - Returns: The `Data` of the PDF file, or `nil` if it doesn't exist or cannot be read.
    func getPDFData(for identifier: String) -> Data? {
        guard let fileURL = getPDFURL(for: identifier) else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }
    
    /// Checks if a PDF file exists for the given identifier and has a reasonable size.
    /// - Parameter identifier: The unique identifier of the PDF.
    /// - Returns: `true` if a PDF file exists and is larger than 100 bytes, `false` otherwise.
    func pdfExists(for identifier: String) -> Bool {
        let fileURL = getFileURL(for: identifier)
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        
        // Additional check for file size to ensure it's a valid PDF
        if exists {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let size = attributes[FileAttributeKey.size] as? Int, size > 100 {
                    return true
                }
            } catch {
                Logger.error("Error checking PDF file size: \(error)", category: logCategory)
            }
        }
        
        return false
    }
    
    // MARK: - PDF Verification and Repair
    
    /// Verifies if the provided data represents a valid, non-empty PDF document.
    /// - Parameter data: The data to verify.
    /// - Returns: `true` if the data is a valid PDF with at least one page, `false` otherwise.
    func verifyPDF(data: Data) -> Bool {
        guard !data.isEmpty else { 
            Logger.warning("PDF data is empty", category: logCategory)
            return false 
        }
        
        if let document = PDFKit.PDFDocument(data: data), document.pageCount > 0 {
            return true
        }
        
        return false
    }
    
    /// Verifies PDF data. If invalid, attempts to repair it. If repair fails, returns data for a placeholder PDF.
    /// - Parameter data: The PDF data to verify and potentially repair.
    /// - Returns: The original data if valid, repaired data if successful, or placeholder PDF data if repair fails.
    func verifyAndRepairPDF(data: Data) -> Data {
        // Check if PDF is valid first
        if verifyPDF(data: data) {
            Logger.info("PDF is valid, no repair needed", category: logCategory)
            return data
        }
        
        // Try to repair the PDF using the dedicated repairer
        Logger.warning("Attempting to repair corrupted PDF", category: logCategory)
        if let repairedData = pdfRepairer.repairPDF(data) { // Use the pdfRepairer instance
            Logger.info("PDF repair successful", category: logCategory)
            return repairedData
        }
        
        // If repair failed, create a placeholder
        Logger.warning("PDF repair failed, creating placeholder", category: logCategory)
        return placeholderGenerator.createPlaceholderPDF() // Use the placeholder generator
    }
    
    /// Retrieves URLs for all PDF files currently stored in the PDF directory.
    /// - Returns: An array of `URL`s, each pointing to a stored PDF file.
    func getAllPDFs() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: getPDFDirectoryPath(), includingPropertiesForKeys: nil)
            let pdfFiles = files.filter { $0.pathExtension == "pdf" }
            Logger.info("Found \(pdfFiles.count) PDF files", category: logCategory)
            return pdfFiles
        } catch {
            Logger.error("Failed to get PDF files: \(error)", category: logCategory)
            return []
        }
    }
    
    /// Deletes the PDF file associated with the given identifier.
    /// - Parameter identifier: The unique identifier of the PDF to delete.
    /// - Throws: An error if the file exists but cannot be removed.
    func deletePDF(identifier: String) throws {
        if let pdfURL = getPDFURL(for: identifier) {
            try fileManager.removeItem(at: pdfURL)
            Logger.info("Deleted PDF for ID \(identifier)", category: logCategory)
        } else {
            Logger.info("No PDF found to delete for ID \(identifier)", category: logCategory)
        }
    }
    
    // MARK: - Debugging Methods
    
    /// Analyzes PDF data and returns a string containing debugging information.
    /// Checks data size, attempts to load with `PDFDocument`, and extracts preview text.
    /// - Parameters:
    ///   - data: The PDF data to analyze.
    ///   - identifier: An identifier for the PDF being analyzed (used in logging).
    /// - Returns: A string summarizing the analysis results.
    func analyzePDF(data: Data, identifier: String) -> String {
        var debugInfo = "PDF Analysis for \(identifier):\n"
        
        // Check basic data
        debugInfo += "Data size: \(data.count) bytes\n"
        
        // Try to create PDFDocument
        if let pdfDocument = PDFKit.PDFDocument(data: data) {
            debugInfo += "PDF document created successfully\n"
            debugInfo += "Page count: \(pdfDocument.pageCount)\n"
            debugInfo += "Is locked: \(pdfDocument.isLocked)\n"
            
            // Extract text from first page for analysis
            if let firstPage = pdfDocument.page(at: 0) {
                if let text = firstPage.string {
                    let previewText = text.prefix(100)
                    debugInfo += "First page text preview: \(previewText)...\n"
                } else {
                    debugInfo += "No text could be extracted from first page\n"
                }
            }
        } else {
            debugInfo += "Failed to create PDF document from data\n"
        }
        
        print("[PDFManager] \(debugInfo)")
        return debugInfo
    }
} 