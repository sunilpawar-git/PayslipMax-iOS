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
                            // Start async parsing with progress updates
                            progressService.startParsing(image: cropped, processor: imageProcessor)
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
