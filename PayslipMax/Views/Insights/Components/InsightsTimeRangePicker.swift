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
                    
                    Text("Controls all data displayed below")
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
            
            // Time range options
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(FinancialTimeRange.allCases, id: \.self) { range in
                    TimeRangeButton(
                        range: range,
                        isSelected: selectedTimeRange == range,
                        action: { selectedTimeRange = range }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FintechColors.cardBackground)
        )
    }
}

/// Individual time range button
private struct TimeRangeButton: View {
    let range: FinancialTimeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(range.shortName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? FintechColors.primaryBlue : FintechColors.textSecondary)
                
                Text(range.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? FintechColors.primaryBlue.opacity(0.8) : FintechColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? FintechColors.primaryBlue.opacity(0.1) : FintechColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? FintechColors.primaryBlue : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions

extension FinancialTimeRange {
    var shortName: String {
        switch self {
        case .last3Months:
            return "3M"
        case .last6Months:
            return "6M"
        case .lastYear:
            return "1Y"
        case .all:
            return "ALL"
        }
    }
    
    var description: String {
        switch self {
        case .last3Months:
            return "Last 3 Months"
        case .last6Months:
            return "Last 6 Months"
        case .lastYear:
            return "Last Year"
        case .all:
            return "Complete history"
        }
    }
}
