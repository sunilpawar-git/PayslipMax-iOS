import Foundation
import PDFKit

protocol PDFService {
    func extract(_ pdfData: Data) -> [String: String]
    func unlockPDF(data: Data, password: String) async throws -> Data
    var fileType: PDFFileType { get }
}

enum PDFServiceError: Error, Equatable {
    case incorrectPassword
    case unsupportedEncryptionMethod
    case unableToProcessPDF
    case militaryPDFNotSupported
    case failedToExtractText
    case invalidFormat
}

enum PDFFileType {
    case standard
    case military
    case pcda
}

class DefaultPDFService: PDFService {
    var fileType: PDFFileType = .standard
    
    // Create PCDAPayslipHandler directly instead of getting it from DIContainer
    private let pcdaHandler = PCDAPayslipHandler()
    
    func extract(_ pdfData: Data) -> [String: String] {
        print("PDFService: Starting extraction process")
        
        var result = [String: String]()
        
        // Create PDF document
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("PDFService: Failed to create PDF document from data")
            return [:]
        }
        
        print("PDFService: Created PDF document, is locked: \(pdfDocument.isLocked)")
        
        // Check if the document is locked
        if pdfDocument.isLocked {
            print("PDFService: Document is locked, cannot extract text. Will need password first.")
            return ["page_1": "This PDF is password protected. Please enter the password to view content."]
        }
        
        // Check if this is a military PDF based on content
        fileType = isMilitaryPDF(pdfDocument) ? .military : .standard
        print("PDFService: PDF detected as \(fileType == .military ? "military" : fileType == .pcda ? "pcda" : "standard") format")
        
        // First try PDFKit extraction
        var extractedText = extractTextFromDocument(pdfDocument)
        print("PDFService: Extracted \(extractedText.count) text entries from PDF using PDFKit")
        
        // If PDFKit extraction failed, try CoreGraphics
        if extractedText.isEmpty {
            print("PDFService: No text extracted using PDFKit, trying CoreGraphics method")
            let cgResult = extractTextFromCGPDF(pdfData, password: nil)
            
            // Convert CoreGraphics result to match PDFKit format
            for (key, value) in cgResult {
                if let pageNum = Int(key.replacingOccurrences(of: "page_", with: "")) {
                    extractedText[pageNum - 1] = value
                }
            }
            
            if !extractedText.isEmpty {
                print("PDFService: Successfully extracted text using CoreGraphics")
            } else {
                print("PDFService: CoreGraphics extraction also returned empty text")
            }
        }
        
        // If we still couldn't extract any text
        if extractedText.isEmpty {
            print("PDFService: Warning: No text extracted from PDF despite successful document opening")
            return ["page_0": "PDF text extraction failed"]
        }
        
        // Convert Int keys to String keys for compatibility
        for (key, value) in extractedText {
            result["page_\(key + 1)"] = value
            // Log first 100 characters of each page for debugging
            print("PDFService: Page \(key + 1) content preview: \(String(value.prefix(100)))")
        }
        
