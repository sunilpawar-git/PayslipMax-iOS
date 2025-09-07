import SwiftUI

/// Integration view that adds gamification elements to the Insights screen
/// Core view following MVVM architecture with extracted components for maintainability
/// Maintains <300 line rule through component-based architecture
struct GamificationIntegrationView: View {

    // Import component files for access to extracted components
    // This approach maintains clean separation while avoiding module complexity

    @StateObject private var quizViewModel: QuizViewModel
    @State private var showQuizSheet = false
    @State private var showAchievementsSheet = false

    // MARK: - Initialization

    init(quizViewModel: QuizViewModel) {
        self._quizViewModel = StateObject(wrappedValue: quizViewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Gamification Header Component
            GamificationHeader(
                userProgress: quizViewModel.userProgress,
                unlockedAchievementsCount: quizViewModel.getUnlockedAchievements().count,
                onAchievementsTap: { showAchievementsSheet = true }
            )

            // Quick Quiz Card Component
            QuickQuizCard(
                userProgress: quizViewModel.userProgress,
                onQuickQuizTap: { showQuizSheet = true },
                onChallengeTap: handleChallengeTap
            )

            // Achievement Showcase Component
            AchievementShowcase(
                unlockedAchievements: quizViewModel.getUnlockedAchievements(),
                lockedAchievements: quizViewModel.getLockedAchievements(),
                onViewAllTap: { showAchievementsSheet = true },
                achievementProgressGetter: quizViewModel.getAchievementProgress
            )
        }
        .padding(.horizontal)
        .sheet(isPresented: $showQuizSheet) {
            quizSheetContent
        }
        .sheet(isPresented: $showAchievementsSheet) {
            achievementsSheetContent
        }
    }

    // MARK: - Private Methods

    private func handleChallengeTap() {
        Task {
            await quizViewModel.startQuiz(
                questionCount: 10,
                difficulty: .hard,
                focusArea: nil
            )
            showQuizSheet = true
        }
    }

    // MARK: - Sheet Content

    private var quizSheetContent: some View {
        NavigationView {
            QuizView(viewModel: quizViewModel)
                .navigationTitle("Quiz")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showQuizSheet = false
                        }
                    }
                }
        }
    }

    private var achievementsSheetContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Simple progress summary for now
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("\(quizViewModel.userProgress.level)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Level")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        VStack(spacing: 4) {
                            Text("\(quizViewModel.userProgress.totalPoints)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                }

                // Simple achievements list
                List {
                    Section("Unlocked") {
                        let unlockedAchievements = quizViewModel.getUnlockedAchievements()
                        if unlockedAchievements.isEmpty {
                            Text("No achievements unlocked yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(unlockedAchievements) { achievement in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(achievement.badgeColor.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: achievement.iconName)
                                            .foregroundColor(achievement.badgeColor)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(achievement.title)
                                            .font(.headline)
                                        Text(achievement.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Text("+\(achievement.pointsReward)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(FintechColors.premiumGold)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section("In Progress") {
                        let lockedAchievements = quizViewModel.getLockedAchievements()
                        if lockedAchievements.isEmpty {
                            Text("All achievements unlocked!")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(lockedAchievements) { achievement in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: achievement.iconName)
                                            .foregroundColor(.gray)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(achievement.title)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text(achievement.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        Text("Progress: \(Int(quizViewModel.getAchievementProgress(achievement)))%")
                                            .font(.caption)
                                            .foregroundColor(achievement.badgeColor)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAchievementsSheet = false
                    }
                }
            }
        }
    }
} 