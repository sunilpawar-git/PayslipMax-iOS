import SwiftUI

/// Component views for the GamificationIntegrationView
/// Extracted to maintain 300-line architectural constraint
/// Contains core UI components while maintaining MVVM separation

// MARK: - Header Components

struct GamificationHeader: View {
    let userProgress: UserGamificationProgress
    let unlockedAchievementsCount: Int
    let onAchievementsTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Progress")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Level \(userProgress.level) • \(userProgress.totalPoints) pts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onAchievementsTap) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(FintechColors.premiumGold)

                    Text("\(unlockedAchievementsCount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.premiumGold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(FintechColors.premiumGold.opacity(0.15))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Quiz Components

struct QuickQuizCard: View {
    let userProgress: UserGamificationProgress
    let onQuickQuizTap: () -> Void
    let onChallengeTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(FintechColors.primaryBlue)

                        Text("Test Your Knowledge")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Text("Answer questions about your payslip data and earn stars!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 4) {
                    if userProgress.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(userProgress.currentStreak)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }

                    Text("\(Int(userProgress.accuracyPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button("Quick Quiz") { onQuickQuizTap() }
                    .buttonStyle(CompactPrimaryButtonStyle())

                Button("Challenge") { onChallengeTap() }
                    .buttonStyle(CompactSecondaryButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Achievement Components

struct AchievementShowcase: View {
    let unlockedAchievements: [Achievement]
    let lockedAchievements: [Achievement]
    let onViewAllTap: () -> Void
    let achievementProgressGetter: (Achievement) -> Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("View All") { onViewAllTap() }
                    .font(.subheadline)
                    .foregroundColor(FintechColors.primaryBlue)
            }

            if unlockedAchievements.isEmpty && lockedAchievements.isEmpty {
                EmptyAchievementsView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(unlockedAchievements.prefix(3)) { achievement in
                            AchievementBadgeView(
                                achievement: achievement,
                                isUnlocked: true,
                                progress: 100.0
                            )
                        }

                        ForEach(lockedAchievements.prefix(2)) { achievement in
                            AchievementBadgeView(
                                achievement: achievement,
                                isUnlocked: false,
                                progress: achievementProgressGetter(achievement)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.badgeColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? achievement.badgeColor : .gray)

                if !isUnlocked {
                    Circle()
                        .trim(from: 0, to: progress / 100)
                        .stroke(achievement.badgeColor, lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                }
            }

            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)

                if !isUnlocked {
                    Text("\(Int(progress))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 70)
    }
}

struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle")
                .font(.title)
                .foregroundColor(.gray)

            Text("No achievements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Take a quiz to start earning badges!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}