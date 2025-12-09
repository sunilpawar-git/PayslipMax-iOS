import SwiftUI
import VisionKit
import UIKit

/// Full-screen scanner that routes captured images through the payslip processing pipeline.
struct PayslipScannerView: View {
    @Environment(\.dismiss) private var dismiss

    private let imageProcessor = ImageImportProcessor.makeDefault()
    private let onFinished: (() -> Void)?
    private let onImageCaptured: ((UIImage) -> Void)?

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingPhotoPicker = false
    @State private var userHint: PayslipUserHint = .auto

    init(onFinished: (() -> Void)? = nil, onImageCaptured: ((UIImage) -> Void)? = nil) {
        self.onFinished = onFinished
        self.onImageCaptured = onImageCaptured
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScannerView(onScanCompleted: handleScanCompleted)
                    .overlay(alignment: .top) {
                        hintSelector
                            .padding(.horizontal, 16)
                            .padding(.top, 52)
                    }

                if isProcessing {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    ProgressView("Processing payslip...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }

                bottomBar
            }
            .navigationTitle("Scan Payslip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView { image in
                    showingPhotoPicker = false
                    handleScanCompleted(image)
                }
            }
        }
    }

    // MARK: - Private

    private func handleScanCompleted(_ image: UIImage) {
        if let onImageCaptured {
            dismiss()
            onImageCaptured(image)
            return
        }

        isProcessing = true
        Task {
            await processScannedImage(image)
        }
    }

    private func processScannedImage(_ image: UIImage) async {
        imageProcessor.updateUserHint(userHint)
        let result = await imageProcessor.process(image: image)

        switch result {
        case .success:
            await MainActor.run {
                isProcessing = false
                onFinished?()
                dismiss()
            }
        case .failure(let error):
            await handleError(error.localizedDescription)
        }
    }

    private func handleError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
            isProcessing = false
        }
    }

    // MARK: - UI

    private var hintSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parsing preference")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Picker("Parsing preference", selection: $userHint) {
                Text("Auto").tag(PayslipUserHint.auto)
                Text("Officer").tag(PayslipUserHint.officer)
                Text("JCO/OR").tag(PayslipUserHint.jcoOr)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("payslip_hint_picker")
        }
    }

    private var bottomBar: some View {
        VStack {
            Spacer()
            HStack {
                galleryButton
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .allowsHitTesting(!isProcessing)
    }

    private var galleryButton: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            Image(systemName: "photo.on.rectangle")
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .accessibilityIdentifier("scanner_photo_picker_button")
    }
}