        return result
    }
    
    // Extract text from a PDFDocument using PDFKit
    private func extractTextFromDocument(_ document: PDFDocument) -> [Int: String] {
        var result = [Int: String]()
        let pageCount = document.pageCount
        
        print("PDFService: Extracting text from \(pageCount) pages using PDFKit")
        
        for i in 0..<pageCount {
            guard let page = document.page(at: i) else {
                print("PDFService: Warning - Could not access page \(i)")
                continue
            }
            
            if let pageText = page.string {
                print("PDFService: Page \(i) extracted \(pageText.count) characters")
                if !pageText.isEmpty {
                    result[i] = pageText
                    // Log first 50 characters for debugging
                    print("PDFService: Page \(i) preview: \(String(pageText.prefix(50)))")
                } else {
                    print("PDFService: Warning - Empty text content found on page \(i)")
                }
            } else {
                print("PDFService: Warning - Could not extract string from page \(i)")
            }
        }
        
        return result
    }
    
    // Extract text using CoreGraphics
    private func extractTextFromCGPDF(_ data: Data, password: String?) -> [String: String] {
        print("PDFService: Attempting CoreGraphics extraction")
        
        // Create a new PDFDocument from the data
        guard let pdfDocument = PDFDocument(data: data) else {
            print("PDFService: Failed to create PDFDocument")
            return [:]
        }
        
        var result = [String: String]()
        let pageCount = pdfDocument.pageCount
        
        print("PDFService: CoreGraphics - Processing \(pageCount) pages")
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else {
                print("PDFService: CoreGraphics - Could not access page \(i)")
                continue
            }
            
            if let text = page.string {
                let pageNumber = i + 1
                print("PDFService: CoreGraphics - Extracted \(text.count) characters from page \(pageNumber)")
                if !text.isEmpty {
                    result["page_\(pageNumber)"] = text
                    print("PDFService: CoreGraphics - Page \(pageNumber) preview: \(String(text.prefix(50)))")
                }
            } else {
                print("PDFService: CoreGraphics - No text extracted from page \(i + 1)")
            }
        }
        
        return result
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw PDFServiceError.invalidFormat
        }
        
        // If the PDF is locked, attempt to unlock it with the password
        if pdfDocument.isLocked {
            let unlocked = pdfDocument.unlock(withPassword: password)
            
            if !unlocked {
                // Try with specific format for PCDA military PDFs (all caps)
                if pdfDocument.unlock(withPassword: password.uppercased()) {
                    print("PDFService: PDF unlocked successfully with uppercased password")
                } else if pdfDocument.unlock(withPassword: password.lowercased()) {
                    print("PDFService: PDF unlocked successfully with lowercased password")
                } else {
                    // Try the specialized PCDA handler if normal methods fail
                    let (unlockedData, successfulPassword) = await pcdaHandler.unlockPDF(data: data, basePassword: password)
                    if let unlockedData = unlockedData, successfulPassword != nil {
                        print("PDFService: PDF unlocked successfully by PCDAPayslipHandler")
                        return unlockedData
                    }
                    
                    // Try with common military PDF passwords
                    let militaryDefaults = ["pcda", "PCDA", "army", "ARMY", password + "1", password + "@"]
                    var success = false
                    
                    for defaultPwd in militaryDefaults {
                        if pdfDocument.unlock(withPassword: defaultPwd) {
                            print("PDFService: PDF unlocked with military default password")
                            success = true
                            break
                        }
                    }
                    
                    if !success {
                        throw PDFServiceError.incorrectPassword
                    }
                }
            }
            
            print("PDFService: PDF unlocked successfully")
            
            // Check if this is a military PDF
            let isMilitary = isMilitaryPDF(pdfDocument)
            let isPCDA = isPCDAPDF(pdfDocument)
            
            if isMilitary {
                print("PDFService: Military PDF detected")
                fileType = .military
            }
            
            if isPCDA {
                print("PDFService: PCDA PDF detected")
                fileType = .pcda
            }
            
            // For military PDFs, we need special handling
            if fileType == .military || fileType == .pcda {
                print("PDFService: Using special military PDF handling")
                
                // Military PDFs need special treatment after unlocking
                guard let pdfData = createUnlockedPDF(from: pdfDocument) else {
                    print("PDFService: Failed to create unlocked version of military PDF")
                    throw PDFServiceError.unableToProcessPDF
                }
                
                return pdfData
            } else {
                // Standard PDF handling
                guard let pdfData = pdfDocument.dataRepresentation() else {
                    throw PDFServiceError.unableToProcessPDF
                }
                
                // Verify the new data can be opened without password
                if let verificationDoc = PDFDocument(data: pdfData),
                   !verificationDoc.isLocked {
                    print("PDFService: Successfully created data representation of unlocked PDF")
                    return pdfData
                }
                
                print("PDFService: Warning - Generated PDF is still locked, trying alternative method")
                return try createPermanentlyUnlockedPDF(from: pdfDocument)
            }
        }
        
        // If not locked, return original data
        return data
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
    
    // Create a permanently unlocked PDF from a password-protected one
    private func createPermanentlyUnlockedPDF(from document: PDFDocument) throws -> Data {
        // Create a new document and copy all pages
        let newDocument = PDFDocument()
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                newDocument.insert(page, at: i)
            }
        }
        
        // Get data representation of the new document
        guard let unlockedData = newDocument.dataRepresentation(),
               let finalCheck = PDFDocument(data: unlockedData),
               !finalCheck.isLocked else {
            throw PDFServiceError.unableToProcessPDF
        }
        
        print("PDFService: Successfully created permanently unlocked version")
        return unlockedData
    }
    
    // Handle military PDFs specifically
    private func createUnlockedPDF(from document: PDFDocument) -> Data? {
        // First try standard data representation
        if let pdfData = document.dataRepresentation(),
           let verificationDoc = PDFDocument(data: pdfData),
           !verificationDoc.isLocked {
            print("PDFService: Standard unlocking worked for military PDF")
            return pdfData
        }
        
        // Try alternative approach by creating a new document
        let newDocument = PDFDocument()
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                newDocument.insert(page, at: i)
            }
        }
        
        // Get data representation of the new document
        if let unlockedData = newDocument.dataRepresentation(),
           let finalCheck = PDFDocument(data: unlockedData),
           !finalCheck.isLocked {
            print("PDFService: Created new unlocked document for military PDF")
            return unlockedData
        }
        
        print("PDFService: Could not create permanently unlocked version for military PDF")
        return document.dataRepresentation()
    }
} 