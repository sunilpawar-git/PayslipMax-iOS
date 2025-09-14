import SwiftUI

/// Time range picker component for InsightsView
struct InsightsTimeRangePicker: View {
    @Binding var selectedTimeRange: FinancialTimeRange

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights Period")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)

                    Text("Controls all data displayed in the insights view")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Spacer()

                // Selected range indicator
                HStack(spacing: 4) {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(FintechColors.primaryBlue)
                        .font(.caption)

                    Text(selectedTimeRange.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.primaryBlue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    FintechColors.primaryBlue.opacity(0.1)
                        .clipShape(Capsule())
                )
            }

            // Time range picker - Full width segmented control
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(FinancialTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity, minHeight: 44) // Full width with increased height for better touch targets
            .padding(.vertical, 4) // Additional padding for prominence
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FintechColors.cardBackground)
        )
    }
}

