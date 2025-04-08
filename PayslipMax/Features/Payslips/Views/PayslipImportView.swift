import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PayslipImportView: View {
    @StateObject private var coordinator: PayslipImportCoordinator
    @State private var isShowingDocumentPicker = false
    @State private var isShowingScanner = false
    
    init(parsingCoordinator: PDFParsingCoordinator) {
        _coordinator = StateObject(wrappedValue: PayslipImportCoordinator(parsingCoordinator: parsingCoordinator))
    }
    
    var body: some View {
        VStack {
            if coordinator.isLoading {
                ProgressView("Processing payslip...")
                    .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Import Payslip")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Choose a method to import your payslip")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        isShowingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Select PDF")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan Document")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        coordinator.createEmptyPayslip()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Manual Entry")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack {
                        Text("Premium Feature")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text("AI-powered parsing is available in the paid version")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(types: [UTType.pdf]) { url in
                if let pdfDocument = PDFDocument(url: url) {
                    coordinator.processPDF(pdfDocument)
                } else {
                    coordinator.errorMessage = "Could not open the PDF document."
                    coordinator.showError = true
                }
            }
        }
        .sheet(isPresented: $coordinator.showManualEntry) {
            if let payslip = coordinator.payslip {
                PayslipManualEntryView(payslip: Binding(
                    get: { payslip },
                    set: { coordinator.payslip = $0 }
                ))
            }
        }
        .alert("Error", isPresented: $coordinator.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(coordinator.errorMessage ?? "An unknown error occurred.")
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

#Preview {
    PayslipImportView(parsingCoordinator: PDFParsingCoordinator(abbreviationManager: AbbreviationManager()))
} 