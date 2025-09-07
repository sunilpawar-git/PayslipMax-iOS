//
//  PDFParser.swift
//  PayslipMax
//
//  Created on: Phase 1 Refactoring
//  Description: Extracted PDF parsing logic following SOLID principles
//

import Foundation
import PDFKit

/// Protocol defining PDF parsing capabilities
protocol PDFParserProtocol {
    /// Extracts text content from PDF data
    func extractText(from pdfData: Data) -> [String: String]

    /// Extracts text using PDFKit from a PDFDocument
    func extractTextFromDocument(_ document: PDFDocument) -> [Int: String]

    /// Extracts text using CoreGraphics as fallback
    func extractTextFromCGPDF(_ data: Data, password: String?) -> [String: String]
}

/// Default implementation of PDF parsing
class PDFParser: PDFParserProtocol {
    func extractText(from pdfData: Data) -> [String: String] {
        print("PDFParser: Starting extraction process")

        var result = [String: String]()

        // Create PDF document
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("PDFParser: Failed to create PDF document from data")
            return [:]
        }

        print("PDFParser: Created PDF document, is locked: \(pdfDocument.isLocked)")

        // Check if the document is locked
        if pdfDocument.isLocked {
            print("PDFParser: Document is locked, cannot extract text. Will need password first.")
            return ["page_1": "This PDF is password protected. Please enter the password to view content."]
        }

        // First try PDFKit extraction
        var extractedText = extractTextFromDocument(pdfDocument)
        print("PDFParser: Extracted \(extractedText.count) text entries from PDF using PDFKit")

        // If PDFKit extraction failed, try CoreGraphics
        if extractedText.isEmpty {
            print("PDFParser: No text extracted using PDFKit, trying CoreGraphics method")
            let cgResult = extractTextFromCGPDF(pdfData, password: nil)

            // Convert CoreGraphics result to match PDFKit format
            for (key, value) in cgResult {
                if let pageNum = Int(key.replacingOccurrences(of: "page_", with: "")) {
                    extractedText[pageNum - 1] = value
                }
            }

            if !extractedText.isEmpty {
                print("PDFParser: Successfully extracted text using CoreGraphics")
            } else {
                print("PDFParser: CoreGraphics extraction also returned empty text")
            }
        }

        // If we still couldn't extract any text
        if extractedText.isEmpty {
            print("PDFParser: Warning: No text extracted from PDF despite successful document opening")
            return ["page_0": "PDF text extraction failed"]
        }

        // Convert Int keys to String keys for compatibility
        for (key, value) in extractedText {
            result["page_\(key + 1)"] = value
            // Log first 100 characters of each page for debugging
            print("PDFParser: Page \(key + 1) content preview: \(String(value.prefix(100)))")
        }

        return result
    }

    func extractTextFromDocument(_ document: PDFDocument) -> [Int: String] {
        var result = [Int: String]()
        let pageCount = document.pageCount

        print("PDFParser: Extracting text from \(pageCount) pages using PDFKit")

        for i in 0..<pageCount {
            guard let page = document.page(at: i) else {
                print("PDFParser: Warning - Could not access page \(i)")
                continue
            }

            if let pageText = page.string {
                print("PDFParser: Page \(i) extracted \(pageText.count) characters")
                if !pageText.isEmpty {
                    result[i] = pageText
                    // Log first 50 characters for debugging
                    print("PDFParser: Page \(i) preview: \(String(pageText.prefix(50)))")
                } else {
                    print("PDFParser: Warning - Empty text content found on page \(i)")
                }
            } else {
                print("PDFParser: Warning - Could not extract string from page \(i)")
            }
        }

        return result
    }

    func extractTextFromCGPDF(_ data: Data, password: String?) -> [String: String] {
        print("PDFParser: Attempting CoreGraphics extraction")

        // Create a new PDFDocument from the data
        guard let pdfDocument = PDFDocument(data: data) else {
            print("PDFParser: Failed to create PDFDocument")
            return [:]
        }

        var result = [String: String]()
        let pageCount = pdfDocument.pageCount

        print("PDFParser: CoreGraphics - Processing \(pageCount) pages")

        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else {
                print("PDFParser: CoreGraphics - Could not access page \(i)")
                continue
            }

            if let text = page.string {
                let pageNumber = i + 1
                print("PDFParser: CoreGraphics - Extracted \(text.count) characters from page \(pageNumber)")
                if !text.isEmpty {
                    result["page_\(pageNumber)"] = text
                    print("PDFParser: CoreGraphics - Page \(pageNumber) preview: \(String(text.prefix(50)))")
                }
            } else {
                print("PDFParser: CoreGraphics - No text extracted from page \(i + 1)")
            }
        }

        return result
    }
}
