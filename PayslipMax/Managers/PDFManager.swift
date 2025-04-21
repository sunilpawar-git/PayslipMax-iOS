import Foundation
import PDFKit
import UIKit

enum PDFStorageError: Error {
    case failedToSave
    case fileNotFound
    case invalidData
    case failedToCreateDirectory
}

class PDFManager {
    static let shared = PDFManager()
    private let fileManager = FileManager.default
    private let logCategory = "PDFManager"
    
    private init() {
        checkAndCreatePDFDirectory()
    }
    
    // MARK: - PDF Directory Management
    
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
                Logger.error("Error checking PDF file size: \(error)", category: logCategory)
            }
        }
        
        return false
    }
    
    // MARK: - PDF Verification and Repair
    
    /// Verifies if the provided data contains a valid PDF document
    func verifyPDF(data: Data) -> Bool {
        guard !data.isEmpty else { 
            Logger.warning("PDF data is empty", category: logCategory)
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
            Logger.info("PDF is valid, no repair needed", category: logCategory)
            return data
        }
        
        // Try to repair the PDF
        Logger.warning("Attempting to repair corrupted PDF", category: logCategory)
        if let repairedData = repairPDF(data) {
            Logger.info("PDF repair successful", category: logCategory)
            return repairedData
        }
        
        // If repair failed, create a placeholder
        Logger.warning("PDF repair failed, creating placeholder", category: logCategory)
        return createPlaceholderPDF()
    }
    
    /// Attempts to repair corrupted PDF data by extracting content and creating a new document
    private func repairPDF(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        
        Logger.debug("Attempting PDF repair with different methods", category: logCategory)
        
        // Method 1: Try low-level CoreGraphics API
        if let dataProvider = CGDataProvider(data: data as CFData),
           let cgPDF = CGPDFDocument(dataProvider) {
            
            // Check if we have pages
            if cgPDF.numberOfPages > 0 {
                Logger.info("Repair - Found \(cgPDF.numberOfPages) pages using CoreGraphics", category: logCategory)
                
                // Create a new PDF by rendering each page from the CoreGraphics PDF
                return renderCGPDFToNewDocument(cgPDF)
            }
        }
        
        // Method 2: Try to create a basic PDF structure
        Logger.debug("Repair - Attempting to restructure PDF data", category: logCategory)
        return restructurePDFData(data)
    }
    
    // Renders a CGPDFDocument to a new PDF Data
    private func renderCGPDFToNewDocument(_ cgPDF: CGPDFDocument) -> Data {
        let pageCount = cgPDF.numberOfPages
        
        // Create a PDF renderer with appropriate size
        var pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // Default A4 size
        
        // Try to get bounds from the first page
        if let firstPage = cgPDF.page(at: 1) {
            pageBounds = firstPage.getBoxRect(.mediaBox)
            // Validate the bounds - if too small or invalid, use A4
            if pageBounds.width < 10 || pageBounds.height < 10 {
                pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            }
        }
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        
        return renderer.pdfData { context in
            for i in 1...pageCount {
                guard let page = cgPDF.page(at: i) else { continue }
                
                context.beginPage()
                let ctx = context.cgContext
                
                // Get the actual page bounds
                let pageRect = page.getBoxRect(.mediaBox)
                
                // Set up the transform to correctly render the PDF page
                ctx.saveGState()
                
                // Flip coordinates for PDF rendering (PDF uses bottom-left origin)
                ctx.translateBy(x: 0, y: context.pdfContextBounds.height)
                ctx.scaleBy(x: 1, y: -1)
                
                // Scale to fit if needed
                let scaleX = context.pdfContextBounds.width / pageRect.width
                let scaleY = context.pdfContextBounds.height / pageRect.height
                let scale = min(scaleX, scaleY)
                
                ctx.scaleBy(x: scale, y: scale)
                
                // Draw the PDF page
                ctx.drawPDFPage(page)
                ctx.restoreGState()
                
                Logger.debug("Rendered page \(i)", category: logCategory)
            }
        }
    }
    
    // Attempts to restructure corrupt PDF data
    private func restructurePDFData(_ data: Data) -> Data? {
        Logger.debug("Attempting basic PDF restructuring", category: logCategory)
        
        // Create a standard PDF with A4 size
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Convert the raw data to text if possible
        var pdfText = "PDF content could not be extracted"
        if let dataString = String(data: data, encoding: .utf8) {
            pdfText = String(dataString.prefix(2000)) // Limit text to reasonable size
        } else if let dataString = String(data: data, encoding: .ascii) {
            pdfText = String(dataString.prefix(2000))
        }
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let textFont = UIFont.systemFont(ofSize: 12)
            
            // Title
            let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 30)
            "Recovered Document Content".draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Content - break into multiple text blocks to avoid issues with large text
            let contentHeight = pageRect.height - 150
            let blockHeight: CGFloat = 200
            let contentWidth = pageRect.width - 100
            let numBlocks = Int(ceil(contentHeight / blockHeight))
            
            // Split the text roughly into sections
            let textLength = pdfText.count
            let charsPerBlock = textLength / numBlocks + 1
            
            for i in 0..<numBlocks {
                let startPos = min(i * charsPerBlock, textLength)
                let endPos = min((i + 1) * charsPerBlock, textLength)
                
                if startPos >= textLength {
                    break
                }
                
                let startIndex = pdfText.index(pdfText.startIndex, offsetBy: startPos)
                let endIndex = pdfText.index(pdfText.startIndex, offsetBy: endPos)
                let textBlock = String(pdfText[startIndex..<endIndex])
                
                let blockRect = CGRect(
                    x: 50,
                    y: 100 + CGFloat(i) * blockHeight,
                    width: contentWidth,
                    height: blockHeight
                )
                
                textBlock.draw(in: blockRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
            }
            
            // Footer
            let footerRect = CGRect(x: 50, y: pageRect.height - 50, width: contentWidth, height: 20)
            "This document was reconstructed from corrupted PDF data.".draw(in: footerRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
        }
    }
    
    /// Creates a placeholder PDF document with payslip information
    private func createPlaceholderPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let textFont = UIFont.systemFont(ofSize: 16)
            let smallFont = UIFont.systemFont(ofSize: 14)
            
            // Title
            let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 50)
            "Payslip Details".draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Message about placeholder
            let messageRect = CGRect(x: 50, y: 120, width: pageRect.width - 100, height: 80)
            let message = "The original PDF document could not be displayed due to formatting issues or data corruption. Military and government PDFs may have security features that prevent direct viewing."
            message.draw(in: messageRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Payslip info message
            let infoRect = CGRect(x: 50, y: 220, width: pageRect.width - 100, height: 60)
            "The payslip data is still available and can be viewed in the app interface. This document is provided for sharing purposes.".draw(in: infoRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Technical details section
            let techHeaderRect = CGRect(x: 50, y: 300, width: pageRect.width - 100, height: 30)
            "Technical Information:".draw(in: techHeaderRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let techInfoRect = CGRect(x: 50, y: 340, width: pageRect.width - 100, height: 200)
            let techInfo = """
            • Some military and government PDFs use security features that prevent standard viewing
            • PDF format: v1.7, Adobe ExtensionLevel: 8
            • Content may be encrypted or use special rendering methods
            • Try viewing the document in Adobe Acrobat or external applications
            • The app uses the extracted data to display payslip information
            """
            
            techInfo.draw(in: techInfoRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Footer
            let footerRect = CGRect(x: 50, y: pageRect.height - 50, width: pageRect.width - 100, height: 30)
            "Generated by PayslipMax App".draw(in: footerRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
        }
    }
    
    // Get all stored PDF files
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
    
    // Delete PDF for a given identifier
    func deletePDF(identifier: String) throws {
        if let pdfURL = getPDFURL(for: identifier) {
            try fileManager.removeItem(at: pdfURL)
            Logger.info("Deleted PDF for ID \(identifier)", category: logCategory)
        } else {
            Logger.info("No PDF found to delete for ID \(identifier)", category: logCategory)
        }
    }
    
    // MARK: - Debugging Methods
    
    /// Adds debugging information to analyze PDF documents
    func analyzePDF(data: Data, identifier: String) -> String {
        var debugInfo = "PDF Analysis for \(identifier):\n"
        
        // Check basic data
        debugInfo += "Data size: \(data.count) bytes\n"
        
        // Try to create PDFDocument
        if let pdfDocument = PDFDocument(data: data) {
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