//
//  ParsingProgressOverlay.swift
//  PayslipMax
//
//  In-app progress indicator for async payslip parsing
//

import SwiftUI

/// Full-screen overlay showing parsing progress
struct ParsingProgressOverlay: View {
    let state: ParsingProgressState
    let onDismiss: (() -> Void)?

    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal while parsing
                }

            // Progress card
            VStack(spacing: 24) {
                // Progress indicator
                progressIndicator

                // Status message
                Text(state.progressMessage)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Progress bar
                if state.isActive {
                    ProgressView(value: state.progressPercent)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                }

                // Action buttons
                if case .completed = state {
                    Button("View Payslip") {
                        onDismiss?()
                    }
                    .buttonStyle(.borderedProminent)
                } else if case .failed = state {
                    Button("Dismiss") {
                        onDismiss?()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 300)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: state)
    }

    @ViewBuilder
    private var progressIndicator: some View {
        switch state {
        case .idle:
            EmptyView()

        case .preparing, .extracting, .validating, .verifying, .saving:
            // Animated spinner
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: rotationAngle))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }

                // Icon overlay
                iconForState
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

        case .completed:
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 60, height: 60)

                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
            .transition(.scale.combined(with: .opacity))

        case .failed:
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)

                Image(systemName: "xmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var iconForState: some View {
        switch state {
        case .preparing:
            Image(systemName: "gearshape")
        case .extracting:
            Image(systemName: "doc.text.magnifyingglass")
        case .validating:
            Image(systemName: "checkmark.shield")
        case .verifying:
            Image(systemName: "checkmark.circle")
        case .saving:
            Image(systemName: "square.and.arrow.down")
        default:
            EmptyView()
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ParsingProgressOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ParsingProgressOverlay(state: .preparing, onDismiss: nil)
                .previewDisplayName("Preparing")

            ParsingProgressOverlay(state: .extracting, onDismiss: nil)
                .previewDisplayName("Extracting")

            ParsingProgressOverlay(state: .validating, onDismiss: nil)
                .previewDisplayName("Validating")

            ParsingProgressOverlay(state: .verifying, onDismiss: nil)
                .previewDisplayName("Verifying")

            ParsingProgressOverlay(state: .completed(PayslipItem.previewItem()), onDismiss: {})
                .previewDisplayName("Completed")

            ParsingProgressOverlay(state: .failed("Network error"), onDismiss: {})
                .previewDisplayName("Failed")
        }
    }
}

private extension PayslipItem {
    static func previewItem() -> PayslipItem {
        PayslipItem(
            month: "AUGUST",
            year: 2025,
            credits: 86953,
            debits: 28701,
            dsop: 2220,
            tax: 15585,
            earnings: ["BPAY": 37000, "DA": 24200],
            deductions: ["DSOP": 2220, "ITAX": 15585],
            source: "LLM Vision"
        )
    }
}
#endif
