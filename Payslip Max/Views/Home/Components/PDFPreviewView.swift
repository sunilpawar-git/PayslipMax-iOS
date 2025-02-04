import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let document: PDFDocument
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (() -> Void)?
    
    var body: some View {
        NavigationView {
            PDFKitView(document: document)
                .navigationTitle("Preview PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    if let onConfirm = onConfirm {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Confirm") {
                                onConfirm()
                                dismiss()
                            }
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
} 