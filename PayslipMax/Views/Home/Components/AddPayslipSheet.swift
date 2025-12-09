import SwiftUI
import UIKit

struct AddPayslipSheet: View {
    @Binding var isPresented: Bool
    let pdfManager: PDFUploadManager
    private let imageProcessor = ImageImportProcessor.makeDefault()

    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    SelectPDFButton(pdfManager: pdfManager)
                    ScanDocumentButton {
                        showingScanner = true
                    }
                    PhotoPickerButton {
                        showingPhotoPicker = true
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle("Add Payslip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                }

                if isProcessing {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView("Processing payslip...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            PayslipScannerView {
                showingScanner = false
                isPresented = false
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                processImage(image)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
}

// MARK: - Subviews
private struct SelectPDFButton: View {
    let pdfManager: PDFUploadManager

    var body: some View {
        Button {
            pdfManager.showPicker()
        } label: {
            HStack {
                Image(systemName: "doc.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Select PDF")
                        .font(.headline)
                    Text("Choose from Files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

private struct ScanDocumentButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Scan Document")
                        .font(.headline)
                    Text("Use Camera")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

private struct PhotoPickerButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack {
                Image(systemName: "photo")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Choose from Photos")
                        .font(.headline)
                    Text("Import payslip image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

// MARK: - Helpers
private extension AddPayslipSheet {
    func processImage(_ image: UIImage) {
        isProcessing = true
        Task {
            let result = await imageProcessor.process(image: image)
            await MainActor.run {
                isProcessing = false
                switch result {
                case .success:
                    showingPhotoPicker = false
                    isPresented = false
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
