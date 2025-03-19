import Foundation
import PDFKit

enum PDFStorageError: Error {
    case failedToSave
    case fileNotFound
    case invalidData
    case failedToCreateDirectory
}

class PDFManager {
    static let shared = PDFManager()
    private let fileManager = FileManager.default
    
    private init() {
        checkAndCreatePDFDirectory()
    }
    
    // MARK: - PDF Directory Management
    
    private func checkAndCreatePDFDirectory() {
        if !FileManager.default.fileExists(atPath: getPDFDirectoryPath().path) {
            do {
                try FileManager.default.createDirectory(at: getPDFDirectoryPath(), withIntermediateDirectories: true)
                print("PDF directory created successfully")
            } catch {
                print("Error creating PDF directory: \(error)")
            }
        }
    }
    
    private func getPDFDirectoryPath() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent("PDFs", isDirectory: true)
    }
    
    private func getFileURL(for identifier: String) -> URL {
        return getPDFDirectoryPath().appendingPathComponent("\(identifier).pdf")
    }
    
    // MARK: - PDF Storage Methods
    
    func savePDF(data: Data, identifier: String) throws -> URL {
        let fileURL = getFileURL(for: identifier)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func savePDFWithRepair(data: Data, identifier: String) throws -> URL {
        let repairedData = verifyAndRepairPDF(data: data)
        return try savePDF(data: repairedData, identifier: identifier)
    }
    
    func saveWithRetry(data: Data, identifier: String, maxRetries: Int = 3) throws -> URL {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let fileURL = getFileURL(for: identifier)
                try data.write(to: fileURL)
                print("PDF saved successfully on attempt \(attempt)")
                return fileURL
            } catch {
                lastError = error
                print("Error saving PDF (attempt \(attempt)): \(error)")
                
                // Wait a bit before retrying
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }
        
        throw lastError ?? NSError(domain: "PDFManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save PDF after \(maxRetries) attempts"])
    }
    
    func getPDFURL(for identifier: String) -> URL? {
        let fileURL = getFileURL(for: identifier)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func getPDFData(for identifier: String) -> Data? {
        guard let fileURL = getPDFURL(for: identifier) else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }
    
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
                print("Error checking PDF file size: \(error)")
            }
        }
        
        return false
    }
    
    // MARK: - PDF Verification and Repair
    
    /// Verifies if the provided data contains a valid PDF document
    func verifyPDF(data: Data) -> Bool {
        guard !data.isEmpty else { 
            print("PDFManager: PDF data is empty")
            return false 
        }
        
        if let document = PDFDocument(data: data), document.pageCount > 0 {
            return true
        }
        
        return false
    }
    
    /// Verifies and repairs PDF data if needed, or creates placeholder if repair fails
    func verifyAndRepairPDF(data: Data) -> Data {
        // Check if PDF is valid first
        if verifyPDF(data: data) {
            print("PDFManager: PDF is valid, no repair needed")
            return data
        }
        
        // Try to repair the PDF
        print("PDFManager: Attempting to repair corrupted PDF")
        if let repairedData = repairPDF(data) {
            print("PDFManager: PDF repair successful")
            return repairedData
        }
        
        // If repair failed, create a placeholder
        print("PDFManager: PDF repair failed, creating placeholder")
        return createPlaceholderPDF()
    }
    
    /// Attempts to repair corrupted PDF data by extracting content and creating a new document
    private func repairPDF(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        
        // Try to create a PDF document using lower-level Core Graphics APIs
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let cgPDF = CGPDFDocument(dataProvider) else {
            return nil
        }
        
        // Check if we have pages
        if cgPDF.numberOfPages == 0 {
            return nil
        }
        
        // Create a new PDF by rendering each page from the corrupted PDF
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            for i in 1...cgPDF.numberOfPages {
                context.beginPage()
                guard let page = cgPDF.page(at: i) else { continue }
                
                // Draw the PDF page onto the context
                let pdfContext = context.cgContext
                pdfContext.saveGState()
                
                // Set up the transform to correctly render the PDF page
                let pageRect = page.getBoxRect(.mediaBox)
                let scale = min(
                    pageRect.width > 0 ? context.pdfContextBounds.width / pageRect.width : 1,
                    pageRect.height > 0 ? context.pdfContextBounds.height / pageRect.height : 1
                )
                
                pdfContext.translateBy(x: 0, y: context.pdfContextBounds.height)
                pdfContext.scaleBy(x: scale, y: -scale)
                pdfContext.drawPDFPage(page)
                pdfContext.restoreGState()
            }
        }
    }
    
    /// Creates a placeholder PDF document with an error message
    private func createPlaceholderPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let textFont = UIFont.systemFont(ofSize: 16)
            
            let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 50)
            "Payslip Details" .draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let messageRect = CGRect(x: 50, y: 120, width: pageRect.width - 100, height: 100)
            "The original PDF document could not be displayed due to formatting issues or data corruption. This is a placeholder document generated by the app." .draw(in: messageRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let infoRect = CGRect(x: 50, y: 220, width: pageRect.width - 100, height: 60)
            "The payslip data is still available and can be viewed in the app interface. This document is provided for sharing purposes." .draw(in: infoRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
        }
    }
    
    // Get all stored PDF files
    func getAllPDFs() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: getPDFDirectoryPath(), includingPropertiesForKeys: nil)
            let pdfFiles = files.filter { $0.pathExtension == "pdf" }
            print("PDFManager: Found \(pdfFiles.count) PDF files")
            return pdfFiles
        } catch {
            print("PDFManager: Failed to get PDF files: \(error)")
            return []
        }
    }
    
    // Delete PDF for a given identifier
    func deletePDF(identifier: String) throws {
        if let pdfURL = getPDFURL(for: identifier) {
            try fileManager.removeItem(at: pdfURL)
            print("PDFManager: Deleted PDF for ID \(identifier)")
        } else {
            print("PDFManager: No PDF found to delete for ID \(identifier)")
        }
    }
} 