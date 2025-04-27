import Foundation
import PDFKit
import UIKit

/// A utility responsible for attempting to repair corrupted or invalid PDF data.
struct PDFRepairer {
    /// Logging category for this utility.
    private let logCategory = "PDFRepairer"

    /// Attempts to repair corrupted PDF data using CoreGraphics or by restructuring.
    /// - Parameter data: The potentially corrupted PDF data.
    /// - Returns: Repaired PDF data as `Data` if successful, otherwise `nil`.
    func repairPDF(_ data: Data) -> Data? {
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
    
    /// Renders pages from a `CGPDFDocument` into a new PDF document context.
    /// Used as part of the repair process.
    /// - Parameter cgPDF: The CoreGraphics PDF document to render.
    /// - Returns: `Data` representing the newly rendered PDF document.
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
    
    /// Attempts to restructure potentially corrupt PDF data by creating a new PDF
    /// and embedding the original data's content as text.
    /// Used as a fallback repair method.
    /// - Parameter data: The potentially corrupted PDF data.
    /// - Returns: `Data` representing the restructured PDF, or `nil` if restructuring fails.
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
} 