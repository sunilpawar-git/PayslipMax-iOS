import SwiftUI
import VisionKit
import UIKit

/// Full-screen photo selector that routes captured images through the payslip processing pipeline.
/// Uses WhatsApp-style gallery-first approach with privacy education.
struct PayslipScannerView: View {
    @Environment(\.dismiss) private var dismiss

    private let imageProcessor = ImageImportProcessor.makeDefault()
    private let onFinished: (() -> Void)?
    private let onImageCaptured: ((UIImage) -> Void)?

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingPhotoPicker = true // Show gallery-first
    @State private var showingCropper = false
    @State private var pendingImage: UIImage?
    @State private var userHint: PayslipUserHint = .auto
    @State private var showPrivacyEducation = false

    init(onFinished: (() -> Void)? = nil, onImageCaptured: ((UIImage) -> Void)? = nil) {
        self.onFinished = onFinished
        self.onImageCaptured = onImageCaptured
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Privacy tip banner for returning users
                    if UserDefaults.hasSeenPrivacyEducation {
                        privacyTipBanner
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Hint selector
                    hintSelector
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Spacer()

                    // Instructions
                    instructionsView

                    Spacer()
                }

                if isProcessing {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    ProgressView("Processing payslip...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Select Payslip Photo")
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
                    showingPhotoPicker = true
                }
            }
            .onAppear {
                // Show privacy education for first-time users
                if !UserDefaults.hasSeenPrivacyEducation {
                    showPrivacyEducation = true
                    showingPhotoPicker = false
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
        imageProcessor.updateUserHint(userHint)
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

    // MARK: - UI Components

    private var privacyTipBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.footnote)

            Text("Next: Crop personal info before AI scan")
                .font(.footnote)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

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

    private var instructionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Select a payslip photo from your gallery")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("You'll crop out sensitive info in the next step")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
    }
}
