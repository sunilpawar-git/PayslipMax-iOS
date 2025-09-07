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
        AchievementsDetailSheet(
            unlockedAchievements: quizViewModel.getUnlockedAchievements(),
            lockedAchievements: quizViewModel.getLockedAchievements(),
            userProgress: quizViewModel.userProgress,
            achievementProgressGetter: quizViewModel.getAchievementProgress,
            onDone: { showAchievementsSheet = false }
        )
    }
} 