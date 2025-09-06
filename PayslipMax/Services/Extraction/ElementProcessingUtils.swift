import Foundation
import PDFKit
import CoreGraphics

/// Utility functions for processing and transforming positional elements
struct ElementProcessingUtils {
    
    // MARK: - Element Filtering
    
    /// Filters elements by minimum size requirements
    static func filterBySize(_ elements: [PositionalElement], configuration: ExtractionConfiguration) -> [PositionalElement] {
        return elements.filter { element in
            element.bounds.width >= configuration.minimumElementSize.width &&
            element.bounds.height >= configuration.minimumElementSize.height
        }
    }
    
    /// Limits the number of elements per page if configured
    static func limitElements(_ elements: [PositionalElement], configuration: ExtractionConfiguration) -> [PositionalElement] {
        guard configuration.maxElementsPerPage > 0,
              elements.count > configuration.maxElementsPerPage else {
            return elements
        }
        
        // Keep the largest elements by area
        let sortedByArea = elements.sorted { first, second in
            let firstArea = first.bounds.width * first.bounds.height
            let secondArea = second.bounds.width * second.bounds.height
            return firstArea > secondArea
        }
        
        return Array(sortedByArea.prefix(configuration.maxElementsPerPage))
    }
    
    // MARK: - Element Classification
    
    /// Classifies all elements using the element classifier
    @MainActor
    static func classifyElements(_ elements: [PositionalElement], classifier: ElementTypeClassifier) async throws -> [PositionalElement] {
        var classifiedElements: [PositionalElement] = []
        
        for element in elements {
            let (type, confidence) = await classifier.classify(
                text: element.text,
                bounds: element.bounds,
                context: elements
            )
            
            let classifiedElement = PositionalElement(
                text: element.text,
                bounds: element.bounds,
                type: type,
                confidence: confidence,
                metadata: element.metadata,
                fontSize: element.fontSize,
                isBold: element.isBold,
                pageIndex: element.pageIndex
            )
            
            classifiedElements.append(classifiedElement)
        }
        
        return classifiedElements
    }
    
    // MARK: - Font Information
    
    /// Extracts font size from a PDF selection
    static func extractFontSize(from selection: PDFSelection, page: PDFPage, configuration: ExtractionConfiguration) -> Double? {
        guard configuration.extractFontInfo else { return nil }
        
        // This is a simplified implementation
        // In a full implementation, you would parse the PDF's font information
        return nil
    }
    
    /// Extracts bold status from a PDF selection
    static func extractBoldStatus(from selection: PDFSelection, page: PDFPage, configuration: ExtractionConfiguration) -> Bool {
        guard configuration.extractFontInfo else { return false }
        
        // This is a simplified implementation
        // In a full implementation, you would parse the PDF's font styling
        return false
    }
    
    // MARK: - Metadata Extraction
    
    /// Extracts metadata from a PDF page
    static func extractPageMetadata(from page: PDFPage) -> [String: String] {
        var metadata: [String: String] = [:]
        
        let bounds = page.bounds(for: .mediaBox)
        metadata["width"] = "\(bounds.width)"
        metadata["height"] = "\(bounds.height)"
        metadata["rotation"] = "\(page.rotation)"
        
        return metadata
    }
    
    /// Extracts metadata from a PDF document
    static func extractDocumentMetadata(from document: PDFDocument) -> [String: String] {
        var metadata: [String: String] = [:]
        
        metadata["pageCount"] = "\(document.pageCount)"
        metadata["isLocked"] = "\(document.isLocked)"
        
        if let attributes = document.documentAttributes {
            if let title = attributes[PDFDocumentAttribute.titleAttribute] as? String {
                metadata["title"] = title
            }
            if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String {
                metadata["creator"] = creator
            }
            if let subject = attributes[PDFDocumentAttribute.subjectAttribute] as? String {
                metadata["subject"] = subject
            }
        }
        
        return metadata
    }
    
    // MARK: - Mock Element Generation
    
    /// Creates mock positional elements for testing purposes
    static func createMockElements(from pageString: String, pageIndex: Int, pageBounds: CGRect) -> [PositionalElement] {
        var elements: [PositionalElement] = []
        
        // Create mock positional elements for testing
        // In a full implementation, this would use PDFKit's text annotation APIs
        let words = pageString.components(separatedBy: .whitespacesAndNewlines)
        
        for (index, word) in words.enumerated() {
            guard !word.isEmpty, word.count > 2 else { continue }
            
            // Create mock bounds - evenly distributed across the page
            let x = CGFloat(index % 4) * (pageBounds.width / 4) + 10
            let y = CGFloat(index / 4) * 20 + 50
            let width = CGFloat(word.count * 8) // Approximate width based on character count
            let height: CGFloat = 12
            
            let bounds = CGRect(x: x, y: y, width: width, height: height)
            
            let element = PositionalElement(
                text: word,
                bounds: bounds,
                type: .unknown, // Will be classified later if enabled
                confidence: 0.5,
                metadata: ["mock": "true"],
                fontSize: 12,
                isBold: false,
                pageIndex: pageIndex
            )
            
            elements.append(element)
        }
        
        return elements
    }
}
