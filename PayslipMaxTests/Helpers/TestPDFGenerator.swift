import XCTest
import PDFKit
@testable import PayslipMax

/// Helper class to generate test PDF documents for testing
class TestPDFGenerator {
    
    /// Create a basic PDF with standard text
    static func createPDF(withText text: String) -> PDFDocument {
        let pdfData = createPDFWithText(text)
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a PDF simulating scanned content (image-based)
    static func createPDFWithScannedContent() -> PDFDocument {
        let pdfData = createPDFWithImage()
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a PDF with complex multi-column layout
    static func createPDFWithComplexLayout(columnCount: Int = 3) -> PDFDocument {
        let pdfData = createPDFWithColumns(columnCount: columnCount)
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a PDF with heavy text content
    static func createPDFWithHeavyText() -> PDFDocument {
        let pdfData = createPDFWithText(String(repeating: "This is a text-heavy document. ", count: 100))
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a large PDF with multiple pages
    static func createLargeDocument(pageCount: Int = 100) -> PDFDocument {
        let pdfData = createMultiPagePDF(pageCount: pageCount)
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a PDF containing tables
    static func createPDFWithTables() -> PDFDocument {
        let pdfData = createPDFWithTable()
        return PDFDocument(data: pdfData)!
    }
    
    /// Create a PDF with mixed content types (text, tables, images)
    static func createPDFWithMixedContent() -> PDFDocument {
        let pdfData = createPDFWithMixedContent()
        return PDFDocument(data: pdfData)!
    }
    
    // MARK: - Private Implementation Methods
    
    /// Create a PDF with standard text
    private static func createPDFWithText(_ text: String) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(in: pageRect.insetBy(dx: 50, dy: 50), withAttributes: attributes)
        })
        
        return pdfData as Data
    }
    
    /// Create a PDF with an image (simulating scanned content)
    private static func createPDFWithImage() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            // Create a mock image (a simple colored rectangle)
            let imageRect = pageRect.insetBy(dx: 50, dy: 50)
            context.cgContext.setFillColor(UIColor.lightGray.cgColor)
            context.cgContext.fill(imageRect)
            
            // Add minimal text to simulate OCR capabilities
            let text = "Sample scanned document"
            let textRect = CGRect(x: 100, y: 100, width: 400, height: 50)
            text.draw(in: textRect, withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
        })
        
        return pdfData as Data
    }
    
    /// Create a PDF with multiple columns (complex layout)
    private static func createPDFWithColumns(columnCount: Int) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let contentRect = pageRect.insetBy(dx: 50, dy: 50)
            let columnWidth = contentRect.width / CGFloat(columnCount)
            
            for i in 0..<columnCount {
                let columnRect = CGRect(
                    x: contentRect.minX + (columnWidth * CGFloat(i)),
                    y: contentRect.minY,
                    width: columnWidth,
                    height: contentRect.height
                ).insetBy(dx: 5, dy: 0)
                
                let text = "Column \(i+1): This is some sample text for column \(i+1). This text demonstrates a complex multi-column layout that would be typical in magazines, newspapers, or academic papers."
                
                text.draw(in: columnRect, withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
        })
        
