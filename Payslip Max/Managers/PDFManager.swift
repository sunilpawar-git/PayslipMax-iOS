import Foundation
import PDFKit

enum PDFStorageError: Error {
    case failedToSave
    case fileNotFound
    case invalidData
}

class PDFManager {
    static let shared = PDFManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    // Get the documents directory for PDF storage
    private var pdfDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let pdfDirectory = documentsDirectory.appendingPathComponent("Payslips", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: pdfDirectory.path) {
            try? fileManager.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
        }
        
        return pdfDirectory
    }
    
    // Save PDF data with a unique identifier
    func savePDF(data: Data, identifier: String) throws -> URL {
        let pdfURL = pdfDirectory.appendingPathComponent("\(identifier).pdf")
        
        do {
            try data.write(to: pdfURL)
            return pdfURL
        } catch {
            throw PDFStorageError.failedToSave
        }
    }
    
    // Get PDF URL for a given identifier
    func getPDFURL(for identifier: String) -> URL? {
        let pdfURL = pdfDirectory.appendingPathComponent("\(identifier).pdf")
        return fileManager.fileExists(atPath: pdfURL.path) ? pdfURL : nil
    }
    
    // Delete PDF for a given identifier
    func deletePDF(identifier: String) throws {
        let pdfURL = pdfDirectory.appendingPathComponent("\(identifier).pdf")
        if fileManager.fileExists(atPath: pdfURL.path) {
            try fileManager.removeItem(at: pdfURL)
        }
    }
    
    // Get all stored PDF files
    func getAllPDFs() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: pdfDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "pdf" }
        } catch {
            return []
        }
    }
    
    // Check if PDF exists for identifier
    func pdfExists(for identifier: String) -> Bool {
        let pdfURL = pdfDirectory.appendingPathComponent("\(identifier).pdf")
        return fileManager.fileExists(atPath: pdfURL.path)
    }
} 