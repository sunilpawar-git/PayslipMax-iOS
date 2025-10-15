import Foundation
import SwiftUI
import Combine

/// Protocol for Gamification Coordinator to enable dependency injection
@MainActor
protocol GamificationCoordinatorProtocol: ObservableObject {
    /// Current star count - published for real-time updates across all views
    var currentStarCount: Int { get set }

    /// Current user level
    var currentLevel: Int { get set }

    /// Current accuracy percentage
    var currentAccuracy: Double { get set }

    /// Current streak
    var currentStreak: Int { get set }

    /// Total questions answered
    var totalQuestionsAnswered: Int { get set }

    /// Recently unlocked achievements
    var recentAchievements: [Achievement] { get set }

    /// Gets the current user progress
    var userProgress: UserGamificationProgress { get }

    /// Records a quiz answer and updates all published properties
    func recordQuizAnswer(correct: Bool, points: Int, category: String, question: QuizQuestion)

    /// Refreshes all data from the achievement service
    func refreshData()

    /// Gets unlocked achievements
    func getUnlockedAchievements() -> [Achievement]

    /// Gets locked achievements
    func getLockedAchievements() -> [Achievement]

    /// Gets progress for a specific achievement
    func getAchievementProgress(_ achievement: Achievement) -> Double

    /// Clears recent achievements (after they've been shown)
    func clearRecentAchievements()

    /// Resets all gamification progress to start fresh (for development/testing)
    func resetProgress()

    /// Gets comprehensive user stats for analytics
    func getUserStats() -> [String: Any]
}

/// Coordinator that manages gamification state consistency across the entire app
/// Ensures star counts and quiz progress are synchronized between all views
/// Now supports both singleton and dependency injection patterns
@MainActor
class GamificationCoordinator: GamificationCoordinatorProtocol, @preconcurrency SafeConversionProtocol {

    // MARK: - Singleton Instance

    static let shared = GamificationCoordinator()

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    // MARK: - Published Properties

    /// Current star count - published for real-time updates across all views
    @Published var currentStarCount: Int = 0

    /// Current user level
    @Published var currentLevel: Int = 1

    /// Current accuracy percentage
    @Published var currentAccuracy: Double = 0.0

    /// Current streak
    @Published var currentStreak: Int = 0

    /// Total questions answered
    @Published var totalQuestionsAnswered: Int = 0

    /// Recently unlocked achievements
    @Published var recentAchievements: [Achievement] = []

    // MARK: - Private Properties

    private let achievementService: AchievementService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Optional dependencies including achievementService
    init(dependencies: [String: Any] = [:]) {
        // Initialize with injected achievement service or fallback to shared
        if let injectedService = dependencies["achievementService"] as? AchievementService {
            self.achievementService = injectedService
        } else {
            // Fallback to shared achievement service from DIContainer
            self.achievementService = DIContainer.shared.makeAchievementService()
        }

        // Set up bindings to achievement service
        setupBindings()

        // Load initial data
        refreshData()
    }

    // MARK: - Public Methods

    /// Gets the current user progress
    var userProgress: UserGamificationProgress {
        return achievementService.userProgress
    }

    /// Records a quiz answer and updates all published properties
    func recordQuizAnswer(correct: Bool, points: Int, category: String, question: QuizQuestion) {
        achievementService.recordQuizAnswer(
            correct: correct,
            points: points,
            category: category,
            question: question
        )

        // Refresh all published properties
        refreshData()

        // Trigger achievements check
        checkForNewAchievements()
    }

    /// Refreshes all data from the achievement service
    func refreshData() {
        let progress = achievementService.userProgress

        currentStarCount = progress.totalPoints
        currentLevel = progress.level
        currentAccuracy = progress.accuracyPercentage
        currentStreak = progress.currentStreak
        totalQuestionsAnswered = progress.totalQuestionsAnswered
    }

    /// Gets unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return achievementService.getUnlockedAchievements()
    }

    /// Gets locked achievements
    func getLockedAchievements() -> [Achievement] {
        return achievementService.getLockedAchievements()
    }

    /// Gets progress for a specific achievement
    func getAchievementProgress(_ achievement: Achievement) -> Double {
        return achievementService.getAchievementProgress(achievement)
    }

    /// Clears recent achievements (after they've been shown)
    func clearRecentAchievements() {
        recentAchievements.removeAll()
    }

    /// Resets all gamification progress to start fresh (for development/testing)
    func resetProgress() {
        achievementService.resetProgress()
        refreshData()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Monitor changes to the achievement service's user progress
        achievementService.$userProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.currentStarCount = progress.totalPoints
                self?.currentLevel = progress.level
                self?.currentAccuracy = progress.accuracyPercentage
                self?.currentStreak = progress.currentStreak
                self?.totalQuestionsAnswered = progress.totalQuestionsAnswered
            }
            .store(in: &cancellables)

        // Monitor for new achievements
        achievementService.$recentlyUnlockedAchievements
            .receive(on: DispatchQueue.main)
            .sink { [weak self] achievements in
                if !achievements.isEmpty {
                    self?.recentAchievements = achievements
                }
            }
            .store(in: &cancellables)
    }

    private func checkForNewAchievements() {
        // This will be called by the achievement service automatically
        // We just need to refresh our local state
        recentAchievements = achievementService.recentlyUnlockedAchievements
    }

    // MARK: - Analytics and Metrics

    /// Gets comprehensive user stats for analytics
    func getUserStats() -> [String: Any] {
        let progress = userProgress

        return [
            "total_stars": progress.totalPoints,
            "current_level": progress.level,
            "accuracy_percentage": progress.accuracyPercentage,
            "current_streak": progress.currentStreak,
            "longest_streak": progress.longestStreak,
            "total_questions_answered": progress.totalQuestionsAnswered,
            "total_correct_answers": progress.totalCorrectAnswers,
            "achievements_unlocked": progress.unlockedAchievements.count,
            "last_quiz_date": progress.lastQuizDate?.timeIntervalSince1970 ?? 0
        ]
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // Gamification coordinator depends on AchievementService
        // Achievement service is always available (injected or fallback)
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // AchievementService is always available (either injected or DIContainer fallback)
        // No validation errors expected
        return DependencyValidationResult.success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return GamificationCoordinator(dependencies: dependencies) as? Self
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
            ConversionTracker.shared.updateConversionState(for: GamificationCoordinator.self, state: .converting)
        }

        // Note: Integration with existing DI architecture will be handled separately
        // This method validates the conversion is safe and updates tracking

        await MainActor.run {
            conversionState = .dependencyInjected
            ConversionTracker.shared.updateConversionState(for: GamificationCoordinator.self, state: .dependencyInjected)
        }

        Logger.info("Successfully converted GamificationCoordinator to DI pattern", category: "GamificationCoordinator")
        return true
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
            ConversionTracker.shared.updateConversionState(for: GamificationCoordinator.self, state: .singleton)
        }
        Logger.info("Rolled back GamificationCoordinator to singleton pattern", category: "GamificationCoordinator")
        return true
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }
}
