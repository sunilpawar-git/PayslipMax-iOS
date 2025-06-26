import SwiftUI

// MARK: - Premium Tab Selection View

struct PremiumTabSelectionView: View {
    @Binding var selectedTab: InsightsTab
    @ObservedObject var subscriptionManager: SubscriptionManager
    let showPaywall: Binding<Bool>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightsTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        icon: tab.icon,
                        isSelected: selectedTab == tab,
                        requiresPremium: tab != .overview && !subscriptionManager.isPremiumUser
                    ) {
                        if tab == .overview || subscriptionManager.isPremiumUser {
                            selectedTab = tab
                        } else {
                            showPaywall.wrappedValue = true
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let requiresPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if requiresPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? FintechColors.primaryBlue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.clear : FintechColors.divider, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : FintechColors.textSecondary)
        }
    }
}

// MARK: - Insights Tab

enum InsightsTab: String, CaseIterable {
    case overview = "Overview"
    case health = "Health Score"
    case predictions = "Predictions"
    case recommendations = "Recommendations"
    case benchmarks = "Benchmarks"
    case goals = "Goals"
    
    var icon: String {
        switch self {
        case .overview: return "chart.line.uptrend.xyaxis"
        case .health: return "heart.circle"
        case .predictions: return "crystal.ball"
        case .recommendations: return "lightbulb"
        case .benchmarks: return "chart.bar.xaxis"
        case .goals: return "target"
        }
    }
} 