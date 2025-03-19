import SwiftUI
import PDFKit

/// An enhanced PDF viewer that can better handle password-protected PDFs
struct EnhancedPDFView: UIViewRepresentable {
    var pdfData: Data
    var password: String?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        updatePDFDocument(in: pdfView)
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        updatePDFDocument(in: pdfView)
    }
    
    private func updatePDFDocument(in pdfView: PDFView) {
        // First check if our data is in the special password-wrapped format
        if checkForAndHandleSpecialFormat(in: pdfView) {
            return
        }
        
        // Regular PDF data handling
        if handleStandardPDF(in: pdfView) {
            return
        }
        
        // Last resort - render a message that this PDF couldn't be displayed
        print("EnhancedPDFView: Unable to render PDF with any method")
        let label = UILabel()
        label.text = "Unable to render this PDF. The file may be corrupted or use unsupported encryption."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .systemRed
        pdfView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: pdfView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor, constant: -20)
        ])
    }
    
    private func checkForAndHandleSpecialFormat(in pdfView: PDFView) -> Bool {
        // Check for PWDPDF format (original format)
        let pwdMarker = "PWDPDF:"
        if let pwdMarkerData = pwdMarker.data(using: .utf8),
           pdfData.starts(with: pwdMarkerData) {
            
            print("EnhancedPDFView: Detected wrapped password format (PWDPDF)")
            let (rawData, extractedPassword) = extractDataAndPassword(
                from: pdfData, 
                marker: pwdMarkerData
            )
            
            let passwordToUse = password ?? extractedPassword ?? ""
            return tryToDisplayPDF(data: rawData, password: passwordToUse, in: pdfView)
        }
        
        // Check for MILPDF format (military PDF format)
        let milMarker = "MILPDF:"
        if let milMarkerData = milMarker.data(using: .utf8),
           pdfData.starts(with: milMarkerData) {
            
            print("EnhancedPDFView: Detected military PDF format (MILPDF)")
            let (rawData, extractedPassword) = extractDataAndPassword(
                from: pdfData, 
                marker: milMarkerData
            )
            
            let passwordToUse = password ?? extractedPassword ?? ""
            
            // Use our most aggressive display method for military PDFs
            return tryToDisplayMilitaryPDF(data: rawData, password: passwordToUse, in: pdfView)
        }
        
        return false
    }
    
    private func extractDataAndPassword(from data: Data, marker markerData: Data) -> (Data, String?) {
        let markerSize = markerData.count
        let sizeBytes = data.subdata(in: markerSize..<(markerSize + 4))
        
        let passwordSize = sizeBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        let passwordStart = markerSize + 4
        let passwordEnd = passwordStart + Int(passwordSize)
        let pdfDataStart = passwordEnd
        
        let extractedPasswordData = data.subdata(in: passwordStart..<passwordEnd)
        let extractedPassword = String(data: extractedPasswordData, encoding: .utf8)
        let rawPDFData = data.subdata(in: pdfDataStart..<data.count)
        
        print("EnhancedPDFView: Extracted password: \(extractedPassword?.prefix(1) ?? "")*** and PDF data size: \(rawPDFData.count)")
        
        return (rawPDFData, extractedPassword)
    }
    
    private func handleStandardPDF(in pdfView: PDFView) -> Bool {
        // Try standard PDFKit approach
        if let document = PDFDocument(data: pdfData) {
            if document.isLocked && password != nil {
                let unlockSuccess = document.unlock(withPassword: password!)
                print("EnhancedPDFView: Standard PDF unlock attempt result: \(unlockSuccess)")
            }
            pdfView.document = document
            return true
        }
        
        // If we have a password, try the direct CG approach
        if let password = password {
            if tryToDisplayPDFWithCG(data: pdfData, password: password, in: pdfView) {
                return true
            }
        }
        
        return false
    }
    
    private func tryToDisplayPDF(data: Data, password: String, in pdfView: PDFView) -> Bool {
        // Try standard PDFKit approach first
        if let document = PDFDocument(data: data) {
            if document.isLocked {
                let unlockSuccess = document.unlock(withPassword: password)
                print("EnhancedPDFView: PDF unlock attempt result: \(unlockSuccess)")
            }
            pdfView.document = document
            return true
        }
        
        // Try CG approach as fallback
        return tryToDisplayPDFWithCG(data: data, password: password, in: pdfView)
    }
    
    private func tryToDisplayMilitaryPDF(data: Data, password: String, in pdfView: PDFView) -> Bool {
        // For military PDFs, try multiple approaches
        
        // First try with PDFKit
        if let document = PDFDocument(data: data) {
            if document.isLocked {
                let unlockSuccess = document.unlock(withPassword: password)
                print("EnhancedPDFView: Military PDF unlock attempt with PDFKit: \(unlockSuccess)")
                if unlockSuccess {
                    pdfView.document = document
                    return true
                }
            } else {
                pdfView.document = document
                return true
            }
        }
        
        // Try with CoreGraphics if PDFKit fails
        return tryToDisplayPDFWithCG(data: data, password: password, in: pdfView)
    }
    
    private func tryToDisplayPDFWithCG(data: Data, password: String, in pdfView: PDFView) -> Bool {
        print("EnhancedPDFView: Attempting to display with CoreGraphics")
        if let provider = CGDataProvider(data: data as CFData),
            let cgPDF = CGPDFDocument(provider) {
            
            if cgPDF.isEncrypted {
                let _ = cgPDF.unlockWithPassword(password)
            }
            
            if cgPDF.numberOfPages > 0 {
                let document = PDFDocument()
                for i in 1...cgPDF.numberOfPages {
                    if let _ = cgPDF.page(at: i),
                       let pdfPage = PDFPage(cgPDF: cgPDF, pageNumber: i) {
                        document.insert(pdfPage, at: document.pageCount)
                    }
                }
                
                if document.pageCount > 0 {
                    pdfView.document = document
                    return true
                }
            }
        }
        
        return false
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