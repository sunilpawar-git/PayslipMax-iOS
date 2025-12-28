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
    let onRetry: (() -> Void)?

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
                    .accessibilityLabel(accessibilityLabel)

                // Progress bar
                if state.isActive {
                    ProgressView(value: state.progressPercent)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                        .accessibilityValue("\(Int(state.progressPercent * 100)) percent complete")
                }

                // Action buttons
                if case .completed = state {
                    Button("View Payslip") {
                        onDismiss?()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Opens the parsed payslip details")
                } else if case .failed = state {
                    HStack(spacing: 12) {
                        if onRetry != nil {
                            Button("Retry") {
                                onRetry?()
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityHint("Attempts to parse the payslip again")
                        }

                        Button("Dismiss") {
                            onDismiss?()
                        }
                        .buttonStyle(.bordered)
                        .accessibilityHint("Closes the error message")
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: 300)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("parsing_progress_overlay")
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

    // MARK: - Accessibility

    /// Comprehensive accessibility label for VoiceOver
    private var accessibilityLabel: String {
        switch state {
        case .idle:
            return "Idle"
        case .preparing:
            return "Preparing payslip for analysis"
        case .extracting:
            return "Analyzing payslip with artificial intelligence"
        case .validating:
            return "Validating extracted data"
        case .verifying:
            return "Verifying accuracy of extracted information"
        case .saving:
            return "Saving payslip to your library"
        case .completed:
            return "Payslip parsing complete. Ready to view."
        case .failed(let error):
            return "Payslip parsing failed. Error: \(error)"
        }
    }
}

// MARK: - Previews

#if DEBUG
struct ParsingProgressOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ParsingProgressOverlay(state: .preparing, onDismiss: nil, onRetry: nil)
                .previewDisplayName("Preparing")

            ParsingProgressOverlay(state: .extracting, onDismiss: nil, onRetry: nil)
                .previewDisplayName("Extracting")

            ParsingProgressOverlay(state: .validating, onDismiss: nil, onRetry: nil)
                .previewDisplayName("Validating")

            ParsingProgressOverlay(state: .verifying, onDismiss: nil, onRetry: nil)
                .previewDisplayName("Verifying")

            ParsingProgressOverlay(state: .completed(PayslipItem.previewItem()), onDismiss: {}, onRetry: nil)
                .previewDisplayName("Completed")

            ParsingProgressOverlay(state: .failed("Network error"), onDismiss: {}, onRetry: {})
                .previewDisplayName("Failed with Retry")
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
