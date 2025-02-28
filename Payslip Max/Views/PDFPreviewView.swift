import SwiftUI
import PDFKit

/// View for displaying PDF documents
struct PDFPreviewView: View {
    /// The PDF document to display
    let document: PDFDocument
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    var body: some View {
        PDFKitView(document: document)
            .navigationTitle("PDF Preview")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // In a real implementation, this would share the PDF
                        print("Share PDF")
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        router.dismissSheet()
                    } label: {
                        Text("Close")
                    }
                }
            }
    }
}

/// SwiftUI wrapper for PDFView
struct PDFKitView: UIViewRepresentable {
    /// The PDF document to display
    let document: PDFDocument
    
    /// Creates the PDF view
    /// - Parameter context: The context
    /// - Returns: A configured PDF view
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    /// Updates the PDF view
    /// - Parameters:
    ///   - uiView: The PDF view to update
    ///   - context: The context
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

#if os(macOS)
/// SwiftUI wrapper for PDFView on macOS
struct PDFKitView: NSViewRepresentable {
    /// The PDF document to display
    let document: PDFDocument
    
    /// Creates the PDF view
    /// - Parameter context: The context
    /// - Returns: A configured PDF view
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    /// Updates the PDF view
    /// - Parameters:
    ///   - nsView: The PDF view to update
    ///   - context: The context
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}
#endif

#Preview {
    // Create a sample PDF document for preview
    let samplePDF = PDFDocument()
    let page = PDFPage()
    
    return NavigationStack {
        PDFPreviewView(document: samplePDF)
            .environmentObject(NavRouter())
    }
} 