import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import UIKit

struct PayslipImportView: View {
    @StateObject private var coordinator: PayslipImportCoordinator
    @State private var isShowingDocumentPicker = false
    @State private var isShowingScanner = false
    @State private var isShowingPhotoPicker = false
    @State private var isProcessingImage = false

    private let imageProcessor = ImageImportProcessor.makeDefault()

    private let dataService: DataServiceProtocol

    init(parsingCoordinator: PDFParsingCoordinatorProtocol, abbreviationManager: AbbreviationManager, dataService: DataServiceProtocol? = nil) {
        _coordinator = StateObject(wrappedValue: PayslipImportCoordinator(parsingCoordinator: parsingCoordinator, abbreviationManager: abbreviationManager))
        self.dataService = dataService ?? DIContainer.shared.makeDataService()
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
                        isShowingPhotoPicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Choose from Photos")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
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
            PayslipDocumentPicker(types: [UTType.pdf]) { url in
                if let pdfDocument = PDFDocument(url: url) {
                    coordinator.processPDF(pdfDocument)
                } else {
                    coordinator.errorMessage = "Could not open the PDF document."
                    coordinator.showError = true
                }
            }
        }
        .sheet(isPresented: $coordinator.showManualEntry) {
            if let payslip = coordinator.parsedPayslipItem {
                PayslipManualEntryView(payslip: Binding(
                    get: { payslip },
                    set: { coordinator.parsedPayslipItem = $0 }
                ))
            }
        }
        .sheet(isPresented: $coordinator.showParsingFeedback) {
            if let payslip = coordinator.parsedPayslipItem,
               let pdfDoc = coordinator.sourcePdfDocument {
                let feedbackViewModel = PDFParsingFeedbackViewModel(
                    payslipItem: payslip,
                    pdfDocument: pdfDoc,
                    parsingCoordinator: coordinator.parsingCoordinatorForFeedback,
                    abbreviationManager: coordinator.abbreviationManagerForFeedback,
                    dataService: dataService
                )
                PDFParsingFeedbackView(viewModel: feedbackViewModel)
            } else {
                Text("Preparing feedback...")
            }
        }
        .alert("Error", isPresented: $coordinator.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(coordinator.errorMessage ?? "An unknown error occurred.")
        }
        .fullScreenCover(isPresented: $isShowingScanner) {
            PayslipScannerView {
                isShowingScanner = false
            }
        }
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoPickerView { image in
                processImage(image)
            }
        }
        .overlay {
            if isProcessingImage {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView("Processing payslip...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
}

struct PayslipDocumentPicker: UIViewControllerRepresentable {
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
        let parent: PayslipDocumentPicker

        init(_ parent: PayslipDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

#Preview {
    let abbreviationManager = AbbreviationManager()
    let parsingCoordinator = DIContainer.shared.makePDFParsingCoordinator()
    PayslipImportView(parsingCoordinator: parsingCoordinator, abbreviationManager: abbreviationManager)
}

// MARK: - Helpers
private extension PayslipImportView {
    func processImage(_ image: UIImage) {
        isProcessingImage = true
        Task {
            let result = await imageProcessor.process(image: image)
            await MainActor.run {
                isProcessingImage = false
                switch result {
                case .success:
                    isShowingPhotoPicker = false
                case .failure(let error):
                    coordinator.errorMessage = error.localizedDescription
                    coordinator.showError = true
                }
            }
        }
    }
}
