import SwiftUI
import VisionKit
import UIKit

/// Streamlined photo selector that opens gallery immediately.
/// Privacy education shown once for first-time users, then direct gallery access.
struct PayslipScannerView: View {
    @Environment(\.dismiss) private var dismiss

    private let imageProcessor = ImageImportProcessor.makeDefault()
    private let onFinished: (() -> Void)?
    private let onImageCaptured: ((UIImage) -> Void)?

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingPhotoPicker = false
    @State private var showingCropper = false
    @State private var pendingImage: UIImage?
    @State private var showPrivacyEducation = false

    init(onFinished: (() -> Void)? = nil, onImageCaptured: ((UIImage) -> Void)? = nil) {
        self.onFinished = onFinished
        self.onImageCaptured = onImageCaptured
    }

    var body: some View {
        // No intermediate screen - gallery opens immediately
        Color.clear
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showingCropper) {
                if let image = pendingImage {
                    PayslipCropView(
                        image: image,
                        defaultKeepTopRatio: 0.08,
                        defaultKeepBottomRatio: 0.92,
                        onCancel: {
                            showingCropper = false
                            pendingImage = nil
                            showingPhotoPicker = true // Allow re-selection
                        },
                        onCropped: { cropped in
                            showingCropper = false
                            pendingImage = nil
                            isProcessing = true
                            Task {
                                await processCroppedImageWithLLM(cropped)
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                ModernPhotoPickerView(
                    onImageSelected: { image in
                        showingPhotoPicker = false
                        handlePhotoSelected(image)
                    },
                    onCancel: {
                        showingPhotoPicker = false
                        dismiss()
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showPrivacyEducation) {
                PrivacyEducationSheet {
                    showPrivacyEducation = false
                    // Small delay to ensure smooth sheet transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showingPhotoPicker = true
                    }
                }
            }
            .onAppear {
                // First-time users: Show privacy education, then gallery
                // Returning users: Open gallery immediately
                if !UserDefaults.hasSeenPrivacyEducation {
                    showPrivacyEducation = true
                } else {
                    showingPhotoPicker = true
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        ProgressView("Processing payslip...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                }
            }
    }

    // MARK: - Private

    private func handlePhotoSelected(_ image: UIImage) {
        if let onImageCaptured {
            dismiss()
            onImageCaptured(image)
            return
        }

        pendingImage = image
        showingCropper = true
    }

    private func processCroppedImageWithLLM(_ image: UIImage) async {
        // LLM handles format detection automatically - no user hint needed
        imageProcessor.updateUserHint(.auto)
        let result = await imageProcessor.processCroppedImageLLMOnly(image)

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
}
