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

    @ObservedObject private var progressService = PayslipParsingProgressService.shared
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingPhotoPicker = false
    @State private var showingCropper = false
    @State private var pendingImage: UIImage?
    @State private var showPrivacyEducation = false
    @State private var originalImageIdentifier: UUID?

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
                            // Save cropped image
                            if let imageID = originalImageIdentifier {
                                do {
                                    let imageManager = ImageManager.shared
                                    let croppedURL = try imageManager.saveImage(
                                        image: cropped,
                                        identifier: imageID.uuidString,
                                        suffix: "-cropped"
                                    )
                                    Logger.info("Saved cropped image to: \(croppedURL.path)", category: "PayslipScanner")
                                } catch {
                                    Logger.error("Failed to save cropped image: \(error)", category: "PayslipScanner")
                                }
                            }

                            showingCropper = false
                            let originalImage = pendingImage
                            pendingImage = nil

                            // Start async parsing with BOTH original and cropped images
                            if let original = originalImage {
                                progressService.startParsing(
                                    originalImage: original,
                                    croppedImage: cropped,
                                    imageIdentifier: originalImageIdentifier,
                                    processor: imageProcessor
                                )
                            } else {
                                // Fallback to cropped-only if original is somehow nil
                                progressService.startParsing(image: cropped, processor: imageProcessor)
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
                if progressService.state.isActive {
                    ParsingProgressOverlay(
                        state: progressService.state,
                        onDismiss: {
                            // User clicked "View Payslip" or "Dismiss"
                            progressService.reset()
                            onFinished?()
                            dismiss()
                        },
                        onRetry: {
                            // User clicked "Retry"
                            progressService.retry()
                        }
                    )
                }
            }
            .onChange(of: progressService.state) { oldState, newState in
                // Auto-dismiss on completion with smooth transition
                if case .completed = newState {
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s to show success
                        if case .completed = progressService.state {
                            // Animated transition to Payslips tab
                            await animateToPayslipsTab()
                            onFinished?()
                            dismiss()
                        }
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

        // Generate unique identifier for this scan
        let imageID = UUID()
        originalImageIdentifier = imageID

        // Save original image BEFORE cropping
        do {
            let imageManager = ImageManager.shared
            let originalURL = try imageManager.saveImage(
                image: image,
                identifier: imageID.uuidString,
                suffix: "-original"
            )
            Logger.info("Saved original image to: \(originalURL.path)", category: "PayslipScanner")
        } catch {
            Logger.error("Failed to save original image: \(error)", category: "PayslipScanner")
        }

        // Continue to cropper
        pendingImage = image
        showingCropper = true
    }

    @MainActor
    private func animateToPayslipsTab() async {
        // Animate tab transition to Payslips (tab index 1)
        withAnimation(.easeInOut(duration: 0.4)) {
            TabTransitionCoordinator.shared.selectedTab = 1
        }
    }
}
