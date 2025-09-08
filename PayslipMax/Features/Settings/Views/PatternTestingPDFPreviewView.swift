import SwiftUI
import PDFKit

/// View component for PDF document preview and selection in pattern testing
struct PatternTestingPDFPreviewView: View {
    // MARK: - Properties

    @Binding var documentURL: URL?
    @Binding var showingDocumentPicker: Bool
    @Binding var pdfPreviewHeight: CGFloat

    let pdfDocument: PDFDocument?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerSection

            if let _ = documentURL, pdfDocument != nil {
                documentPreviewSection
            } else {
                documentPickerSection
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            Text("Test Document")
                .font(.headline)

            Spacer()

            if documentURL != nil {
                Button {
                    showingDocumentPicker = true
                } label: {
                    Text("Change")
                        .font(.caption)
                }
            }
        }
    }

    private var documentPreviewSection: some View {
        VStack {
            if let pdfDocument = pdfDocument {
                TestingPDFKitView(document: pdfDocument)
                    .frame(height: pdfPreviewHeight)
            }

            HStack {
                if let documentURL = documentURL {
                    Text(documentURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Slider(value: $pdfPreviewHeight, in: 200...600, step: 50)
                    .frame(width: 100)
            }
        }
    }

    private var documentPickerSection: some View {
        Button {
            showingDocumentPicker = true
        } label: {
            VStack {
                Image(systemName: "doc.text.viewfinder")
                    .font(.largeTitle)
                    .padding()

                Text("Select PDF Document")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

/// PDF view wrapper for SwiftUI
struct TestingPDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

/// Preview provider for PatternTestingPDFPreviewView
struct PatternTestingPDFPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        @State var documentURL: URL? = nil
        @State var showingPicker = false
        @State var previewHeight: CGFloat = 300

        // Create a sample PDF document for preview
        let pdfDocument = PDFDocument()

        return PatternTestingPDFPreviewView(
            documentURL: $documentURL,
            showingDocumentPicker: $showingPicker,
            pdfPreviewHeight: $previewHeight,
            pdfDocument: pdfDocument
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
