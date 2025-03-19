import Foundation
import PDFKit

protocol PDFService {
    func extract(_ pdfData: Data) -> [String: String]
    func unlockPDF(_ pdfData: Data, password: String) async throws -> Data
}

class DefaultPDFService: PDFService {
    func extract(_ pdfData: Data) -> [String: String] {
        guard let document = PDFDocument(data: pdfData) else {
            return [:]
        }
        
        var extractedText: [String: String] = [:]
        
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                if let pageContent = page.string {
                    extractedText["page_\(pageIndex + 1)"] = pageContent
                }
            }
        }
        
        return extractedText
    }
    
    func unlockPDF(_ pdfData: Data, password: String) async throws -> Data {
        // Check if this is our special military PDF format already
        let milMarker = "MILPDF:"
        if let markerData = milMarker.data(using: .utf8),
           pdfData.starts(with: markerData) {
            // It's already in our special format, just return it
            return pdfData
        }
        
        // First, try regular unlocking with PDFKit
        if let document = PDFDocument(data: pdfData) {
            if document.isLocked {
                if document.unlock(withPassword: password) {
                    if let data = document.dataRepresentation() {
                        return data
                    }
                }
                throw PDFServiceError.incorrectPassword
            } else {
                // Document wasn't locked, just return the original data
                return pdfData
            }
        }
        
        // PDFKit couldn't handle the document, try with CoreGraphics
        if let provider = CGDataProvider(data: pdfData as CFData),
           let cgPDF = CGPDFDocument(provider) {
            
            if cgPDF.isEncrypted {
                let unlockSuccess = cgPDF.unlockWithPassword(password)
                if !unlockSuccess {
                    throw PDFServiceError.incorrectPassword
                }
            }
            
            // If we get here with CGPDFDocument, we'll create our special format
            // which embeds the password with the PDF data
            return createMilitaryPDFFormat(pdfData: pdfData, password: password)
        }
        
        // Neither PDFKit nor CoreGraphics could handle this document
        throw PDFServiceError.unableToProcessPDF
    }
    
    private func createMilitaryPDFFormat(pdfData: Data, password: String) -> Data {
        // Create a special format that wraps the password with the data
        // Format: "MILPDF:" + 4 bytes for password length + password + original PDF data
        
        let marker = "MILPDF:"
        guard let markerData = marker.data(using: .utf8),
              let passwordData = password.data(using: .utf8) else {
            return pdfData
        }
        
        let passwordLength = UInt32(passwordData.count)
        var lengthBytes = Data(count: 4)
        lengthBytes.withUnsafeMutableBytes { 
            $0.storeBytes(of: passwordLength, as: UInt32.self)
        }
        
        var combinedData = Data()
        combinedData.append(markerData)
        combinedData.append(lengthBytes)
        combinedData.append(passwordData)
        combinedData.append(pdfData)
        
        return combinedData
    }
}

enum PDFServiceError: Error {
    case incorrectPassword
    case unableToProcessPDF
    case militaryPDFNotSupported
} 