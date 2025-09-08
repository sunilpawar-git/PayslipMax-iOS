import SwiftUI

/// Helper views for quiz-related UI components
/// Extracted from HomeQuizSection to maintain file size limits and improve reusability
// Note: FintechColors import may be implicit through project structure
enum QuizHelperViews {

    static func scoringRuleRow(_ title: String, _ points: String, _ description: String, _ color: Color, _ iconName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(points)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    static func progressInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    static func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(FintechColors.primaryBlue)
                .fontWeight(.bold)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
