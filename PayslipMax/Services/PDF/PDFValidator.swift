//
//  PDFValidator.swift
//  PayslipMax
//
//  Created on: Phase 1 Refactoring
//  Description: Extracted PDF validation and type detection logic following SOLID principles
//

import Foundation
import PDFKit

/// Protocol defining PDF validation and type detection capabilities
protocol PDFValidatorProtocol {
    /// Determines the PDF file type (standard, military, pcda)
    func detectFileType(_ document: PDFDocument) -> PDFFileType

    /// Validates if a PDF document can be processed
    func validateDocument(_ document: PDFDocument) -> Bool

    /// Checks if PDF is password protected
    func isPasswordProtected(_ document: PDFDocument) -> Bool

    /// Validates PDF data integrity
    func validatePDFData(_ data: Data) -> Bool
}

/// Default implementation of PDF validation
class PDFValidator: PDFValidatorProtocol {
    func detectFileType(_ document: PDFDocument) -> PDFFileType {
        if isPCDAPDF(document) {
            return .pcda
        } else if isMilitaryPDF(document) {
            return .military
        } else {
            return .standard
        }
    }

    func validateDocument(_ document: PDFDocument) -> Bool {
        // Check if document has pages
        guard document.pageCount > 0 else {
            print("PDFValidator: Document has no pages")
            return false
        }

        // Check if document is not corrupted
        for i in 0..<min(3, document.pageCount) {
            guard document.page(at: i) != nil else {
                print("PDFValidator: Cannot access page \(i)")
                return false
            }
        }

        return true
    }

    func isPasswordProtected(_ document: PDFDocument) -> Bool {
        return document.isLocked
    }

    func validatePDFData(_ data: Data) -> Bool {
        guard let document = PDFDocument(data: data) else {
            print("PDFValidator: Invalid PDF data - cannot create document")
            return false
        }

        return validateDocument(document)
    }

    // Helper to detect military PDFs
    private func isMilitaryPDF(_ document: PDFDocument) -> Bool {
        // Check document attributes
        if let attributes = document.documentAttributes {
            if let title = attributes[PDFDocumentAttribute.titleAttribute] as? String,
               title.contains("Ministry of Defence") || title.contains("Army") ||
               title.contains("Defence") || title.contains("Military") {
                return true
            }

            if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String,
               creator.contains("Defence") || creator.contains("Military") ||
               creator.contains("PCDA") || creator.contains("Army") {
                return true
            }
        }

        // Check content of first few pages
        for i in 0..<min(3, document.pageCount) {
            if let page = document.page(at: i),
               let text = page.string,
               text.contains("Ministry of Defence") || text.contains("ARMY") ||
               text.contains("NAVY") || text.contains("AIR FORCE") ||
               text.contains("PCDA") || text.contains("CDA") ||
               text.contains("Defence") || text.contains("DSOP FUND") {
                return true
            }
        }

        return false
    }

    // Helper to specifically detect PCDA PDFs
    private func isPCDAPDF(_ document: PDFDocument) -> Bool {
        // Check document attributes
        if let attributes = document.documentAttributes {
            if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String,
               creator.contains("PCDA") {
                return true
            }
        }

        // Check content of first few pages
        for i in 0..<min(3, document.pageCount) {
            if let page = document.page(at: i),
               let text = page.string {
                if text.contains("PCDA") || text.contains("Principal Controller of Defence Accounts") {
                    return true
                }

                // Check for common PCDA identifiers
                if text.contains("PAY AND ALLOWANCES") &&
                   (text.contains("ARMY") || text.contains("OFFICERS")) {
                    return true
                }
            }
        }

        return false
    }
}
