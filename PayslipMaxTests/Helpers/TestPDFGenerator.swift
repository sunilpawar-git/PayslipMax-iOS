import Foundation
import PDFKit
import UIKit
@testable import PayslipMax

/// Utility class for generating test PDF documents for use in tests
class TestPDFGenerator {
    
    // MARK: - Standard PDF Generation
    
    /// Creates a simple PDF with text content
    static func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            
            text.draw(with: CGRect(x: 10, y: 10, width: pageRect.width - 20, height: pageRect.height - 20),
                     options: .usesLineFragmentOrigin,
                     attributes: attributes,
                     context: nil)
        }
    }
    
    /// Creates a PDF with an image to simulate scanned content
    static func createPDFWithImage() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Create a simple image (a colored rectangle)
            UIColor.blue.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 300, height: 200))
            
            // Add some text to indicate it's a test document
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            
            "This is a test document with an image.".draw(
                with: CGRect(x: 50, y: 300, width: 300, height: 50),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil)
        }
    }
    
    /// Creates a multi-page PDF document
    static func createMultiPagePDF(pageCount: Int) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            for i in 0..<pageCount {
                context.beginPage()
                
                let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .natural
                
                let attributes = [
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.font: textFont
                ]
                
                "Page \(i+1) of the test document.".draw(
                    with: CGRect(x: 50, y: 50, width: 300, height: 50),
                    options: .usesLineFragmentOrigin,
                    attributes: attributes,
                    context: nil)
            }
        }
    }
    
    // MARK: - Specialized PDF Content
    
    /// Creates a PDF with table content
    static func createPDFWithTable() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let headerFont = UIFont.systemFont(ofSize: 12.0, weight: .bold)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Draw table header
            UIColor.lightGray.setFill()
            let headerRect = CGRect(x: 50, y: 50, width: 400, height: 30)
            context.fill(headerRect)
            
            // Draw table cells
            for row in 0..<5 {
                for col in 0..<3 {
                    // Draw cell border
                    let cellRect = CGRect(
                        x: 50 + (CGFloat(col) * (400.0/3.0)),
                        y: 80.0 + (CGFloat(row) * 30.0),
                        width: 400.0/3.0,
                        height: 30
                    )
                    
                    context.stroke(cellRect)
                    
                    // Draw cell content
                    let font = row == 0 ? headerFont : textFont
                    let attributes = [
                        NSAttributedString.Key.paragraphStyle: paragraphStyle,
                        NSAttributedString.Key.font: font
                    ]
                    
                    let cellContent = row == 0 ?
                        ["Item", "Quantity", "Price"][col] :
                        ["Item \(row)", "\(row * 2)", "$\(row * 10).00"][col]
                    
                    cellContent.draw(
                        with: CGRect(x: cellRect.minX + 5, y: cellRect.minY + 5, width: cellRect.width - 10, height: cellRect.height - 10),
                        options: .usesLineFragmentOrigin,
                        attributes: attributes,
                        context: nil)
                }
            }
        }
    }
    
    /// Creates a PDF with mixed content types (text, images, tables)
    static func createPDFWithMixedContent() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Mix of image, table, and different text layouts
            // Add an image
            UIColor.blue.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 200, height: 120))
            
            // Add some text
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            
            // Add header
            let headerAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: headerFont
            ]
            
            "Mixed Content Document".draw(
                with: CGRect(x: 50, y: 180, width: 500, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: headerAttributes,
                context: nil)
            
            // Add some text
            let textAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            
            "This document contains a mix of content types including images, tables, and text.".draw(
                with: CGRect(x: 50, y: 220, width: 500, height: 50),
                options: .usesLineFragmentOrigin,
                attributes: textAttributes,
                context: nil)
            
            // Add a table
            let tableY = 300.0
            
            // Table header
            UIColor.lightGray.setFill()
            context.fill(CGRect(x: 50, y: tableY, width: 400, height: 30))
            
            // Table cells
            for row in 0..<3 {
                for col in 0..<3 {
                    let cellRect = CGRect(
                        x: 50 + (CGFloat(col) * (400.0/3.0)),
                        y: tableY + 30.0 + (CGFloat(row) * 30.0),
                        width: 400.0/3.0,
                        height: 30
                    )
                    
                    context.stroke(cellRect)
                    
                    let cellContent = row == 0 ?
                        ["Column 1", "Column 2", "Column 3"][col] :
                        ["Data \(row),\(col)", "Value \(row*col)", "$\(row * 10).00"][col]
                    
                    paragraphStyle.alignment = .center
                    let cellAttributes = [
                        NSAttributedString.Key.paragraphStyle: paragraphStyle,
                        NSAttributedString.Key.font: row == 0 ? headerFont : textFont
                    ]
                    
                    cellContent.draw(
                        with: CGRect(x: cellRect.minX + 5, y: cellRect.minY + 5, width: cellRect.width - 10, height: cellRect.height - 10),
                        options: .usesLineFragmentOrigin,
                        attributes: cellAttributes,
                        context: nil)
                }
            }
        }
    }
    
    /// Creates a PDF with column-based layout
    static func createPDFWithColumns(columnCount: Int) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let columnWidth = (pageRect.width - 40) / CGFloat(columnCount)
            let textFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            
            for i in 0..<columnCount {
                let columnRect = CGRect(
                    x: 20.0 + (columnWidth * CGFloat(i)),
                    y: 20.0,
                    width: columnWidth - 10.0,
                    height: pageRect.height - 40.0
                )
                
                let columnText = "This is column \(i+1) of the test document with a complex layout. " +
                                "Each column contains different text to simulate a multi-column layout " +
                                "that might be found in a newspaper or magazine."
                
                columnText.draw(
                    with: columnRect,
                    options: .usesLineFragmentOrigin,
                    attributes: attributes,
                    context: nil
                )
            }
        }
    }
} 