        return pdfData as Data
    }
    
    /// Create a PDF with multiple pages
    private static func createMultiPagePDF(pageCount: Int) -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            for i in 1...pageCount {
                context.beginPage()
                
                let text = "Page \(i) of \(pageCount)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                
                text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
            }
        })
        
        return pdfData as Data
    }
    
    /// Create a PDF with a table
    private static func createPDFWithTable() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            let tableRect = pageRect.insetBy(dx: 100, dy: 200)
            let rowCount = 5
            let columnCount = 4
            let rowHeight = tableRect.height / CGFloat(rowCount)
            let columnWidth = tableRect.width / CGFloat(columnCount)
            
            // Draw table grid
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            
            // Draw horizontal lines
            for i in 0...rowCount {
                let y = tableRect.minY + (CGFloat(i) * rowHeight)
                context.cgContext.move(to: CGPoint(x: tableRect.minX, y: y))
                context.cgContext.addLine(to: CGPoint(x: tableRect.maxX, y: y))
            }
            
            // Draw vertical lines
            for i in 0...columnCount {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                context.cgContext.move(to: CGPoint(x: x, y: tableRect.minY))
                context.cgContext.addLine(to: CGPoint(x: x, y: tableRect.maxY))
            }
            
            context.cgContext.strokePath()
            
            // Add header text
            let headers = ["Header 1", "Header 2", "Header 3", "Header 4"]
            for (i, header) in headers.enumerated() {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                let headerRect = CGRect(x: x, y: tableRect.minY, width: columnWidth, height: rowHeight)
                
                header.draw(in: headerRect.insetBy(dx: 5, dy: 5), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10)
                ])
            }
            
            // Add cell data
            for row in 1..<rowCount {
                for col in 0..<columnCount {
                    let x = tableRect.minX + (CGFloat(col) * columnWidth)
                    let y = tableRect.minY + (CGFloat(row) * rowHeight)
                    let cellRect = CGRect(x: x, y: y, width: columnWidth, height: rowHeight)
                    
                    let cellText = "Cell \(row),\(col)"
                    cellText.draw(in: cellRect.insetBy(dx: 5, dy: 5), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10)
                    ])
                }
            }
        })
        
        return pdfData as Data
    }
    
    /// Create a PDF with mixed content (tables, images, text)
    private static func createPDFWithMixedContent() -> Data {
        let pdfData = NSMutableData()
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        pdfData.append(renderer.pdfData { context in
            context.beginPage()
            
            // Add title
            let titleRect = CGRect(x: 50, y: 50, width: 512, height: 40)
            "Mixed Content Document".draw(in: titleRect, withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 18)
            ])
            
            // Add paragraph text
            let paragraphRect = CGRect(x: 50, y: 100, width: 512, height: 100)
            "This document contains a mixture of content types including text, tables, and images. This type of document would require sophisticated analysis to properly extract all content.".draw(in: paragraphRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12)
            ])
            
            // Add an image (simulating scanned content)
            let imageRect = CGRect(x: 50, y: 220, width: 200, height: 150)
            context.cgContext.setFillColor(UIColor.darkGray.cgColor)
            context.cgContext.fill(imageRect)
            
            // Add a small table
            let tableRect = CGRect(x: 300, y: 220, width: 250, height: 150)
            let rowCount = 3
            let columnCount = 2
            let rowHeight = tableRect.height / CGFloat(rowCount)
            let columnWidth = tableRect.width / CGFloat(columnCount)
            
            // Draw table grid
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            
            // Draw horizontal lines
            for i in 0...rowCount {
                let y = tableRect.minY + (CGFloat(i) * rowHeight)
                context.cgContext.move(to: CGPoint(x: tableRect.minX, y: y))
                context.cgContext.addLine(to: CGPoint(x: tableRect.maxX, y: y))
            }
            
            // Draw vertical lines
            for i in 0...columnCount {
                let x = tableRect.minX + (CGFloat(i) * columnWidth)
                context.cgContext.move(to: CGPoint(x: x, y: tableRect.minY))
                context.cgContext.addLine(to: CGPoint(x: x, y: tableRect.maxY))
            }
            
            context.cgContext.strokePath()
            
            // Add columns at the bottom (complex layout)
            let columnRect = CGRect(x: 50, y: 400, width: 512, height: 300)
            let columns = 2
            let columnWidth2 = columnRect.width / CGFloat(columns)
            
            for i in 0..<columns {
                let colX = columnRect.minX + (columnWidth2 * CGFloat(i))
                let colRect = CGRect(x: colX, y: columnRect.minY, width: columnWidth2, height: columnRect.height).insetBy(dx: 10, dy: 0)
                
                let colText = "Column \(i+1): This is text in a multi-column layout section of the document. This demonstrates how the document has a complex layout with multiple sections and content types."
                
                colText.draw(in: colRect, withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            }
        })
        
        return pdfData as Data
    }
} 