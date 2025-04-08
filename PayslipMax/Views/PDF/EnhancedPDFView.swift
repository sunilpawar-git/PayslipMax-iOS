import SwiftUI
import PDFKit
import CoreGraphics

/// An enhanced PDF viewer that can better handle password-protected PDFs
final class EnhancedPDFView: UIViewRepresentable {
    let pdfData: Data?
    let password: String?
    @Binding var hasError: Bool
    
    private var pdfDocument: PDFDocument?
    
    init(pdfData: Data?, password: String? = nil, hasError: Binding<Bool>) {
        self.pdfData = pdfData
        self.password = password
        self._hasError = hasError
    }
    
    private func updatePDFDocument() -> PDFDocument? {
        guard let pdfData = pdfData else { return nil }
        
        var document: PDFDocument?
        
        // Check for special wrapped formats
        let pwdMarkerData = Data("PWDPDF:".utf8)
        let milMarkerData = Data("MILPDF:".utf8)
        
        if pdfData.starts(with: pwdMarkerData) {
            let (rawData, extractedPassword) = extractDataAndPassword(from: pdfData, marker: pwdMarkerData)
            let passwordToUse = extractedPassword ?? password ?? ""
            document = createDocument(from: rawData, password: passwordToUse)
        } else if pdfData.starts(with: milMarkerData) {
            let (rawData, extractedPassword) = extractDataAndPassword(from: pdfData, marker: milMarkerData)
            let passwordToUse = extractedPassword ?? password ?? ""
            document = createDocument(from: rawData, password: passwordToUse)
        } else {
            // Standard PDF
            document = createDocument(from: pdfData, password: password)
        }

        self.pdfDocument = document
        return document
    }
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground
        pdfView.pageBreakMargins = .zero
        
        // Apply the document
        let document = updatePDFDocument()
        pdfView.document = document
        hasError = (document == nil)
        
        if document == nil {
            displayErrorMessage(in: pdfView)
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Apply the document
        let document = updatePDFDocument()
        pdfView.document = document
        hasError = (document == nil)
        
        if document == nil {
            displayErrorMessage(in: pdfView)
        }
    }
    
    private func displayErrorMessage(in view: UIView) {
        // Clear existing subviews
        for subview in view.subviews {
            if subview is UILabel {
                subview.removeFromSuperview()
            }
        }
        
        // Create error message label
        let errorLabel = UILabel()
        errorLabel.text = "Unable to load PDF"
        errorLabel.textAlignment = .center
        errorLabel.textColor = .secondaryLabel
        errorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Add to view
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createDocument(from data: Data, password: String?) -> PDFDocument? {
        // Try to create PDF document directly
        if let document = PDFDocument(data: data) {
            return document
        }
        
        // If password provided, try to unlock 
        if let password = password, !password.isEmpty,
           let document = PDFDocument(data: data),
           let unlocked = unlockWithPassword(document: document, password: password) {
            return unlocked
        }
        
        // Try creating with CGPDFDocument as fallback
        if let provider = CGDataProvider(data: data as CFData),
           let cgPdfDocument = CGPDFDocument(provider),
           let documentData = createDataFromCGPDF(cgPdfDocument) {
            return PDFDocument(data: documentData)
        }
        
        print("Failed to create PDF document from data")
        return nil
    }
    
    private func unlockWithPassword(document: PDFDocument, password: String) -> PDFDocument? {
        guard let passwordCString = password.cString(using: .utf8) else {
            print("Failed to convert password to C string")
            return nil
        }
        
        if let cgPDF = document.documentRef,
           !cgPDF.isUnlocked,
           cgPDF.unlockWithPassword(passwordCString) {
            // Successfully unlocked
            return document
        }
        
        return nil
    }
    
    private func createDataFromCGPDF(_ cgPDF: CGPDFDocument) -> Data? {
        guard cgPDF.numberOfPages > 0 else { return nil }
        
        let writeOptions = [
            kCGPDFContextUserPassword: "",
            kCGPDFContextOwnerPassword: ""
        ]
        
        let data = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: nil, writeOptions as CFDictionary) else {
            return nil
        }
        
        for i in 1...cgPDF.numberOfPages {
            guard let page = cgPDF.page(at: i) else { continue }
            
            var mediaBox = page.getBoxRect(.mediaBox)
            
            // Draw page to context
            context.beginPage(mediaBox: &mediaBox)
            context.drawPDFPage(page)
            context.endPage()
        }
        
        return data as Data
    }
    
    private func extractDataAndPassword(from data: Data, marker: Data) -> (Data, String?) {
        guard data.count > marker.count else { return (data, nil) }
        
        let startIndex = marker.count
        
        // Check if password is included (format is MARKER:password:data)
        if let rangeOfSecondColon = data[startIndex...].firstIndex(of: 0x3A) { // 0x3A is ':'
            let passwordEndIndex = rangeOfSecondColon
            let passwordRange = startIndex..<passwordEndIndex
            
            if let password = String(data: data.subdata(in: passwordRange), encoding: .utf8),
               data.count > passwordEndIndex + 1 {
                let pdfDataRange = (passwordEndIndex + 1)..<data.count
                return (data.subdata(in: pdfDataRange), password)
            }
        }
        
        // No password found, return data after marker
        return (data.subdata(in: startIndex..<data.count), nil)
    }
}

// Helper extension to create PDFPage from CGPDFDocument
extension PDFPage {
    convenience init?(cgPDF: CGPDFDocument, pageNumber: Int) {
        guard let page = cgPDF.page(at: pageNumber) else { return nil }
        self.init()
        
        // This is a workaround to create a PDFPage from a CGPDFPage
        // We're accessing private API here, which might not be reliable
        // For production apps, consider alternative approaches
        
        // Alternative approach: render the page to a graphics context
        let mediaBox = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: mediaBox.size)
        let image = renderer.image { context in
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: mediaBox.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            context.cgContext.drawPDFPage(page)
            context.cgContext.restoreGState()
        }
        
        // Create PDF representation from the image
        if let data = image.pngData(),
           let provider = CGDataProvider(data: data as CFData),
           let cgImage = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent),
           let tempPage = PDFPage(image: UIImage(cgImage: cgImage)) {
            
            // Copy properties from temp page
            self.setBounds(tempPage.bounds(for: .mediaBox), for: .mediaBox)
            self.setBounds(tempPage.bounds(for: .cropBox), for: .cropBox)
            self.setBounds(tempPage.bounds(for: .bleedBox), for: .bleedBox)
            self.setBounds(tempPage.bounds(for: .trimBox), for: .trimBox)
            self.setBounds(tempPage.bounds(for: .artBox), for: .artBox)
            
            return
        }
        
        return nil
    }
} 