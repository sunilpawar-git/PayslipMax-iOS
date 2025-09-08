import SwiftUI

// MARK: - Success Animation View

struct BackupSuccessView: View {
    let title: String
    let subtitle: String
    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(FintechColors.successGreen.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(FintechColors.successGreen)
                    .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCheckmark)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.easeInOut.delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Progress Indicator

struct BackupProgressView: View {
    let title: String
    let progress: Double
    let subtitle: String?

    var body: some View {
        VStack(spacing: 16) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(FintechColors.primaryBlue.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(FintechColors.primaryBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
        }
    }
}
