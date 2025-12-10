import SwiftUI
import UIKit

/// Lightweight cropper to let the user trim PII (top band) before LLM.
struct PayslipCropView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let defaultKeepTopRatio: CGFloat
    let defaultKeepBottomRatio: CGFloat
    let onCancel: () -> Void
    let onCropped: (UIImage) -> Void

    @State private var keepTop: CGFloat
    @State private var keepBottom: CGFloat

    init(
        image: UIImage,
        defaultKeepTopRatio: CGFloat = 0.1,
        defaultKeepBottomRatio: CGFloat = 0.9,
        onCancel: @escaping () -> Void,
        onCropped: @escaping (UIImage) -> Void
    ) {
        self.image = image
        self.defaultKeepTopRatio = defaultKeepTopRatio
        self.defaultKeepBottomRatio = defaultKeepBottomRatio
        self.onCancel = onCancel
        self.onCropped = onCropped
        _keepTop = State(initialValue: min(max(defaultKeepTopRatio, 0.0), 0.9))
        _keepBottom = State(initialValue: min(max(defaultKeepBottomRatio, 0.1), 1.0))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Select the area to keep")
                    .font(.headline)
                    .padding(.top, 8)

                GeometryReader { proxy in
                    ZStack(alignment: .top) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()

                        let keepTopY = proxy.size.height * keepTop
                        let keepBottomY = proxy.size.height * keepBottom
                        let keepHeight = max(keepBottomY - keepTopY, 1)

                        // Shade outside keep area
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.black.opacity(0.35))
                                .frame(height: keepTopY)
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .background(Color.clear)
                                .frame(height: keepHeight)
                            Rectangle()
                                .fill(Color.black.opacity(0.35))
                                .frame(maxHeight: .infinity)
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text("Keep area top: \(Int(keepTop * 100))% of page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Slider(value: $keepTop, in: 0.0...0.9, step: 0.005, onEditingChanged: { _ in
                        enforceMinimumKeep()
                    })
                    .accessibilityIdentifier("payslip_keep_top_slider")

                    Text("Keep area bottom: \(Int(keepBottom * 100))% of page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Slider(value: $keepBottom, in: 0.1...1.0, step: 0.005, onEditingChanged: { _ in
                        enforceMinimumKeep()
                    })
                    .accessibilityIdentifier("payslip_keep_bottom_slider")
                }
                .padding(.horizontal)

                HStack {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)

                    Button("Use Crop") {
                        let cropped = cropRegion(image: image, topRatio: keepTop, bottomRatio: keepBottom)
                        dismiss()
                        onCropped(cropped)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("payslip_crop_confirm")
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .padding(.horizontal)
            .navigationTitle("Crop Payslip")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    /// Keeps the middle band between top and bottom removals.
    private func cropRegion(image: UIImage, topRatio: CGFloat, bottomRatio: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let clampedTop = min(max(topRatio, 0.0), 0.95)
        let clampedBottom = min(max(bottomRatio, 0.05), 1.0)

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let removeTop = height * clampedTop
        let removeBottom = height * clampedBottom
        let remainingHeight = height - removeTop - removeBottom

        if remainingHeight <= 10 {
            return image
        }
        let rect = CGRect(x: 0, y: removeTop, width: width, height: remainingHeight)

        if let cropped = cgImage.cropping(to: rect) {
            return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }

    /// Ensure keep window has a minimum height and ordered edges.
    private func enforceMinimumKeep() {
        let minGap: CGFloat = 0.15
        if keepBottom - keepTop < minGap {
            keepBottom = min(1.0, keepTop + minGap)
        }
        if keepTop > keepBottom - minGap {
            keepTop = max(0.0, keepBottom - minGap)
        }
    }
}
